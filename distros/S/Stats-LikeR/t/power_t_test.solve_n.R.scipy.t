#!/usr/bin/env perl
#
# Cross-validation of power_t_test() against the reference implementations:
# the inverse problem, solving for n, the sample size.
#
# Split from t/power_t_test.R.scipy.t, whose header records the bugs these
# rows were written to pin down. That file holds the forward problem and
# everything that is not a table row; the other inverse rows are in
# t/power_t_test.solve_delta.R.scipy.t and
# t/power_t_test.solve_sd_sig_level.R.scipy.t.
# The split is for wall time only: each solve costs ~20 noncentral t CDFs at a
# fixed 30000-step quadrature, ~4 s apiece on a quadmath perl, and the harness
# runs files in parallel.
#
# Every expected value in the table below was produced by one of:
#
#   * scipy 1.17.1 -- scipy.stats.nct.sf() for the power (R's
#     pt(..., ncp = ..., lower.tail = FALSE)) and scipy.stats.t.isf() for the
#     critical value, driven by scipy.optimize.brentq() at xtol = 1e-13 to
#     solve for the parameter. This is the `want` column, and it is the
#     tighter of the two references: brentq at that tolerance puts the root at
#     machine precision.
#   * R 4.6.1 stats::power.t.test() -- the function power_t_test() is modelled
#     on, carried in the `r` column. R solves with uniroot() at its default
#     tol, .Machine$double.eps^0.25 == 1.2e-4 measured on the width of the
#     bracket, which leaves its answer good to four or five significant digits
#     and no more; hence the looser check against `r`.

require 5.010;
use warnings FATAL => 'all';
use strict;
use Stats::LikeR;
use Test::More;

# Relative comparison: across the power_t_test files the solved quantities span
# 3e-3 (a sig_level) to 6e3 (an n), so a single absolute epsilon cannot serve
# both ends.
sub is_rel {
	my ($got, $want, $eps, $name) = @_;
	my $scale = abs($want) > 1e-300 ? abs($want) : 1.0;
	my $rel   = abs($got - $want) / $scale;
	ok($rel <= $eps, sprintf('%s (rel %.2e <= %.0e)', $name, $rel, $eps))
		or diag(sprintf("got      %.17g\nexpected %.17g", $got, $want));
	return;
}

# `want` is scipy at machine precision, so power_t_test() is held to 1e-9
# relative -- 1e4 tighter than R manages on the inverse problems, and still
# three decades looser than the ~1e-13 actually observed.
my $EPS_SCIPY = 1e-9;
# All R promises is uniroot()'s bracket tolerance, which is *absolute*:
# .Machine$double.eps^0.25 == 1.22e-4. A solved sig_level of 0.006 therefore
# carries no useful relative accuracy at all, which is why the R check below is
# the looser of an absolute and a relative bound rather than a relative one
# alone.
my $EPS_R_ABS = 2e-4;
my $EPS_R_REL = 1e-3;

sub matches_R {
	my ($got, $r, $name) = @_;
	my $abs = abs($got - $r);
	ok($abs <= $EPS_R_ABS || $abs <= $EPS_R_REL * abs($r),
		sprintf('%s (abs %.2e <= %.0e or rel %.2e <= %.0e)',
			$name, $abs, $EPS_R_ABS, $abs / (abs($r) || 1), $EPS_R_REL))
		or diag(sprintf("got      %.17g\nR        %.17g", $got, $r));
	return;
}

my @cases = (
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 63.76576372485063, r => 63.765763714273874 },
	{ solve => 'n', delta => 1.0, sd => 1.0, sig_level => 0.05, power => 0.9, type => 'two.sample', alternative => 'two.sided', want => 22.021095570096936, r => 22.02109770385123 },
	{ solve => 'n', delta => 0.2, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'two.sample', alternative => 'two.sided', want => 892.3686643877469, r => 892.3686644933304 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'two.sample', alternative => 'two.sided', want => 31.71688513064714, r => 31.716885098969467 },
	{ solve => 'n', delta => 0.3, sd => 1.5, sig_level => 0.05, power => 0.99, type => 'two.sample', alternative => 'two.sided', want => 919.5850707709836, r => 919.5850716046169 },
	{ solve => 'n', delta => 2.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 5.090000758688685, r => 5.090008148710024 },
	{ solve => 'n', delta => 0.05, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 6280.06429630707, r => 6280.064296248465 },
	{ solve => 'n', delta => 1.2, sd => 0.8, sig_level => 0.1, power => 0.7, type => 'two.sample', alternative => 'two.sided', want => 5.016240394604637, r => 5.016239192472101 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 50.15078338686112, r => 50.15079949213846 },
	{ solve => 'n', delta => 1.0, sd => 1.0, sig_level => 0.05, power => 0.9, type => 'two.sample', alternative => 'one.sided', want => 17.847120626538363, r => 17.84712608648425 },
	{ solve => 'n', delta => 0.2, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'two.sample', alternative => 'one.sided', want => 789.876743619327, r => 789.8767436943195 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'two.sample', alternative => 'one.sided', want => 22.348948189364748, r => 22.348947912100638 },
	{ solve => 'n', delta => 0.3, sd => 1.5, sig_level => 0.05, power => 0.99, type => 'two.sample', alternative => 'one.sided', want => 789.1994995881087, r => 789.1994996375407 },
	{ solve => 'n', delta => 2.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 3.987012149150331, r => 3.987012442106156 },
	{ solve => 'n', delta => 0.05, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 4946.722310276315, r => 4946.722315516795 },
	{ solve => 'n', delta => 1.2, sd => 0.8, sig_level => 0.1, power => 0.7, type => 'two.sample', alternative => 'one.sided', want => 3.4795095650385712, r => 3.4795078307850504 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 33.36720397881093, r => 33.367204088022 },
	{ solve => 'n', delta => 1.0, sd => 1.0, sig_level => 0.05, power => 0.9, type => 'one.sample', alternative => 'two.sided', want => 12.585463005715868, r => 12.585474548896386 },
	{ solve => 'n', delta => 0.2, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'one.sample', alternative => 'two.sided', want => 448.6778185846029, r => 448.6778186489428 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'one.sample', alternative => 'two.sided', want => 17.352095777354506, r => 17.352095776453723 },
	{ solve => 'n', delta => 0.3, sd => 1.5, sig_level => 0.05, power => 0.99, type => 'one.sample', alternative => 'two.sided', want => 461.23817219616666, r => 461.238172658909 },
	{ solve => 'n', delta => 2.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 4.220719403683978, r => 4.220731336263879 },
	{ solve => 'n', delta => 0.05, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 3141.4731640671507, r => 3141.473164054113 },
	{ solve => 'n', delta => 1.2, sd => 0.8, sig_level => 0.1, power => 0.7, type => 'one.sample', alternative => 'two.sided', want => 3.7969652896027313, r => 3.796988379559186 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 26.137503805973445, r => 26.137510107001134 },
	{ solve => 'n', delta => 1.0, sd => 1.0, sig_level => 0.05, power => 0.9, type => 'one.sample', alternative => 'one.sided', want => 10.081070224109228, r => 10.08107040503181 },
	{ solve => 'n', delta => 0.2, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'one.sample', alternative => 'one.sided', want => 396.97368855240643, r => 396.9736886090751 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'one.sample', alternative => 'one.sided', want => 12.264761691049461, r => 12.264761690285427 },
	{ solve => 'n', delta => 0.3, sd => 1.5, sig_level => 0.05, power => 0.99, type => 'one.sample', alternative => 'one.sided', want => 395.61873003160383, r => 395.61874378124577 },
	{ solve => 'n', delta => 2.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 3.3385091172365535, r => 3.3384894217135592 },
	{ solve => 'n', delta => 0.05, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 2474.3762276778907, r => 2474.376230296638 },
	{ solve => 'n', delta => 1.2, sd => 0.8, sig_level => 0.1, power => 0.7, type => 'one.sample', alternative => 'one.sided', want => 2.7067334338742848, r => 2.706736595611079 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 63.76561019095229, r => 63.76561017078221 },
	{ solve => 'n', delta => 0.5, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 33.36712895333084, r => 33.367129103906585 },
);

for my $c (@cases) {
	my %args = (
		type        => $c->{type},
		alternative => $c->{alternative},
		($c->{strict} ? (strict => 1) : ()),
	);
	$args{$_} = $c->{$_} for grep { defined $c->{$_} } qw(n delta sd sig_level power);
	$args{ $c->{solve} } = undef;   # the one parameter being solved for

	my $got = power_t_test(%args);
	my $label = join ' ', "solve=$c->{solve}", $c->{type}, $c->{alternative},
		($c->{strict} ? 'strict' : ()),
		map { "$_=$c->{$_}" } grep { defined $c->{$_} } qw(n delta sd sig_level power);

	is_rel($got->{ $c->{solve} }, $c->{want}, $EPS_SCIPY, "scipy: $label");
	matches_R($got->{ $c->{solve} }, $c->{r}, "R: $label");

	# The parameters that were supplied come back unchanged.
	for my $k (qw(n delta sd)) {
		next if $c->{solve} eq $k or not defined $c->{$k};
		my $want = $c->{alternative} eq 'two.sided' && $k eq 'delta'
			? abs($c->{$k}) : $c->{$k};   # a two-sided delta is reported as |delta|
		is_rel($got->{$k}, $want, 1e-15, "$label: '$k' echoed back");
	}
}

# alternative => 'greater' and 'less', LikeR extensions R's power.t.test()
# lacks. 'greater' is R's one.sided (H1: delta > 0); 'less' is H1: delta < 0,
# whose power at delta is the one-sided power at -delta, so a one-sided row is
# checked again as 'less' with delta's sign flipped, against the same scipy
# value; where delta is what is solved for, it has to come back negated. One
# row per solved parameter: 'greater' takes one.sided's branch outright and
# 'less' only negates delta on the way in and back on the way out, so a
# mirrored row repeats its one.sided row's computation to the bit and adds only
# the sign handling and the echoed alternative.
my %mirrored;
for my $c (grep { $_->{alternative} eq 'one.sided' && !$_->{strict}
		&& !$mirrored{ $_->{solve} }++ } @cases) {
	for my $alt (qw(greater less)) {
		my $flip = $alt eq 'less' ? -1 : 1;
		my %args = (type => $c->{type}, alternative => $alt);
		$args{$_} = $c->{$_} for grep { defined $c->{$_} } qw(n delta sd sig_level power);
		$args{delta} = $flip * $args{delta} if defined $args{delta};
		$args{ $c->{solve} } = undef;
		my $label = join ' ', "solve=$c->{solve}", $c->{type}, $alt,
			map { "$_=$args{$_}" } grep { defined $args{$_} } qw(n delta sd sig_level power);
		my $got = power_t_test(%args);
		my $want = $c->{solve} eq 'delta' ? $flip * $c->{want} : $c->{want};
		is_rel($got->{ $c->{solve} }, $want, $EPS_SCIPY, "scipy, mirrored: $label");
		is($got->{alternative}, $alt, "$label: alternative echoed");
	}
}

done_testing();
