use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;

# The POD for exit_status() says: "Call this after reading all output;
# returns -1 until the remote process has exited." That describes the
# safe order of operations, but does not say what happens if a caller
# calls it first. This test pins down what actually happens today rather
# than assuming "-1", per the ticket's instruction to document real
# behaviour instead of encoding an assumption.
#
# Finding: libssh's ssh_channel_get_exit_status() pumps the session's
# packet loop internally while it waits for the exit-status message, so
# on the libssh build under test, reading exit_status() BEFORE any read()
# still (a) returns the correct exit code, not -1, and (b) does not
# discard the undrained output -- it stays buffered inside libssh and a
# later read() still returns it in full. Verified here for a small
# command and for 300000 bytes of output. Every assertion here is guarded
# by an alarm() so that if a different libssh build blocks instead
# (rather than pumping the loop), this file fails fast with a diagnostic
# instead of hanging the suite.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

my $ssh = Net::LibSSH->new;
$ssh->option(host       => $srv->host);
$ssh->option(port       => $srv->port);
$ssh->option(user       => scalar getpwuid($<));
$ssh->option(knownhosts => $srv->known_hosts);

$ssh->connect
    or plan skip_all => 'connect failed: ' . ($ssh->error // '');
$ssh->auth_publickey($srv->client_key)
    or plan skip_all => 'auth failed: ' . ($ssh->error // '');

sub with_timeout {
    my ($seconds, $code) = @_;
    my $result;
    local $@;
    eval {
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };
        alarm($seconds);
        $result = $code->();
        alarm(0);
    };
    my $err = $@;
    alarm(0);
    return ($result, $err);
}

# small output, non-zero exit, exit_status() read before ANY read() of stdout
{
    my $ch = $ssh->channel;
    ok $ch->exec('echo some_output_before_exit; exit 5'), 'exec() succeeds';

    my ($rc, $err) = with_timeout(10, sub { $ch->exit_status });
    ok !$err, 'exit_status() called before any read() returns within 10s'
        or diag "exit_status() before drain timed out or died: $err";

  SKIP: {
        skip 'exit_status() before drain did not return -- see diagnostic above', 2 if $err;
        is $rc, 5, 'exit_status() returns the correct code even though stdout was never drained';

        my ($out, $rerr) = with_timeout(10, sub { $ch->read });
        ok !$rerr, 'the undrained output can still be read afterward';
        is $out, "some_output_before_exit\n",
            'exit_status() read first did not discard the undrained output';
    }
    $ch->close;
}

# moderate output (300000 bytes of known content), exit_status() before ANY read
{
    my $ch = $ssh->channel;
    ok $ch->exec('yes ABCDEFGHIJ | head -c 300000'), 'exec() succeeds';

    my ($rc, $err) = with_timeout(15, sub { $ch->exit_status });
    ok !$err, 'exit_status() called before any read() returns within 15s, even with 300000 undrained bytes waiting'
        or diag "exit_status() before drain timed out or died: $err";

  SKIP: {
        skip 'exit_status() before drain did not return -- see diagnostic above', 2 if $err;
        is $rc, 0, 'exit_status() resolves correctly with 300000 bytes of undrained stdout waiting';

        my ($data, $rerr) = with_timeout(15, sub {
            my $buf = '';
            while (1) {
                my $chunk = $ch->read(65536);
                last if length($chunk) == 0;
                $buf .= $chunk;
            }
            return $buf;
        });
        ok !$rerr, 'draining after exit_status() completes within 15s'
            or diag "post-exit_status drain timed out or died: $rerr";
        is length($data // ''), 300000,
            'none of the undrained output was lost by reading exit_status() first';
    }
    $ch->close;
}

done_testing;
