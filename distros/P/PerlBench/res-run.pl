#!/usr/bin/perl -w

use strict;
use PerlBench qw(make_timeit_sub make_timeit_sub_code);
use PerlBench::Stats qw(calc_stats);
use PerlBench::Utils qw(sec_f);

#use Time::HiRes qw(clock_gettime clock_getres CLOCK_REALTIME CLOCK_MONOTONIC);

$| = 1;

accuracy(10 ** (shift || 5));

sub accuracy {
    my $count = shift;
    print "$count\n";
    print "#,0%,1.5%,2.0%,2.5%\n";
    my $sub = make_timeit_sub('', '', 1, 1);
    $sub->(100);  # cache warmup
    for my $try (1..20) {
	print $try;
	for my $f (1, 1.015, 1.020, 1.025) {
	    my $n = int($f * $count + 0.5);
	    print ",", $sub->($n);
	}
	print "\n";
    }
}
