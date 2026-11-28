#!/usr/bin/env perl
#
# Cross-validation of power_t_test() against the reference implementations:
# the inverse problem, solving for delta, the effect size.
#
# Split from t/power_t_test.R.scipy.t, whose header records the bugs these
# rows were written to pin down. That file holds the forward problem and
# everything that is not a table row; the other inverse rows are in
# t/power_t_test.solve_n.R.scipy.t and
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
use Stats::LikeR qw(:all);
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
	{ solve => 'delta', n => 30.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 0.7356219641260183, r => 0.7356289015301828 },
	{ solve => 'delta', n => 10.0, sd => 2.0, sig_level => 0.05, power => 0.9, type => 'two.sample', alternative => 'two.sided', want => 3.0673845239989928, r => 3.06740159810974 },
	{ solve => 'delta', n => 100.0, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'two.sample', alternative => 'two.sided', want => 0.601954672197985, r => 0.6019551787701918 },
	{ solve => 'delta', n => 25.0, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'two.sample', alternative => 'two.sided', want => 0.5656992435244989, r => 0.5656976497908537 },
	{ solve => 'delta', n => 5.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 2.0244409773588266, r => 2.0244379394941245 },
	{ solve => 'delta', n => 500.0, sd => 3.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 0.5320756185731333, r => 0.5320814999330704 },
	{ solve => 'delta', n => 30.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 0.6496285461948388, r => 0.6496277812694267 },
	{ solve => 'delta', n => 10.0, sd => 2.0, sig_level => 0.05, power => 0.9, type => 'two.sample', alternative => 'one.sided', want => 2.7224831310254256, r => 2.7225057484923214 },
	{ solve => 'delta', n => 100.0, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'two.sample', alternative => 'one.sided', want => 0.5654896536559569, r => 0.5654977031202721 },
	{ solve => 'delta', n => 25.0, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'two.sample', alternative => 'one.sided', want => 0.4719028861068025, r => 0.471887329414011 },
	{ solve => 'delta', n => 5.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 1.7246073442461853, r => 1.7245818519905847 },
	{ solve => 'delta', n => 500.0, sd => 3.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 0.4720955108070633, r => 0.4720952928711648 },
	{ solve => 'delta', n => 30.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 0.5292362447757996, r => 0.529226615011549 },
	{ solve => 'delta', n => 10.0, sd => 2.0, sig_level => 0.05, power => 0.9, type => 'one.sample', alternative => 'two.sided', want => 2.3091302276155576, r => 2.3091335910376505 },
	{ solve => 'delta', n => 100.0, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'one.sample', alternative => 'two.sided', want => 0.42930977646131807, r => 0.42931660918073655 },
	{ solve => 'delta', n => 25.0, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'one.sample', alternative => 'two.sided', want => 0.4083853204351029, r => 0.4083945522760921 },
	{ solve => 'delta', n => 5.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 1.6819972822157452, r => 1.6819990382002459 },
	{ solve => 'delta', n => 500.0, sd => 3.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 0.3765974198149913, r => 0.3765971045911596 },
	{ solve => 'delta', n => 30.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 0.4649454675959891, r => 0.4649453616404649 },
	{ solve => 'delta', n => 10.0, sd => 2.0, sig_level => 0.05, power => 0.9, type => 'one.sample', alternative => 'one.sided', want => 2.0097005994773114, r => 2.009702566461256 },
	{ solve => 'delta', n => 100.0, sd => 1.0, sig_level => 0.01, power => 0.95, type => 'one.sample', alternative => 'one.sided', want => 0.40265942267360855, r => 0.4026376294114157 },
	{ solve => 'delta', n => 25.0, sd => 1.0, sig_level => 0.05, power => 0.5, type => 'one.sample', alternative => 'one.sided', want => 0.3385625677011041, r => 0.3385670345182003 },
	{ solve => 'delta', n => 5.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 1.3594179588549475, r => 1.3594144829521853 },
	{ solve => 'delta', n => 500.0, sd => 3.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 0.33404873962012777, r => 0.3340645968872011 },
	{ solve => 'delta', n => 30.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.735621069597668, r => 0.7356276582144912 },
	{ solve => 'delta', n => 30.0, sd => 1.0, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.5292356151129529, r => 0.5292232526673517 },
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
