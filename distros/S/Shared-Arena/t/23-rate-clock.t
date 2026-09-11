#!/usr/bin/perl
# A timestamp from the future must not read as a refill.
#
# A caller reads the clock once and then races for its slot. In between, another
# process can store a timestamp LATER than the one this caller is holding, so
# `now` is behind what the slot says. Computed unsigned, that one millisecond
# becomes 4,294,967,295 of them, which clears any window, and the bucket comes
# back FULL. The limiter then allows everything.
#
# Measured before the fix, three processes on one key: 88 backwards readings in
# 1.5 million calls, and 88 refills to full - 88 million tokens handed to a
# bucket holding one million. Every request allowed, `denied` exactly zero.
#
# Reproducing that by contention takes half a second and a race that a loaded
# smoker may lose. `_skew` produces the same condition exactly, in one process,
# with no timing in it at all.

use strict;
use warnings;
use Test::More;
use blib;
use Shared::Arena;

plan skip_all => 'no atomics in this build' unless Shared::Arena->have_atomics;

my $arena = Shared::Arena->create(size => 1 << 20);

# ---- a timestamp from the future is not time that has passed ---------------
{
    my $rl = $arena->rate('future', limit => 10, window => 60, slots => 64);

    ok($rl->allow('k'), "spends its first token") for 1 .. 1;
    $rl->allow('k') for 1 .. 9;
    ok(!$rl->allow('k'), 'the bucket is empty');

    # Another process stored a timestamp five milliseconds ahead of ours.
    $rl->_skew('k', 5);

    ok(!$rl->allow('k'),
       'a timestamp five milliseconds ahead is not forty-nine days of refill');
    cmp_ok($rl->remaining('k'), '<', 1,
           'and the bucket is still empty when asked directly');
}

# ---- the same thing through the peeking path -------------------------------
#
# `remaining` and `retry_after` refill without spending, so they read the same
# elapsed time and would report a full bucket to a status page and a header
# while `allow` was refusing. Both paths, or the fix is half a fix.
{
    my $rl = $arena->rate('peek', limit => 10, window => 60, slots => 64);
    $rl->allow('k') for 1 .. 10;
    is(int $rl->remaining('k'), 0, 'empty before the skew');

    $rl->_skew('k', 50);
    cmp_ok($rl->remaining('k'), '<', 1, 'remaining does not invent a full bucket');
    cmp_ok($rl->retry_after('k'), '>', 0, 'and retry_after still says to wait');
}

# ---- a refusal does not drag the bucket's clock backwards ------------------
#
# A caller holding a stale reading must not write it over a later one: that
# throws away time another process already accounted for, and hands the next
# caller a refill it has not earned.
#
# One token per millisecond here, so 200ms of stolen time is 200 tokens and the
# two answers cannot be confused. No sleep: the skew supplies the interval.
{
    my $rl = $arena->rate('stamp', limit => 1000, window => 1, slots => 64);
    $rl->allow('k') for 1 .. 1000;
    cmp_ok($rl->remaining('k'), '<', 50, 'drained');

    $rl->_skew('k', 200);       # somebody else's clock, 200ms ahead
    $rl->allow('k');            # refused, and writes a timestamp back
    $rl->_skew('k', -200);      # real time again

    cmp_ok($rl->remaining('k'), '<', 50,
           'the refusal kept the later timestamp, so no time was invented');
}

# ---- and it still refills when time really has passed ----------------------
#
# The fix must not turn into "never refill". This is the assertion that a
# mutation replacing the elapsed calculation with zero would survive without.
{
    my $rl = $arena->rate('forward', limit => 1000, window => 1, slots => 64);
    $rl->allow('k') for 1 .. 1000;
    cmp_ok($rl->remaining('k'), '<', 50, 'drained');

    # Move the stored timestamp 300ms into the PAST, which is what 300ms of
    # real elapsed time looks like to the next caller.
    $rl->_skew('k', -300);
    cmp_ok($rl->remaining('k'), '>', 250, 'time that really passed does refill');
    ok($rl->allow('k'), 'and the refilled tokens can be spent');
}

# ---- the boundary the signed difference buys, pinned ------------------------
#
# A signed difference measures forward intervals up to half the field: 24.9
# days rather than 49.7. Past that a key measures short and refills slower than
# it should, once, for one hit. That is the accepted trade - wrong in the
# direction of refusing rather than allowing - and it is asserted here so that
# nobody restores the unsigned version to "fix" it and brings the real bug back
# with it.
#
# The wrap itself is not testable from here: it needs `now` to have just rolled
# past zero, which no test can arrange, and it is the same int32 cast the two
# assertions above already exercise.
{
    my $rl = $arena->rate('cap', limit => 1000, window => 1, slots => 64);
    $rl->allow('k') for 1 .. 1000;
    cmp_ok($rl->remaining('k'), '<', 50, 'drained');

    # A day and a half short of the half-field: still measurable.
    $rl->_skew('k', -(2 ** 31) + 100_000_000);
    cmp_ok($rl->remaining('k'), '>', 250, 'just inside the half-field refills');

    my $rl2 = $arena->rate('cap2', limit => 1000, window => 1, slots => 64);
    $rl2->allow('k') for 1 .. 1000;
    $rl2->_skew('k', -(2 ** 31) - 500);
    cmp_ok($rl2->remaining('k'), '<', 50,
           'past it, the key measures short and refuses rather than allowing');
}

done_testing();
