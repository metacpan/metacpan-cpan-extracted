#!/usr/bin/env perl
#
# Cross-validation of power_t_test() against the reference implementations:
# the inverse problem, solving for sd and sig_level.
#
# Split from t/power_t_test.R.scipy.t, whose header records the bugs these
# rows were written to pin down. That file holds the forward problem and
# everything that is not a table row; the other inverse rows are in
# t/power_t_test.solve_delta.R.scipy.t and
# t/power_t_test.solve_n.R.scipy.t.
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
	{ solve => 'sd', n => 30.0, delta => 0.5, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 0.6796969427007827, r => 0.6796918527979604 },
	{ solve => 'sd', n => 20.0, delta => 1.0, sig_level => 0.05, power => 0.9, type => 'two.sample', alternative => 'two.sided', want => 0.950576552887166, r => 0.9505796138019411 },
	{ solve => 'sd', n => 50.0, delta => 2.0, sig_level => 0.01, power => 0.95, type => 'two.sample', alternative => 'two.sided', want => 2.3289098465743043, r => 2.3289039893583916 },
	{ solve => 'sd', n => 15.0, delta => 0.75, sig_level => 0.05, power => 0.5, type => 'two.sample', alternative => 'two.sided', want => 1.011915404041474, r => 1.0119164645573857 },
	{ solve => 'sd', n => 8.0, delta => 4.0, sig_level => 0.1, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 3.058038416277059, r => 3.0580669930692275 },
	{ solve => 'sd', n => 30.0, delta => 0.5, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 0.7696706108879009, r => 0.76966993899846 },
	{ solve => 'sd', n => 20.0, delta => 1.0, sig_level => 0.05, power => 0.9, type => 'two.sample', alternative => 'one.sided', want => 1.061121889161472, r => 1.061117915410015 },
	{ solve => 'sd', n => 50.0, delta => 2.0, sig_level => 0.01, power => 0.95, type => 'two.sample', alternative => 'one.sided', want => 2.4831325902928474, r => 2.4831306244990796 },
	{ solve => 'sd', n => 15.0, delta => 0.75, sig_level => 0.05, power => 0.5, type => 'two.sample', alternative => 'one.sided', want => 1.218416121893955, r => 1.2183899014386326 },
	{ solve => 'sd', n => 8.0, delta => 4.0, sig_level => 0.1, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 3.654639092455417, r => 3.6546369538380667 },
	{ solve => 'sd', n => 30.0, delta => 0.5, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 0.9447576671771887, r => 0.944778600545872 },
	{ solve => 'sd', n => 20.0, delta => 1.0, sig_level => 0.05, power => 0.9, type => 'one.sample', alternative => 'two.sided', want => 1.3081163004534617, r => 1.3081104699539052 },
	{ solve => 'sd', n => 50.0, delta => 2.0, sig_level => 0.01, power => 0.95, type => 'one.sample', alternative => 'two.sided', want => 3.2357351863281196, r => 3.2357348865842113 },
	{ solve => 'sd', n => 15.0, delta => 0.75, sig_level => 0.05, power => 0.5, type => 'one.sample', alternative => 'two.sided', want => 1.379909668541831, r => 1.3798816541977543 },
	{ solve => 'sd', n => 8.0, delta => 4.0, sig_level => 0.1, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 4.089326907177371, r => 4.089311329682658 },
	{ solve => 'sd', n => 30.0, delta => 0.5, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 1.07539493305583, r => 1.0754192578922093 },
	{ solve => 'sd', n => 20.0, delta => 1.0, sig_level => 0.05, power => 0.9, type => 'one.sample', alternative => 'one.sided', want => 1.4724244427213713, r => 1.4724363843081958 },
	{ solve => 'sd', n => 50.0, delta => 2.0, sig_level => 0.01, power => 0.95, type => 'one.sample', alternative => 'one.sided', want => 3.4615472566327394, r => 3.461570961125464 },
	{ solve => 'sd', n => 15.0, delta => 0.75, sig_level => 0.05, power => 0.5, type => 'one.sample', alternative => 'one.sided', want => 1.679915181922281, r => 1.6799233698344598 },
	{ solve => 'sd', n => 8.0, delta => 4.0, sig_level => 0.1, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 5.000641946815355, r => 5.0006211249014285 },
	{ solve => 'sd', n => 30.0, delta => 0.5, sig_level => 0.05, power => 0.8, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.679697769224397, r => 0.6796975202389116 },
	{ solve => 'sd', n => 30.0, delta => 0.5, sig_level => 0.05, power => 0.8, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.9447587912111444, r => 0.9447609388074347 },
	{ solve => 'sig_level', n => 30.0, delta => 0.5, sd => 1.0, power => 0.8, type => 'two.sample', alternative => 'two.sided', want => 0.27792837666380965, r => 0.27790317707348083 },
	{ solve => 'sig_level', n => 20.0, delta => 1.0, sd => 1.0, power => 0.9, type => 'two.sample', alternative => 'two.sided', want => 0.07005359746483382, r => 0.07004583620272126 },
	{ solve => 'sig_level', n => 50.0, delta => 0.4, sd => 1.0, power => 0.95, type => 'two.sample', alternative => 'two.sided', want => 0.7229619916354408, r => 0.7229632704285954 },
	{ solve => 'sig_level', n => 12.0, delta => 0.6, sd => 1.5, power => 0.6, type => 'two.sample', alternative => 'two.sided', want => 0.47115525566595323, r => 0.47115226620533407 },
	{ solve => 'sig_level', n => 30.0, delta => 0.5, sd => 1.0, power => 0.8, type => 'two.sample', alternative => 'one.sided', want => 0.13896418833190483, r => 0.13894997101343887 },
	{ solve => 'sig_level', n => 20.0, delta => 1.0, sd => 1.0, power => 0.9, type => 'two.sample', alternative => 'one.sided', want => 0.035026798732416944, r => 0.03502288397019566 },
	{ solve => 'sig_level', n => 50.0, delta => 0.4, sd => 1.0, power => 0.95, type => 'two.sample', alternative => 'one.sided', want => 0.3614809958177223, r => 0.3614816995967671 },
	{ solve => 'sig_level', n => 12.0, delta => 0.6, sd => 1.5, power => 0.6, type => 'two.sample', alternative => 'one.sided', want => 0.23557762783297678, r => 0.23555910726490628 },
	{ solve => 'sig_level', n => 40.0, delta => 0.5, sd => 1.0, power => 0.99, type => 'two.sample', alternative => 'one.sided', want => 0.5359909046648442, r => 0.5359870262202796 },
	{ solve => 'sig_level', n => 30.0, delta => 0.5, sd => 1.0, power => 0.8, type => 'one.sample', alternative => 'two.sided', want => 0.0690642500236002, r => 0.06905708592684968 },
	{ solve => 'sig_level', n => 20.0, delta => 1.0, sd => 1.0, power => 0.9, type => 'one.sample', alternative => 'two.sided', want => 0.006164685749415106, r => 0.006170974052137374 },
	{ solve => 'sig_level', n => 50.0, delta => 0.4, sd => 1.0, power => 0.95, type => 'one.sample', alternative => 'two.sided', want => 0.24449594244676448, r => 0.24449587911018197 },
	{ solve => 'sig_level', n => 12.0, delta => 0.6, sd => 1.5, power => 0.6, type => 'one.sample', alternative => 'two.sided', want => 0.27403569827586816, r => 0.27400540165280934 },
	{ solve => 'sig_level', n => 40.0, delta => 0.5, sd => 1.0, power => 0.99, type => 'one.sample', alternative => 'two.sided', want => 0.4110537372853186, r => 0.4110565493237006 },
	{ solve => 'sig_level', n => 30.0, delta => 0.5, sd => 1.0, power => 0.8, type => 'one.sample', alternative => 'one.sided', want => 0.03453212501180006, r => 0.0345284933143366 },
	{ solve => 'sig_level', n => 20.0, delta => 1.0, sd => 1.0, power => 0.9, type => 'one.sample', alternative => 'one.sided', want => 0.00308234287470755, r => 0.003058129074615677 },
	{ solve => 'sig_level', n => 50.0, delta => 0.4, sd => 1.0, power => 0.95, type => 'one.sample', alternative => 'one.sided', want => 0.12224797122338214, r => 0.12224792756533148 },
	{ solve => 'sig_level', n => 12.0, delta => 0.6, sd => 1.5, power => 0.6, type => 'one.sample', alternative => 'one.sided', want => 0.1370178491379342, r => 0.13701915485458005 },
	{ solve => 'sig_level', n => 40.0, delta => 0.5, sd => 1.0, power => 0.99, type => 'one.sample', alternative => 'one.sided', want => 0.20552686864265912, r => 0.20552826955078907 },
	{ solve => 'sig_level', n => 30.0, delta => 0.5, sd => 1.0, power => 0.8, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.2759479733366265, r => 0.27592543292083577 },
	{ solve => 'sig_level', n => 30.0, delta => 0.5, sd => 1.0, power => 0.8, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.06906239113785696, r => 0.06905513354775511 },
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
