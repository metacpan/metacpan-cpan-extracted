#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# TELLING A READER THERE IS SOMETHING TO READ.
#
# A publisher writes one byte into the reader's pipe; the reader selects on it.
# Two things make that more than a one-liner, and both have a test here.
#
# COALESCING. Only the publisher that flips a waker's `pending` flag writes a
# byte, so a thousand records cost one wakeup rather than a thousand syscalls.
#
# THE ORDERING, which is the whole correctness: drain the pipe, THEN clear the
# flag, THEN read the ring. Clear first and a publisher can slip between the
# clear and the drain, and its byte is drained by a reader that has already
# decided it is up to date - so the record sits in the ring and the reader sits
# asleep. THE ASSERTION THAT CATCHES THAT IS THE SECOND CONSECUTIVE PUBLISH: the
# first one wakes the reader either way, and a test that publishes once cannot
# tell a correct implementation from a deaf one.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'wakeups are POSIX-only' if $^O eq 'MSWin32';

require POSIX;

my $arena = Shared::Arena->create(size => 512 * 1024);
my $ring  = $arena->ring('woken', slots => 64, slot_size => 128);
ok($arena->wakers(8), 'created the wakers, before any fork');

# A region that never called wakers has none, and says so rather than lying.
{
    my $other = Shared::Arena->create(size => 64 * 1024);
    is($other->waker_fd, -1, 'a region with no wakers reports no descriptor');
}

my $idx = $arena->waker;
cmp_ok($idx, '>=', 0, 'this process claimed a waker');
my $fd = $arena->waker_fd;
cmp_ok($fd, '>=', 0, 'and has a descriptor to select on');

open my $rfh, '<&=', $fd or die "fdopen: $!";

sub wait_ready {
    my ($secs) = @_;
    my $bits = '';
    vec($bits, $fd, 1) = 1;
    return select($bits, undef, undef, $secs) > 0;
}

my $cursor = $ring->cursor;

# Nothing published: nothing to wake us.
ok(!wait_ready(0.05), 'an idle ring does not wake anybody');

# ---- a child publishes; the parent must wake ------------------------------
my $pid = fork();
die "fork: $!" unless defined $pid;
if (!$pid) {
    # The child takes its own waker so the parent's poke skips itself properly.
    $arena->waker;
    select undef, undef, undef, 0.1;
    $ring->publish('t', 'first');
    select undef, undef, undef, 0.3;
    $ring->publish('t', 'second');
    POSIX::_exit(0);
}

ok(wait_ready(3), 'the first publish woke the reader');
$arena->drained;
my @got = $cursor->drain;
is(scalar @got, 1, 'and there was one record waiting');
is($got[0][1], 'first', 'which is the one that was published');

# THE ASSERTION THAT MATTERS. A reader that cleared its flag before draining
# its pipe is deaf from here on, and every check above would still have passed.
ok(wait_ready(3), 'the SECOND publish woke the reader too - the flag was '
                . 'cleared after the pipe was drained, not before');
$arena->drained;
@got = $cursor->drain;
is(scalar @got, 1, 'and its record was there');
is($got[0][1], 'second', 'and is the second one');

waitpid $pid, 0;

# ---- a storm of publishes costs one wakeup, not one each ------------------
{
    my $before = 0;
    # Drain anything outstanding so the flag starts clear.
    $arena->drained;
    $cursor->drain;

    my $kid = fork();
    die "fork: $!" unless defined $kid;
    if (!$kid) {
        $arena->waker;
        $ring->publish('t', "burst $_") for 1 .. 200;
        POSIX::_exit(0);
    }
    waitpid $kid, 0;

    ok(wait_ready(3), 'a burst of 200 records woke the reader');

    # Count the bytes actually in the pipe. Coalescing means one, not 200 -
    # and a pipe holding 200 would be 200 syscalls the publishers did not need.
    my $buf = '';
    my $n = sysread($rfh, $buf, 4096);
    cmp_ok($n, '<=', 2, 'and left at most a byte or two in the pipe, not one '
                      . 'per record');

    $arena->drained;
    my @all = $cursor->drain;
    my %s = $cursor->stats;
    # 200 records into 64 slots laps the ring, which is what drop-oldest means -
    # the wakeup said "there is something", not "there is everything".
    cmp_ok(scalar @all, '>', 0, 'and records were waiting to be read');
    cmp_ok(scalar @all, '<=', 64, 'at most a ring-full of them');
    is($s{delivered} + $s{lapped}, 200 + 2,
       'with every record either delivered or counted lost, including the '
     . 'two from the first half of this test');
}

# ---- a wakeup must mean there is something to READ -------------------------
#
# The ordering inside publish that actually carries weight here: the poke goes
# out AFTER the record is committed. Poke first and a reader wakes, finds
# nothing, and goes back to sleep - and nothing will wake it again until the
# next publish, which on a quiet ring may be a long time.
#
# The window is nanoseconds wide in ordinary running, so this uses the stall
# hook to hold a publisher between reserving its sequence and committing it.
# With the poke in the right place the parent stays asleep for the whole stall
# and its first wakeup already has the record behind it.
{
    $arena->drained;
    $cursor->drain;
    $arena->_test_timing(stall_us => 400_000);

    my $kid = fork();
    die "fork: $!" unless defined $kid;
    if (!$kid) {
        $arena->waker;
        $ring->publish('t', 'after the stall');
        POSIX::_exit(0);
    }

    my $woke = wait_ready(3);
    ok($woke, 'the reader was woken');
    $arena->drained;
    my @got = $cursor->drain;
    is(scalar @got, 1,
       'and the record was already readable when it woke - the poke follows '
     . 'the commit, so a wakeup is never a false alarm');
    is($got[0][1], 'after the stall', 'and is the one that was published');

    waitpid $kid, 0;
    $arena->_test_timing(stall_us => 0);
}

done_testing;
