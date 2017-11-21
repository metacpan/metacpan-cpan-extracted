#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(
	linear_width => 1, only_linear => 1);

$stat->add_data( 1 .. 5 );

is $stat->mean, 3, "<x> == 3";
is $stat->abs_moment(1), 1.2, "<|x-3|> == 6/5";
is $stat->abs_moment(1, 0), 3, "<x-0> == 3";
is $stat->abs_moment(1, 1), 2, "<x-1> == 2";

is $stat->abs_moment(3), 3.6, "<|x-3|**3> == 18/5";
is $stat->std_moment(3), 0, "<(x-3)**3> == 0 (cancels out)";
is $stat->std_moment(9), 0, "<(x-3)**9> == 0 (cancels out)";

note "WHOLE STDEV DISTRO";
$stat = Statistics::Descriptive::LogScale->new(
	linear_width => 1, only_linear => 1);

my @sample = (11, (1) x 7); # n = 8, sum = 18, sum_sq = 128
$stat->add_data( @sample, map { -$_ } @sample );

is $stat->mean, 0, "mean == 0";
is $stat->stdev(0), 4, "stdev == 4";

is $stat->std_abs_moment( 1 ), 18/8/4, "std_abs_moment(1)";
is $stat->std_abs_moment( 3 ), 1338/8/64, "std_abs_moment(3)";

done_testing;
