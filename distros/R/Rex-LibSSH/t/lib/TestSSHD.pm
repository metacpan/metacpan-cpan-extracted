package TestSSHD;

use strict;
use warnings;

use File::Temp qw(tempdir);
use IO::Socket::INET;
use POSIX qw(SIGTERM);

my $SFTP_SERVER = do {
    my @candidates = qw(
        /usr/lib/openssh/sftp-server
        /usr/libexec/openssh/sftp-server
        /usr/libexec/sftp-server
    );
    my ($found) = grep { -x $_ } @candidates;
    $found // '';
};

sub start {
    my ($class) = @_;

    my $sshd = do {
        my ($found) = grep { -x $_ } qw(/usr/sbin/sshd /usr/bin/sshd);
        $found // return undef;
    };

    -x '/usr/bin/ssh-keygen' or return undef;

    my $dir = tempdir(CLEANUP => 1);

    system('ssh-keygen', '-t', 'ed25519', '-N', '', '-f', "$dir/host_key", '-q') == 0
        or return undef;

    system('ssh-keygen', '-t', 'ed25519', '-N', '', '-f', "$dir/client_key", '-q') == 0
        or return undef;

    system('cp', "$dir/client_key.pub", "$dir/authorized_keys") == 0
        or return undef;
    chmod 0600, "$dir/authorized_keys";

    my $port = _free_port() or return undef;
    my $user = getpwuid($<);

    my $cfg = "$dir/sshd_config";
    open my $fh, '>', $cfg or return undef;
    print $fh <<"CONFIG";
Port $port
HostKey $dir/host_key
AuthorizedKeysFile $dir/authorized_keys
PidFile $dir/sshd.pid
LogLevel ERROR
StrictModes no
UsePAM no
AllowUsers $user
CONFIG
    print $fh "Subsystem sftp $SFTP_SERVER\n" if $SFTP_SERVER;
    close $fh;

    my $pid = fork();
    return undef unless defined $pid;

    if ($pid == 0) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        exec $sshd, '-D', '-f', $cfg;
        exit 1;
    }

    # Wait until the port is open (up to 5s)
    my $started;
    for (1..50) {
        if (IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port", Timeout => 0.1)) {
            $started = 1;
            last;
        }
        select undef, undef, undef, 0.1;
    }

    unless ($started) {
        kill SIGTERM, $pid;
        waitpid $pid, 0;
        return undef;
    }

    return bless {
        dir        => $dir,
        pid        => $pid,
        port       => $port,
        host       => '127.0.0.1',
        client_key => "$dir/client_key",
        has_sftp   => $SFTP_SERVER ? 1 : 0,
    }, $class;
}

sub port       { $_[0]->{port}       }
sub host       { $_[0]->{host}       }
sub client_key { $_[0]->{client_key} }
sub has_sftp   { $_[0]->{has_sftp}   }

sub DESTROY {
    my ($self) = @_;
    if ($self->{pid}) {
        kill SIGTERM, $self->{pid};
        waitpid $self->{pid}, 0;
    }
}

sub _free_port {
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or return undef;
    my $port = $sock->sockport;
    $sock->close;
    return $port;
}

1;
