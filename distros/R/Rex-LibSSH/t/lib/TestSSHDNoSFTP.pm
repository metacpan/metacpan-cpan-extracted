package TestSSHDNoSFTP;

use strict;
use warnings;

use File::Temp qw(tempdir);
use IO::Socket::INET;
use POSIX qw(SIGTERM);

# Like TestSSHD, but writes an sshd_config WITHOUT a `Subsystem sftp` line.
# This is the configuration Rex::LibSSH exists for: minimal containers and
# Hetzner dedicated servers ship sshd without SFTP, and the OpenSSH/SSH
# backends crash on them with "Can't call method \"stat\" on an undefined
# value". has_sftp is hardcoded to 0 so the test can sanity-check that the
# harness really is what it claims to be.

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

    # A known_hosts that trusts exactly this server, in the bracketed
    # [host]:port form libssh expects for a non-22 port. Mirrors TestSSHD.pm
    # so callers can rely on the same accessor regardless of which harness
    # started the daemon.
    {
        open my $pub, '<', "$dir/host_key.pub" or return undef;
        my $line = <$pub>;
        close $pub;
        defined $line or return undef;
        chomp $line;
        open my $kh, '>', "$dir/known_hosts" or return undef;
        print $kh "[127.0.0.1]:$port $line\n";
        close $kh;
    }

    my $cfg = "$dir/sshd_config";
    open my $fh, '>', $cfg or return undef;

    # NOTE: no `Subsystem sftp` line — that is the whole point of this harness.
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
        dir          => $dir,
        pid          => $pid,
        port         => $port,
        host         => '127.0.0.1',
        client_key   => "$dir/client_key",
        host_key_pub => "$dir/host_key.pub",
        known_hosts  => "$dir/known_hosts",
        has_sftp     => 0,
    }, $class;
}

sub port         { $_[0]->{port}         }
sub host         { $_[0]->{host}         }
sub client_key   { $_[0]->{client_key}   }
sub host_key_pub { $_[0]->{host_key_pub} }
sub known_hosts  { $_[0]->{known_hosts}  }
sub has_sftp     { $_[0]->{has_sftp}     }    # always 0 — that is the whole point

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
