#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A WAKER SLOT OUTLIVES ITS OWNER.
#
# Nothing releases a slot on the way out: sa_wake_leave hangs off the region's
# release, and a process that is killed, crashes, or calls _exit runs no such
# thing. So `live` stays set for a process that no longer exists.
#
# Left alone that is permanent and silent. A prefork supervisor hands a
# respawned worker the SAME index its predecessor died holding, the take is
# refused, the worker has no descriptor to watch, and it never reads the ring
# again - while every statistic still reports a healthy pool. Found from the
# other end: a Punk cache stopped invalidating across a worker pool, because
# the pool's second generation of workers could not claim a waker between them.
#
# So a take RECLAIMS a slot whose owner is gone. The assertion that keeps that
# honest is the one BELOW it: a slot whose owner is still alive must still be
# refused, or "reclaim" is just a word for theft.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'wakeups are POSIX-only' if $^O eq 'MSWin32';

require POSIX;

my $arena = Shared::Arena->create(size => 512 * 1024);
my $ring  = $arena->ring('woken', slots => 64, slot_size => 128);
ok($arena->wakers(4), 'created four wakers, before any fork');

# Run $code in a child and hand back what it returned.
#
# POSIX::_exit, not exit: a forked test child runs END blocks, and Test::More's
# would print a second plan and a second summary into the same TAP stream.
sub in_child {
    my ($code) = @_;
    pipe my ($r, $w) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $r;
        my $out = eval { $code->() };
        syswrite $w, defined $out ? $out : "died: $@";
        close $w;
        POSIX::_exit(0);
    }
    close $w;
    my $got = do { local $/; <$r> };
    close $r;
    waitpid $pid, 0;
    return $got;
}

# ---- the reclaim ------------------------------------------------------------

is(in_child(sub { $arena->waker(0) }), '0', 'a child claimed waker 0');

is(in_child(sub { $arena->waker(0) }), '0',
    'and the next child gets waker 0 TOO - the slot did not die with its '
  . 'owner, which is what left a respawned worker deaf for ever');

# A number is not a wakeup. The slot has to be a working pipe: a byte left in
# it by the dead owner, or a `pending` flag it never cleared, would leave the
# new owner either woken by nothing or woken by nothing ever again.
{
    pipe my ($r, $w)          or die "pipe: $!";
    pipe my ($ready_r, $ready_w) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $r; close $ready_r;
        my $idx = $arena->waker(0);
        my $fd  = $arena->waker_fd;
        syswrite $ready_w, 'go';
        close $ready_w;
        my $woke = 0;
        if ($fd >= 0) {
            my $bits = '';
            vec($bits, $fd, 1) = 1;
            $woke = select($bits, undef, undef, 5) > 0 ? 1 : 0;
        }
        syswrite $w, "$idx:$fd:$woke";
        close $w;
        POSIX::_exit(0);
    }
    close $w; close $ready_w;
    sysread $ready_r, my $go, 8;
    close $ready_r;
    select undef, undef, undef, 0.1;      # let it reach the select
    $ring->publish('t', 'payload');
    my $got = do { local $/; <$r> };
    close $r;
    waitpid $pid, 0;

    my ($idx, $fd, $woke) = split /:/, ($got // '');
    is($idx, 0, 'a third child reclaimed waker 0');
    cmp_ok($fd, '>=', 0, 'and was given a descriptor');
    is($woke, 1,
        'and a publish WOKE it - a reclaimed slot is a working pipe with a '
      . 'clear flag, not just an index that was handed back');
}

# ---- and what it must NOT do ------------------------------------------------

{
    pipe my ($ready_r, $ready_w) or die "pipe: $!";
    pipe my ($hold_r,  $hold_w)  or die "pipe: $!";
    my $holder = fork // die "fork: $!";
    if (!$holder) {
        close $ready_r; close $hold_w;
        syswrite $ready_w, $arena->waker(1);
        close $ready_w;
        sysread $hold_r, my $stay, 1;     # hold the slot until told to go
        POSIX::_exit(0);
    }
    close $ready_w; close $hold_r;
    sysread $ready_r, my $held, 8;
    close $ready_r;
    is($held, '1', 'a child holds waker 1');

    is(in_child(sub { $arena->waker(1) }), '-1',
        'and another is REFUSED it while that owner is alive - a reclaim '
      . 'takes a dead process\'s slot, never a live one\'s pipe');

    syswrite $hold_w, 'x';
    close $hold_w;
    waitpid $holder, 0;

    is(in_child(sub { $arena->waker(1) }), '1',
        'once the holder has gone the same slot is available again');
}

# ---- "any free slot", when none of them is free ------------------------------
#
# The index path is what a supervisor uses. This is the other one, and it has
# the same hole: every slot live, every owner gone, and a caller asking for
# whatever is going was told there was nothing.
{
    for my $i (0 .. 3) { in_child(sub { $arena->waker($i) }) }

    cmp_ok(in_child(sub { $arena->waker(-1) }), '>=', 0,
        'with every slot held by a DEAD owner, "any free slot" reclaims one '
      . 'rather than answering -1 and leaving the caller to poll for ever');
}

done_testing;
