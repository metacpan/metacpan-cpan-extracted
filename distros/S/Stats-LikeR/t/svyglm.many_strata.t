#!/usr/bin/env perl
# svyglm() variance accumulation over many strata and uneven PSU counts.
#
# PROVENANCE
#
# This is a regression test for a pure performance change (the per-stratum
# variance loop went from O(strata * PSUs) to a counting sort of the PSUs by
# stratum). It is NOT pinned to R: the expected numbers were frozen from the
# 0.3419 build BEFORE that change (by running the design below on it), so
# that the new code is shown to accumulate in the same
# order (bit-identical). The R-pinned correctness tests are t/svyglm.R.t.
#
# To regenerate, run the design below on a build you trust and print each
# summary value with "%.17g".
# Design: 40 strata, stratum h has 2 + h % 3 PSUs of 3 rows each, dyadic
# y, x and weights (multiples of 1/8 and 1/4) under srand(7).
#
# TOLERANCE: 1e-12 relative on Estimate, Std. Error and t value, 1e-10 on
# Pr(>|t|). On a double perl the old and new builds agree to every printed
# digit (so the new code is bit-identical there). The literals are double
# results, so a quadmath perl, whose own sums are the more accurate, differs
# from them by up to 2e-15 relative on the estimates and standard errors,
# 3e-14 on the t values and 1e-13 on the p-value (a tail 1e-25 out, which
# amplifies the t error); the bounds leave a 30x to 1000x headroom over
# those worst cases, measured on 5.44.0-quadmath.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

srand(7);
my (@y, @x, @s, @c, @w);
for my $h (1 .. 40) {
	my $np = 2 + $h % 3;
	for my $u (1 .. $np) {
		for (1 .. 3) {
			push @s, $h; push @c, "$h.$u";
			push @x, int(rand(64)) / 8; push @y, int(rand(64)) / 8;
			push @w, 1 + int(rand(8)) / 4;
		}
	}
}
my $r = Stats::LikeR::svyglm(formula => 'y~x', data => {y => \@y, x => \@x, s => \@s, c => \@c, w => \@w},
	strata => 's', cluster => 'c', weights => 'w', nest => 1);
is($r->{degf}, 80, 'degf');
my %expect = (
	Intercept => {Estimate => 3.8725454139156827, 'Std. Error' => 0.25152283107035062, 't value' => 15.39639720750653, 'Pr(>|t|)' => 1.692033461794841e-25},
	x => {Estimate => -0.028507893314538308, 'Std. Error' => 0.061372489663659865, 't value' => -0.46450605916055121, 'Pr(>|t|)' => 0.6435628558650035},
);
for my $term (sort keys %expect) {
	for my $k (sort keys %{$expect{$term}}) {
		my ($got, $want) = ($r->{summary}{$term}{$k}, $expect{$term}{$k});
		my $tol = $k eq 'Pr(>|t|)' ? 1e-10 : 1e-12;
		cmp_ok(abs($got - $want), '<=', $tol * abs($want), "$term $k");
	}
}
done_testing;
