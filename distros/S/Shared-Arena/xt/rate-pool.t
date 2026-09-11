#!/usr/bin/perl
# The limit holds across processes at a limit worth having.
#
# t/22-rate.t asserts this with four children and twenty tokens, which finishes
# inside a millisecond. That is small enough to have passed for a year against a
# limiter that stopped limiting entirely above a few thousand tokens: the bug
# needed the run to cross millisecond boundaries before two processes could
# disagree about the time. See t/23-rate-clock.t, which reproduces the mechanism
# exactly and in no time at all.
#
# This is the end-to-end version, in xt/ because it wants real contention and
# half a second to get it.

use strict;
use warnings;
use Test::More;
use blib;
use Shared::Arena;
use Time::HiRes qw(time);

plan skip_all => 'needs fork'    if $^O eq 'MSWin32';
plan skip_all => 'no atomics'    unless Shared::Arena->have_atomics;

for my $limit (100_000, 1_000_000) {
    my $arena = Shared::Arena->create(size => 8 << 20);
    my $rl = $arena->rate('pool', limit => $limit, window => 3600, slots => 256);

    # Half the budget each, so three of them together ask for half again as
    # much as the bucket holds.
    my $each = int($limit / 2) + 1000;
    my @pid;
    my $t0 = time;
    for (1 .. 3) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) { $rl->allow('k') for 1 .. $each; exit 0 }
        push @pid, $pid;
    }
    waitpid($_, 0) for @pid;
    my $ms = (time - $t0) * 1000;

    my %st = $rl->stats;

    # Tokens that legitimately accrued while the test ran. Asserting against
    # the bare limit would fail on a slow smoker for the right reasons, which
    # is its own kind of wrong.
    my $accrued = $ms * $limit / 3_600_000;
    my $ceiling = $limit + $accrued + $limit * 0.001;

    cmp_ok($st{allowed}, '<=', $ceiling,
           "limit $limit: allowed $st{allowed} against a ceiling of "
           . int($ceiling) . " (${\ int $ms }ms, $st{denied} denied)");
    cmp_ok($st{denied}, '>', 0,
           "limit $limit: and it actually refused the overspend");
}

done_testing();
