#!/usr/bin/perl
# A counter under real contention loses nothing it does not report.
#
# t/14-map.t asserts this with four children and a thousand increments, which
# finishes in a millisecond or two. That was small enough to pass for several
# releases against a write path that abandoned its write after burning a
# hundred thousand test-and-sets on a lock byte whose holder was not scheduled:
# an Alpine smoker read 999 of that thousand, and a FreeBSD one 38 of 40 in
# t/32-map-ttl.t. Neither table was anywhere near full.
#
# Two things were wrong and both are tested here.
#
# THE WAIT. A write now waits out an ordinary preemption by the holder rather
# than spinning through its budget and giving up, so at the concurrency the
# t/ tests use nothing is refused at all.
#
# THE INVARIANT, which holds at ANY concurrency and is the one that matters: a
# write that did not happen SAYS SO. incr answers undef, `busy` counts it, and
# the hits that landed plus the refusals that were reported add up to exactly
# what was asked for. A bounded wait can always be beaten by enough contenders
# - a test-and-set lock makes no fairness promise, so a waiter can be starved
# whatever the budget - and a library that cannot promise "never refused" must
# at least promise "never silently". That is the promise with teeth: a caller
# that needs every hit can retry on undef, and one that gets a short total
# with no refusals has found a bug.
#
# In xt/ because it wants real contention, more processes than the box has
# cores, and a couple of seconds to get them.

use strict;
use warnings;
use Test::More;
use blib;
use Shared::Arena;
use POSIX ();
use Time::HiRes ();

plan skip_all => 'needs fork' if $^O eq 'MSWin32';
plan skip_all => 'no atomics' unless Shared::Arena->have_atomics;

# THE CHILDREN HAVE TO START TOGETHER. Without a gate the first ones finish
# their whole run before the last are forked, the stripe is never actually
# contended, and the run proves nothing - which is how a four-child test went
# on passing over a write path that dropped writes.
sub burst {
    my ($kids, $each) = @_;

    my $arena = Shared::Arena->create(size => 8 << 20);
    my $m     = $arena->map('ctr',  slots => 64, slot_size => 128);
    my $gate  = $arena->map('gate', slots => 8,  slot_size => 64);

    my @pid;
    for (1 .. $kids) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            1 while !$gate->exists('go');
            # Count what was REFUSED, not just what was asked. An increment
            # that answered undef did not happen, and a test that throws that
            # answer away cannot tell a lost update from an unasked one.
            my $refused = 0;
            for (1 .. $each) { $refused++ unless defined $m->incr('hot') }
            POSIX::_exit($refused > 254 ? 254 : $refused);
        }
        push @pid, $pid;
    }

    Time::HiRes::sleep(0.25);        # let every child reach the gate
    $gate->store('go', '1');

    my $refused = 0;
    for (@pid) { waitpid $_, 0; $refused += ($? >> 8) }

    my %s = $m->stats;
    return ($m->counter('hot'), $refused, \%s);
}

# ---- at the concurrency the t/ tests use, nothing is refused ---------------

{
    my ($got, $refused, $s) = burst(4, 1000);
    is($refused, 0, 'four children, four thousand hits: none refused');
    is($got, 4000, 'and every one of them landed');
    is($s->{busy}, 0, 'no write gave up waiting');
    is($s->{full}, 0, 'and nothing was called "full": there was room');
}

# ---- oversubscribed, nothing vanishes without saying so --------------------
#
# Refusals are allowed here and the count may legitimately come up short; what
# is NOT allowed is a shortfall larger than what was reported, or a transient
# refusal wearing the name of a permanent one.
#
# TWO HUNDRED, AND THE NUMBER IS CALIBRATED RATHER THAN CHOSEN. At 48 the
# release this test was written against lost a couple of hits in ten runs, so
# most single runs saw nothing and the test passed over the very bug it exists
# for. At 200 on a ten-core box it lost three or four EVERY run. A test of a
# race has to be run at a level where the race actually happens, and the way
# to know is to put the old code back and watch it fail.

{
    my $kids = 200;
    my $each = 200;
    my $want = $kids * $each;

    # THREE BURSTS, SUMMED, BECAUSE ONE QUIET RUN MUST NOT HIDE THE DEFECT.
    # Whether a given burst refuses anything at all depends on what else the
    # box is doing: against the old code one run in three came through clean
    # and the whole file passed on it. Summing makes a single quiet burst
    # harmless instead of exculpatory.
    my ($landed, $refused, $busy, $full, $over) = (0, 0, 0, 0, 0);
    for my $run (1 .. 3) {
        my ($got, $ref, $s) = burst($kids, $each);
        note sprintf 'burst %d: %d of %d landed, %d refused, busy=%d, full=%d',
            $run, $got, $want, $ref, $s->{busy}, $s->{full};
        $landed  += $got;
        $refused += $ref;
        $busy    += $s->{busy};
        $full    += $s->{full};
        $over++ if $got > $want;
    }

    is($over, 0, 'no hit was counted twice in any burst');
    is($landed + $refused, 3 * $want,
       'every hit either landed or was refused out loud: '
     . 'nothing vanished silently');
    is($full, 0,
       'and a contended stripe is never reported as a full table: '
     . 'full means stop, busy means try again');
    my $s = { busy => $busy };

    # AND THE REFUSALS ARE IN THE STATS. This is the assertion that fails on
    # the release before this one, where a write refused for a held stripe
    # returned the same code as a full table and was then counted in NO
    # statistic at all: `stats` showed a clean map while writes went missing,
    # so the only evidence was a short total. A refusal the stats cannot see
    # is a refusal nobody will diagnose.
    if ($refused) {
        is($s->{busy}, $refused,
           "all $refused refusals are visible in stats: a dropped write "
         . 'leaves a trace');
    }
    else {
        pass('nothing was refused, so there is nothing to account for');
    }

    # The refusal is the transient one, so insisting works. This is what a
    # caller that needs every hit recorded actually does.
    if ($refused) {
        my $arena = Shared::Arena->create(size => 1 << 20);
        my $m = $arena->map('r', slots => 16, slot_size => 64);
        my $v;
        for (1 .. 50) { last if defined($v = $m->incr('k')) }
        ok(defined $v, 'a retry on undef gets through');
    }
    else {
        pass('nothing was refused even oversubscribed');
    }
}

done_testing;
