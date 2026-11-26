package FakeSSHD;

# Starts t/lib/fake-sshd.c: a one-connection SSH server that lets any client
# in with auth "none" and then plays a switch's "User Name:" / "Password:"
# dialog on an interactive shell. The C source is compiled on the fly against
# the same Alien::libssh the module itself links, so the fake speaks exactly
# the protocol the binding is built for.
#
# start() returns undef only when there is no C compiler at all (the caller
# says so out loud); a compiler that fails on the source is a die, not a
# skip -- a broken fake server must not turn the suite green.

use strict;
use warnings;

use Alien::libssh;
use Config;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Handle;
use IO::Socket::INET;
use POSIX qw(SIGTERM);

my $BINARY;    # compiled once per process

sub _binary {
    return $BINARY if defined $BINARY;

    my $cc = $Config{cc} || 'cc';
    my $has_cc = grep { -x File::Spec->catfile($_, (split ' ', $cc)[0]) }
        File::Spec->path;
    return unless $has_cc;

    my $src = File::Spec->catfile(dirname(__FILE__), 'fake-sshd.c');
    my $dir = tempdir(CLEANUP => 1);
    my $out = "$dir/fake-sshd";

    my @cmd = (
        split(' ', $cc),
        '-Wno-deprecated-declarations',
        split(' ', Alien::libssh->cflags),
        '-o', $out, $src,
        split(' ', Alien::libssh->libs),
    );
    system(@cmd) == 0 or die "cannot compile fake-sshd.c: @cmd\n";
    return $BINARY = $out;
}

sub start {
    my ($class, @args) = @_;

    my $binary = _binary() or return undef;
    my $dir    = tempdir(CLEANUP => 1);
    my $port   = _free_port() or die "no free port\n";

    pipe(my $rd, my $wr) or die "pipe: $!\n";
    my $pid = fork();
    die "fork: $!\n" unless defined $pid;
    if ($pid == 0) {
        close $rd;
        open STDOUT, '>&', $wr or exit 1;
        open STDERR, '>', "$dir/stderr" or exit 1;
        exec $binary, $port, @args;
        exit 1;
    }
    close $wr;

    my ($key, $ready);
    while (defined(my $line = <$rd>)) {
        chomp $line;
        $key   = $1 if $line =~ /^KEY (.+)/;
        $ready = 1, last if $line eq 'READY';
    }
    unless ($ready) {
        kill SIGTERM, $pid;
        waitpid $pid, 0;
        my $err = do { local (@ARGV, $/) = "$dir/stderr"; <> } // '';
        die "fake-sshd did not become ready: $err\n";
    }

    open my $kh, '>', "$dir/known_hosts" or die "known_hosts: $!\n";
    print $kh "[127.0.0.1]:$port $key\n";
    close $kh;

    return bless {
        dir         => $dir,
        pid         => $pid,
        port        => $port,
        host        => '127.0.0.1',
        known_hosts => "$dir/known_hosts",
    }, $class;
}

sub port        { $_[0]->{port}        }
sub host        { $_[0]->{host}        }
sub known_hosts { $_[0]->{known_hosts} }

# What the server printed on stderr, e.g. why a handshake failed.
sub stderr_text {
    my ($self) = @_;
    return do { local (@ARGV, $/) = "$self->{dir}/stderr"; <> } // '';
}

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
