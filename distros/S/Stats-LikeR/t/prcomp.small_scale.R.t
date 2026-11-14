#!/usr/bin/env perl
# prcomp(scale => 1): refuse only an exactly-zero scale, as R does.
#
# PROVENANCE
#
# R 4.6.1, src/library/stats/R/prcomp.R, prcomp.default(): scale. = TRUE goes
# through scale(x, center, scale.), and then
#   if(any(sc == 0)) stop("cannot rescale a constant/zero column to unit variance")
# so only a scale of exactly 0 is an error. The expected sdev is frozen from
#   options(digits=17)
#   x <- cbind((1:10)*1e-20, c(1,4,2,2,2,4,1,2,2,0))
#   prcomp(x, scale. = TRUE)$sdev
# which gives 1.16322565816005796 0.80430471103811163. The same R session
# showed scale()'s "scaled:scale" is exactly 0 for a constant column of 0.1,
# 0.3, 1/3, 0.7, 3e-20 and 123.456 at n = 3, 7, 10, 11 and 100, because
# colMeans() sums in long double; the constant-column cases below are those.
# The data are the invented part: R's own tests do not scale by 1e-20, so
# these are cross-checks against R's rule, not copies of its suite.
#
# TOLERANCE: 1e-13 relative on sdev. The observed disagreement with R is
# below 1e-15 on double, long double and quadmath perls (checked on
# perl-5.12.5 and 5.44.0-quadmath); the bound leaves a hundredfold headroom.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

my @want = (1.16322565816005796, 0.80430471103811163);
my $r = prcomp([map { [$_ * 1e-20, (1, 4, 2, 2, 2, 4, 1, 2, 2, 0)[$_ - 1]] } 1 .. 10], scale => 1);
for my $k (0, 1) {
	cmp_ok(abs($r->{sdev}[$k] - $want[$k]), '<=', 1e-13 * $want[$k], "sdev[$k] with a column of scale 1e-20");
}
# the same data in unit-scale first column gives the same answer (scale invariance)
my $r2 = prcomp([map { [$_, (1, 4, 2, 2, 2, 4, 1, 2, 2, 0)[$_ - 1]] } 1 .. 10], scale => 1);
for my $k (0, 1) {
	cmp_ok(abs($r->{sdev}[$k] - $r2->{sdev}[$k]), '<=', 1e-13 * $want[$k], "sdev[$k] unchanged by rescaling a column");
}
# constant columns have a scale of exactly 0 in R and must still be refused
for my $v (0.1, 0.3, 1 / 3, 0.7, 3e-20, 123.456) {
	for my $n (3, 7, 10, 11, 100) {
		my $d = [map { [$v, ($_ * $_) % 7] } 1 .. $n];
		eval { prcomp($d, scale => 1) };
		like($@, qr/cannot rescale a constant\/zero column to unit variance/, "constant column $v, n = $n");
	}
}
done_testing;
