#!/usr/bin/env perl
# qnorm() near the median, against R 4.6.1.
#
# Provenance: every expected value below was produced by R 4.6.1
# (options(digits=17)) as qnorm(0.5 + 2^-k) and qnorm(0.5 - 2^-k) -- dyadic
# p, so R and this module see the same double -- and as qnorm(p) for the
# Wichura (1988) cases that R's tests/d-p-q-r-tests.R pins at tolerance 1e-15
# (0.25, .001, 1e-20; the literal expectations there are used for those) plus
# a few p near 0.5.  shapiro.test() of the 16 values below is R's own output.
# Before the fix qnorm(0.5 + 1e-10) was 2.5066284462393505e-10 where R gives
# 2.5066284820303544e-10 (8th digit wrong), because Newton's residual
# pnorm(z) - p rounded to 0 near p = 0.5.
#
# Tolerance: relative 1e-14.  Worst observed disagreement with R is 2.2e-16
# (one ulp-pair) on a double perl; the headroom covers long double and
# quadmath builds, where this module is more accurate than R's double.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

sub rel_ok {
	my ($got, $exp, $name) = @_;
	my $err = $exp == 0 ? abs($got) : abs(($got - $exp) / $exp);
	ok($err <= 1e-14, $name) or diag("got $got expected $exp rel err $err");
}
my @grid = (
[3, 0.31863936396437514, -0.31863936396437514],
[5, 0.078412412733112197, -0.078412412733112197],
[8, 0.0097916731613453493, -0.0097916731613453493],
[12, 0.00061196983180892076, -0.00061196983180892076],
[16, 3.8248112110018403e-05, -3.8248112110018403e-05],
[20, 2.3905070062955743e-06, -2.3905070062955743e-06],
[24, 1.4940668789333167e-07, -1.4940668789333167e-07],
[28, 9.3379179933331949e-09, -9.3379179933331949e-09],
[33, 2.9180993729166234e-10, -2.9180993729166234e-10],
[36, 3.6476242161457793e-11, -3.6476242161457793e-11],
[40, 2.279765135091112e-12, -2.279765135091112e-12],
[45, 7.1242660471597251e-14, -7.1242660471597251e-14],
[50, 2.2263331397374141e-15, -2.2263331397374141e-15],
);
for my $g (@grid) {
	my ($k, $hi, $lo) = @$g;
	rel_ok(qnorm(0.5 + 2**-$k), $hi, "qnorm(0.5 + 2^-$k)");
	rel_ok(qnorm(0.5 - 2**-$k), $lo, "qnorm(0.5 - 2^-$k)");
}
my @pts = (
	[0.25, -0.67448975019608171], [0.001, -3.0902323061678132],
	[1e-20, -9.2623400897984052], [0.3, -0.52440051270804067],
	[0.45, -0.12566134685507399], [0.55, 0.12566134685507413],
	[0.7, 0.52440051270804067], [0.2, -0.84162123357291418],
);
rel_ok(qnorm($_->[0]), $_->[1], "qnorm($_->[0])") for @pts;
is(qnorm(0.5), 0, 'qnorm(0.5) is 0');
# R tests/d-p-q-r-tests.R: qnorm(0) == -Inf, qnorm(1) == Inf, qnorm(1.1) NaN
is(qnorm(0), -9**9**9, 'qnorm(0)');
is(qnorm(1),  9**9**9, 'qnorm(1)');
my $sw = shapiro_test([2.1,3.4,1.9,5.6,4.4,3.8,2.7,6.1,4.9,3.3,2.2,5.1,4.0,3.6,2.9,4.7]);
rel_ok($sw->{statistic}, 0.97055007353531986, 'shapiro W unchanged vs R');
rel_ok($sw->{p_value},   0.84743970353870568, 'shapiro p unchanged vs R');
done_testing();
