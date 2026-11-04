#!/usr/bin/env perl
# glm(): the fitted-mean floor and the binomial range, against R's own family
# objects.
#
# PROVENANCE
#
# %EXPECT below is frozen output of t/glm_mu_floor.R.R, run under R 4.6.1 with
# MASS 7.3-66 (re-run with `Rscript t/glm_mu_floor.R.R` and paste its block
# over this one).  The rules being tested are R's:
#
#   poisson()$linkinv and $mu.eta   pmax(exp(eta), .Machine$double.eps), in
#                                   src/library/stats/R/family.R;
#                                   MASS::negative.binomial() is the same.
#   binomial() logit linkinv/mu.eta logit_linkinv() and logit_mu_eta() in
#                                   src/library/stats/src/family.c: eta clamped
#                                   at +-30 (THRESH/MTHRESH), mu.eta
#                                   DBL_EPSILON past it.
#   glm.fit()                       no clamp of the variance: it only stops on
#                                   NA or zero.
#
# pois_tiny*, negbin_tiny   fits whose fitted rates reach exp(-60), about 1e-26.
#                   Through 0.3413 glm() floored mu and the variance at 1e-10, and
#                   so missed R's slope by 3.7e-10 (1.0734182285526 against
#                   1.0734182281786).  The data are from the 2026-11-03 audit,
#                   not from R's own tests, which have no such case; the
#                   expected values are R's.
# binom_sep         complete separation, which drives eta well past 30; R stops
#                   at maxit = 25 with a deviance of 7.9e-10.
# binom_quasisep    the same with one swapped observation, a fit that converges.
# D93               src/library/stats/man/glm.Rd and glm.control.Rd:55, the
#                   Dobson (1990) poisson example.
#
# TOLERANCE
#
# 1e-12 relative for the converging fits: the worst observed disagreement with
# R is 3.9e-14 (about 26 times under the bound).  binom_sep stops at maxit with a
# deviance of 8e-10 and a slope that is still moving about 2e-8 per step, so
# it is compared at 1e-6 (observed 6e-7 on the deviance, 2.3e-8 on the slope,
# on this double build).  D93's two zero coefficients are compared absolutely
# at 1e-12 (R's own are 1e-15 rounding noise).
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

my @x  = (-60, -50, -45, -40, -35, -30, -25, -20, 0, 1, 2, 3, 4);
my @y  = (0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 9, 30, 80);
my @xs = (1 .. 10);
my @counts = (18, 17, 15, 20, 10, 20, 25, 13, 12);
my @outcome   = (qw(o1 o2 o3 o1 o2 o3 o1 o2 o3));
my @treatment = (qw(t1 t1 t1 t2 t2 t2 t3 t3 t3));

my %EXPECT = (
	pois_tiny => { coef => [0.10488582499052766, 1.0734182281786178], deviance => 0.24939493397275028, iter => 8, df => 11 },
	negbin_tiny => { coef => [0.008873171833860069, 1.1050665780683973], deviance => 0.016781231771711286, iter => 10, df => 11 },
	pois_tiny_off => { coef => [1.1048858249905271, 1.0734182281786178], deviance => 0.24939493397276205, iter => 8, df => 11 },
	binom_sep => { coef => [-245.84732230400616, 44.69951314748596], deviance => 7.864775496750447e-10, iter => 25, df => 8 },
	binom_quasisep => { coef => [-5.824600705768312, 1.2954370770864758], deviance => 5.013792276988629, iter => 6, df => 8 },
	D93 => { coef => [3.044522437723422, -0.454255272277595, -0.29298712468147264, 1.2175105494406915e-15, 8.437694923483453e-16], deviance => 5.129141077001142, iter => 4, df => 4 },
);

sub rel { my ($g, $e) = @_; return abs($g - $e) / (abs($e) > 1e-300 ? abs($e) : 1); }
my $worst = 0;

sub check {
	my ($name, $fit, $tol, @names) = @_;
	my $e = $EXPECT{$name};
	for my $i (0 .. $#names) {
		my $got = $fit->{coefficients}{ $names[$i] };
		my $d = abs($e->{coef}[$i]) < 1e-10 ? abs($got - $e->{coef}[$i]) : rel($got, $e->{coef}[$i]);
		$worst = $d if $d > $worst && $tol <= 1e-12;
		cmp_ok($d, '<=', $tol, "$name: $names[$i]") or diag("got $got, R $e->{coef}[$i]");
	}
	cmp_ok(rel($fit->{deviance}, $e->{deviance}), '<=', $tol, "$name: deviance")
		or diag("got $fit->{deviance}, R $e->{deviance}");
	is($fit->{iter}, $e->{iter}, "$name: iterations");
	is($fit->{df_residual}, $e->{df}, "$name: residual df");
}

check('pois_tiny', glm(formula => 'y ~ x', data => { x => \@x, y => \@y }, family => 'poisson'),
      1e-12, 'Intercept', 'x');
check('pois_tiny_off',
      glm(formula => 'y ~ x + offset(o)', data => { x => \@x, y => \@y, o => [(-1) x 13] }, family => 'poisson'),
      1e-12, 'Intercept', 'x');
check('negbin_tiny',
      glm(formula => 'y ~ x', data => { x => \@x, y => \@y }, family => 'negbin', theta => 2),
      1e-12, 'Intercept', 'x');
check('binom_sep',
      glm(formula => 'y ~ x', data => { x => \@xs, y => [0,0,0,0,0,1,1,1,1,1] }, family => 'binomial'),
      1e-6, 'Intercept', 'x');
check('binom_quasisep',
      glm(formula => 'y ~ x', data => { x => \@xs, y => [0,0,0,1,0,1,1,1,1,1] }, family => 'binomial'),
      1e-12, 'Intercept', 'x');
{
	my $f = glm(formula => 'counts ~ outcome + treatment',
	            data => { counts => \@counts, outcome => \@outcome, treatment => \@treatment },
	            family => 'poisson');
	check('D93', $f, 1e-12, 'Intercept', 'outcomeo2', 'outcomeo3', 'treatmentt2', 'treatmentt3');
}
diag(sprintf('worst relative disagreement with R: %.3g', $worst));
done_testing();
