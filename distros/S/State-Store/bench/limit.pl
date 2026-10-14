#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(clock_gettime CLOCK_PROCESS_CPUTIME_ID);
use State::Store;

# 1,000,000 changes under history limits of 10 and 1,000, and with none:
# what keeping the past cut costs. CPU time for the fixed work, best of
# five, since a million changes is the measure and not a rate.
#
# Usage: perl bench/limit.pl [CHANGES]

my $n = shift // 1_000_000;
print "$n changes of a number; perl $], $^O\n\n";

for my $case (['no limit', undef], ['limit 1,000', 1000], ['limit 10', 10], ['limit 0', 0]) {
    my ($label, $limit) = @$case;
    my $best;
    for (1 .. 5) {
        my $s = State::Store->new(0, defined $limit ? (history => $limit) : ());
        my $t0 = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
        $s->set($_) for 1 .. $n;
        my $t = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $t0;
        $best = $t if !defined $best || $t < $best;
    }
    printf "  %-12s %7.0f ms  %5.0f ns a change\n", $label, $best * 1000, $best * 1e9 / $n;
}
