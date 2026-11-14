#!/usr/bin/env perl
# zerotrunc() and hurdle() with counts in the thousands.
#
# PROVENANCE
#
# %ZT and %HU are frozen output of t/zerotrunc.large_counts.R.R (re-run:
# `Rscript t/zerotrunc.large_counts.R.R`) under R 4.6.1 with countreg 0.3-0
# zerotrunc(y ~ x, dist = "negbin") and pscl 1.5.9
# hurdle(y ~ x | x, dist = "negbin", zero.dist = "binomial").  The data are
# simulated there (set.seed(7)): negative binomial counts with mean
# 8000 * exp(0.3 x) and size 14.  countreg and pscl stop BFGS at reltol 1e-8,
# so they are matched to 1e-6 relative; the observed disagreement is 2e-8 or
# less (coefficients, SE), 1.3e-9 (theta) and 3e-13 (loglik), and LikeR's
# loglik must be at or above R's.
#
# REGRESSION: until 0.3419 zt_fit() demanded a log-likelihood change below
# 1e-12 * (|ll| + 1) although ll is a sum of terms of order y log y, whose
# rounding noise (about 2e-10 here) is larger.  On this data zerotrunc()
# took 23.6 s and returned converged = 0 after 500 iterations.  The checks
# below require convergence in a few iterations; they do not time anything.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(zerotrunc hurdle);

my %ZT = (
	y => [12966, 11903, 12529, 8565, 7688, 11221, 8385, 11227, 7874, 7128, 7076, 9662, 12318, 7478, 10714, 4919, 11336, 7640, 12488, 11318, 12650, 10156, 8006, 14683, 14284, 7812, 12119, 9171, 9750, 9979, 15322, 9838, 10085, 9354, 8397, 9440, 8748, 12786, 10204, 10348],
	x => [0.98890900000000004, 0.39774500000000002, 0.115698, 0.069749000000000005, 0.24374899999999999, 0.79200999999999999, 0.34006199999999998, 0.97206300000000001, 0.165855, 0.45910400000000001, 0.17174800000000001, 0.23147699999999999, 0.77281200000000005, 0.096301999999999999, 0.45344800000000002, 0.084700999999999999, 0.560666, 0.0087049999999999992, 0.98573699999999997, 0.31658500000000001, 0.63944900000000005, 0.29522300000000001, 0.99670400000000003, 0.90602099999999997, 0.98873900000000003, 0.065645999999999996, 0.62703900000000001, 0.49047499999999999, 0.971024, 0.36222100000000002, 0.67999299999999996, 0.26372000000000001, 0.18571399999999999, 0.185143, 0.379297, 0.847024, 0.49807600000000002, 0.79058600000000001, 0.83846399999999999, 0.45690399999999998],
	coef => [9.0080822315150435, 0.43062079701858985],
	se => [0.054844279533844818, 0.0942660372214503],
	theta => [29.405934686236247],
	ll => [-357.54099947586991],
);
my %HU = (
	y => [0, 0, 0, 0, 7688, 0, 0, 0, 0, 7128, 7076, 9662, 0, 7478, 0, 0, 11336, 7640, 0, 0, 12650, 10156, 8006, 0, 0, 0, 0, 9171, 0, 0, 15322, 9838, 10085, 9354, 0, 0, 0, 0, 0, 0],
	count => [9.0050850277028065, 0.40729169475269156],
	zero => [0.50832578800558736, -2.2006628484232089],
	theta => [26.355075122283264],
	ll => [-158.37619769505048],
);

sub rel_ok {
	my ($got, $want, $tol, $name) = @_;
	my $r = abs($got - $want) / abs($want);
	ok($r <= $tol, $name) or diag("got $got, want $want: relative $r > $tol");
}

my $zt = zerotrunc(formula => 'y ~ x', data => {y => $ZT{y}, x => $ZT{x}}, dist => 'negbin');
ok($zt->{converged}, 'zerotrunc negbin at counts ~1e4 converges');
cmp_ok($zt->{iter}, '<', 30, 'in a handful of iterations, not 500');
rel_ok($zt->{coefficients}{Intercept}, $ZT{coef}[0], 1e-6, 'zerotrunc intercept');
rel_ok($zt->{coefficients}{x}, $ZT{coef}[1], 1e-6, 'zerotrunc slope');
rel_ok($zt->{summary}{x}{'Std. Error'}, $ZT{se}[1], 1e-5, 'zerotrunc slope SE');
rel_ok($zt->{theta}, $ZT{theta}[0], 1e-6, 'zerotrunc theta');
rel_ok($zt->{loglik}, $ZT{ll}[0], 1e-8, 'zerotrunc loglik');
cmp_ok($zt->{loglik}, '>=', $ZT{ll}[0] - 1e-9 * abs($ZT{ll}[0]), "at or above countreg's maximum");

my $h = hurdle(formula => 'y ~ x | x', data => {y => $HU{y}, x => $ZT{x}}, dist => 'negbin', zero_dist => 'binomial');
ok($h->{converged}, 'hurdle negbin at counts ~1e4 converges');
rel_ok($h->{coefficients}{count}{Intercept}, $HU{count}[0], 1e-6, 'hurdle count intercept');
rel_ok($h->{coefficients}{count}{x}, $HU{count}[1], 1e-6, 'hurdle count slope');
rel_ok($h->{coefficients}{zero}{Intercept}, $HU{zero}[0], 1e-6, 'hurdle zero intercept');
rel_ok($h->{coefficients}{zero}{x}, $HU{zero}[1], 1e-6, 'hurdle zero slope');
rel_ok($h->{theta}, $HU{theta}[0], 1e-6, 'hurdle theta');
rel_ok($h->{loglik}, $HU{ll}[0], 1e-8, 'hurdle loglik');

done_testing();
