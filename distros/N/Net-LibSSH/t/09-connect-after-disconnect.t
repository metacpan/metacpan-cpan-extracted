use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;
use Time::HiRes qw(time);

# libssh 0.10.6 cannot reconnect an ssh_session it has already disconnected.
# ssh_connect() does not fail fast on such a session -- it sits out the whole
# SSH_OPTIONS_TIMEOUT and then reports "Timeout connecting to 127.0.0.1",
# measured at 5.005s against a live sshd with timeout => 5. A caller who tries
# to reuse a session therefore waits out a timeout to be told, wrongly, that
# the host is unreachable.
#
# The session now knows it is spent and connect() refuses straight away. What
# it must NOT do is croak: connect()'s contract is 1 or 0 with the message on
# error() (t/01-session.t pins that for a refused port, and Rex::LibSSH relies
# on it), so this is a fast 0 plus an error() that names the real state.
#
# Being spent is not the same as "disconnect() was called". Measured on the
# same libssh: disconnect() on a session that was never connected leaves it
# fully connectable -- connect() afterwards succeeds and authenticates. Only
# the connect -> disconnect transition is terminal, and the last case below is
# what keeps the guard from over-refusing.
#
# This is its own file rather than more cases in t/01-session.t because it
# needs a real successful connection first: folding it in would make that
# whole file -- the option() coverage and the refused-port contract with it --
# skip on any machine without sshd.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

# timeout => 5 is what bounds this test: it is the timeout ssh_connect() would
# wait out on a spent session, so a regression costs five seconds and a failed
# assertion rather than hanging the suite.
sub session {
    my $ssh = Net::LibSSH->new;
    $ssh->option(host       => $srv->host);
    $ssh->option(port       => $srv->port);
    $ssh->option(user       => scalar getpwuid($<));
    $ssh->option(knownhosts => $srv->known_hosts);
    $ssh->option(timeout    => 5);
    return $ssh;
}

sub timed {
    my ($code) = @_;
    my $t0  = time;
    my $rc  = eval { $code->() };
    my $err = $@;
    return ($rc, $err, time - $t0);
}

# --- 1. connect() after disconnect(): fast 0, no croak ----------------------
{
    my $ssh = session();
    ok $ssh->connect, 'connect() succeeds on a fresh session'
        or diag('connect: ' . ($ssh->error // '(no error)'));
    ok $ssh->auth_publickey($srv->client_key), 'auth_publickey() succeeds'
        or diag('auth: ' . ($ssh->error // '(no error)'));

    $ssh->disconnect;

    my ($rc, $err, $elapsed) = timed(sub { $ssh->connect });
    is $err, '', 'connect() on a disconnected session does not croak';
    is $rc,  0,  'connect() on a disconnected session returns 0';

    # The whole point of the ticket: without the guard this is the full
    # SSH_OPTIONS_TIMEOUT (5.005s measured). 1s leaves room for a loaded
    # machine while still being nowhere near the timeout.
    cmp_ok $elapsed, '<', 1,
        sprintf('connect() refuses immediately (%.3fs, was ~5s of timeout)', $elapsed);

    my $msg = $ssh->error;
    ok defined($msg) && length($msg), 'error() is set after the refusal';
    like $msg, qr/disconnect/i, 'error() names the session state';
    unlike $msg, qr/timeout/i,
        'error() no longer blames a timeout for a state we know about';

    # Nothing un-spends the session, and asking twice must not start behaving
    # differently.
    my ($rc2, $err2, $elapsed2) = timed(sub { $ssh->connect });
    is $err2, '', 'a second connect() attempt still does not croak';
    is $rc2,  0,  'and still returns 0';
    cmp_ok $elapsed2, '<', 1, 'and is still immediate';
    like $ssh->error, qr/disconnect/i,
        'and still names the state, not whatever libssh made of the retry';
}

# --- 2. disconnect() on a never-connected session is not terminal -----------
#
# Measured, not assumed: libssh lets this session connect afterwards, so the
# binding must not refuse it. This is the case that decides the guard hangs
# off "was connected", not off "disconnect() was called".
{
    my $ssh = session();
    $ssh->disconnect;

    my ($rc, $err, $elapsed) = timed(sub { $ssh->connect });
    is $err, '', 'connect() after disconnect() on a never-connected session does not croak';
    is $rc,  1,  'and still connects -- disconnect() alone does not spend a session';
    cmp_ok $elapsed, '<', 5, 'without waiting out a timeout';
    ok !defined($ssh->error), 'error() reports nothing after that connect';
    ok $ssh->auth_publickey($srv->client_key),
        'the session is usable: auth_publickey() succeeds on it';
}

done_testing;
