#!/usr/bin/env perl
#
# Cross-validation of lm() against the two reference implementations.
#
# Every expected value in this file was produced by one of:
#
#   * R 4.6.1 stats::lm() / summary.lm() -- the function lm() is modelled on.
#     Estimates, standard errors, t values, two-sided Pr(>|t|), the F statistic
#     with both its degrees of freedom, R^2, adjusted R^2, the residual sum of
#     squares, the rank, and the fitted and residual vectors.
#   * statsmodels 0.14.6 OLS, with the tail probabilities recomputed through
#     scipy 1.17.1 (scipy.stats.t.sf, scipy.stats.f.sf).  statsmodels solves by
#     pinv/QR and takes its tails from scipy rather than from R's pt/pf, so it is
#     a genuinely independent second opinion: every case marked ref => 'R+scipy'
#     below agrees with BOTH references, which is what rules out the two of them
#     sharing a bug.
#
# The data sets are R's own built-ins (mtcars, iris, ToothGrowth, warpbreaks,
# airquality), the bodyfat table this distribution already ships, and synthetic
# cases built to reach specific paths: an exactly determined fit, a rank-deficient
# design, hand-placed NAs, p close to n, predictors spanning nine orders of
# magnitude, and factors whose levels are first seen out of alphabetical order.
#
# ---------------------------------------------------------------------------
# On tolerances
#
# lm() solves the normal equations: it forms X'X and sweeps it.  R and
# statsmodels both factor X directly (Householder QR) and never form X'X.
# Forming X'X squares the condition number, so the relative accuracy available
# to lm() is bounded by eps * kappa(X'X), not by eps * kappa(X).  Each case
# carries kappa(X'X) as `cond` to record where that bound sits -- for
# `BodyFat ~ .` it is 2.1e9, which permits 4.6e-7.
#
# That bound is only a ceiling, and using it as the tolerance would accept far
# more error than lm() actually makes.  Each case instead carries a `tol` derived
# from the deviation from R measured when this file was generated, times 200 for
# headroom on other builds (a long-double NV perl rounds the literals below
# differently, and its libm tails differ in the last bits).  The result is tight
# where lm() is accurate and honest where it cannot be:
#
#   13 of the 42 generated cases hold to the 1e-11 floor.
#   For the other 29, worst last -- `on` is the quantity that
#   deviates most, and `permits` is eps * kappa(X'X) for that design:
#
#     warp_fac_inter  5.6e-14  on t_value       permits  2.2e-14
#     tooth_noint_mixed 7.6e-14  on p_value       permits  5.5e-15
#     nasfac_drop     8.7e-14  on p_value       permits  8.2e-14
#     tooth_two       9.9e-14  on p_value       permits  5.3e-15
#     aliased_x3      1.3e-13  on p_value       permits  9.0e+02
#     tooth_interact  1.6e-13  on p_value       permits  2.7e-14
#     mt_two          1.7e-13  on p_value       permits  7.9e-11
#     mt_simple       2.0e-13  on f_pvalue      permits  3.7e-14
#     mt_hp_resp      2.6e-13  on p_value       permits  1.8e-10
#     iris_factor     6.7e-13  on p_value       permits  3.2e-15
#     wide_dot        7.2e-13  on t_value       permits  3.4e-15
#     nasfac_inter    8.2e-13  on t_value       permits  3.4e-13
#     three_way_noint 8.7e-13  on estimate      permits  1.0e-14
#     air_dot         1.0e-12  on p_value       permits  1.6e-09
#     mt_five         1.1e-12  on p_value       permits  1.3e-08
#     mt_colon        1.1e-12  on p_value       permits  9.3e-09
#     mt_star         1.1e-12  on p_value       permits  9.3e-09
#     air_three       1.3e-12  on fitted        permits  1.4e-09
#     mt_dot          2.7e-12  on f_pvalue      permits  3.4e-08
#     mt_quad         2.9e-12  on p_value       permits  4.6e-12
#     bigscale_three  4.4e-12  on p_value       permits  2.5e+04
#     iris_dotted     4.9e-12  on f_pvalue      permits  1.5e-13
#     iris_mixed      5.3e-12  on f_pvalue      permits  6.7e-13
#     three_way       7.2e-12  on estimate      permits  2.1e-12
#     bf_three        1.8e-11  on f_pvalue      permits  5.9e-09
#     mt_cubic        1.0e-10  on t_value       permits  1.8e-09
#     iris_fac_inter  1.6e-10  on f_pvalue      permits  7.2e-12
#     bf_dot          1.1e-08  on residuals     permits  4.8e-07
#     bf_star         1.3e-08  on estimate      permits  6.2e-05
#
# Two independent things move those numbers, which is the reason the tolerance is
# measured rather than predicted:
#
#   * The linear solve, bounded by eps * kappa(X'X).  This is what dominates the
#     two ill-conditioned bodyfat models -- and even they stay well inside the
#     bound, bf_dot by two orders of magnitude and bf_star by four.  Note that
#     bigscale, whose kappa(X'X) of 1.1e20 formally guarantees nothing at all,
#     still agrees with R to 4.4e-12, and on a p-value at that: its estimates
#     agree better still.
#   * The special functions behind Pr(>|t|) and f.pvalue.  lm()'s incomplete beta
#     and R's pt/pf agree only to a few ulp of each other, and that difference is
#     independent of the design matrix.  It is why several well-conditioned cases
#     (tooth_two, iris_factor, wide_dot) sit above their eps * kappa figure: the
#     digits they lose are not lost in the solve at all.  Their absolute
#     disagreement is in the last two or three digits of a p-value.
#
# Three further notes on what is NOT compared:
#
#   * For a rank-deficient design, dropping an aliased column (R, and lm()) and
#     taking the minimum-norm solution (statsmodels' pinv) are both valid least
#     squares answers: identical fitted values, different coefficients.  Those
#     cases are marked ref => 'R'.
#   * `exact_fit` has y as an exact linear function of its predictors, so its
#     residual sum of squares is pure rounding noise (3e-29 in R, 5e-28 here) and
#     the standard errors, t values and p-values derived from it carry no
#     information at all.  Only the estimates, rank, degrees of freedom and
#     R^2 = 1 are checked there.
#   * Residuals are allowed an absolute miss of 1e-12 * max|fitted| as well as a
#     relative one.  A residual is y minus a fitted value of similar size, so
#     wherever the fit is near-exact the subtraction cancels every significant
#     digit and only the absolute size means anything.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

my $INF = 9**9**9;

# An inestimable quantity: R reports NA (undef in the tables below), lm() reports
# NaN in `coefficients` and the string "NaN" in the `summary` table.  All three
# mean the same thing and must compare equal to one another.
sub is_nanish {
	my ($x) = @_;
	return 1 if !defined $x;
	return 1 if $x eq 'NaN' || $x eq 'nan' || $x eq '-nan' || $x eq 'NA';
	no warnings 'numeric';
	return $x != $x ? 1 : 0;
}

sub close_enough {
	my ($got, $want, $rtol, $atol) = @_;
	my ($gn, $wn) = (is_nanish($got), is_nanish($want));
	return 1 if $gn && $wn;
	return 0 if $gn || $wn;
	$got += 0; $want += 0;
	return $got == $want
		if $got == $INF || $want == $INF || $got == -$INF || $want == -$INF;
	return 1 if $got == $want;
	my $diff = abs($got - $want);
	return 1 if defined($atol) && $diff <= $atol;
	my $scale = abs($got) > abs($want) ? abs($got) : abs($want);
	return 1 if $scale < 1e-300;
	return $diff <= $rtol * $scale;
}

sub is_close {
	my ($got, $want, $rtol, $name, $atol) = @_;
	if (close_enough($got, $want, $rtol, $atol)) {
		pass($name);
	} else {
		fail($name);
		diag(sprintf("  got:      %s\n  expected: %s\n  rel tol:  %g%s",
			defined($got)  ? $got  : 'undef',
			defined($want) ? $want : 'undef', $rtol,
			defined($atol) ? sprintf("\n  abs tol:  %g", $atol) : ''));
	}
	return;
}

# ---------------------------------------------------------------------------
# Data sets, as whitespace-separated tables with a header row.  A field of "NA"
# becomes undef, which is what lm() must treat as missing.
sub parse_table {
	my ($text) = @_;
	my @lines = grep { /\S/ } split /\n/, $text;
	my @cols  = split ' ', shift @lines;
	my %hoa   = map { $_ => [] } @cols;
	for my $line (@lines) {
		my @f = split ' ', $line;
		die "row has " . scalar(@f) . " fields, header has " . scalar(@cols)
			unless @f == @cols;
		push @{ $hoa{ $cols[$_] } }, ($f[$_] eq 'NA' ? undef : $f[$_])
			for 0 .. $#cols;
	}
	return \%hoa;
}

my %DATA;
$DATA{mtcars} = parse_table(<<'END_MTCARS');
mpg	cyl	disp	hp	drat	wt	qsec	vs	am	gear	carb
21.0	6.0	160.0	110.0	3.9	2.62	16.46	0.0	1.0	4.0	4.0
21.0	6.0	160.0	110.0	3.9	2.875	17.02	0.0	1.0	4.0	4.0
22.8	4.0	108.0	93.0	3.85	2.32	18.61	1.0	1.0	4.0	1.0
21.4	6.0	258.0	110.0	3.08	3.215	19.44	1.0	0.0	3.0	1.0
18.7	8.0	360.0	175.0	3.15	3.44	17.02	0.0	0.0	3.0	2.0
18.1	6.0	225.0	105.0	2.76	3.46	20.22	1.0	0.0	3.0	1.0
14.3	8.0	360.0	245.0	3.21	3.57	15.84	0.0	0.0	3.0	4.0
24.4	4.0	146.7	62.0	3.69	3.19	20.0	1.0	0.0	4.0	2.0
22.8	4.0	140.8	95.0	3.92	3.15	22.9	1.0	0.0	4.0	2.0
19.2	6.0	167.6	123.0	3.92	3.44	18.3	1.0	0.0	4.0	4.0
17.8	6.0	167.6	123.0	3.92	3.44	18.9	1.0	0.0	4.0	4.0
16.4	8.0	275.8	180.0	3.07	4.07	17.4	0.0	0.0	3.0	3.0
17.3	8.0	275.8	180.0	3.07	3.73	17.6	0.0	0.0	3.0	3.0
15.2	8.0	275.8	180.0	3.07	3.78	18.0	0.0	0.0	3.0	3.0
10.4	8.0	472.0	205.0	2.93	5.25	17.98	0.0	0.0	3.0	4.0
10.4	8.0	460.0	215.0	3.0	5.424	17.82	0.0	0.0	3.0	4.0
14.7	8.0	440.0	230.0	3.23	5.345	17.42	0.0	0.0	3.0	4.0
32.4	4.0	78.7	66.0	4.08	2.2	19.47	1.0	1.0	4.0	1.0
30.4	4.0	75.7	52.0	4.93	1.615	18.52	1.0	1.0	4.0	2.0
33.9	4.0	71.1	65.0	4.22	1.835	19.9	1.0	1.0	4.0	1.0
21.5	4.0	120.1	97.0	3.7	2.465	20.01	1.0	0.0	3.0	1.0
15.5	8.0	318.0	150.0	2.76	3.52	16.87	0.0	0.0	3.0	2.0
15.2	8.0	304.0	150.0	3.15	3.435	17.3	0.0	0.0	3.0	2.0
13.3	8.0	350.0	245.0	3.73	3.84	15.41	0.0	0.0	3.0	4.0
19.2	8.0	400.0	175.0	3.08	3.845	17.05	0.0	0.0	3.0	2.0
27.3	4.0	79.0	66.0	4.08	1.935	18.9	1.0	1.0	4.0	1.0
26.0	4.0	120.3	91.0	4.43	2.14	16.7	0.0	1.0	5.0	2.0
30.4	4.0	95.1	113.0	3.77	1.513	16.9	1.0	1.0	5.0	2.0
15.8	8.0	351.0	264.0	4.22	3.17	14.5	0.0	1.0	5.0	4.0
19.7	6.0	145.0	175.0	3.62	2.77	15.5	0.0	1.0	5.0	6.0
15.0	8.0	301.0	335.0	3.54	3.57	14.6	0.0	1.0	5.0	8.0
21.4	4.0	121.0	109.0	4.11	2.78	18.6	1.0	1.0	4.0	2.0
END_MTCARS

$DATA{iris} = parse_table(<<'END_IRIS');
Sepal.Length	Sepal.Width	Petal.Length	Petal.Width	Species
5.1	3.5	1.4	0.2	setosa
4.9	3.0	1.4	0.2	setosa
4.7	3.2	1.3	0.2	setosa
4.6	3.1	1.5	0.2	setosa
5.0	3.6	1.4	0.2	setosa
5.4	3.9	1.7	0.4	setosa
4.6	3.4	1.4	0.3	setosa
5.0	3.4	1.5	0.2	setosa
4.4	2.9	1.4	0.2	setosa
4.9	3.1	1.5	0.1	setosa
5.4	3.7	1.5	0.2	setosa
4.8	3.4	1.6	0.2	setosa
4.8	3.0	1.4	0.1	setosa
4.3	3.0	1.1	0.1	setosa
5.8	4.0	1.2	0.2	setosa
5.7	4.4	1.5	0.4	setosa
5.4	3.9	1.3	0.4	setosa
5.1	3.5	1.4	0.3	setosa
5.7	3.8	1.7	0.3	setosa
5.1	3.8	1.5	0.3	setosa
5.4	3.4	1.7	0.2	setosa
5.1	3.7	1.5	0.4	setosa
4.6	3.6	1.0	0.2	setosa
5.1	3.3	1.7	0.5	setosa
4.8	3.4	1.9	0.2	setosa
5.0	3.0	1.6	0.2	setosa
5.0	3.4	1.6	0.4	setosa
5.2	3.5	1.5	0.2	setosa
5.2	3.4	1.4	0.2	setosa
4.7	3.2	1.6	0.2	setosa
4.8	3.1	1.6	0.2	setosa
5.4	3.4	1.5	0.4	setosa
5.2	4.1	1.5	0.1	setosa
5.5	4.2	1.4	0.2	setosa
4.9	3.1	1.5	0.2	setosa
5.0	3.2	1.2	0.2	setosa
5.5	3.5	1.3	0.2	setosa
4.9	3.6	1.4	0.1	setosa
4.4	3.0	1.3	0.2	setosa
5.1	3.4	1.5	0.2	setosa
5.0	3.5	1.3	0.3	setosa
4.5	2.3	1.3	0.3	setosa
4.4	3.2	1.3	0.2	setosa
5.0	3.5	1.6	0.6	setosa
5.1	3.8	1.9	0.4	setosa
4.8	3.0	1.4	0.3	setosa
5.1	3.8	1.6	0.2	setosa
4.6	3.2	1.4	0.2	setosa
5.3	3.7	1.5	0.2	setosa
5.0	3.3	1.4	0.2	setosa
7.0	3.2	4.7	1.4	versicolor
6.4	3.2	4.5	1.5	versicolor
6.9	3.1	4.9	1.5	versicolor
5.5	2.3	4.0	1.3	versicolor
6.5	2.8	4.6	1.5	versicolor
5.7	2.8	4.5	1.3	versicolor
6.3	3.3	4.7	1.6	versicolor
4.9	2.4	3.3	1.0	versicolor
6.6	2.9	4.6	1.3	versicolor
5.2	2.7	3.9	1.4	versicolor
5.0	2.0	3.5	1.0	versicolor
5.9	3.0	4.2	1.5	versicolor
6.0	2.2	4.0	1.0	versicolor
6.1	2.9	4.7	1.4	versicolor
5.6	2.9	3.6	1.3	versicolor
6.7	3.1	4.4	1.4	versicolor
5.6	3.0	4.5	1.5	versicolor
5.8	2.7	4.1	1.0	versicolor
6.2	2.2	4.5	1.5	versicolor
5.6	2.5	3.9	1.1	versicolor
5.9	3.2	4.8	1.8	versicolor
6.1	2.8	4.0	1.3	versicolor
6.3	2.5	4.9	1.5	versicolor
6.1	2.8	4.7	1.2	versicolor
6.4	2.9	4.3	1.3	versicolor
6.6	3.0	4.4	1.4	versicolor
6.8	2.8	4.8	1.4	versicolor
6.7	3.0	5.0	1.7	versicolor
6.0	2.9	4.5	1.5	versicolor
5.7	2.6	3.5	1.0	versicolor
5.5	2.4	3.8	1.1	versicolor
5.5	2.4	3.7	1.0	versicolor
5.8	2.7	3.9	1.2	versicolor
6.0	2.7	5.1	1.6	versicolor
5.4	3.0	4.5	1.5	versicolor
6.0	3.4	4.5	1.6	versicolor
6.7	3.1	4.7	1.5	versicolor
6.3	2.3	4.4	1.3	versicolor
5.6	3.0	4.1	1.3	versicolor
5.5	2.5	4.0	1.3	versicolor
5.5	2.6	4.4	1.2	versicolor
6.1	3.0	4.6	1.4	versicolor
5.8	2.6	4.0	1.2	versicolor
5.0	2.3	3.3	1.0	versicolor
5.6	2.7	4.2	1.3	versicolor
5.7	3.0	4.2	1.2	versicolor
5.7	2.9	4.2	1.3	versicolor
6.2	2.9	4.3	1.3	versicolor
5.1	2.5	3.0	1.1	versicolor
5.7	2.8	4.1	1.3	versicolor
6.3	3.3	6.0	2.5	virginica
5.8	2.7	5.1	1.9	virginica
7.1	3.0	5.9	2.1	virginica
6.3	2.9	5.6	1.8	virginica
6.5	3.0	5.8	2.2	virginica
7.6	3.0	6.6	2.1	virginica
4.9	2.5	4.5	1.7	virginica
7.3	2.9	6.3	1.8	virginica
6.7	2.5	5.8	1.8	virginica
7.2	3.6	6.1	2.5	virginica
6.5	3.2	5.1	2.0	virginica
6.4	2.7	5.3	1.9	virginica
6.8	3.0	5.5	2.1	virginica
5.7	2.5	5.0	2.0	virginica
5.8	2.8	5.1	2.4	virginica
6.4	3.2	5.3	2.3	virginica
6.5	3.0	5.5	1.8	virginica
7.7	3.8	6.7	2.2	virginica
7.7	2.6	6.9	2.3	virginica
6.0	2.2	5.0	1.5	virginica
6.9	3.2	5.7	2.3	virginica
5.6	2.8	4.9	2.0	virginica
7.7	2.8	6.7	2.0	virginica
6.3	2.7	4.9	1.8	virginica
6.7	3.3	5.7	2.1	virginica
7.2	3.2	6.0	1.8	virginica
6.2	2.8	4.8	1.8	virginica
6.1	3.0	4.9	1.8	virginica
6.4	2.8	5.6	2.1	virginica
7.2	3.0	5.8	1.6	virginica
7.4	2.8	6.1	1.9	virginica
7.9	3.8	6.4	2.0	virginica
6.4	2.8	5.6	2.2	virginica
6.3	2.8	5.1	1.5	virginica
6.1	2.6	5.6	1.4	virginica
7.7	3.0	6.1	2.3	virginica
6.3	3.4	5.6	2.4	virginica
6.4	3.1	5.5	1.8	virginica
6.0	3.0	4.8	1.8	virginica
6.9	3.1	5.4	2.1	virginica
6.7	3.1	5.6	2.4	virginica
6.9	3.1	5.1	2.3	virginica
5.8	2.7	5.1	1.9	virginica
6.8	3.2	5.9	2.3	virginica
6.7	3.3	5.7	2.5	virginica
6.7	3.0	5.2	2.3	virginica
6.3	2.5	5.0	1.9	virginica
6.5	3.0	5.2	2.0	virginica
6.2	3.4	5.4	2.3	virginica
5.9	3.0	5.1	1.8	virginica
END_IRIS

$DATA{ToothGrowth} = parse_table(<<'END_TOOTHGROWTH');
len	supp	dose
4.2	VC	0.5
11.5	VC	0.5
7.3	VC	0.5
5.8	VC	0.5
6.4	VC	0.5
10.0	VC	0.5
11.2	VC	0.5
11.2	VC	0.5
5.2	VC	0.5
7.0	VC	0.5
16.5	VC	1.0
16.5	VC	1.0
15.2	VC	1.0
17.3	VC	1.0
22.5	VC	1.0
17.3	VC	1.0
13.6	VC	1.0
14.5	VC	1.0
18.8	VC	1.0
15.5	VC	1.0
23.6	VC	2.0
18.5	VC	2.0
33.9	VC	2.0
25.5	VC	2.0
26.4	VC	2.0
32.5	VC	2.0
26.7	VC	2.0
21.5	VC	2.0
23.3	VC	2.0
29.5	VC	2.0
15.2	OJ	0.5
21.5	OJ	0.5
17.6	OJ	0.5
9.7	OJ	0.5
14.5	OJ	0.5
10.0	OJ	0.5
8.2	OJ	0.5
9.4	OJ	0.5
16.5	OJ	0.5
9.7	OJ	0.5
19.7	OJ	1.0
23.3	OJ	1.0
23.6	OJ	1.0
26.4	OJ	1.0
20.0	OJ	1.0
25.2	OJ	1.0
25.8	OJ	1.0
21.2	OJ	1.0
14.5	OJ	1.0
27.3	OJ	1.0
25.5	OJ	2.0
26.4	OJ	2.0
22.4	OJ	2.0
24.5	OJ	2.0
24.8	OJ	2.0
30.9	OJ	2.0
26.4	OJ	2.0
27.3	OJ	2.0
29.4	OJ	2.0
23.0	OJ	2.0
END_TOOTHGROWTH

$DATA{warpbreaks} = parse_table(<<'END_WARPBREAKS');
breaks	wool	tension
26	A	L
30	A	L
54	A	L
25	A	L
70	A	L
52	A	L
51	A	L
26	A	L
67	A	L
18	A	M
21	A	M
29	A	M
17	A	M
12	A	M
18	A	M
35	A	M
30	A	M
36	A	M
36	A	H
21	A	H
24	A	H
18	A	H
10	A	H
43	A	H
28	A	H
15	A	H
26	A	H
27	B	L
14	B	L
29	B	L
19	B	L
29	B	L
31	B	L
41	B	L
20	B	L
44	B	L
42	B	M
26	B	M
19	B	M
16	B	M
39	B	M
28	B	M
21	B	M
39	B	M
29	B	M
20	B	H
21	B	H
24	B	H
17	B	H
13	B	H
15	B	H
15	B	H
16	B	H
28	B	H
END_WARPBREAKS

$DATA{airquality} = parse_table(<<'END_AIRQUALITY');
Ozone	Solar.R	Wind	Temp	Month	Day
41	190	7.4	67	5	1
36	118	8.0	72	5	2
12	149	12.6	74	5	3
18	313	11.5	62	5	4
NA	NA	14.3	56	5	5
28	NA	14.9	66	5	6
23	299	8.6	65	5	7
19	99	13.8	59	5	8
8	19	20.1	61	5	9
NA	194	8.6	69	5	10
7	NA	6.9	74	5	11
16	256	9.7	69	5	12
11	290	9.2	66	5	13
14	274	10.9	68	5	14
18	65	13.2	58	5	15
14	334	11.5	64	5	16
34	307	12.0	66	5	17
6	78	18.4	57	5	18
30	322	11.5	68	5	19
11	44	9.7	62	5	20
1	8	9.7	59	5	21
11	320	16.6	73	5	22
4	25	9.7	61	5	23
32	92	12.0	61	5	24
NA	66	16.6	57	5	25
NA	266	14.9	58	5	26
NA	NA	8.0	57	5	27
23	13	12.0	67	5	28
45	252	14.9	81	5	29
115	223	5.7	79	5	30
37	279	7.4	76	5	31
NA	286	8.6	78	6	1
NA	287	9.7	74	6	2
NA	242	16.1	67	6	3
NA	186	9.2	84	6	4
NA	220	8.6	85	6	5
NA	264	14.3	79	6	6
29	127	9.7	82	6	7
NA	273	6.9	87	6	8
71	291	13.8	90	6	9
39	323	11.5	87	6	10
NA	259	10.9	93	6	11
NA	250	9.2	92	6	12
23	148	8.0	82	6	13
NA	332	13.8	80	6	14
NA	322	11.5	79	6	15
21	191	14.9	77	6	16
37	284	20.7	72	6	17
20	37	9.2	65	6	18
12	120	11.5	73	6	19
13	137	10.3	76	6	20
NA	150	6.3	77	6	21
NA	59	1.7	76	6	22
NA	91	4.6	76	6	23
NA	250	6.3	76	6	24
NA	135	8.0	75	6	25
NA	127	8.0	78	6	26
NA	47	10.3	73	6	27
NA	98	11.5	80	6	28
NA	31	14.9	77	6	29
NA	138	8.0	83	6	30
135	269	4.1	84	7	1
49	248	9.2	85	7	2
32	236	9.2	81	7	3
NA	101	10.9	84	7	4
64	175	4.6	83	7	5
40	314	10.9	83	7	6
77	276	5.1	88	7	7
97	267	6.3	92	7	8
97	272	5.7	92	7	9
85	175	7.4	89	7	10
NA	139	8.6	82	7	11
10	264	14.3	73	7	12
27	175	14.9	81	7	13
NA	291	14.9	91	7	14
7	48	14.3	80	7	15
48	260	6.9	81	7	16
35	274	10.3	82	7	17
61	285	6.3	84	7	18
79	187	5.1	87	7	19
63	220	11.5	85	7	20
16	7	6.9	74	7	21
NA	258	9.7	81	7	22
NA	295	11.5	82	7	23
80	294	8.6	86	7	24
108	223	8.0	85	7	25
20	81	8.6	82	7	26
52	82	12.0	86	7	27
82	213	7.4	88	7	28
50	275	7.4	86	7	29
64	253	7.4	83	7	30
59	254	9.2	81	7	31
39	83	6.9	81	8	1
9	24	13.8	81	8	2
16	77	7.4	82	8	3
78	NA	6.9	86	8	4
35	NA	7.4	85	8	5
66	NA	4.6	87	8	6
122	255	4.0	89	8	7
89	229	10.3	90	8	8
110	207	8.0	90	8	9
NA	222	8.6	92	8	10
NA	137	11.5	86	8	11
44	192	11.5	86	8	12
28	273	11.5	82	8	13
65	157	9.7	80	8	14
NA	64	11.5	79	8	15
22	71	10.3	77	8	16
59	51	6.3	79	8	17
23	115	7.4	76	8	18
31	244	10.9	78	8	19
44	190	10.3	78	8	20
21	259	15.5	77	8	21
9	36	14.3	72	8	22
NA	255	12.6	75	8	23
45	212	9.7	79	8	24
168	238	3.4	81	8	25
73	215	8.0	86	8	26
NA	153	5.7	88	8	27
76	203	9.7	97	8	28
118	225	2.3	94	8	29
84	237	6.3	96	8	30
85	188	6.3	94	8	31
96	167	6.9	91	9	1
78	197	5.1	92	9	2
73	183	2.8	93	9	3
91	189	4.6	93	9	4
47	95	7.4	87	9	5
32	92	15.5	84	9	6
20	252	10.9	80	9	7
23	220	10.3	78	9	8
21	230	10.9	75	9	9
24	259	9.7	73	9	10
44	236	14.9	81	9	11
21	259	15.5	76	9	12
28	238	6.3	77	9	13
9	24	10.9	71	9	14
13	112	11.5	71	9	15
46	237	6.9	78	9	16
18	224	13.8	67	9	17
13	27	10.3	76	9	18
24	238	10.3	68	9	19
16	201	8.0	82	9	20
13	238	12.6	64	9	21
23	14	9.2	71	9	22
36	139	10.3	81	9	23
7	49	10.3	69	9	24
14	20	16.6	63	9	25
30	193	6.9	70	9	26
NA	145	13.2	77	9	27
14	191	14.3	75	9	28
18	131	8.0	76	9	29
20	223	11.5	68	9	30
END_AIRQUALITY

$DATA{exact} = parse_table(<<'END_EXACT');
x1	x2	y
1.0	3.0	1.75
2.0	1.0	4.75
3.0	4.0	4.0
4.0	1.0	7.75
5.0	5.0	6.25
6.0	9.0	4.75
7.0	2.0	11.5
8.0	6.0	10.0
9.0	5.0	12.25
10.0	3.0	15.25
11.0	5.0	15.25
12.0	8.0	14.5
END_EXACT

$DATA{aliased} = parse_table(<<'END_ALIASED');
x1	x2	x3	y
1.0	2.0	3.0	3.2
2.0	1.0	3.0	2.9
3.0	4.0	7.0	7.1
4.0	3.0	7.0	6.8
5.0	6.0	11.0	11.2
6.0	5.0	11.0	10.9
7.0	8.0	15.0	15.1
8.0	7.0	15.0	14.8
END_ALIASED

$DATA{nas} = parse_table(<<'END_NAS');
y	x1	x2
2.1	1	0.5
3.9	2	1.5
NA	3	2.5
8.2	4	NA
9.8	5	4.5
12.1	6	5.5
13.9	7	6.5
16.2	NA	7.5
NA	9	8.5
20.1	10	9.5
21.8	11	10.5
24.2	12	11.5
END_NAS

$DATA{wide} = parse_table(<<'END_WIDE');
v1	v2	v3	v4	v5	v6	v7	v8	y
1.370958	-0.306639	0.205999	-0.367235	1.512707	1.200965	-1.493625	-0.086107	6.149217
-0.564698	-1.781308	-0.361057	0.185231	0.257921	1.044751	-1.470436	-0.887679	4.221031
0.363128	-0.171917	0.758163	0.581824	0.08844	-1.003209	0.124702	-0.444684	4.033094
0.632863	1.214675	-0.726705	1.399737	-0.120897	1.848482	-0.996639	-0.029445	2.334892
0.404268	1.895193	-1.368281	-0.727292	-1.194329	-0.666773	-0.001823	-0.413869	1.142751
-0.106125	-0.430469	0.432818	1.302543	0.611997	0.105514	-0.428259	1.113386	3.86318
1.511522	-0.257269	-0.811393	0.335848	-0.21714	-0.422256	-0.613672	-0.480993	6.11114
-0.094659	-1.763163	1.444101	1.038506	-0.182757	-0.12235	-2.024678	-0.433169	5.591822
2.018424	0.460097	-0.431446	0.920729	0.933346	0.188193	-1.224748	0.696863	6.372172
-0.062714	-0.639995	0.655648	0.720878	0.821773	0.119161	0.179516	-1.056368	4.103234
1.30487	0.45545	0.321925	-1.043119	1.392116	-0.025093	0.567621	-0.040698	4.857632
2.286645	0.704837	-0.783839	-0.090186	-0.476174	0.108073	-0.492877	-1.551545	6.76702
-1.388861	1.035104	1.575728	0.623518	0.650349	-0.485435	6.3e-05	1.16717	-1.853895
-0.278789	-0.608926	0.642899	-0.953523	1.39111	-0.504217	1.12289	-0.273646	3.862649
-0.133321	0.504955	0.089761	-0.542829	-1.110789	-1.661099	1.439856	-0.467845	2.235359
0.63595	-1.717009	0.276551	0.580996	-0.860793	-0.382334	-1.097114	-1.238252	6.802181
-0.284253	-0.784459	0.679289	0.768179	-1.131739	-0.51265	-0.11732	-0.007762	3.17348
-2.656455	-0.850908	0.089833	0.463768	-1.459214	2.701891	1.201498	-0.800282	-0.843645
-2.440467	-2.414208	-2.99309	-0.885776	0.079983	-1.362116	-0.46973	-0.533492	1.885336
1.320113	0.036123	0.284883	-1.099781	0.653204	0.137256	-0.052469	1.287675	5.584135
END_WIDE

$DATA{bigscale} = parse_table(<<'END_BIGSCALE');
tiny	huge	mid	y
0.000228724716	1121855.0535	6.706403	6.63019612
-0.000119677168	930068.2921	8.614093	4.48803763
-6.9429251e-05	971456.7248	5.515253	3.59347186
-4.1229295e-05	868844.7327	6.968934	4.7100284
-9.7067334e-05	960898.7569	5.604898	3.4040257
-9.4727995e-05	959847.3387	5.721744	3.38168171
7.4813934e-05	1135051.7581	4.12303	4.04176055
-1.1695523e-05	1059119.0027	8.283123	5.07009798
1.5265763e-05	1010052.5456	2.925775	3.33481727
0.000218997811	1093107.1996	4.807125	5.83951044
3.5698623e-05	973725.7651	4.398702	4.17397698
0.000271675178	999233.1895	8.061855	7.96674052
0.000228145193	1036715.3007	4.28181	5.91628243
3.2402054e-05	1170716.2545	7.58458	4.8762803
0.000189606707	1072374.0263	4.422993	5.40368163
4.6768051e-05	1048103.6049	7.433481	5.37395671
-8.9380072e-05	843213.1756	1.333524	2.04788117
-3.073283e-05	1031825.0283	5.487032	3.84718178
-4.82242e-07	1016599.1451	7.493413	4.99188396
9.8816415e-05	910009.237	9.806662	7.1960176
8.3975036e-05	1007637.1474	9.541528	6.55571421
7.0534183e-05	1015915.5278	3.664829	4.20202139
0.000130596472	1054367.4185	3.333938	4.51086015
-0.000138799622	1070480.7353	9.315766	4.11798779
0.000127291686	1031896.9143	7.588353	6.24902738
1.8419277e-05	1110924.9789	7.65751	4.99108438
7.522799e-05	1076915.4195	6.340927	5.08323336
5.9174505e-05	1115347.3675	1.722353	2.93631053
-9.830526e-05	1126068.3503	8.21227	3.85027281
-2.7606396e-05	1070062.3507	3.35043	2.90487887
-8.7085102e-05	1043262.7161	3.547934	2.38886747
7.1871055e-05	907739.8282	7.427414	6.00707716
1.1065288e-05	938441.5793	8.813935	5.86421053
-7.846677e-06	913334.0312	7.311907	5.12470935
-4.2049046e-05	836048.2913	1.55602	2.75051362
-5.6212588e-05	867416.0756	4.936698	3.77245013
9.9751344e-05	911096.3272	3.975834	4.87681909
-0.000110513006	944239.767	9.137846	4.76308569
-1.4228783e-05	993759.7691	4.961052	3.8743416
3.149949e-05	1242269.2977	4.464732	3.42445683
END_BIGSCALE

$DATA{onelevel} = parse_table(<<'END_ONELEVEL');
y	x	g
1.2	1	only
2.3	2	only
3.1	3	only
4.4	4	only
5.2	5	only
6.3	6	only
7.1	7	only
8.4	8	only
END_ONELEVEL

$DATA{fourlevel} = parse_table(<<'END_FOURLEVEL');
y	g	x
12.1	delta	1
11.8	delta	2
12.4	delta	3
4.1	alpha	1
4.3	alpha	2
3.9	alpha	3
8.2	charlie	1
8.5	charlie	2
7.8	charlie	3
15.1	echo	1
15.4	echo	2
14.7	echo	3
END_FOURLEVEL

$DATA{mixedcase} = parse_table(<<'END_MIXEDCASE');
y	g
3.1	b
3.4	b
2.9	b
7.2	A
7.5	A
6.8	A
11.1	a
11.4	a
10.7	a
END_MIXEDCASE

$DATA{threeway} = parse_table(<<'END_THREEWAY');
a	b	z	y
lo	x	0.333333	4.163587
hi	x	0.666667	6.010638
lo	y	1.0	4.793379
hi	y	1.333333	6.454939
lo	z	1.666667	6.871396
hi	z	2.0	7.626339
lo	x	2.333333	5.529442
hi	x	2.666667	6.849967
lo	y	3.0	5.981711
hi	y	3.333333	7.198352
lo	z	3.666667	6.668627
hi	z	4.0	8.460659
lo	x	4.333333	4.984683
hi	x	4.666667	7.097774
lo	y	5.0	6.140022
hi	y	5.333333	8.204931
lo	z	5.666667	7.510812
hi	z	6.0	9.555109
lo	x	6.333333	5.963138
hi	x	6.666667	7.537713
lo	y	7.0	6.926993
hi	y	7.333333	8.793657
lo	z	7.666667	8.022958
hi	z	8.0	9.941023
END_THREEWAY

$DATA{nasfac} = parse_table(<<'END_NASFAC');
y	g	x
2.1	p	1
3.9	q	2
6.1	p	3
NA	q	4
9.8	NA	5
12.1	q	6
13.9	p	NA
16.2	q	8
18.1	p	9
20.1	NA	10
21.8	q	11
24.2	p	12
END_NASFAC


# bodyfat: 252 x 15, kappa(X'X) = 2.1e9 under `BodyFat ~ .`.  Read from the copy
# the distribution already ships rather than inlined here.
for my $path ('t/bodyfat.csv', 'bodyfat.csv') {
	next unless -e $path;
	$DATA{bodyfat} = read_table($path, 'output.type' => 'hoa');
	last;
}

my @CASES = (
  {
    name    => 'mt_simple',
    data    => 'mtcars',
    formula => 'mpg ~ wt',
    ref     => 'R+scipy',
    cond => 160.538,   # kappa(X'X), so eps*cond permits 3.7e-14
    tol  => 4.01937e-11,   # measured deviation from R 2.0e-13 x 200
    atol => 2.91989e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 2,
    df_residual => 30,
    n_used      => 32,
    rss           => 278.321937543344,
    r_squared     => 0.752832793658264,
    adj_r_squared => 0.744593886780206,
    fstatistic => [91.3753250037617, 1, 30],
    f_pvalue   => 1.29395870135052e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [37.285126167342, 1.8776273372559, 19.8575752640209, 8.24179884532659e-19],
      "wt" => [-5.34447157272268, 0.559101045099323, -9.55904414697211, 1.29395870135052e-10],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [23.2826106468087, -2.28261064680868],  # R row "Mazda RX4"
      "2" => [21.9197703957643, -0.919770395764312],  # R row "Mazda RX4 Wag"
      "3" => [24.8859521186254, -2.08595211862542],  # R row "Datsun 710"
      "4" => [20.1026500610386, 1.29734993896137],  # R row "Hornet 4 Drive"
      "29" => [20.3431512818111, -4.54315128181114],  # R row "Ford Pantera L"
      "30" => [22.4809399109002, -2.78093991090022],  # R row "Ferrari Dino"
      "31" => [18.2053626527221, -3.20536265272208],  # R row "Maserati Bora"
      "32" => [22.427495195173, -1.02749519517299],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_two',
    data    => 'mtcars',
    formula => 'mpg ~ wt + hp',
    ref     => 'R+scipy',
    cond => 345403,   # kappa(X'X), so eps*cond permits 7.9e-11
    tol  => 3.30514e-11,   # measured deviation from R 1.7e-13 x 200
    atol => 2.93124e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 29,
    n_used      => 32,
    rss           => 195.047754741466,
    r_squared     => 0.826785451882791,
    adj_r_squared => 0.814839620978156,
    fstatistic => [69.2112133917776, 2, 29],
    f_pvalue   => 9.10905438522209e-12,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [37.2272701164472, 1.59878753799939, 23.2846886979309, 2.56545851198376e-20],
      "wt" => [-3.87783074240468, 0.632733494377395, -6.12869521981041, 1.11964713620004e-06],
      "hp" => [-0.031772946982161, 0.00902970967585572, -3.51871191020878, 0.00145122853156942],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [23.5723294033093, -2.57232940330929],  # R row "Mazda RX4"
      "2" => [22.583482563996, -1.58348256399602],  # R row "Mazda RX4 Wag"
      "3" => [25.2758187247274, -2.47581872472736],  # R row "Datsun 710"
      "4" => [21.2650201115784, 0.134979888421558],  # R row "Hornet 4 Drive"
      "29" => [16.5464886597339, -0.746488659733856],  # R row "Ford Pantera L"
      "30" => [20.9254132381081, -1.22541323810806],  # R row "Ferrari Dino"
      "31" => [12.7394771270386, 2.26052287296145],  # R row "Maserati Bora"
      "32" => [22.9836494315066, -1.58364943150664],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_five',
    data    => 'mtcars',
    formula => 'mpg ~ wt + hp + qsec + disp + drat',
    ref     => 'R+scipy',
    cond => 5.50056e+07,   # kappa(X'X), so eps*cond permits 1.3e-08
    tol  => 2.13043e-10,   # measured deviation from R 1.1e-12 x 200
    atol => 3.08334e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 6,
    df_residual => 26,
    n_used      => 32,
    rss           => 170.129133515847,
    r_squared     => 0.848914738738827,
    adj_r_squared => 0.819859880803986,
    fstatistic => [29.2176523678973, 5, 26],
    f_pvalue   => 6.89213591002428e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [16.533569595148, 10.9642303392135, 1.50795533143953, 0.143622105994955],
      "wt" => [-4.38546388784249, 1.24343208710105, -3.52690262165167, 0.00158405928094187],
      "hp" => [-0.0205980807447024, 0.0152830856984087, -1.3477697600588, 0.189359669728447],
      "qsec" => [0.640149901345911, 0.459344349397129, 1.39361658021064, 0.175232675561169],
      "disp" => [0.00872017588346061, 0.0111890913070086, 0.779346208212503, 0.442812305102993],
      "drat" => [2.01577455846857, 1.30945946779883, 1.53939438985236, 0.135791211284744],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [22.5714816226183, -1.57148162261831],  # R row "Mazda RX4"
      "2" => [21.8116722759721, -0.81167227597211],  # R row "Mazda RX4 Wag"
      "3" => [25.0593725756613, -2.25937257566127],  # R row "Datsun 710"
      "4" => [21.0714194139977, 0.328580586002297],  # R row "Hornet 4 Drive"
      "29" => [18.0432796954336, -2.24327969543364],  # R row "Ford Pantera L"
      "30" => [19.265023371121, 0.43497662887896],  # R row "Ferrari Dino"
      "31" => [13.0839099036257, 1.91609009637429],  # R row "Maserati Bora"
      "32" => [23.3435520680118, -1.94355206801185],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_star',
    data    => 'mtcars',
    formula => 'mpg ~ wt * hp',
    ref     => 'R+scipy',
    cond => 4.03193e+07,   # kappa(X'X), so eps*cond permits 9.3e-09
    tol  => 2.26433e-10,   # measured deviation from R 1.1e-12 x 200
    atol => 3.2632e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 28,
    n_used      => 32,
    rss           => 129.761498010318,
    r_squared     => 0.884763711991139,
    adj_r_squared => 0.872416966847332,
    fstatistic => [71.6596723821547, 3, 28],
    f_pvalue   => 2.98139412009605e-13,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [49.8084234287603, 3.60515579869117, 13.8158865275234, 5.00576063420635e-14],
      "wt" => [-8.21662429724361, 1.26970813923061, -6.47127008433806, 5.19928727958316e-07],
      "hp" => [-0.120102090978023, 0.0246983470182827, -4.86275826026409, 4.03624302067519e-05],
      "wt:hp" => [0.0278481483187412, 0.00741958045779372, 3.75333194068794, 0.000810830737370625],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [23.0954741078608, -2.09547410786076],  # R row "Mazda RX4"
      "2" => [21.7813754724042, -0.78137547240425],  # R row "Mazda RX4 Wag"
      "3" => [25.5848770794505, -2.78487707945055],  # R row "Datsun 710"
      "4" => [20.0292439584624, 1.37075604153764],  # R row "Hornet 4 Drive"
      "29" => [15.3603307532881, 0.439669246711918],  # R row "Ford Pantera L"
      "30" => [19.5298981017512, 0.17010189824876],  # R row "Ferrari Dino"
      "31" => [13.5458671917614, 1.45413280823859],  # R row "Maserati Bora"
      "32" => [22.3136258693635, -0.913625869363489],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_colon',
    data    => 'mtcars',
    formula => 'mpg ~ wt + hp + wt:hp',
    ref     => 'R+scipy',
    cond => 4.03193e+07,   # kappa(X'X), so eps*cond permits 9.3e-09
    tol  => 2.26433e-10,   # measured deviation from R 1.1e-12 x 200
    atol => 3.2632e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 28,
    n_used      => 32,
    rss           => 129.761498010318,
    r_squared     => 0.884763711991139,
    adj_r_squared => 0.872416966847332,
    fstatistic => [71.6596723821547, 3, 28],
    f_pvalue   => 2.98139412009605e-13,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [49.8084234287603, 3.60515579869117, 13.8158865275234, 5.00576063420635e-14],
      "wt" => [-8.21662429724361, 1.26970813923061, -6.47127008433806, 5.19928727958316e-07],
      "hp" => [-0.120102090978023, 0.0246983470182827, -4.86275826026409, 4.03624302067519e-05],
      "wt:hp" => [0.0278481483187412, 0.00741958045779372, 3.75333194068794, 0.000810830737370625],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [23.0954741078608, -2.09547410786076],  # R row "Mazda RX4"
      "2" => [21.7813754724042, -0.78137547240425],  # R row "Mazda RX4 Wag"
      "3" => [25.5848770794505, -2.78487707945055],  # R row "Datsun 710"
      "4" => [20.0292439584624, 1.37075604153764],  # R row "Hornet 4 Drive"
      "29" => [15.3603307532881, 0.439669246711918],  # R row "Ford Pantera L"
      "30" => [19.5298981017512, 0.17010189824876],  # R row "Ferrari Dino"
      "31" => [13.5458671917614, 1.45413280823859],  # R row "Maserati Bora"
      "32" => [22.3136258693635, -0.913625869363489],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_quad',
    data    => 'mtcars',
    formula => 'mpg ~ wt + I(wt^2)',
    ref     => 'R+scipy',
    cond => 20059.4,   # kappa(X'X), so eps*cond permits 4.6e-12
    tol  => 5.80456e-10,   # measured deviation from R 2.9e-12 x 200
    atol => 3.23672e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 29,
    n_used      => 32,
    rss           => 203.745448778314,
    r_squared     => 0.819061358138409,
    adj_r_squared => 0.806582831113472,
    fstatistic => [65.6376635240348, 2, 29],
    f_pvalue   => 1.71476349398838e-11,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [49.9308109494518, 4.211288008533, 11.8564227495913, 1.21314150189528e-12],
      "wt" => [-13.3803370835673, 2.514005216245, -5.32231874345614, 1.03575012770171e-05],
      "I(wt^2)" => [1.1710868938265, 0.359445552105612, 3.25803695988541, 0.0028598951253866],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [22.9131366644882, -1.91313666448824],  # R row "Mazda RX4"
      "2" => [21.1421069409805, -0.142106940980514],  # R row "Mazda RX4 Wag"
      "3" => [25.1916870129075, -2.39168701290748],  # R row "Datsun 710"
      "4" => [19.0176448549248, 2.38235514507517],  # R row "Hornet 4 Drive"
      "29" => [19.2832774819167, -3.48327748191666],  # R row "Ford Pantera L"
      "30" => [21.8529098556118, -2.15290985561181],  # R row "Ferrari Dino"
      "31" => [17.088392914246, -2.088392914246],  # R row "Maserati Bora"
      "32" => [21.7841018073835, -0.384101807383504],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_cubic',
    data    => 'mtcars',
    formula => 'mpg ~ wt + I(wt^2) + I(wt^3)',
    ref     => 'R+scipy',
    cond => 7.79806e+06,   # kappa(X'X), so eps*cond permits 1.8e-09
    tol  => 2.05607e-08,   # measured deviation from R 1.0e-10 x 200
    atol => 3.22482e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 28,
    n_used      => 32,
    rss           => 203.669885708925,
    r_squared     => 0.819128462847899,
    adj_r_squared => 0.799749369581602,
    fstatistic => [42.2686681771897, 3, 28],
    f_pvalue   => 1.58454587859939e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [48.4036962279532, 15.5837858508322, 3.10602934943233, 0.00431411095384767],
      "wt" => [-11.8259760179136, 15.4634572326057, -0.76476921299189, 0.45080687589309],
      "I(wt^2)" => [0.689379193455858, 4.74034223939359, 0.145428148146545, 0.88541470505789],
      "I(wt^3)" => [0.0459361802204469, 0.450696803395477, 0.101922578270738, 0.919544539845077],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [22.9779633032016, -1.97796330320165],  # R row "Mazda RX4"
      "2" => [21.1937773863096, -0.193777386309594],  # R row "Mazda RX4 Wag"
      "3" => [25.2515592369414, -2.45155923694136],  # R row "Datsun 710"
      "4" => [19.0352653067322, 2.36473469326779],  # R row "Hornet 4 Drive"
      "29" => [19.3061524463782, -3.50615244637822],  # R row "Ford Pantera L"
      "30" => [21.9116047684812, -2.21160476848118],  # R row "Ferrari Dino"
      "31" => [17.061094449828, -2.061094449828],  # R row "Maserati Bora"
      "32" => [21.8422176839572, -0.44221768395719],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_noint',
    data    => 'mtcars',
    formula => 'mpg ~ wt - 1',
    ref     => 'R+scipy',
    cond => 1,   # kappa(X'X), so eps*cond permits 2.3e-16
    tol  => 1e-11,   # measured deviation from R 8.7e-15 x 200
    atol => 2.87018e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 1,
    df_residual => 31,
    n_used      => 32,
    rss           => 3936.61605703707,
    r_squared     => 0.719660365207927,
    adj_r_squared => 0.710617151182377,
    fstatistic => [79.5801540441923, 1, 31],
    f_pvalue   => 4.55314035426685e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "wt" => [5.29162410075426, 0.5931801343546, 8.92077093328779, 4.55314035426683e-10],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [13.8640551439762, 7.13594485602383],  # R row "Mazda RX4"
      "2" => [15.2134192896685, 5.7865807103315],  # R row "Mazda RX4 Wag"
      "3" => [12.2765679137499, 10.5234320862501],  # R row "Datsun 710"
      "4" => [17.0125714839249, 4.38742851607505],  # R row "Hornet 4 Drive"
      "29" => [16.774448399391, -0.974448399391001],  # R row "Ford Pantera L"
      "30" => [14.6577987590893, 5.0422012409107],  # R row "Ferrari Dino"
      "31" => [18.8910980396927, -3.89109803969271],  # R row "Maserati Bora"
      "32" => [14.7107150000968, 6.68928499990316],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_noint2',
    data    => 'mtcars',
    formula => 'mpg ~ wt + hp - 1',
    ref     => 'R+scipy',
    cond => 23395.4,   # kappa(X'X), so eps*cond permits 5.4e-12
    tol  => 1e-11,   # measured deviation from R 3.7e-14 x 200
    atol => 2.98065e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 2,
    df_residual => 30,
    n_used      => 32,
    rss           => 3841.61166586475,
    r_squared     => 0.726425946595343,
    adj_r_squared => 0.708187676368365,
    fstatistic => [39.8297611316697, 2, 30],
    f_pvalue   => 3.59851715880265e-09,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "wt" => [6.8404499708353, 1.89424763819297, 3.61116985599665, 0.00109783859258725],
      "hp" => [-0.0339352599066577, 0.0393981150048478, -0.861342221638829, 0.395882072615036],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [14.1891003338562, 6.81089966614384],  # R row "Mazda RX4"
      "2" => [15.9334150764192, 5.06658492358085],  # R row "Mazda RX4 Wag"
      "3" => [12.7138647610187, 10.0861352389813],  # R row "Datsun 710"
      "4" => [18.2591680665032, 3.14083193349685],  # R row "Hornet 4 Drive"
      "29" => [12.7253177921903, 3.07468220780972],  # R row "Ford Pantera L"
      "30" => [13.0093759355487, 6.69062406445131],  # R row "Ferrari Dino"
      "31" => [13.0520943271517, 1.9479056728483],  # R row "Maserati Bora"
      "32" => [15.3175075890965, 6.08249241090355],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_noint_zero',
    data    => 'mtcars',
    formula => 'mpg ~ wt + 0',
    ref     => 'R+scipy',
    cond => 1,   # kappa(X'X), so eps*cond permits 2.3e-16
    tol  => 1e-11,   # measured deviation from R 8.7e-15 x 200
    atol => 2.87018e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 1,
    df_residual => 31,
    n_used      => 32,
    rss           => 3936.61605703707,
    r_squared     => 0.719660365207927,
    adj_r_squared => 0.710617151182377,
    fstatistic => [79.5801540441923, 1, 31],
    f_pvalue   => 4.55314035426685e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "wt" => [5.29162410075426, 0.5931801343546, 8.92077093328779, 4.55314035426683e-10],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [13.8640551439762, 7.13594485602383],  # R row "Mazda RX4"
      "2" => [15.2134192896685, 5.7865807103315],  # R row "Mazda RX4 Wag"
      "3" => [12.2765679137499, 10.5234320862501],  # R row "Datsun 710"
      "4" => [17.0125714839249, 4.38742851607505],  # R row "Hornet 4 Drive"
      "29" => [16.774448399391, -0.974448399391001],  # R row "Ford Pantera L"
      "30" => [14.6577987590893, 5.0422012409107],  # R row "Ferrari Dino"
      "31" => [18.8910980396927, -3.89109803969271],  # R row "Maserati Bora"
      "32" => [14.7107150000968, 6.68928499990316],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_dot',
    data    => 'mtcars',
    formula => 'mpg ~ .',
    ref     => 'R+scipy',
    cond => 1.49152e+08,   # kappa(X'X), so eps*cond permits 3.4e-08
    tol  => 5.4414e-10,   # measured deviation from R 2.7e-12 x 200
    atol => 2.98967e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 11,
    df_residual => 21,
    n_used      => 32,
    rss           => 147.494430016651,
    r_squared     => 0.869015764477765,
    adj_r_squared => 0.806642318990986,
    fstatistic => [13.9324636902088, 10, 21],
    f_pvalue   => 3.79315210530589e-07,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [12.3033741559962, 18.7178844287215, 0.657305808402012, 0.518124396898475],
      "cyl" => [-0.111440477886863, 1.04502336251002, -0.106639221556919, 0.916087375515961],
      "disp" => [0.0133352399133411, 0.0178575003141284, 0.746758486840995, 0.463488650353868],
      "hp" => [-0.0214821189891363, 0.0217685792527032, -0.986840654126229, 0.334955314116977],
      "drat" => [0.787110972236116, 1.63537306860509, 0.481303616493753, 0.6352778979695],
      "wt" => [-3.71530392832747, 1.89441429953271, -1.96118870578834, 0.0632521511445564],
      "qsec" => [0.821040749674628, 0.730844796023449, 1.12341328027775, 0.273941269972362],
      "vs" => [0.317762814185423, 2.10450860570774, 0.150991453930672, 0.881423471976983],
      "am" => [2.52022688720842, 2.05665055348227, 1.22540354896034, 0.233989710706795],
      "gear" => [0.655413017081792, 1.4932599610728, 0.438914210631433, 0.665206434293021],
      "carb" => [-0.199419254856267, 0.828752497681768, -0.240625826666096, 0.812178712952694],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [22.5995057612624, -1.59950576126242],  # R row "Mazda RX4"
      "2" => [22.1118860793567, -1.11188607935666],  # R row "Mazda RX4 Wag"
      "3" => [26.2506440847988, -3.45064408479879],  # R row "Datsun 710"
      "4" => [21.2374045466757, 0.162595453324264],  # R row "Hornet 4 Drive"
      "29" => [18.8700408028648, -3.07004080286476],  # R row "Ford Pantera L"
      "30" => [19.6938281544748, 0.00617184552523092],  # R row "Ferrari Dino"
      "31" => [13.9411183820599, 1.05888161794013],  # R row "Maserati Bora"
      "32" => [24.3682676832438, -2.96826768324378],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_sq_only',
    data    => 'mtcars',
    formula => 'mpg ~ I(hp^2)',
    ref     => 'R+scipy',
    cond => 2.73918e+09,   # kappa(X'X), so eps*cond permits 6.3e-07
    tol  => 1e-11,   # measured deviation from R 2.7e-14 x 200
    atol => 2.39429e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 2,
    df_residual => 30,
    n_used      => 32,
    rss           => 628.72581329168,
    r_squared     => 0.441652339021822,
    adj_r_squared => 0.42304075032255,
    fstatistic => [23.7299644945992, 1, 30],
    f_pvalue   => 3.34956790432787e-05,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [24.3887251807155, 1.1972543565032, 20.3705461986767, 4.03607246563692e-19],
      "I(hp^2)" => [-0.000164860161460442, 3.38428692939048e-05, -4.87134113921405, 3.34956790432787e-05],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [22.3939172270442, -1.39391722704416],  # R row "Mazda RX4"
      "2" => [22.3939172270441, -1.39391722704411],  # R row "Mazda RX4 Wag"
      "3" => [22.9628496442441, -0.162849644244096],  # R row "Datsun 710"
      "4" => [22.3939172270441, -0.993917227044112],  # R row "Hornet 4 Drive"
      "29" => [12.8986313675685, 2.90136863243152],  # R row "Ford Pantera L"
      "30" => [19.3398827359894, 0.360117264010581],  # R row "Ferrari Dino"
      "31" => [5.88729356081733, 9.11270643918267],  # R row "Maserati Bora"
      "32" => [22.4300216024039, -1.03002160240395],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'mt_hp_resp',
    data    => 'mtcars',
    formula => 'hp ~ mpg * wt',
    ref     => 'R+scipy',
    cond => 784207,   # kappa(X'X), so eps*cond permits 1.8e-10
    tol  => 5.25959e-11,   # measured deviation from R 2.6e-13 x 200
    atol => 2.52167e-10,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 28,
    n_used      => 32,
    rss           => 54695.2921554407,
    r_squared     => 0.624672579059691,
    adj_r_squared => 0.584458926816087,
    fstatistic => [15.5338434637963, 3, 28],
    f_pvalue   => 3.84514188448793e-06,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [311.319670415284, 106.789093633086, 2.91527589404345, 0.00691963986240677],
      "mpg" => [-6.02584582784761, 3.77285248005386, -1.59715914144663, 0.121456075938154],
      "wt" => [18.7567147699551, 24.4148615205098, 0.768249893786965, 0.448770039607226],
      "mpg:wt" => [-1.7411962792055, 1.37932191481589, -1.26235671347098, 0.217233753374815],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [138.118881445881, -28.1188814458809],  # R row "Mazda RX4"
      "2" => [133.577737637073, -23.5777376370732],  # R row "Mazda RX4 Wag"
      "3" => [125.3436454218, -32.3436454218004],  # R row "Datsun 710"
      "4" => [122.873362479133, -12.8733624791335],  # R row "Hornet 4 Drive"
      "29" => [188.360535315763, 75.639464684237],  # R row "Ford Pantera L"
      "30" => [149.551267759497, 25.448732240503],  # R row "Ferrari Dino"
      "31" => [194.652393974855, 140.347606025145],  # R row "Maserati Bora"
      "32" => [130.922987717327, -21.922987717327],  # R row "Volvo 142E"
    },
  },
  {
    name    => 'bf_three',
    data    => 'bodyfat',
    formula => 'BodyFat ~ Abdomen + Weight + Wrist',
    ref     => 'R+scipy',
    cond => 2.54819e+07,   # kappa(X'X), so eps*cond permits 5.9e-09
    tol  => 3.59549e-09,   # measured deviation from R 1.8e-11 x 200
    atol => 4.82803e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 248,
    n_used      => 252,
    rss           => 4786.05422347369,
    r_squared     => 0.727740088213853,
    adj_r_squared => 0.724446621539021,
    fstatistic => [220.964764506349, 3, 248],
    f_pvalue   => 9.33450126322556e-70,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [-27.9299169352083, 6.8171934909632, -4.09698169374713, 5.67213594131711e-05],
      "Abdomen" => [0.975129591608891, 0.0561459924224373, 17.3677505648507, 9.45304274183904e-45],
      "Weight" => [-0.114460940358786, 0.023644994954862, -4.8408105215201, 2.27601176675931e-06],
      "Wrist" => [-1.24485892665973, 0.436183485056878, -2.85397996326569, 0.00468237873960263],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [16.2084365736427, -3.90843657364272],
      "2" => [10.5190487859628, -4.41904878596277],
      "3" => [19.4923311694086, 5.80766883059138],
      "4" => [12.518188583307, -2.118188583307],
      "249" => [26.4303767457486, 7.16962325425139],
      "250" => [37.0139912373045, -7.71399123730454],
      "251" => [24.3690795734712, 1.63092042652882],
      "252" => [28.1034470627198, 3.79655293728016],
    },
  },
  {
    name    => 'bf_dot',
    data    => 'bodyfat',
    formula => 'BodyFat ~ .',
    ref     => 'R+scipy',
    cond => 2.08199e+09,   # kappa(X'X), so eps*cond permits 4.8e-07
    tol  => 2.18863e-06,   # measured deviation from R 1.1e-08 x 200
    atol => 4.55983e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 15,
    df_residual => 237,
    n_used      => 252,
    rss           => 384.855286634483,
    r_squared     => 0.978107087488556,
    adj_r_squared => 0.97681383527269,
    fstatistic => [756.315802508538, 14, 237],
    f_pvalue   => 8.49860199251789e-188,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [450.012569344575, 10.713195463649, 42.0054474756402, 8.69685954755793e-112],
      "Density" => [-411.237849325571, 8.25845450436352, -49.7959816946724, 1.61672494637519e-127],
      "Age" => [0.0125870031285524, 0.00962628632543003, 1.30756583619385, 0.192287615327365],
      "Weight" => [0.0100541596940517, 0.0159658570459375, 0.629728780930681, 0.529478658648838],
      "Height" => [-0.00798073928028574, 0.0284435292309902, -0.280581893177674, 0.779275878248448],
      "Neck" => [-0.0284558253044915, 0.0693778019810338, -0.410157492626685, 0.682060943931803],
      "Chest" => [0.0267803353981002, 0.0293637814632343, 0.912019299409078, 0.362685305483702],
      "Abdomen" => [0.0185648834358458, 0.0317521275575609, 0.584681558808649, 0.559318035518162],
      "Hip" => [0.0191660401386865, 0.043426839607673, 0.441340892218647, 0.659368598156307],
      "Thigh" => [-0.0167583630980725, 0.0430286738538078, -0.389469662834833, 0.697278484704231],
      "Knee" => [-0.004639005218716, 0.0716232312142135, -0.064769560658908, 0.948412075884264],
      "Ankle" => [-0.0856761180984368, 0.0657582028793665, -1.30289628285021, 0.193874653458637],
      "Biceps" => [-0.055050821875107, 0.050873292351112, -1.08211635872047, 0.280300609279073],
      "Forearm" => [0.0338634346945606, 0.0595347610340864, 0.56880105179514, 0.570029764037791],
      "Wrist" => [0.00734493755953322, 0.161677002398454, 0.0454296990330854, 0.963803064011213],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [12.0685525557525, 0.231447444247516],
      "2" => [6.25369298730432, -0.153692987304325],
      "3" => [24.3315245176444, 0.968475482355627],
      "4" => [10.9165048798553, -0.516504879855268],
      "249" => [33.1365703786319, 0.463429621368136],
      "250" => [29.7354056068159, -0.435405606815926],
      "251" => [26.5618888805165, -0.561888880516451],
      "252" => [32.022313780128, -0.12231378012797],
    },
  },
  {
    name    => 'bf_star',
    data    => 'bodyfat',
    formula => 'Density ~ Abdomen * Weight',
    ref     => 'R+scipy',
    cond => 2.69836e+11,   # kappa(X'X), so eps*cond permits 6.2e-05
    tol  => 2.57818e-06,   # measured deviation from R 1.3e-08 x 200
    atol => 1.09268e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 248,
    n_used      => 252,
    rss           => 0.0259368748750864,
    r_squared     => 0.714700578375905,
    adj_r_squared => 0.711249375694968,
    fstatistic => [207.087396612111, 3, 248],
    f_pvalue   => 3.0587231257384e-67,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [1.26386614295046, 0.0190886469378398, 66.2103577621875, 1.1885780707801e-159],
      "Abdomen" => [-0.0028713308350121, 0.000220198633131678, -13.0397305113836, 6.0091278809751e-30],
      "Weight" => [6.07763118213541e-07, 0.000113906892727066, 0.00533561318075642, 0.995747106242844],
      "Abdomen:Weight" => [3.40587384883913e-06, 9.98303105967168e-07, 3.41166307956087, 0.00075377276681711],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [1.06408283797724, 0.00671716202275794],
      "2" => [1.07462659308253, 0.0106734069174721],
      "3" => [1.05767371001529, -0.0162737100152941],
      "4" => [1.07026136376621, 0.00483863623378864],
      "249" => [1.0343795332407, -0.0107795332406973],
      "250" => [1.01474548856062, 0.0180545114393818],
      "251" => [1.0389278754128, 0.000972124587197183],
      "252" => [1.02913185056298, -0.00203185056297557],
    },
  },
  {
    name    => 'iris_dotted',
    data    => 'iris',
    formula => 'Sepal.Length ~ Petal.Length + Petal.Width',
    ref     => 'R+scipy',
    cond => 641.001,   # kappa(X'X), so eps*cond permits 1.5e-13
    tol  => 9.83806e-10,   # measured deviation from R 4.9e-12 x 200
    atol => 7.19388e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 147,
    n_used      => 150,
    rss           => 23.8806936655756,
    r_squared     => 0.766261297542531,
    adj_r_squared => 0.763081179141749,
    fstatistic => [240.953700766025, 2, 147],
    f_pvalue   => 3.99669695097114e-47,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [4.19058242865159, 0.097045873205548, 43.1814593473308, 2.0926454488312e-85],
      "Petal.Length" => [0.541777153740105, 0.0692817941627323, 7.81990651782998, 9.41447712097158e-13],
      "Petal.Width" => [-0.319550560650562, 0.160452617094262, -1.99155717393399, 0.0482724572929061],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [4.88516033175761, 0.214839668242387],
      "2" => [4.88516033175761, 0.0148396682423885],
      "3" => [4.83098261638361, -0.130982616383615],
      "4" => [4.93933804713164, -0.339338047131636],
      "147" => [6.29232213211605, 0.00767786788394845],
      "148" => [6.36872250679902, 0.131277493200983],
      "149" => [6.38121276935187, -0.181212769351869],
      "150" => [6.37845490355512, -0.478454903555118],
    },
  },
  {
    name    => 'iris_factor',
    data    => 'iris',
    formula => 'Sepal.Length ~ Species',
    ref     => 'R+scipy',
    cond => 13.9282,   # kappa(X'X), so eps*cond permits 3.2e-15
    tol  => 1.33656e-10,   # measured deviation from R 6.7e-13 x 200
    atol => 6.588e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 147,
    n_used      => 150,
    rss           => 38.9562,
    r_squared     => 0.618705730738487,
    adj_r_squared => 0.613518053605677,
    fstatistic => [119.264502184505, 2, 147],
    f_pvalue   => 1.66966919076942e-31,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [5.006, 0.0728022201948961, 68.7616392274662, 1.13428618636279e-113],
      "Speciesversicolor" => [0.93, 0.102957887170494, 9.03281939401063, 8.77019424057073e-16],
      "Speciesvirginica" => [1.582, 0.102957887170494, 15.3655056788439, 2.21482134895686e-32],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [5.006, 0.0940000000000025],
      "2" => [5.006, -0.106],
      "3" => [5.006, -0.306000000000001],
      "4" => [5.006, -0.406],
      "147" => [6.588, -0.288],
      "148" => [6.588, -0.088],
      "149" => [6.588, -0.388],
      "150" => [6.588, -0.688],
    },
  },
  {
    name    => 'iris_mixed',
    data    => 'iris',
    formula => 'Sepal.Length ~ Petal.Length + Species',
    ref     => 'R+scipy',
    cond => 2912.4,   # kappa(X'X), so eps*cond permits 6.7e-13
    tol  => 1.05688e-09,   # measured deviation from R 5.3e-12 x 200
    atol => 7.80735e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 146,
    n_used      => 150,
    rss           => 16.6816588040819,
    r_squared     => 0.836723784563887,
    adj_r_squared => 0.833368793835748,
    fstatistic => [249.396750204415, 3, 146],
    f_pvalue   => 3.10151170762731e-57,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [3.68352656983536, 0.106096084032687, 34.7187797119874, 1.96867076860698e-72],
      "Petal.Length" => [0.904564589715897, 0.0647855855328134, 13.9624359689972, 1.1210016283423e-28],
      "Speciesversicolor" => [-1.60097172202508, 0.193466160218272, -8.27520285831298, 7.3715290554562e-14],
      "Speciesvirginica" => [-2.11766917193802, 0.273461207425534, -7.74394727454965, 1.48029580156391e-12],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [4.94991699543759, 0.150083004562414],
      "2" => [4.94991699543761, -0.0499169954376107],
      "3" => [4.85946053646602, -0.159460536466024],
      "4" => [5.0403734544092, -0.440373454409205],
      "147" => [6.08868034647682, 0.211319653523175],
      "148" => [6.26959326442, 0.230406735579996],
      "149" => [6.45050618236318, -0.250506182363184],
      "150" => [6.17913680544841, -0.279136805448414],
    },
  },
  {
    name    => 'tooth_two',
    data    => 'ToothGrowth',
    formula => 'len ~ dose + supp',
    ref     => 'R+scipy',
    cond => 23.0932,   # kappa(X'X), so eps*cond permits 5.3e-15
    tol  => 1.97918e-11,   # measured deviation from R 9.9e-14 x 200
    atol => 2.87996e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 57,
    n_used      => 60,
    rss           => 1022.55503571429,
    r_squared     => 0.703796920470364,
    adj_r_squared => 0.693403829960552,
    fstatistic => [67.7177707445086, 2, 57],
    f_pvalue   => 8.71570914416456e-16,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [9.27249999999999, 1.28236494523084, 7.23078093680332, 1.31233452929289e-09],
      "dose" => [9.76357142857144, 0.876834290340831, 11.1350246404897, 6.31351904531957e-16],
      "suppVC" => [-3.7, 1.09360449981015, -3.38330721997058, 0.00130066247399747],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [10.4542857142857, -6.25428571428573],
      "2" => [10.4542857142857, 1.04571428571426],
      "3" => [10.4542857142857, -3.15428571428571],
      "4" => [10.4542857142857, -4.65428571428571],
      "57" => [28.7996428571429, -2.39964285714286],
      "58" => [28.7996428571429, -1.49964285714286],
      "59" => [28.7996428571429, 0.60035714285714],
      "60" => [28.7996428571429, -5.79964285714286],
    },
  },
  {
    name    => 'warp_twofac',
    data    => 'warpbreaks',
    formula => 'breaks ~ wool + tension',
    ref     => 'R+scipy',
    cond => 17.78,   # kappa(X'X), so eps*cond permits 4.1e-15
    tol  => 1e-11,   # measured deviation from R 4.4e-14 x 200
    atol => 3.92778e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 50,
    n_used      => 54,
    rss           => 6747.88888888889,
    r_squared     => 0.269140665741357,
    adj_r_squared => 0.225289105685839,
    fstatistic => [6.13753912975069, 3, 50],
    f_pvalue   => 0.00122981589685474,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [24.5555555555556, 3.16178310894083, 7.76636306460043, 3.82787344529e-10],
      "woolB" => [-5.77777777777778, 3.16178310894083, -1.82737954461187, 0.0736136689806041],
      "tensionL" => [14.7222222222222, 3.87237764712784, 3.80185600780487, 0.00039138418457667],
      "tensionM" => [4.72222222222222, 3.87237764712783, 1.21946324778647, 0.228389867360251],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [39.2777777777777, -13.2777777777777],
      "2" => [39.2777777777778, -9.27777777777778],
      "3" => [39.2777777777778, 14.7222222222222],
      "4" => [39.2777777777778, -14.2777777777778],
      "51" => [18.7777777777778, -3.77777777777778],
      "52" => [18.7777777777778, -3.77777777777778],
      "53" => [18.7777777777778, -2.77777777777778],
      "54" => [18.7777777777778, 9.22222222222222],
    },
  },
  {
    name    => 'air_three',
    data    => 'airquality',
    formula => 'Ozone ~ Solar.R + Wind + Temp',
    ref     => 'R+scipy',
    cond => 6.26748e+06,   # kappa(X'X), so eps*cond permits 1.4e-09
    tol  => 2.66844e-10,   # measured deviation from R 1.3e-12 x 200
    atol => 9.6747e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 107,
    n_used      => 111,
    rss           => 48002.7904250024,
    r_squared     => 0.605894600006622,
    adj_r_squared => 0.594844915894659,
    fstatistic => [54.8336580364863, 3, 107],
    f_pvalue   => 1.50899392096659e-21,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [-64.3420789285916, 23.0547243474709, -2.79084138933328, 0.00622663808819815],
      "Solar.R" => [0.0598205899684985, 0.0231864659413458, 2.5799787738168, 0.0112366354972334],
      "Wind" => [-3.33359130551275, 0.654407102054186, -5.09406345843221, 1.51593440783201e-06],
      "Temp" => [1.65209291099271, 0.25352979303236, 6.51636595144399, 2.42350607501852e-09],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [33.0454825411398, 7.95451745886016],
      "2" => [34.9987098350646, 1.00129016493541],
      "3" => [24.8228139407149, -12.8228139407149],
      "4" => [18.4752261997001, -0.475226199700102],
      "149" => [39.8480186967805, -9.84801869678053],
      "151" => [23.3202664110128, -9.32026641101277],
      "152" => [42.3847491486259, -24.3847491486259],
      "153" => [23.0039305684914, -3.00393056849143],
    },
  },
  {
    name    => 'air_dot',
    data    => 'airquality',
    formula => 'Ozone ~ .',
    ref     => 'R+scipy',
    cond => 6.74024e+06,   # kappa(X'X), so eps*cond permits 1.6e-09
    tol  => 2.0616e-10,   # measured deviation from R 1.0e-12 x 200
    atol => 1.0139e-10,   # residual floor: 1e-12 * max|fitted|
    rank        => 6,
    df_residual => 105,
    n_used      => 111,
    rss           => 45682.926974152,
    r_squared     => 0.62494079930322,
    adj_r_squared => 0.607080837365279,
    fstatistic => [34.9911607580523, 5, 105],
    f_pvalue   => 6.50436814594811e-21,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [-64.1163211033426, 23.4824886897717, -2.73038867176245, 0.00742053148669057],
      "Solar.R" => [0.0502743187831685, 0.0234186035592084, 2.1467684294694, 0.0341138105362936],
      "Wind" => [-3.31844386167726, 0.64450954314126, -5.14878933445046, 1.23127565175534e-06],
      "Temp" => [1.89578641698692, 0.273886881576857, 6.9217861259811, 3.65772896665827e-10],
      "Month" => [-3.03995664077384, 1.51345680829035, -2.00861803529621, 0.0471447134526981],
      "Day" => [0.273877521151533, 0.22967079817527, 1.192478640417, 0.235761543504306],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [32.9710991444526, 8.02890085554736],
      "2" => [37.1130914811453, -1.11309148114527],
      "3" => [27.4722039548336, -15.4722039548336],
      "4" => [16.8919210004267, 1.10807899957335],
      "149" => [35.1556147482955, -5.15561474829546],
      "151" => [20.5252686615551, -6.52526866155508],
      "152" => [40.5846698012701, -22.5846698012701],
      "153" => [18.7029397987074, 1.29706020129258],
    },
  },
  {
    name    => 'exact_fit',
    data    => 'exact',
    formula => 'y ~ x1 + x2',
    ref     => 'R+scipy',
    cond => 422.037,   # kappa(X'X), so eps*cond permits 9.7e-14
    tol  => 1e-11,   # measured deviation from R 4.1e-15 x 200
    atol => 1.525e-11,   # residual floor: 1e-12 * max|fitted|
    skip => [qw(rss std_error t_value p_value fstatistic f_pvalue residuals)],
    rank        => 3,
    df_residual => 9,
    n_used      => 12,
    rss           => 3.40812562958765e-29,
    r_squared     => 1.0,
    adj_r_squared => 1.0,
    fstatistic => [3.28773091658469e+31, 2, 9],
    f_pvalue   => 1.29844367965464e-139,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [2.5, 1.31784900895448e-15, 1897030678790270.0, 1.60030087272838e-134],
      "x1" => [1.5, 1.87579217262938e-16, 7996621490841310.0, 3.80813182130158e-140],
      "x2" => [-0.75, 2.66836622505152e-16, -2810708638712130.0, 4.65080761648876e-136],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [1.75, 4.47941181113608e-15],
      "2" => [4.75, -2.75371914381318e-15],
      "3" => [4.0, 3.30801154639122e-16],
      "4" => [7.75, -8.30752387112233e-16],
      "9" => [12.25, -2.85219432947031e-16],
      "10" => [15.25, 8.83262283790425e-16],
      "11" => [15.25, 6.65233594907305e-16],
      "12" => [14.5, 7.66711119394135e-16],
    },
  },
  {
    name    => 'aliased_x3',
    data    => 'aliased',
    formula => 'y ~ x1 + x2 + x3',
    ref     => 'R',
    # ref is R alone: statsmodels spreads a rank-deficient fit across all columns rather than reporting one as aliased.
    cond => 3.91315e+18,   # kappa(X'X), so eps*cond permits 9.0e+02
    tol  => 2.64795e-11,   # measured deviation from R 1.3e-13 x 200
    atol => 1.512e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 5,
    n_used      => 8,
    rss           => 0.016,
    r_squared     => 0.999899117276167,
    adj_r_squared => 0.999858764186633,
    fstatistic => [24778.7500000001, 2, 5],
    f_pvalue   => 1.02221441080185e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [0.0449999999999994, 0.0449444101084884, 1.00123685885245, 0.362674377869251],
      "x1" => [0.845, 0.0204939015319192, 41.2317780820756, 1.58274291591616e-07],
      "x2" => [1.145, 0.0204939015319192, 55.8702791763036, 3.47464247458728e-08],
      "x3" => [undef, undef, undef, undef],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [3.18, 0.0200000000000017],
      "2" => [2.88, 0.0199999999999984],
      "3" => [7.16, -0.06],
      "4" => [6.86, -0.06],
      "5" => [11.14, 0.0599999999999994],
      "6" => [10.84, 0.0600000000000004],
      "7" => [15.12, -0.020000000000001],
      "8" => [14.82, -0.0199999999999988],
    },
  },
  {
    name    => 'nas_drop',
    data    => 'nas',
    formula => 'y ~ x1 + x2',
    ref     => 'R',
    # ref is R alone: statsmodels returns the minimum-norm pinv solution for a rank-deficient fit instead of dropping an aliased column.
    cond => 2.78119e+16,   # kappa(X'X), so eps*cond permits 6.4e+00
    tol  => 1e-11,   # measured deviation from R 2.1e-14 x 200
    atol => 2.40182e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 2,
    df_residual => 6,
    n_used      => 8,
    rss           => 0.164805194805193,
    r_squared     => 0.999645480160142,
    adj_r_squared => 0.999586393520165,
    fstatistic => [16918.2996453902, 1, 6],
    f_pvalue   => 1.39260965153749e-11,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [-0.0519480519480513, 0.119452283507188, -0.434885382035625, 0.678851783412977],
      "x1" => [2.00584415584416, 0.0154212234896596, 130.070364208724, 1.39260965153749e-11],
      "x2" => [undef, undef, undef, undef],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [1.9538961038961, 0.146103896103896],
      "2" => [3.95974025974026, -0.0597402597402603],
      "5" => [9.97727272727273, -0.177272727272727],
      "6" => [11.9831168831169, 0.116883116883116],
      "7" => [13.988961038961, -0.088961038961039],
      "10" => [20.0064935064935, 0.0935064935064945],
      "11" => [22.0123376623377, -0.212337662337661],
      "12" => [24.0181818181818, 0.18181818181818],
    },
  },
  {
    name    => 'wide_dot',
    data    => 'wide',
    formula => 'y ~ .',
    ref     => 'R+scipy',
    cond => 14.6082,   # kappa(X'X), so eps*cond permits 3.4e-15
    tol  => 1.43626e-10,   # measured deviation from R 7.2e-13 x 200
    atol => 6.84057e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 9,
    df_residual => 11,
    n_used      => 20,
    rss           => 1.06275297401149,
    r_squared     => 0.990542605895169,
    adj_r_squared => 0.983664501091655,
    fstatistic => [144.01388670163, 8, 11],
    f_pvalue   => 4.96043064565534e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [3.02614914811996, 0.0784085208916118, 38.5946465219408, 4.27587995225599e-13],
      "v1" => [2.04501606662133, 0.0832206080608142, 24.573433363127, 5.80918635771586e-11],
      "v2" => [-1.55488019340402, 0.0987377518346627, -15.7475754158114, 6.82305722035098e-09],
      "v3" => [-0.0626795454950164, 0.086272553929733, -0.726529384374866, 0.482688597514044],
      "v4" => [0.0592840299070255, 0.125150426137658, 0.473702181739409, 0.644974746133118],
      "v5" => [0.0750969090334239, 0.102815299809177, 0.7304059723874, 0.480409501138213],
      "v6" => [-0.000557325266518183, 0.0753734818475124, -0.00739418231528302, 0.994232746601053],
      "v7" => [0.175119934787898, 0.120079008537929, 1.45837259084782, 0.172692150112726],
      "v8" => [-0.067511917490857, 0.1200225811706, -0.562493464416463, 0.585060653121037],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [6.12906412590922, 0.0201528740907834],
      "2" => [4.49587838040655, -0.274847380406546],
      "3" => [4.08209359971859, -0.0489995997185938],
      "4" => [2.37756897643476, -0.0426769764347574],
      "17" => [3.56282474762191, -0.38934474762191],
      "18" => [-0.908074136534869, 0.0644291365348694],
      "19" => [1.88477587362516, 0.000560126374838406],
      "20" => [5.53943404791294, 0.0447009520870641],
    },
  },
  {
    name    => 'bigscale_three',
    data    => 'bigscale',
    formula => 'y ~ tiny + huge + mid',
    ref     => 'R+scipy',
    cond => 1.06767e+20,   # kappa(X'X), so eps*cond permits 2.5e+04
    tol  => 8.70545e-10,   # measured deviation from R 4.4e-12 x 200
    atol => 7.97417e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 36,
    n_used      => 40,
    rss           => 0.0686613629437174,
    r_squared     => 0.999000156700101,
    adj_r_squared => 0.99891683642511,
    fstatistic => [11989.8806959201, 3, 36],
    f_pvalue   => 4.87017017969153e-54,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [4.9275787769995, 0.0811723006129516, 60.7051757778227, 7.31299020611269e-38],
      "tiny" => [10065.2619948456, 70.1997059219983, 143.380401137713, 3.07091949904097e-51],
      "huge" => [-2.91685152502428e-06, 7.90519832066121e-08, -36.8978918264545, 3.33815196441015e-30],
      "mid" => [0.400246213064413, 0.00301136056722724, 132.912085460741, 4.68167999481376e-50],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [6.6416807486123, -0.0114846286122968],
      "2" => [4.4578837123244, 0.0301539176755949],
      "3" => [3.60261927369278, -0.00914741369277722],
      "4" => [4.76759347997224, -0.057565079972244],
      "37" => [4.86538197953287, 0.0114371104671331],
      "38" => [4.71841747047483, 0.0446682195251683],
      "39" => [3.87135492604522, 0.0029866739547835],
      "40" => [3.40810637641394, 0.0163504535860629],
    },
  },
  {
    name    => 'four_factor',
    data    => 'fourlevel',
    formula => 'y ~ g',
    ref     => 'R+scipy',
    cond => 22.9564,   # kappa(X'X), so eps*cond permits 5.3e-15
    tol  => 1e-11,   # measured deviation from R 1.6e-14 x 200
    atol => 1.50667e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 8,
    n_used      => 12,
    rss           => 0.753333333333335,
    r_squared     => 0.996330021963032,
    adj_r_squared => 0.994953780199169,
    fstatistic => [723.949852507373, 3, 8],
    f_pvalue   => 4.4577524481242e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [4.1, 0.177169096878911, 23.1417333622364, 1.29081950124928e-08],
      "gcharlie" => [4.06666666666667, 0.250554939639549, 16.2306385678008, 2.08808748090481e-07],
      "gdelta" => [8.0, 0.250554939639549, 31.9291250514115, 1.00809196240916e-09],
      "gecho" => [10.9666666666667, 0.250554939639549, 43.7695089246432, 8.19085422179466e-11],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [12.1, -8.32667268468867e-17],
      "2" => [12.1, -0.300000000000001],
      "3" => [12.1, 0.300000000000001],
      "4" => [4.1, -3.1272769849605e-15],
      "9" => [8.16666666666667, -0.366666666666667],
      "10" => [15.0666666666667, 0.0333333333333332],
      "11" => [15.0666666666667, 0.333333333333334],
      "12" => [15.0666666666667, -0.366666666666667],
    },
  },
  {
    name    => 'four_fac_num',
    data    => 'fourlevel',
    formula => 'y ~ g + x',
    ref     => 'R+scipy',
    cond => 118.32,   # kappa(X'X), so eps*cond permits 2.7e-14
    tol  => 1e-11,   # measured deviation from R 2.0e-14 x 200
    atol => 1.51542e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 5,
    df_residual => 7,
    n_used      => 12,
    rss           => 0.692083333333336,
    r_squared     => 0.996628410664047,
    adj_r_squared => 0.994701788186359,
    fstatistic => [517.293046357614, 4, 7],
    f_pvalue   => 9.98834414290745e-09,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [4.275, 0.287038103769993, 14.8934930375153, 1.47504817363328e-06],
      "gcharlie" => [4.06666666666667, 0.256734684864937, 15.8399581607217, 9.6896336451482e-07],
      "gdelta" => [8.0, 0.256734684864937, 31.1605734309279, 9.05379637996891e-09],
      "gecho" => [10.9666666666667, 0.256734684864937, 42.7159527448969, 1.00570544510896e-09],
      "x" => [-0.0874999999999993, 0.111169379562814, -0.78708723880715, 0.457047348285596],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [12.1875, -0.0874999999999993],
      "2" => [12.1, -0.300000000000001],
      "3" => [12.0125, 0.3875],
      "4" => [4.1875, -0.0875000000000024],
      "9" => [8.07916666666667, -0.279166666666667],
      "10" => [15.1541666666667, -0.0541666666666661],
      "11" => [15.0666666666667, 0.333333333333334],
      "12" => [14.9791666666667, -0.279166666666668],
    },
  },
  {
    name    => 'tooth_fac_noint',
    data    => 'ToothGrowth',
    formula => 'len ~ supp - 1',
    ref     => 'R',
    # ref is R alone for r.squared / adj.r.squared / f.pvalue:
    # statsmodels calls this model's dummy columns an implicit
    # intercept and centres the total sum of squares. Coefficients,
    # standard errors, t values and p-values agree with both.
    cond => 1,   # kappa(X'X), so eps*cond permits 2.3e-16
    tol  => 1e-11,   # measured deviation from R 4.6e-14 x 200
    atol => 2.06633e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 2,
    df_residual => 58,
    n_used      => 60,
    rss           => 3246.85933333333,
    r_squared     => 0.868488039737478,
    adj_r_squared => 0.863953144556011,
    fstatistic => [191.512263235303, 2, 58],
    f_pvalue   => 2.81833286856211e-26,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "suppOJ" => [20.6633333333333, 1.3660201722929, 15.1266677845976, 8.60016376099875e-22],
      "suppVC" => [16.9633333333333, 1.36602017229289, 12.4180694234259, 5.60135782655782e-18],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [16.9633333333333, -12.7633333333333],
      "2" => [16.9633333333335, -5.46333333333345],
      "3" => [16.9633333333333, -9.66333333333333],
      "4" => [16.9633333333333, -11.1633333333333],
      "57" => [20.6633333333333, 5.73666666666666],
      "58" => [20.6633333333333, 6.63666666666667],
      "59" => [20.6633333333333, 8.73666666666666],
      "60" => [20.6633333333333, 2.33666666666667],
    },
  },
  {
    name    => 'tooth_noint_mixed',
    data    => 'ToothGrowth',
    formula => 'len ~ dose + supp - 1',
    ref     => 'R',
    # ref is R alone for r.squared / adj.r.squared / f.pvalue:
    # statsmodels calls this model's dummy columns an implicit
    # intercept and centres the total sum of squares. Coefficients,
    # standard errors, t values and p-values agree with both.
    cond => 23.994,   # kappa(X'X), so eps*cond permits 5.5e-15
    tol  => 1.52124e-11,   # measured deviation from R 7.6e-14 x 200
    atol => 2.87996e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 57,
    n_used      => 60,
    rss           => 1022.55503571429,
    r_squared     => 0.95858206241259,
    adj_r_squared => 0.956402170960621,
    fstatistic => [439.738438144143, 3, 57],
    f_pvalue   => 2.32557128112897e-39,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "dose" => [9.76357142857144, 0.87683429034083, 11.1350246404897, 6.31351904531939e-16],
      "suppOJ" => [9.27249999999999, 1.28236494523084, 7.23078093680333, 1.31233452929284e-09],
      "suppVC" => [5.5725, 1.28236494523084, 4.34548684500799, 5.78666108801516e-05],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [10.4542857142857, -6.25428571428569],
      "2" => [10.4542857142857, 1.04571428571432],
      "3" => [10.4542857142857, -3.15428571428572],
      "4" => [10.4542857142857, -4.65428571428572],
      "57" => [28.7996428571429, -2.39964285714286],
      "58" => [28.7996428571429, -1.49964285714286],
      "59" => [28.7996428571429, 0.600357142857143],
      "60" => [28.7996428571429, -5.79964285714286],
    },
  },
  {
    name    => 'tooth_interact',
    data    => 'ToothGrowth',
    formula => 'len ~ dose * supp',
    ref     => 'R+scipy',
    cond => 119.185,   # kappa(X'X), so eps*cond permits 2.7e-14
    tol  => 3.25691e-11,   # measured deviation from R 1.6e-13 x 200
    atol => 2.71729e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 56,
    n_used      => 60,
    rss           => 933.634928571429,
    r_squared     => 0.729554369847571,
    adj_r_squared => 0.715066211089405,
    fstatistic => [50.3552164236453, 3, 56],
    f_pvalue   => 6.5207913610368e-16,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [11.55, 1.58139427227613, 7.30368144269035, 1.08955767306658e-09],
      "dose" => [7.81142857142857, 1.19542170548132, 6.53445435666021, 2.02775256564354e-08],
      "suppVC" => [-8.25500000000001, 2.23642922731204, -3.69115190375225, 0.000507339303179275],
      "dose:suppVC" => [3.90428571428572, 1.69058158864685, 2.30943347573702, 0.0246313581344879],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [9.15285714285715, -4.95285714285715],
      "2" => [9.15285714285716, 2.34714285714284],
      "3" => [9.15285714285715, -1.85285714285715],
      "4" => [9.15285714285714, -3.35285714285714],
      "57" => [27.1728571428571, -0.772857142857144],
      "58" => [27.1728571428571, 0.127142857142858],
      "59" => [27.1728571428571, 2.22714285714286],
      "60" => [27.1728571428571, -4.17285714285714],
    },
  },
  {
    name    => 'tooth_bare_inter',
    data    => 'ToothGrowth',
    formula => 'len ~ dose:supp',
    ref     => 'R+scipy',
    cond => 16.0179,   # kappa(X'X), so eps*cond permits 3.7e-15
    tol  => 1e-11,   # measured deviation from R 5.0e-14 x 200
    atol => 2.85487e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 57,
    n_used      => 60,
    rss           => 1160.78501190476,
    r_squared     => 0.663755902431343,
    adj_r_squared => 0.651957863920162,
    fstatistic => [56.2598521612134, 2, 57],
    f_pvalue   => 3.23338991837392e-14,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [7.42249999999999, 1.23585949843608, 6.00594162151343, 1.40650563409939e-07],
      "dose:suppOJ" => [10.5630952380952, 1.03282124634256, 10.2274186123701, 1.63860633683537e-14],
      "dose:suppVC" => [8.96404761904763, 1.03282124634256, 8.67918591991711, 5.18049212923782e-12],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [11.9045238095238, -7.70452380952383],
      "2" => [11.9045238095238, -0.404523809523809],
      "3" => [11.9045238095238, -4.60452380952384],
      "4" => [11.9045238095238, -6.10452380952381],
      "57" => [28.5486904761905, -2.14869047619048],
      "58" => [28.5486904761905, -1.24869047619048],
      "59" => [28.5486904761905, 0.851309523809522],
      "60" => [28.5486904761905, -5.54869047619048],
    },
  },
  {
    name    => 'warp_noint_two',
    data    => 'warpbreaks',
    formula => 'breaks ~ wool + tension - 1',
    ref     => 'R',
    # ref is R alone for r.squared / adj.r.squared / f.pvalue:
    # statsmodels calls this model's dummy columns an implicit
    # intercept and centres the total sum of squares. Coefficients,
    # standard errors, t values and p-values agree with both.
    cond => 10.4039,   # kappa(X'X), so eps*cond permits 2.4e-15
    tol  => 1e-11,   # measured deviation from R 2.2e-14 x 200
    atol => 3.92778e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 50,
    n_used      => 54,
    rss           => 6747.88888888889,
    r_squared     => 0.870277809817969,
    adj_r_squared => 0.859900034603406,
    fstatistic => [83.859766840658, 4, 50],
    f_pvalue   => 1.52219670625551e-21,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "woolA" => [24.5555555555556, 3.16178310894083, 7.76636306460042, 3.82787344529009e-10],
      "woolB" => [18.7777777777778, 3.16178310894083, 5.93898351998856, 2.7225310413048e-07],
      "tensionL" => [14.7222222222222, 3.87237764712784, 3.80185600780486, 0.000391384184576675],
      "tensionM" => [4.72222222222222, 3.87237764712783, 1.21946324778646, 0.228389867360252],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [39.2777777777778, -13.2777777777778],
      "2" => [39.2777777777778, -9.27777777777775],
      "3" => [39.2777777777778, 14.7222222222222],
      "4" => [39.2777777777778, -14.2777777777778],
      "51" => [18.7777777777778, -3.77777777777778],
      "52" => [18.7777777777778, -3.77777777777778],
      "53" => [18.7777777777778, -2.77777777777778],
      "54" => [18.7777777777778, 9.22222222222222],
    },
  },
  {
    name    => 'warp_fac_inter',
    data    => 'warpbreaks',
    formula => 'breaks ~ wool * tension',
    ref     => 'R+scipy',
    cond => 95.4653,   # kappa(X'X), so eps*cond permits 2.2e-14
    tol  => 1.11309e-11,   # measured deviation from R 5.6e-14 x 200
    atol => 4.45556e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 6,
    df_residual => 48,
    n_used      => 54,
    rss           => 5745.11111111111,
    r_squared     => 0.37775085644601,
    adj_r_squared => 0.312933237325803,
    fstatistic => [5.82790391830736, 5, 48],
    f_pvalue   => 0.000277196404347692,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [24.5555555555556, 3.6467613457364, 6.73352414033471, 1.88453069156631e-08],
      "woolB" => [-5.77777777777776, 5.15729935387839, -1.12031072492093, 0.26815563736829],
      "tensionL" => [20.0, 5.15729935387838, 3.87799866318787, 0.000319928225692616],
      "tensionM" => [-0.555555555555542, 5.15729935387838, -0.107722185088549, 0.914665089232854],
      "woolB:tensionL" => [-10.5555555555556, 7.29352269147281, -1.44725066364661, 0.154326580470145],
      "woolB:tensionM" => [10.5555555555555, 7.29352269147281, 1.4472506636466, 0.154326580470148],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [44.5555555555555, -18.5555555555555],
      "2" => [44.5555555555556, -14.5555555555556],
      "3" => [44.5555555555555, 9.44444444444446],
      "4" => [44.5555555555556, -19.5555555555556],
      "51" => [18.7777777777778, -3.77777777777778],
      "52" => [18.7777777777778, -3.77777777777778],
      "53" => [18.7777777777778, -2.77777777777778],
      "54" => [18.7777777777778, 9.22222222222222],
    },
  },
  {
    name    => 'warp_bare_inter',
    data    => 'warpbreaks',
    formula => 'breaks ~ wool:tension',
    ref     => 'R',
    cond => 39.8522,   # kappa(X'X), so eps*cond permits 9.2e-15
    tol  => 1e-11,   # measured deviation from R 4.0e-14 x 200
    atol => 4.45556e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 6,
    df_residual => 48,
    n_used      => 54,
    rss           => 5745.11111111111,
    r_squared     => 0.37775085644601,
    adj_r_squared => 0.312933237325802,
    fstatistic => [5.82790391830735, 5, 48],
    f_pvalue   => 0.000277196404347694,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [28.7777777777778, 3.64676134573641, 7.89132467125198, 3.21518794046683e-10],
      "woolA:tensionH" => [-4.22222222222222, 5.15729935387839, -0.818688606672991, 0.417010212627146],
      "woolB:tensionH" => [-10.0, 5.15729935387839, -1.93899933159393, 0.0583923657656657],
      "woolA:tensionL" => [15.7777777777778, 5.15729935387838, 3.05931005651487, 0.00362399986636655],
      "woolB:tensionL" => [-0.555555555555551, 5.15729935387839, -0.107722185088551, 0.914665089232853],
      "woolA:tensionM" => [-4.77777777777777, 5.15729935387839, -0.926410791761544, 0.358867259206103],
      "woolB:tensionM" => [undef, undef, undef, undef],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [44.5555555555555, -18.5555555555555],
      "2" => [44.5555555555556, -14.5555555555556],
      "3" => [44.5555555555555, 9.44444444444446],
      "4" => [44.5555555555556, -19.5555555555556],
      "51" => [18.7777777777778, -3.77777777777778],
      "52" => [18.7777777777778, -3.77777777777778],
      "53" => [18.7777777777778, -2.77777777777778],
      "54" => [18.7777777777778, 9.22222222222222],
    },
  },
  {
    name    => 'iris_fac_inter',
    data    => 'iris',
    formula => 'Sepal.Length ~ Petal.Length * Species',
    ref     => 'R+scipy',
    cond => 31139.8,   # kappa(X'X), so eps*cond permits 7.2e-12
    tol  => 3.12677e-08,   # measured deviation from R 1.6e-10 x 200
    atol => 7.93026e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 6,
    df_residual => 144,
    n_used      => 150,
    rss           => 16.3006817158317,
    r_squared     => 0.840452700127257,
    adj_r_squared => 0.83491286332612,
    fstatistic => [151.710732697897, 5, 144],
    f_pvalue   => 1.47935631792427e-55,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [4.21316822303425, 0.407420861039605, 10.3410714225178, 4.3316192465224e-19],
      "Petal.Length" => [0.542292597103797, 0.276766681585973, 1.95938540721833, 0.0519990162926877],
      "Speciesversicolor" => [-1.80564511767381, 0.598428358837688, -3.01731208257053, 0.00301641298275354],
      "Speciesvirginica" => [-3.15350913212516, 0.634074055499871, -4.97340823957716, 1.8468939646167e-06],
      "Petal.Length:Speciesversicolor" => [0.285988364079198, 0.295062412598358, 0.969247019844879, 0.334047101190439],
      "Petal.Length:Speciesvirginica" => [0.45344603925984, 0.290145536328146, 1.56282273026943, 0.120289309117185],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [4.97237785897953, 0.127622141020468],
      "2" => [4.97237785897957, -0.0723778589795742],
      "3" => [4.91814859926917, -0.218148599269171],
      "4" => [5.02660711868994, -0.426607118689945],
      "147" => [6.03835227272727, 0.261647727272727],
      "148" => [6.2375, 0.2625],
      "149" => [6.43664772727273, -0.236647727272728],
      "150" => [6.13792613636364, -0.237926136363636],
    },
  },
  {
    name    => 'three_way',
    data    => 'threeway',
    formula => 'y ~ a * b * z',
    ref     => 'R+scipy',
    cond => 9330.47,   # kappa(X'X), so eps*cond permits 2.1e-12
    tol  => 1.43993e-09,   # measured deviation from R 7.2e-12 x 200
    atol => 1.01016e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 12,
    df_residual => 12,
    n_used      => 24,
    rss           => 1.22415618426409,
    r_squared     => 0.974183450531157,
    adj_r_squared => 0.950518280184718,
    fstatistic => [41.1652836751182, 11, 12],
    f_pvalue   => 8.45338285999398e-08,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [5.9887003861828, 0.306722483989763, 19.5248170537856, 1.84652038398843e-10],
      "alo" => [-1.63747013861789, 0.419828324566769, -3.90033269029105, 0.00210880640744873],
      "by" => [-0.06398931913725, 0.46406983087425, -0.13788726368336, 0.892616224784073],
      "bz" => [0.897456613817199, 0.497089735578862, 1.80542173692665, 0.0961403809581832],
      "z" => [0.2414516, 0.0714188404258083, 3.38078297771897, 0.00546024828799988],
      "alo:by" => [0.36145472157234, 0.636122326266303, 0.56821574506571, 0.580365860268477],
      "alo:bz" => [1.01715808367004, 0.68253897602376, 1.49025640937849, 0.161965906785211],
      "alo:z" => [0.00124309999999823, 0.101001492739138, 0.0123077388886603, 0.990382348365364],
      "by:z" => [0.15968505, 0.101001492739138, 1.58101673222224, 0.139858989144689],
      "bz:z" => [0.1604735, 0.101001492739138, 1.58882305249155, 0.138085587679242],
      "alo:by:z" => [-0.0744220999999979, 0.142837680851616, -0.521025681432825, 0.611828751675069],
      "alo:bz:z" => [-0.188324649999999, 0.142837680851617, -1.31845216806366, 0.211963047264094],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [4.4321284, -0.268541399999997],
      "2" => [6.1496682, -0.139030200000001],
      "3" => [4.9766533, -0.1832743],
      "4" => [6.4595598, -0.00462079999999992],
      "21" => [6.9443992, -0.0174061999999998],
      "22" => [8.8663797, -0.0727227000000001],
      "23" => [7.9129789, 0.1099791],
      "24" => [10.1015578, -0.1605348],
    },
  },
  {
    name    => 'three_way_noint',
    data    => 'threeway',
    formula => 'y ~ a * b - 1',
    ref     => 'R',
    # ref is R alone for r.squared / adj.r.squared / f.pvalue:
    # statsmodels calls this model's dummy columns an implicit
    # intercept and centres the total sum of squares. Coefficients,
    # standard errors, t values and p-values agree with both.
    cond => 43.6385,   # kappa(X'X), so eps*cond permits 1.0e-14
    tol  => 1.7419e-10,   # measured deviation from R 8.7e-13 x 200
    atol => 8.89578e-12,   # residual floor: 1e-12 * max|fitted|
    rank        => 6,
    df_residual => 18,
    n_used      => 24,
    rss           => 13.0915154183442,
    r_squared     => 0.989211491481531,
    adj_r_squared => 0.985615321975375,
    fstatistic => [275.073655395865, 6, 18],
    f_pvalue   => 1.06792530621624e-16,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "ahi" => [6.874023, 0.42641130734604, 16.120639583372, 3.83823786800137e-12],
      "alo" => [5.1602125, 0.42641130734604, 12.1014907698318, 4.40611085245196e-10],
      "by" => [0.78894675, 0.603036653998012, 1.30828987718979, 0.207235772282801],
      "bz" => [2.0217595, 0.603036653998012, 3.35263119844563, 0.00354424497780411],
      "alo:by" => [0.0113669999999991, 0.85282261469208, 0.0133286803189468, 0.989512188726437],
      "alo:bz" => [0.0864762499999995, 0.85282261469208, 0.101400043233167, 0.920353893943417],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [5.1602125, -0.9966255],
      "2" => [6.874023, -0.863385000000001],
      "3" => [5.96052625, -1.16714725],
      "4" => [7.66296975, -1.20803075],
      "21" => [5.96052625, 0.966466750000001],
      "22" => [7.66296975, 1.13068725],
      "23" => [7.26844825, 0.75450975],
      "24" => [8.8957825, 1.0452405],
    },
  },
  {
    name    => 'nasfac_drop',
    data    => 'nasfac',
    formula => 'y ~ x + g',
    ref     => 'R+scipy',
    cond => 357.873,   # kappa(X'X), so eps*cond permits 8.2e-14
    tol  => 1.73071e-11,   # measured deviation from R 8.7e-14 x 200
    atol => 2.41427e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 3,
    df_residual => 5,
    n_used      => 8,
    rss           => 0.106342592592592,
    r_squared     => 0.999782592173299,
    adj_r_squared => 0.999695629042619,
    fstatistic => [11496.6260339574, 2, 5],
    f_pvalue   => 6.96928037637695e-10,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [0.105709876543211, 0.110249726057333, 0.958822124312933, 0.38168346390077],
      "x" => [2.00308641975309, 0.0132306286748528, 151.397674969165, 2.38509042283567e-10],
      "gq" => [-0.126543209876544, 0.103334513319811, -1.22459772452699, 0.275270585483729],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [2.10879629629629, -0.00879629629629401],
      "2" => [3.98533950617284, -0.0853395061728413],
      "3" => [6.11496913580247, -0.0149691358024703],
      "6" => [11.9976851851852, 0.102314814814815],
      "8" => [16.0038580246914, 0.196141975308642],
      "9" => [18.133487654321, -0.0334876543209869],
      "11" => [22.0131172839506, -0.213117283950615],
      "12" => [24.1427469135802, 0.0572530864197513],
    },
  },
  {
    name    => 'nasfac_inter',
    data    => 'nasfac',
    formula => 'y ~ x * g',
    ref     => 'R+scipy',
    cond => 1468.2,   # kappa(X'X), so eps*cond permits 3.4e-13
    tol  => 1.6344e-10,   # measured deviation from R 8.2e-13 x 200
    atol => 2.4167e-11,   # residual floor: 1e-12 * max|fitted|
    rank        => 4,
    df_residual => 4,
    n_used      => 8,
    rss           => 0.102365914786967,
    r_squared     => 0.999790722131937,
    adj_r_squared => 0.99963376373089,
    fstatistic => [6369.78151829729, 3, 4],
    f_pvalue   => 8.21140700206921e-08,
    # term => [ Estimate, Std. Error, t value, Pr(>|t|) ], keyed by the
    # name R prints, which is the name lm() builds as well.
    coef => {
      "Intercept" => [0.0793650793650801, 0.138174004558254, 0.574385027189537, 0.596464567769655],
      "x" => [2.00730158730159, 0.0180269564279127, 111.349999392771, 3.900828856286e-08],
      "gq" => [-0.0477861319966631, 0.229706451413213, -0.2080313012659, 0.845367441476409],
      "x:gq" => [-0.0119799498746861, 0.030390824909492, -0.394196271748597, 0.713549000966507],
    },
    # row => [ fitted, residual ]
    fitted => {
      "1" => [2.08666666666667, 0.0133333333333345],
      "2" => [4.02222222222222, -0.122222222222222],
      "3" => [6.10126984126984, -0.00126984126984311],
      "6" => [12.0035087719298, 0.0964912280701756],
      "8" => [15.9941520467836, 0.205847953216374],
      "9" => [18.1450793650794, -0.0450793650793638],
      "11" => [21.9801169590643, -0.180116959064327],
      "12" => [24.1669841269841, 0.0330158730158724],
    },
  },
);

# ---------------------------------------------------------------------------
for my $c (@CASES) {
	my $data = $DATA{ $c->{data} };
	unless ($data) {
		diag("skipping $c->{name}: data set '$c->{data}' is unavailable");
		next;
	}
	my $tol   = $c->{tol};
	my $atol  = $c->{atol};
	my %skip  = map { $_ => 1 } @{ $c->{skip} || [] };
	my $label = "$c->{name} [$c->{formula}] vs $c->{ref}";

	my $fit = lm(formula => $c->{formula}, data => $data);
	ok(ref($fit) eq 'HASH', "$label: returns a hashref") or next;

	is($fit->{rank},          $c->{rank},        "$label: rank");
	is($fit->{'df.residual'}, $c->{df_residual}, "$label: df.residual");
	is(scalar keys %{ $fit->{residuals} }, $c->{n_used},
		"$label: rows kept (a row with an NA anywhere in the model is dropped)");
	is(scalar keys %{ $fit->{'fitted.values'} }, $c->{n_used},
		"$label: fitted.values has one entry per kept row");

	is_close($fit->{rss}, $c->{rss}, $tol, "$label: rss") unless $skip{rss};
	is_close($fit->{'r.squared'},     $c->{r_squared},     $tol,
		"$label: r.squared");
	is_close($fit->{'adj.r.squared'}, $c->{adj_r_squared}, $tol,
		"$label: adj.r.squared");

	# --- the overall F test -------------------------------------------------
	unless ($skip{fstatistic}) {
		if (defined $c->{fstatistic}) {
			if (ref($fit->{fstatistic}) eq 'ARRAY') {
				is_close($fit->{fstatistic}[0], $c->{fstatistic}[0], $tol,
					"$label: F statistic");
				is($fit->{fstatistic}[1], $c->{fstatistic}[1],
					"$label: F numerator df");
				is($fit->{fstatistic}[2], $c->{fstatistic}[2],
					"$label: F denominator df");
				is_close($fit->{'f.pvalue'}, $c->{f_pvalue}, $tol,
					"$label: f.pvalue");
			} else {
				fail("$label: fstatistic is an arrayref");
			}
		} else {
			ok(!defined $fit->{fstatistic},
				"$label: no F statistic for an intercept-only model");
		}
	}

	# --- the coefficient table ---------------------------------------------
	my %want = %{ $c->{coef} };
	is_deeply([ sort @{ $fit->{terms} } ], [ sort keys %want ],
		"$label: term names");
	for my $t (sort keys %want) {
		my ($est, $se, $tv, $p) = @{ $want{$t} };
		is_close($fit->{coefficients}{$t}, $est, $tol, "$label: coef $t");
		next if $skip{std_error};
		my $row = $fit->{summary}{$t};
		unless (ref($row) eq 'HASH') {
			fail("$label: summary has a row for $t");
			next;
		}
		is_close($row->{Estimate},     $est, $tol, "$label: summary $t Estimate");
		is_close($row->{'Std. Error'}, $se,  $tol, "$label: summary $t Std. Error");
		is_close($row->{'t value'},    $tv,  $tol, "$label: summary $t t value");
		is_close($row->{'Pr(>|t|)'},   $p,   $tol, "$label: summary $t Pr(>|t|)");
	}

	# --- fitted values and residuals ---------------------------------------
	# For an HoA, lm() keys these by 1-based row position, which is R's row name
	# for every data set used here.
	for my $row (sort keys %{ $c->{fitted} }) {
		my ($f, $e) = @{ $c->{fitted}{$row} };
		is_close($fit->{'fitted.values'}{$row}, $f, $tol,
			"$label: fitted.values row $row");
		next if $skip{residuals};
		is_close($fit->{residuals}{$row}, $e, $tol,
			"$label: residuals row $row", $atol);
	}
}


# ---------------------------------------------------------------------------
# Formula-parsing equivalences that R defines and lm() has to match.  In a
# formula `^` means crossing, not exponentiation, so wt^2 is just wt -- squaring
# needs I(wt^2).  A repeated term collapses to a single column.  Both of these
# fit exactly the same model as `mpg ~ wt` in R 4.6.1: rank 2, rss 278.321937543344.
{
	my $mt = $DATA{mtcars};
	my $base = lm(formula => 'mpg ~ wt', data => $mt);
	for my $f ('mpg ~ wt^2', 'mpg ~ wt + wt') {
		my $fit = lm(formula => $f, data => $mt);
		is_deeply([ sort @{ $fit->{terms} } ], [ sort @{ $base->{terms} } ],
			"R equivalence: '$f' expands to the same terms as 'mpg ~ wt'");
		is_close($fit->{rss}, 278.321937543344, 1e-11,
			"R equivalence: '$f' rss matches R's mpg ~ wt");
		is($fit->{rank}, 2, "R equivalence: '$f' rank matches R's mpg ~ wt");
	}
	# R: summary(lm(mpg ~ 1, mtcars)) reports no F statistic, there being nothing
	# to test against the intercept-only null.
	my $only = lm(formula => 'mpg ~ 1', data => $mt);
	is($only->{rank}, 1, 'intercept-only: rank 1');
	is($only->{'df.residual'}, 31, 'intercept-only: df.residual 31');
	is_close($only->{rss}, 1126.0471874999998, 1e-11,
		'intercept-only: rss equals R (n-1) * var(mpg)');
	ok(!defined $only->{fstatistic},
		'intercept-only: no fstatistic, as in summary.lm');
	is_close($only->{'r.squared'}, 0, 1e-11, 'intercept-only: r.squared 0');
}

# A term crossed with itself.  R's formula algebra collapses a:a to a, so
# `mpg ~ wt*wt` is `mpg ~ wt` there (rank 2, rss 278.321937543344).  lm() builds
# wt:wt as the column times itself, so it fits `mpg ~ wt + I(wt^2)` instead
# (rank 3, rss 203.745448778314 -- R's own value for that model).  Nobody writes a*a
# deliberately; this test exists so the behaviour cannot change without someone
# noticing which of the two readings is in force.
{
	my $mt = $DATA{mtcars};
	my $quad = lm(formula => 'mpg ~ wt + I(wt^2)', data => $mt);
	for my $f ('mpg ~ wt*wt', 'mpg ~ wt + wt:wt') {
		my $fit = lm(formula => $f, data => $mt);
		is($fit->{rank}, 3,
			"self-crossing: '$f' keeps wt:wt as a squared term (R collapses it)");
		is_close($fit->{rss}, 203.745448778314, 1e-11,
			"self-crossing: '$f' rss equals R's mpg ~ wt + I(wt^2)");
		is_close($fit->{rss}, $quad->{rss}, 1e-12,
			"self-crossing: '$f' fits the same model as mpg ~ wt + I(wt^2)");
	}
}

# ---------------------------------------------------------------------------
# The three accepted input shapes must produce the same fit: they differ only in
# how lm() walks the data, not in the design matrix it builds.
{
	my $hoa = $DATA{mtcars};
	my @cols = keys %$hoa;
	my $n = scalar @{ $hoa->{ $cols[0] } };
	my (%hoh, @aoh);
	for my $i (0 .. $n - 1) {
		my %row = map { $_ => $hoa->{$_}[$i] } @cols;
		$hoh{ 'r' . $i } = { %row };
		push @aoh, { %row };
	}
	my $ref_fit = lm(formula => 'mpg ~ wt + hp', data => $hoa);
	for my $pair ([ 'HoH', \%hoh ], [ 'AoH', \@aoh ]) {
		my ($shape, $data) = @$pair;
		my $fit = lm(formula => 'mpg ~ wt + hp', data => $data);
		# An HoH is walked in hash order, so X'X accumulates the same sums in a
		# different sequence and the last bit or two can differ.  That is not the
		# model being different.
		for my $t (sort @{ $ref_fit->{terms} }) {
			is_close($fit->{coefficients}{$t}, $ref_fit->{coefficients}{$t},
				1e-12, "$shape input: coefficient $t matches the HoA fit");
		}
		is($fit->{rank}, $ref_fit->{rank}, "$shape input: same rank");
		is($fit->{'df.residual'}, $ref_fit->{'df.residual'},
			"$shape input: same df.residual");
		is_close($fit->{rss}, $ref_fit->{rss}, 1e-12, "$shape input: same rss");
	}
}

# ---------------------------------------------------------------------------
# Factor handling.  R sorts a factor's levels and drops the first as the
# reference; lm() does the same, and reports the sorted set in xlevels.
#
# R 4.6.1, lm(y ~ g, fourlevel).  The levels are first seen as delta, alpha,
# charlie, echo, and R sorts them, so alpha becomes the reference:
#   (Intercept) 4.1  se 0.177169096878911
#   gcharlie    4.06666666666667  se 0.250554939639549
#   gdelta      8  se 0.250554939639549
#   gecho       10.9666666666667  se 0.250554939639549
#   rank 4, df.residual 8, rss 0.753333333333335
# statsmodels agrees on every one of them to 1e-15.
{
	my $fit = lm(formula => 'y ~ g', data => $DATA{fourlevel});
	is_deeply($fit->{xlevels}{g}, [qw(alpha charlie delta echo)],
		'xlevels: levels are sorted, not left in first-seen order');
	is_deeply([ sort @{ $fit->{terms} } ],
		[qw(Intercept gcharlie gdelta gecho)],
		'factor levels: the sorted-first level (alpha) is the dropped reference');
	is_close($fit->{coefficients}{Intercept}, 4.1, 1e-11,
		'factor levels: intercept is the alpha group mean');
	is_close($fit->{coefficients}{gcharlie}, 4.06666666666667, 1e-11,
		'factor levels: gcharlie matches R');
	is_close($fit->{coefficients}{gdelta}, 8, 1e-11,
		'factor levels: gdelta matches R');
	is_close($fit->{coefficients}{gecho}, 10.9666666666667, 1e-11,
		'factor levels: gecho matches R');
	is_close($fit->{summary}{gcharlie}{'Std. Error'}, 0.250554939639549,
		1e-11, 'factor levels: gcharlie Std. Error matches R');
	is_close($fit->{rss}, 0.753333333333335, 1e-11,
		'factor levels: rss matches R');
}

# A predictor with no variation is collinear with the intercept.  R reports its
# coefficient as NA and leaves it out of the rank; lm() reports NaN.
{
	my %const = (y => [ 1 .. 6 ], x => [ 1 .. 6 ], k => [ 7, 7, 7, 7, 7, 7 ]);
	my $fit = lm(formula => 'y ~ x + k', data => \%const);
	is($fit->{rank}, 2, 'constant predictor: rank excludes the aliased column');
	is($fit->{'df.residual'}, 4, 'constant predictor: df.residual is n - rank');
	ok(is_nanish($fit->{coefficients}{k}),
		'constant predictor: aliased coefficient is NaN, where R reports NA');
	is($fit->{summary}{k}{Estimate}, 'NaN',
		'constant predictor: summary Estimate is the string NaN');
	is($fit->{summary}{k}{'Std. Error'}, 'NaN',
		'constant predictor: summary Std. Error is the string NaN');
	is_close($fit->{coefficients}{x}, 1, 1e-11,
		'constant predictor: the estimable slope is still exact');
}

# ---------------------------------------------------------------------------
# A factor with a single level contributes no columns, so `y ~ x + g` fits the
# same model as `y ~ x`.  R refuses this outright:
#   Error in `contrasts<-`(...): contrasts can be applied only to factors with
#   2 or more levels
# lm() dropping the term instead is a deliberate difference, so it is pinned
# here: whatever it does must at least be a coherent fit of `y ~ x`.
{
	my $with    = lm(formula => 'y ~ x + g', data => $DATA{onelevel});
	my $without = lm(formula => 'y ~ x',     data => $DATA{onelevel});
	is($with->{rank}, $without->{rank},
		'single-level factor: contributes no column, so rank matches y ~ x');
	is($with->{'df.residual'}, $without->{'df.residual'},
		'single-level factor: df.residual matches y ~ x');
	is_close($with->{rss}, $without->{rss}, 1e-12,
		'single-level factor: rss matches y ~ x');
	is_close($with->{coefficients}{x}, $without->{coefficients}{x}, 1e-12,
		'single-level factor: slope matches y ~ x');
}

# ---------------------------------------------------------------------------
# Level ordering.  lm() sorts levels with strcmp(), i.e. in byte order, which is
# what patsy/pandas does too (Python's sorted() over str).  R sorts with the
# collation of the running locale, so under en_US.UTF-8 it orders c("b","A","a")
# as a, A, b and takes "a" as the reference, where byte order gives A, a, b and
# takes "A".  Both parameterise the same three group means; the point of this
# test is that lm()'s choice is byte order and does not drift.
#
#   statsmodels 0.14.6, ols('y ~ C(g)'):
#     Intercept 7.16666666666667   (level "A")
#     C(g)[T.a] 3.899999999999997
#     C(g)[T.b] -4.0333333333333385
#   R 4.6.1 takes "a" as the reference instead, reporting
#     (Intercept) 11.0666666666667, gA -3.9, gb -7.93333333333334.
#   The fit itself is parameterisation-independent, so rss is
#   0.620000000000001 either way; that is checked below as well.
{
	my $fit = lm(formula => 'y ~ g', data => $DATA{mixedcase});
	is_deeply($fit->{xlevels}{g}, [qw(A a b)],
		'mixed-case levels: xlevels is in byte order (A, a, b), as in patsy');
	is_deeply([ sort @{ $fit->{terms} } ], [qw(Intercept ga gb)],
		'mixed-case levels: "A" is the reference, so ga and gb are fitted');
	is_close($fit->{coefficients}{Intercept},
		7.16666666666667, 1e-11,
		'mixed-case levels: intercept is the "A" group mean, matching statsmodels');
	is_close($fit->{coefficients}{ga},
		3.899999999999997, 1e-11,
		'mixed-case levels: ga matches statsmodels');
	is_close($fit->{coefficients}{gb},
		-4.0333333333333385, 1e-11,
		'mixed-case levels: gb matches statsmodels');
	is($fit->{rank}, 3, 'mixed-case levels: rank 3');
	is_close($fit->{rss}, 0.620000000000001, 1e-11,
		'mixed-case levels: rss matches R and statsmodels despite the different '
		. 'reference level');
}

# ---------------------------------------------------------------------------
# Contrast coding, term by term. The numeric agreement for each of these models
# is checked by the generated cases above; what is pinned here is the structure
# -- which columns a term produces and what they are called -- because that is
# what R's margin rule decides and what changed when factor-bearing terms
# started working. Every expected column set below is R 4.6.1's own.
{
	my $tg = $DATA{ToothGrowth};
	my $wb = $DATA{warpbreaks};
	my $tw = $DATA{threeway};

	# With an intercept to serve as the baseline, a factor drops its first level.
	is_deeply([ sort @{ lm(formula => 'len ~ supp', data => $tg)->{terms} } ],
		[qw(Intercept suppVC)],
		'coding: a factor with an intercept drops its reference level');

	# With no intercept there is no baseline, so every level gets a column. This
	# is the case that used to silently drop suppOJ and fit a model forcing every
	# OJ observation to a fitted value of 0.
	is_deeply([ sort @{ lm(formula => 'len ~ supp - 1', data => $tg)->{terms} } ],
		[qw(suppOJ suppVC)],
		'coding: a factor with no intercept keeps every level');
	is_deeply([ sort @{ lm(formula => 'len ~ supp + 0', data => $tg)->{terms} } ],
		[qw(suppOJ suppVC)],
		'coding: "+ 0" suppresses the intercept the same way as "- 1"');

	# Only the first factor can take the empty margin. Coding both in full would
	# be rank deficient, so tension falls back to contrasts.
	is_deeply([ sort @{ lm(formula => 'breaks ~ wool + tension - 1', data => $wb)->{terms} } ],
		[qw(tensionL tensionM woolA woolB)],
		'coding: with no intercept only the first factor is coded in full');

	# A numeric term cannot take the empty margin, so the factor still does.
	is_deeply([ sort @{ lm(formula => 'len ~ dose + supp - 1', data => $tg)->{terms} } ],
		[qw(dose suppOJ suppVC)],
		'coding: a numeric term does not consume the empty margin');

	# Interactions. Both main effects are present, so both components of the
	# interaction are coded by contrasts.
	is_deeply([ sort @{ lm(formula => 'len ~ dose * supp', data => $tg)->{terms} } ],
		[ sort qw(Intercept dose suppVC dose:suppVC) ],
		'coding: numeric x factor interaction, both margins present');
	# warpbreaks arrives here from a TSV, so tension is a character column whose
	# levels sort H, L, M -- not R's native L, M, H -- and H is the reference.
	# R reads the same file the same way, which is why the two agree.
	is_deeply([ sort @{ lm(formula => 'breaks ~ wool * tension', data => $wb)->{terms} } ],
		[ sort qw(Intercept woolB tensionL tensionM woolB:tensionL woolB:tensionM) ],
		'coding: factor x factor interaction, both margins present');
	# Writing the interaction out longhand must give the identical model.
	is_deeply([ sort @{ lm(formula => 'breaks ~ wool + tension + wool:tension',
			data => $wb)->{terms} } ],
		[ sort @{ lm(formula => 'breaks ~ wool * tension', data => $wb)->{terms} } ],
		'coding: a + b + a:b expands to the same columns as a * b');

	# Without the main effects there is no margin for either component, so both
	# are coded in full and the term spans the whole cross-classification. R
	# reports 6 columns for a rank of 6 including the intercept, i.e. one of them
	# aliased, and lm() has to agree on which.
	{
		my $bare = lm(formula => 'breaks ~ wool:tension', data => $wb);
		is_deeply([ sort @{ $bare->{terms} } ],
			[ sort qw(Intercept woolA:tensionL woolB:tensionL woolA:tensionM
			          woolB:tensionM woolA:tensionH woolB:tensionH) ],
			'coding: a bare a:b codes both components in full');
		is($bare->{rank}, 6,
			'coding: the full cross plus an intercept is rank deficient by one');
		is($bare->{'df.residual'}, 48, 'coding: bare interaction df.residual');
		# The sweep pivots left to right, as R's pivoted QR does, so the column
		# that ends up aliased is the last one -- woolB:tensionM here.
		ok(is_nanish($bare->{coefficients}{'woolB:tensionM'}),
			'coding: the aliased column is the last one, as in R');
	}
	# A numeric crossed with a factor and no main effects: only the factor needs
	# promoting, so dose keeps its single column and supp gets both levels.
	is_deeply([ sort @{ lm(formula => 'len ~ dose:supp', data => $tg)->{terms} } ],
		[ sort qw(Intercept dose:suppOJ dose:suppVC) ],
		'coding: a bare numeric:factor promotes only the factor');

	# n-way crossing. `a * b * z` is every non-empty subset of the three, by
	# increasing degree, which is 12 columns once a and b are coded by contrasts.
	is_deeply([ sort @{ lm(formula => 'y ~ a * b * z', data => $tw)->{terms} } ],
		[ sort qw(Intercept alo by bz z alo:by alo:bz alo:z by:z bz:z
		          alo:by:z alo:bz:z) ],
		'coding: a * b * z crosses all three, by increasing degree');
	is_deeply([ sort @{ lm(formula => 'y ~ a * b * z', data => $tw)->{terms} } ],
		[ sort @{ lm(formula => 'y ~ a + b + z + a:b + a:z + b:z + a:b:z',
			data => $tw)->{terms} } ],
		'coding: a * b * z expands to the same columns written out longhand');

	# The terms list is ordered by degree, as R's terms() is, so that a margin is
	# always decided against terms that precede it.
	{
		my @t = @{ lm(formula => 'y ~ a * b * z', data => $tw)->{terms} };
		my @deg = map { my $c = () = /:/g; $c } @t;
		my @sorted = sort { $a <=> $b } @deg;
		is_deeply(\@deg, \@sorted,
			'coding: terms come out ordered by degree, as in R');
		is($t[0], 'Intercept', 'coding: the intercept is the first term');
	}

	# Writing the interaction the other way round names it the other way round,
	# exactly as R does, and fits the identical model.
	{
		my $ab = lm(formula => 'breaks ~ wool * tension', data => $wb);
		my $ba = lm(formula => 'breaks ~ tension * wool', data => $wb);
		is_close($ab->{rss}, $ba->{rss}, 1e-12,
			'coding: a * b and b * a fit the same model');
		is($ab->{rank}, $ba->{rank}, 'coding: a * b and b * a have the same rank');
		ok(exists $ba->{coefficients}{'tensionM:woolB'},
			'coding: b * a names the interaction tensionM:woolB, as R does');
	}

	# A row missing the factor is dropped, just as a row missing a number is.
	{
		my $fit = lm(formula => 'y ~ x * g', data => $DATA{nasfac});
		is(scalar keys %{ $fit->{residuals} }, 8,
			'NA handling: rows with an NA in the factor are dropped too');
		is($fit->{'df.residual'}, 4, 'NA handling: df.residual counts kept rows');
	}

	# xlevels has to describe every factor the model used, including one that
	# appears only inside an interaction, because predict() resolves dummy names
	# through it.
	{
		my $fit = lm(formula => 'len ~ dose:supp', data => $tg);
		is_deeply($fit->{xlevels}{supp}, [qw(OJ VC)],
			'xlevels: a factor reached only through an interaction is still listed');
	}
}

# ---------------------------------------------------------------------------
# predict() has to be able to score the models above: it recovers each dummy
# from xlevels by name, so a column for a reference level has to resolve too.
{
	my $tg = $DATA{ToothGrowth};
	for my $f ('len ~ supp - 1', 'len ~ dose * supp', 'len ~ dose:supp') {
		my $fit  = lm(formula => $f, data => $tg);
		my $pred = predict($fit, $tg);
		my $ok   = 1;
		for my $row (keys %{ $fit->{'fitted.values'} }) {
			$ok = 0, last
				unless close_enough($pred->{$row}, $fit->{'fitted.values'}{$row}, 1e-9);
		}
		ok($ok, "predict: '$f' reproduces lm's own fitted values");
	}
}

done_testing();

