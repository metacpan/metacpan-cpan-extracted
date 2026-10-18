#!/usr/bin/env perl
# smd() against tableone 0.13.2's StdDiff().
#
# PROVENANCE
#
# t/smd.R.R, committed beside this file, generated every literal in @NHANES,
# @R_PAIRS and @SMD_NUMERIC under R 4.6.1 (2026-06-24) at options(digits =
# 17), with survey 4.5 supplying the nhanes data.  Re-run it with
#     Rscript t/smd.R.R
# This test never invokes R; it reads the frozen literals.
#
# tableone is not installed here, so the generator carries StdDiff() and
# CheckNaOnlyStrata() verbatim from R/modules-smd.R in the CRAN source tarball
# tableone_0.13.2.tar.gz (2022-04-15).  The cases are its own, from
# tests/testthat/test-modules-smd.R:
#
#   RIAGENDR, race   "continuous standardized difference is correct (nhanes
#                    unweighted)": HI_CHOL by sex (one contrast) and by race
#                    (six).  HI_CHOL is 0, 1 or NA, so each group is given by
#                    its three counts and rebuilt here.
#   binary_toy       "binary standardized difference is correct", its
#                    continuous half: c(1,0,0,0,0, 1,1,0,0,0, 1,1,1,0,0) in
#                    three groups of five
#   onlyOne          "decent results are returned for anomalous/difficult
#                    data": a column that is 1 on every row, which StdDiff()
#                    redefines from 0/0 to 0
#   onlyNa           the same test: a column that is NA on every row, where
#                    StdDiff() warns and returns NA, and smd() dies
#
# and from smd 0.8.0's tests/testthat/helper_smd.R, the data its
# compare_packages() holds to tableone::ExtractSmd(): rnorm(60) after
# set.seed(123), split into groups of 30 (smd_numeric), and
# rep(rep(1:3, each = 10), times = 2), whose two halves are equal
# (smd_integer).  smd 0.8.0's own estimate divides each variance by n rather
# than n - 1, which is why its test allows tableone a 1% difference; the
# values pinned here are tableone's.
#
# WHAT IT PINS
#
# StdDiff() returns abs(); smd() returns the signed value, (mean(x) -
# mean(y)) / sqrt((var(x) + var(y)) / 2), and the test checks both the sign
# and the magnitude.  A constant column is 0, as StdDiff() and smd 0.8.0
# define it; a column constant within each group but not between them is
# +-Inf, StdDiff()'s mean difference over sqrt(0).  Up to 0.3217 smd() died on
# both with "pooled standard deviation is zero".
#
# TOLERANCE
#
# 1e-13 relative.  The worst disagreement observed on the double build is
# 3.0e-15, on the race 1 vs 2 contrast: the nhanes groups are rebuilt here as
# a run of 0s then a run of 1s, so their sums of squares are added in a
# different order from R's, which takes the rows as they come.  The diag()
# below the loop reports it on every run.  The nhanes and binary_toy data are
# integers, exact at every NV width; smd_numeric is 17-digit decimals of R's
# doubles, which a wider NV reads as slightly different numbers, at a
# relative distance of at most 2^-53 per value.  Across the nine perls of
# ./test.all.perls.pl on 2026-10-17 none was worse than 3.0e-15; the
# long-double and quadmath perls were at 1.9e-15.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(smd);

my $TOL = 1e-13;

# [ grouping, level, zeros, ones, NAs ]
my @NHANES = (
	[ 'RIAGENDR', '1', 3526, 363, 358 ],
	[ 'RIAGENDR', '2', 3533, 424, 387 ],
	[ 'race', '1', 2282, 250, 185 ],
	[ 'race', '2', 3063, 387, 293 ],
	[ 'race', '3', 1302, 104, 217 ],
	[ 'race', '4', 412, 46, 50 ],
);

# [ set, group a, group b, signed smd(a, b), StdDiff()'s abs value ]
my @R_PAIRS = (
	[ 'RIAGENDR', '1', '2', -0.045995031512077969, 0.045995031512077969 ],
	[ 'race', '1', '2', -0.043754382485288512, 0.043754382485288512 ],
	[ 'race', '1', '3', 0.088239256620575468, 0.088239256620575468 ],
	[ 'race', '1', '4', -0.0056751404491549879, 0.0056751404491549879 ],
	[ 'race', '2', '3', 0.13175545500785238, 0.13175545500785238 ],
	[ 'race', '2', '4', 0.03806391850599726, 0.03806391850599726 ],
	[ 'race', '3', '4', -0.093844811443674001, 0.093844811443674001 ],
	[ 'binary_toy', '1', '2', -0.40000000000000002, 0.40000000000000002 ],
	[ 'binary_toy', '1', '3', -0.79999999999999993, 0.79999999999999993 ],
	[ 'binary_toy', '2', '3', -0.36514837167011066, 0.36514837167011066 ],
	[ 'smd_numeric', 'A', 'B', -0.24746528957654787, 0.24746528957654787 ],
	[ 'smd_integer', 'A', 'B', 0, 0 ],
);

# smd 0.8.0's helper_smd.R: set.seed(123); rnorm(60)
my @SMD_NUMERIC = (
	-0.5604756465522126, -0.23017748948327996, 1.558708314149124, 0.070508391424576003,
	0.12928773516094624, 1.715064986883281, 0.4609162059892023, -1.265061234606534,
	-0.68685285189352607, -0.44566197009995806, 1.2240817974394615, 0.35981382705736381,
	0.40077145059405217, 0.11068271594511971, -0.55584113475407493, 1.7869131368030782,
	0.49785047822923939, -1.9666171566296382, 0.70135590156368555, -0.47279140772793404,
	-1.0678237059868452, -0.21797491465829513, -1.0260044483072397, -0.72889122929114025,
	-0.62503926784925667, -1.6866933107424134, 0.83778704449452468, 0.15337311783651522,
	-1.1381369370119476, 1.2538149210699268, 0.42646422147681357, -0.29507148299227115,
	0.89512566104502223, 0.87813348753304221, 0.82158108163748711, 0.688640254100091,
	0.55391765353758882, -0.061911710576721679, -0.30596266373991676, -0.38047100101238268,
	-0.6947069789205127, -0.20791727801959878, -1.2653963515682645, 2.1689559653385126,
	1.2079619983049905, -1.1231085832033492, -0.40288483529907598, -0.46665535362321886,
	0.77996511833631788, -0.083369066471829276, 0.2533185139947548, -0.028546755348703018,
	-0.04287045729131609, 1.3686022840144576, -0.22577098565926762, 1.5164706044295397,
	-1.5487528042302212, 0.58461374963606916, 0.12385424384461378, 0.21594156874397272,
);

# Each group's values.  An nhanes group's NAs are undef in sex group 1 and in
# odd-numbered races and the string 'NA' elsewhere, so both of the ways smd()
# drops a value that is not a number are taken.
my %GROUP;
for my $r (@NHANES) {
	my ($by, $lv, $n0, $n1, $nna) = @$r;
	my $na = $lv % 2 ? undef : 'NA';
	$GROUP{$by}{$lv} = [ (0) x $n0, (1) x $n1, ($na) x $nna ];
}
my @toy = (1,0,0,0,0, 1,1,0,0,0, 1,1,1,0,0);
$GROUP{binary_toy}{$_ + 1} = [ @toy[5 * $_ .. 5 * $_ + 4] ] for 0 .. 2;
$GROUP{smd_numeric}{A} = [ @SMD_NUMERIC[0 .. 29] ];
$GROUP{smd_numeric}{B} = [ @SMD_NUMERIC[30 .. 59] ];
$GROUP{smd_integer}{$_} = [ (1) x 10, (2) x 10, (3) x 10 ] for qw(A B);

my ($worst, $worst_at) = (0, '');
for my $r (@R_PAIRS) {
	my ($set, $a, $b, $signed, $abs) = @$r;
	my $got = smd($GROUP{$set}{$a}, $GROUP{$set}{$b});
	my $name = "$set, $a vs $b";
	if ($signed == 0) {
		is($got, 0, "$name: equal groups give exactly 0");
		next;
	}
	my $err = abs($got - $signed) / abs($signed);
	ok($err <= $TOL, "$name: the signed value") or diag(sprintf "  got %.17g\n  want %.17g", $got, $signed);
	ok(abs(abs($got) - $abs) <= $TOL * $abs, "$name: its magnitude is StdDiff()'s");
	is(smd($GROUP{$set}{$b}, $GROUP{$set}{$a}), -$got, "$name: swapping the groups only flips the sign");
	($worst, $worst_at) = ($err, $name) if $err > $worst;
}
diag(sprintf 'worst relative error vs R: %.2g (%s)', $worst, $worst_at);

# onlyOne: 1 on all 8591 rows, so each group is a run of 1s as long as the
# group.  StdDiff() gives 0 for the sex contrast and for all six race ones.
for my $by (qw(RIAGENDR race)) {
	my @lv = map { $_->[1] } grep { $_->[0] eq $by } @NHANES;
	my %n = map { $_->[1] => $_->[2] + $_->[3] + $_->[4] } grep { $_->[0] eq $by } @NHANES;
	for my $i (0 .. $#lv) {
		for my $j ($i + 1 .. $#lv) {
			is(smd([ (1) x $n{ $lv[$i] } ], [ (1) x $n{ $lv[$j] } ]), 0,
				"onlyOne by $by, $lv[$i] vs $lv[$j]: a constant column is 0, not an error");
		}
	}
}
is(smd([ (1.1) x 3 ], [ (1.1) x 5 ]), 0, 'a constant that is not exact in binary is still 0');

# Constant within each group, different between them: StdDiff() gives Inf
# for c(1,1,1) vs c(2,2,2), the abs() of -1 / sqrt(0).
is(smd([1, 1, 1], [2, 2, 2]), -9**9**9, 'constant groups with different means: -Inf');
is(smd([2, 2, 2], [1, 1, 1]),  9**9**9, 'and +Inf the other way round');

# onlyNa: NA on every row.  StdDiff() warns and returns NA; smd() refuses.
throws_ok { smd([ (undef) x 4247 ], [ (undef) x 4344 ]) }
	qr/^smd: each group needs at least two numeric observations$/m,
	'onlyNa: a column with no numbers is refused';
throws_ok { smd([1, 2, 3], [4]) }
	qr/^smd: each group needs at least two numeric observations$/m,
	'a group of one value is refused';
throws_ok { smd([1, 2, 3], { a => 1 }) }
	qr/^smd: first two arguments must be array references$/m,
	'a hash reference is refused';

# Devel::Cover's own per-line counters are allocated inside whatever block is
# running and are reported as leaks, so the check is skipped under it.
no_leaks_ok {
	smd($GROUP{race}{1}, $GROUP{race}{2});
	smd([1, 1, 1], [1, 1]);
	smd([1, 1, 1], [2, 2]);
	eval { smd([undef, undef], [1, 2]) };
} 'smd does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
