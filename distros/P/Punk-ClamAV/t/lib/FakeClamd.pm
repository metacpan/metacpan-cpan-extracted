package  # not indexed
    FakeClamd;

# A clamd-shaped listener, so this suite runs on a box with no ClamAV.
#
# THE FORK RULE: the child must not keep the parent's STDOUT. It is the
# TAP pipe, the harness waits on it, and a child holding it open means a
# run that passes every assertion and is then killed for hanging.

use strict;
use warnings;
use IO::Socket::UNIX;
use POSIX ();

our $EICAR = 'X5O!P%@AP[4\PZX54(P^)7CC)7}' . '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*';

sub new {
    my ($class, %opt) = @_;
    my $mode = $opt{mode} || 'sniff';
    my $path = "/tmp/pc-t-$$-" . int(rand 9999) . ".s";
    unlink $path;

    pipe(my $rr, my $rw) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if (!$pid) {
        close $rr;
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        close STDIN;

        my $srv = IO::Socket::UNIX->new(Local => $path, Type => SOCK_STREAM, Listen => 5)
            or POSIX::_exit(1);
        syswrite($rw, "1"); close $rw;

        while (my $c = $srv->accept) {
            my $buf = '';
            sysread($c, $buf, 65536);

            if ($mode eq 'stall') {
                # Accept, read the command, and never answer. The client
                # must time out rather than wait forever - on a loop that
                # means racing readiness against a timer, because a
                # readiness future alone never resolves.
                sleep 300;
                next;
            }
            elsif ($mode eq 'slow') {
                # Drain the stream, wait, then answer. A fake on a local
                # socket normally has its reply buffered before the client
                # ever asks - so there is nothing to wait for, and nothing
                # to prove about yielding. This makes the client wait.
                if ($buf =~ /INSTREAM/) {
                    my $tail = $buf;
                    while ($tail !~ /\0\0\0\0\z/) {
                        my $n = sysread($c, my $ch, 65536);
                        last if !defined $n || $n == 0;
                        $tail = substr($tail . $ch, -8);
                    }
                }
                elsif ($buf =~ /FILDES/) { sysread($c, my $pad, 16) }
                select undef, undef, undef, $opt{delay} // 0.3;
                syswrite($c, ($opt{literal} // 'stream: OK') . "\0");
            }
            elsif ($mode eq 'literal') {
                # Drain an INSTREAM body so the client is not left writing.
                if ($buf =~ /INSTREAM/) {
                    my $tail = $buf;
                    while ($tail !~ /\0\0\0\0\z/) {
                        my $n = sysread($c, my $ch, 65536);
                        last if !defined $n || $n == 0;
                        $tail = substr($tail . $ch, -8);
                    }
                }
                elsif ($buf =~ /FILDES/) { sysread($c, my $pad, 16) }
                syswrite($c, ($opt{literal} // 'stream: OK') . "\0");
            }
            elsif ($buf =~ /INSTREAM/) {
                # Read the body and answer on what is actually in it, so a
                # test can post real EICAR and get a real FOUND.
                my $body = $buf;
                my $tail = $buf;
                while ($tail !~ /\0\0\0\0\z/) {
                    my $n = sysread($c, my $ch, 65536);
                    last if !defined $n || $n == 0;
                    $body .= $ch;
                    $tail = substr($tail . $ch, -8);
                }
                syswrite($c, index($body, $EICAR) >= 0
                    ? "stream: Eicar-Test-Signature FOUND\0"
                    : "stream: OK\0");
            }
            elsif ($buf =~ /FILDES/) {
                # A descriptor arrives over SCM_RIGHTS, which core Perl
                # cannot receive - so a fake can never see the contents.
                # It answers what the test asked for instead.
                sysread($c, my $pad, 16);
                syswrite($c, ($opt{fildes} // 'fd[9]: OK') . "\0");
            }
            elsif ($buf =~ /PING/) { syswrite($c, "PONG\0") }
            else                   { syswrite($c, "UNKNOWN COMMAND\0") }
            close $c;
        }
        POSIX::_exit(0);
    }

    close $rw;
    my $ok = sysread($rr, my $sig, 1);
    close $rr;
    unless ($ok) { waitpid($pid, 0); die "FakeClamd failed to bind" }
    return bless { pid => $pid, path => $path }, $class;
}

sub path { $_[0]{path} }
sub stop {
    my ($s) = @_;
    return unless $s->{pid};
    kill 'KILL', $s->{pid};
    waitpid($s->{pid}, 0);
    unlink $s->{path};
    delete $s->{pid};
}
sub DESTROY { local $?; $_[0]->stop }

1;
