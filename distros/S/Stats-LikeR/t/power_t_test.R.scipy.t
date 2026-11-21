#!/usr/bin/env perl
#
# Cross-validation of power_t_test() against the reference implementations.
#
# Every expected value in the table below was produced by one of:
#
#   * scipy 1.17.1 -- scipy.stats.nct.sf() for the power itself (R's
#     pt(..., ncp = ..., lower.tail = FALSE)) and scipy.stats.t.isf() for the
#     critical value, driven by scipy.optimize.brentq() at xtol = 1e-13 for the
#     four inverse problems. This is the `want` column, and it is the tighter
#     of the two references: brentq at that tolerance puts the root at machine
#     precision.
#   * R 4.6.1 stats::power.t.test() -- the function power_t_test() is modelled
#     on, carried in the `r` column.
#
# R and scipy agree on the *forward* problem (solving for power) to ~1e-13.
# They part company on the four *inverse* problems, and only because of
# uniroot(): R's default tol is .Machine$double.eps^0.25 == 1.2e-4 measured on
# the width of the bracket, which leaves R's own n, delta, sd and sig.level good
# to four or five significant digits and no more. That is why `want` and `r` are
# checked at different tolerances below -- R is not wrong here, just coarse, and
# holding power_t_test() to R's coarseness would have hidden the real bugs these
# cases were written to pin down:
#
#   1. The quadrature behind the noncentral t CDF put a fixed grid on
#      u = w/(1+w). The chi density it integrates carries w**(df-1), whose
#      derivatives blow up at w = 0 unless df is a whole number, and its width
#      shrinks as 1/sqrt(2 df) while the grid does not -- so accuracy fell apart
#      at both ends: two good digits at df = 1.2 with sig_level = 1e-4, and at
#      df = 8e7 a power of 0.138 where delta = 0 forces sig_level/2 = 0.025.
#      Guarded by the low-df and large-df blocks below.
#   2. The power was formed as 1 - P(T <= t), losing most of its digits to
#      cancellation when the power itself was small. Guarded by the ~1e-3 power
#      case below.
#   3. The four inverse solvers were plain bisection over a fixed bracket with
#      no sign-change test, so an unreachable target came back as the bracket
#      endpoint wearing the requested power: solving for sd with power => 0.01
#      returned sd = delta * 1e7, and solving for sd with a negative delta
#      returned a negative standard deviation. Guarded by the 'unreachable
#      targets croak' block.
#
# type => 'paired' shares tsample == 1 with 'one.sample', so the two produce
# identical numbers; the table carries 'one.sample' and 'paired' is checked
# separately for the numbers it shares and the method/note strings it does not.
#
# This file holds the forward problem (solving for power) and everything that
# is not a table row. The inverse rows, from the same two references, are in
# t/power_t_test.solve_n.R.scipy.t, t/power_t_test.solve_delta.R.scipy.t and
# t/power_t_test.solve_sd_sig_level.R.scipy.t. Each solve costs ~20 noncentral
# t CDFs at a fixed 30000-step quadrature, ~4 s apiece on a quadmath perl, and
# one file holding them all ran 470 s there. The harness runs files in
# parallel, so split four ways none of them is the long pole of a matrix run.

require 5.010;
use warnings FATAL => 'all';
use strict;
use Stats::LikeR;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Test::More;

# Relative comparison: the quantities here span 1e-7 (a solved sig_level) to
# 1e5 (a solved n), so a single absolute epsilon cannot serve both ends.
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
# `r` is R's own answer, and on the forward problem it is exact on both sides.
my $EPS_R_POWER = 1e-9;
# On the inverse problems all R promises is uniroot()'s bracket tolerance, which
# is *absolute*: .Machine$double.eps^0.25 == 1.22e-4. A solved sig_level of
# 0.006 therefore carries no useful relative accuracy at all, which is why the
# R check below is the looser of an absolute and a relative bound rather than a
# relative one alone.
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

# strict => 1 adds the far tail only when tside == 2 (p_body() in LikeR.xs), so
# a one-sided strict row is its non-strict partner to the bit, expected values
# included. One per type is kept to pin that; the other twenty were dropped.
my @cases = (
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 0.4778409859409133, r => 0.4778409859409388 },
	{ solve => 'power', n => 5.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 0.2859275976940434, r => 0.2859275976943807 },
	{ solve => 'power', n => 2.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 0.09131778436167344, r => 0.09131778436172622 },
	{ solve => 'power', n => 10.0, delta => 0.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 0.024999999999999977, r => 0.024999999999999994 },
	{ solve => 'power', n => 100.0, delta => 0.2, sd => 2.0, sig_level => 0.01, type => 'two.sample', alternative => 'two.sided', want => 0.030422417774573794, r => 0.030422417774598864 },
	{ solve => 'power', n => 1000.0, delta => 0.05, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 0.19976320578939022, r => 0.19976320578937834 },
	{ solve => 'power', n => 12.0, delta => 3.0, sd => 1.5, sig_level => 0.1, type => 'two.sample', alternative => 'two.sided', want => 0.9990218066667457, r => 0.9990218066668174 },
	{ solve => 'power', n => 7.0, delta => -0.8, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 0.28035793874992454, r => 0.28035793875029824 },
	{ solve => 'power', n => 50.0, delta => 0.4, sd => 0.25, sig_level => 0.001, type => 'two.sample', alternative => 'two.sided', want => 0.9999963295721584, r => 0.999996329572219 },
	{ solve => 'power', n => 3.0, delta => 0.1, sd => 10.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 0.025575596051855387, r => 0.025575596051873317 },
	{ solve => 'power', n => 20.0, delta => 5.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', want => 1.0, r => 1 },
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.4778965207601644, r => 0.4778965207602086 },
	{ solve => 'power', n => 5.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.28629549338059757, r => 0.2862954933811559 },
	{ solve => 'power', n => 2.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.09520175549788391, r => 0.09520175549797283 },
	{ solve => 'power', n => 10.0, delta => 0.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.049999999999999954, r => 0.04999999999999999 },
	{ solve => 'power', n => 100.0, delta => 0.2, sd => 2.0, sig_level => 0.01, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.030946897035132086, r => 0.030946897035177057 },
	{ solve => 'power', n => 1000.0, delta => 0.05, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.20080706718913166, r => 0.20080706718909624 },
	{ solve => 'power', n => 12.0, delta => 3.0, sd => 1.5, sig_level => 0.1, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.9990218067422038, r => 0.9990218067423112 },
	{ solve => 'power', n => 7.0, delta => -0.8, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.2807662713026989, r => 0.2807662713033301 },
	{ solve => 'power', n => 50.0, delta => 0.4, sd => 0.25, sig_level => 0.001, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.9999963295721584, r => 0.9999963295722443 },
	{ solve => 'power', n => 3.0, delta => 0.1, sd => 10.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 0.05001065359933137, r => 0.05001065359936718 },
	{ solve => 'power', n => 20.0, delta => 5.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'two.sided', strict => 1, want => 1.0, r => 1 },
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 0.606025327886786, r => 0.6060253278868073 },
	{ solve => 'power', n => 5.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 0.42144826495850457, r => 0.4214482649588239 },
	{ solve => 'power', n => 2.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 0.17355047172179056, r => 0.17355047172219384 },
	{ solve => 'power', n => 10.0, delta => 0.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 0.05000000000000001, r => 0.050000000000000044 },
	{ solve => 'power', n => 100.0, delta => 0.2, sd => 2.0, sig_level => 0.01, type => 'two.sample', alternative => 'one.sided', want => 0.052181705971995625, r => 0.05218170597200167 },
	{ solve => 'power', n => 1000.0, delta => 0.05, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 0.2990280047894047, r => 0.29902800478940583 },
	{ solve => 'power', n => 12.0, delta => 3.0, sd => 1.5, sig_level => 0.1, type => 'two.sample', alternative => 'one.sided', want => 0.9997859075469416, r => 0.9997859075469648 },
	{ solve => 'power', n => 7.0, delta => -0.8, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 0.0010980192129737896, r => 0.0010980192133117628 },
	{ solve => 'power', n => 50.0, delta => 0.4, sd => 0.25, sig_level => 0.001, type => 'two.sample', alternative => 'one.sided', want => 0.9999987641686149, r => 0.9999987641686554 },
	{ solve => 'power', n => 3.0, delta => 0.1, sd => 10.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 0.05107973726407406, r => 0.05107973726408421 },
	{ solve => 'power', n => 20.0, delta => 5.0, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', want => 1.0, r => 1 },
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'two.sample', alternative => 'one.sided', strict => 1, want => 0.606025327886786, r => 0.6060253278868073 },
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 0.7539627249951286, r => 0.7539627249951668 },
	{ solve => 'power', n => 5.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 0.40132028519950486, r => 0.40132028519993324 },
	{ solve => 'power', n => 2.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 0.09057971865059411, r => 0.09057971865071845 },
	{ solve => 'power', n => 10.0, delta => 0.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 0.025, r => 0.025 },
	{ solve => 'power', n => 100.0, delta => 0.2, sd => 2.0, sig_level => 0.01, type => 'one.sample', alternative => 'two.sided', want => 0.055640303340316416, r => 0.05564030334054926 },
	{ solve => 'power', n => 1000.0, delta => 0.05, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 0.3518446338812516, r => 0.3518446338813528 },
	{ solve => 'power', n => 12.0, delta => 3.0, sd => 1.5, sig_level => 0.1, type => 'one.sample', alternative => 'two.sided', want => 0.9999992144135351, r => 0.9999992144135951 },
	{ solve => 'power', n => 7.0, delta => -0.8, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 0.42839721284372745, r => 0.4283972128437791 },
	{ solve => 'power', n => 50.0, delta => 0.4, sd => 0.25, sig_level => 0.001, type => 'one.sample', alternative => 'two.sided', want => 0.9999999999999026, r => 0.9999999999999027 },
	{ solve => 'power', n => 3.0, delta => 0.1, sd => 10.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 0.02568068753197848, r => 0.025680687532176005 },
	{ solve => 'power', n => 20.0, delta => 5.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', want => 1.0, r => 1 },
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.75396471574379, r => 0.7539647157438519 },
	{ solve => 'power', n => 5.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.40138991737179486, r => 0.4013899173724529 },
	{ solve => 'power', n => 2.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.09280915505633597, r => 0.09280915505653509 },
	{ solve => 'power', n => 10.0, delta => 0.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.05, r => 0.05 },
	{ solve => 'power', n => 100.0, delta => 0.2, sd => 2.0, sig_level => 0.01, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.05582619939309003, r => 0.05582619939350386 },
	{ solve => 'power', n => 1000.0, delta => 0.05, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.35204501264562066, r => 0.35204501264578014 },
	{ solve => 'power', n => 12.0, delta => 3.0, sd => 1.5, sig_level => 0.1, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.9999992144135352, r => 0.9999992144136153 },
	{ solve => 'power', n => 7.0, delta => -0.8, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.42846866956259094, r => 0.42846866956267105 },
	{ solve => 'power', n => 50.0, delta => 0.4, sd => 0.25, sig_level => 0.001, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.9999999999999026, r => 0.9999999999999027 },
	{ solve => 'power', n => 3.0, delta => 0.1, sd => 10.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 0.05001389364840245, r => 0.05001389364879527 },
	{ solve => 'power', n => 20.0, delta => 5.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'two.sided', strict => 1, want => 1.0, r => 1 },
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 0.8482541909289825, r => 0.848254190929147 },
	{ solve => 'power', n => 5.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 0.5797373588621886, r => 0.579737358862325 },
	{ solve => 'power', n => 2.0, delta => 1.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 0.17956248755732757, r => 0.17956248755739923 },
	{ solve => 'power', n => 10.0, delta => 0.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 0.04999999999999996, r => 0.05000000000000001 },
	{ solve => 'power', n => 100.0, delta => 0.2, sd => 2.0, sig_level => 0.01, type => 'one.sample', alternative => 'one.sided', want => 0.09013154133363165, r => 0.09013154133367962 },
	{ solve => 'power', n => 1000.0, delta => 0.05, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 0.4741724111210383, r => 0.47417241112127784 },
	{ solve => 'power', n => 12.0, delta => 3.0, sd => 1.5, sig_level => 0.1, type => 'one.sample', alternative => 'one.sided', want => 0.9999999575265126, r => 0.999999957526535 },
	{ solve => 'power', n => 7.0, delta => -0.8, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 0.00018666184264119062, r => 0.00018666184277682518 },
	{ solve => 'power', n => 50.0, delta => 0.4, sd => 0.25, sig_level => 0.001, type => 'one.sample', alternative => 'one.sided', want => 0.9999999999999885, r => 0.9999999999999885 },
	{ solve => 'power', n => 3.0, delta => 0.1, sd => 10.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 0.05132574328299878, r => 0.051325743283133995 },
	{ solve => 'power', n => 20.0, delta => 5.0, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', want => 1.0, r => 1 },
	{ solve => 'power', n => 30.0, delta => 0.5, sd => 1.0, sig_level => 0.05, type => 'one.sample', alternative => 'one.sided', strict => 1, want => 0.8482541909289825, r => 0.848254190929147 },
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

	is_rel($got->{power}, $c->{want}, $EPS_SCIPY, "scipy: $label");
	is_rel($got->{power}, $c->{r}, $EPS_R_POWER, "R: $label");

	# The parameters that were supplied come back unchanged.
	for my $k (qw(n delta sd)) {
		next if $c->{solve} eq $k or not defined $c->{$k};
		my $want = $c->{alternative} eq 'two.sided' && $k eq 'delta'
			? abs($c->{$k}) : $c->{$k};   # a two-sided delta is reported as |delta|
		is_rel($got->{$k}, $want, 1e-15, "$label: '$k' echoed back");
	}
}

# low df: the chi density carries w**(df-1), so for any df that
# is not a whole number some derivative of it is infinite at
# w = 0 and Simpson has nothing to work with. Substituting
# w = z**m moves the measure to z**(m*df - 1) and buys back the
# bounded derivatives; before that these lost up to fourteen
# digits, worst where the critical value is largest.
for my $t (
	# n, type, delta, sd, sig_level, scipy nct.sf, old error
	[2.182, 'one.sample', 0.4088, 0.9733,  0.001, 0.0010254836902950423, '7.4e-4'],
	[2.192, 'one.sample', 0.5065, 17.1792, 0.05,  0.026470310425782448,  '1.8e-5'],
	[2.05,  'one.sample', 0.5,    1.0,     0.05,  0.054244180763855739,  '6.9e-5'],
	[2.5,   'one.sample', 0.5,    1.0,     0.05,  0.065361004112922894,  '2.5e-7'],
	[2.9,   'one.sample', 0.5,    1.0,     0.05,  0.076141938646801341,  '5.5e-10'],
	[2.2,   'one.sample', 0.4,    1.0,     1e-4,  0.00010017015505987954, '6.0e-3'],
) {
	my ($n, $type, $delta, $sd, $sig, $want, $was) = @$t;
	my $p = power_t_test(n => $n, delta => $delta, sd => $sd, sig_level => $sig,
		type => $type, power => undef)->{power};
	is_rel($p, $want, 1e-12,
		sprintf('low df: n = %s, sig_level = %s (was off by %s)', $n, $sig, $was));
}

# df == 1 exactly, where w**(df-1) is w**0 and the old grid was
# accurate too -- kept because it is the boundary of the case
# above. R: 0.090579718650718455
for my $type ('one.sample', 'paired') {
	my $r = power_t_test(n => 2, delta => 1, sd => 1, sig_level => 0.05,
		type => $type, power => undef);
	is_rel($r->{power}, 0.09057971865059411, 1e-11,
		"df == 1 (n => 2, type => '$type') power");
}
# and the strict variant of the same, R: 0.092809155056535086
for my $type ('one.sample', 'paired') {
	my $r = power_t_test(n => 2, delta => 1, sd => 1, sig_level => 0.05,
		type => $type, strict => 1, power => undef);
	is_rel($r->{power}, 0.09280915505633597, 1e-11,
		"df == 1 strict (n => 2, type => '$type') power");
}

# large df: W = sqrt(chi2_df / df) has standard deviation
# 1 / sqrt(2 * df), so its density narrows without bound while a
# fixed grid does not. The u = w/(1+w) grid used below df 1e3
# stepped clean over the peak once df passed ~1e7, and these
# came back badly wrong -- 0.138 for the first one, where delta
# is 0 and the answer can only be sig_level / 2.
for my $n (1e2, 999, 1001, 1e4, 1e6, 1e7, 4e7, 1e8) {
	for my $sig (0.05, 0.001) {
		for my $type ('two.sample', 'one.sample') {
			my $p = power_t_test(n => $n, delta => 0, sd => 1, sig_level => $sig,
				type => $type, power => undef)->{power};
			# delta == 0 makes the noncentrality 0, so the power is exactly the
			# two-sided rejection rate under the null. Held at 1e-6 only because
			# of the critical value, not the CDF: past df ~ 1e7 the limit is
			# qt_tail(), which inverts incbeta() at x = 1 - 5e-8 with a = 4e7,
			# right at the edge of where its continued fraction converges. The
			# observed drift is 1.3e-11 at n = 1e6, 1.0e-8 at 4e7 and 1.5e-7 at
			# 1e8; exact_pnt() itself is exact here (see the note in LikeR.xs).
			is_rel($p, $sig / 2, 1e-6,
				"delta => 0 gives sig_level/2 at n = $n, sig_level = $sig, $type");
		}
	}
}
# and a non-null power either side of the df 1e3 crossover, against scipy
# (nct.sf); R agrees with scipy to ~1e-9 on all four.
for my $t (
	[999,   0.0125, 19.7242, 0.005, 0.0026120212270525044],
	[1001,  0.0125, 19.7242, 0.005, 0.002612135765200879],
	[1e7,   0.0125, 19.7242, 0.005, 0.082272055916594436],
	[4e7,   0.0125, 19.7242, 0.005, 0.51082369631098168],
) {
	my ($n, $delta, $sd, $sig, $want) = @$t;
	is_rel(power_t_test(n => $n, delta => $delta, sd => $sd, sig_level => $sig,
		power => undef)->{power}, $want, 1e-7, "large-df power at n = $n");
}
# solving for a large n: this used to land 9% low, because the power it was
# driving to 0.5969 was itself wrong. scipy brentq: 46396124.05711444
{
	my $r = power_t_test(power => 0.5969, delta => 0.0125, sd => 19.7242,
		sig_level => 0.005, strict => 1, n => undef);
	is_rel($r->{n}, 46396124.05711444, 1e-7, 'solving for an n of 4.6e7');
}

# small power: taken as the upper tail directly rather than as
# 1 - lower, which used to lose most of its digits to
# cancellation when the answer was near 1e-3
{
	# scipy nct.sf, R agrees to 2e-10: two-sample so df = 2(n-1) stays above 2
	my $p = power_t_test(n => 2.5, delta => 0.4088, sd => 0.9733,
		sig_level => 0.001, power => undef)->{power};
	is_rel($p, 0.0011362537815083292, 1e-8, 'a power of ~1e-3 keeps its digits');
}

# 'paired' matches 'one.sample' numerically and differs only in
# the method and note strings
{
	my %base = (delta => 0.5, sd => 1, sig_level => 0.05, power => 0.8, n => undef);
	my $one  = power_t_test(%base, type => 'one.sample');
	my $pair = power_t_test(%base, type => 'paired');
	is($pair->{n}, $one->{n}, "'paired' and 'one.sample' solve to the same n");
	is_rel($one->{n}, 33.36720397881093, $EPS_SCIPY, "one.sample n (scipy)");
	matches_R($one->{n}, 33.367204088022, "one.sample n (R)");
}

# method / note / alternative strings, matching R's htest fields
{
	my %base = (n => 30, delta => 0.5, sd => 1, sig_level => 0.05, power => undef);

	my $two = power_t_test(%base, type => 'two.sample');
	is($two->{method}, 'Two-sample t test power calculation', 'two.sample method');
	is($two->{note}, 'n is number in *each* group', 'two.sample note');

	my $one = power_t_test(%base, type => 'one.sample');
	is($one->{method}, 'One-sample t test power calculation', 'one.sample method');
	ok(!exists $one->{note}, 'one.sample has no note (R gives NULL)');

	my $pair = power_t_test(%base, type => 'paired');
	is($pair->{method}, 'Paired t test power calculation', 'paired method');
	is($pair->{note},
		'n is number of *pairs*, sd is std.dev. of *differences* within pairs',
		'paired note');

	is($two->{alternative}, 'two.sided', 'alternative echoed back');
	is(power_t_test(%base, alternative => 'one.sided')->{alternative},
		'one.sided', 'one.sided echoed back');

	# 'two.sample' is the default type and 'two.sided' the default alternative
	is_rel(power_t_test(n => 30, delta => 0.5, power => undef)->{power},
		$two->{power}, 1e-15, 'type/alternative/sd/sig_level defaults');
}

# 'greater' and 'less' are LikeR extensions; R's power.t.test rejects them.
# 'greater' is R's one.sided (H1: delta > 0); 'less' is H1: delta < 0, so its
# power at delta is one.sided's at -delta.  This used to require 'less' to
# equal one.sided at the same delta, which pinned the bug in place.
{
	my %base = (n => 30, delta => 0.5, sd => 1, sig_level => 0.05, power => undef);
	is_rel(power_t_test(%base, alternative => 'greater')->{power},
		power_t_test(%base, alternative => 'one.sided')->{power},
		1e-15, "alternative => 'greater' is one.sided");
	is_rel(power_t_test(%base, alternative => 'less')->{power},
		power_t_test(%base, delta => -0.5, alternative => 'one.sided')->{power},
		1e-15, "alternative => 'less' is one.sided at -delta");
}

# a two-sided delta is used as |delta|; a one-sided delta is not
{
	my %base = (n => 30, sd => 1, sig_level => 0.05, power => undef);
	is_rel(power_t_test(%base, delta => -0.5)->{power},
		power_t_test(%base, delta => 0.5)->{power}, 1e-15,
		'two.sided: -delta and +delta give the same power');
	is($_->{delta}, 0.5, 'two.sided: delta reported as |delta|')
		for power_t_test(%base, delta => -0.5);

	# one-sided: a delta pointing the wrong way cannot beat sig_level.
	# R: 0.0001860692907471595 for delta = -0.5, n = 30, one.sided.
	my $wrong = power_t_test(%base, delta => -0.5, alternative => 'one.sided');
	is_rel($wrong->{power}, 0.00018606929073156087, 1e-9,
		'one.sided: a negative delta gives power below sig_level');
	is($wrong->{delta}, -0.5, 'one.sided: delta keeps its sign');
}

# tol: a looser tolerance is honoured, a tight one is the default
{
	my %base = (delta => 0.5, sd => 1, sig_level => 0.05, power => 0.8, n => undef);
	my $exact = 63.76576372485063;   # scipy brentq at xtol 1e-13
	is_rel(power_t_test(%base)->{n}, $exact, 1e-9, 'default tol solves n tightly');
	is_rel(power_t_test(%base, tol => 1e-3)->{n}, $exact, 1e-2,
		'tol => 1e-3 still lands near the root');
	# R at its own default tolerance, for the record: 63.765763714273874
}

# argument validation
throws_ok { power_t_test(n => 30, delta => 0.5, sd => 1, sig_level => 0.05, power => 0.8) }
	qr/exactly one of/, 'nothing left undef croaks';
throws_ok { power_t_test(delta => 0.5, n => undef, power => undef) }
	qr/exactly one of/, 'two undefs croak';
# omitting 'power' entirely leaves it the unknown, as in R, where it defaults to
# NULL -- so this is the two-argument call, not a missing-undef error
is_rel(power_t_test(n => 30, delta => 0.5)->{power}, 0.4778409859409133, 1e-9,
	"omitting 'power' solves for it (R's default of NULL)");
# Likewise 'n' and 'delta': the XS tells an absent one (!sv_n, !sv_delta) from
# an undef one. Before this file was split only t/01.t called power_t_test()
# without 'n', and nothing called it without 'delta'. sd and sig_level have
# defaults instead. scipy brentq at xtol 1e-13, the same values as the table's
# rows in t/power_t_test.solve_n.R.scipy.t and
# t/power_t_test.solve_delta.R.scipy.t.
is_rel(power_t_test(power => 0.8, delta => 0.5, sd => 1)->{n}, 63.76576372485063, 1e-9,
	"omitting 'n' solves for it (R's default of NULL)");
is_rel(power_t_test(n => 30, sd => 1, power => 0.8)->{delta}, 0.7356219641260183, 1e-9,
	"omitting 'delta' solves for it (R's default of NULL)");
throws_ok { power_t_test(n => 30, delta => 0.5, power => undef, bogus => 1) }
	qr/unknown argument 'bogus'/, 'unknown argument croaks';
throws_ok { power_t_test(n => 30, delta => 0.5, 'power') }
	qr/\Ausage: power_t_test\(.*^options:\n.*^example:\n.*\n\npower_t_test: error: arguments must be name => value pairs\n\z/ms,
	'an odd argument list croaks with the help screen, and the error last';

# R's assert_NULL_or_prob(). power => 1.5 used to run the n bracket out to
# 1.3e12 and report that as the required sample size.
for my $bad (2, -1, 1.0000001) {
	throws_ok { power_t_test(n => 30, delta => 0.5, sig_level => $bad, power => undef) }
		qr/'sig_level' must be numeric in \[0, 1\]/, "sig_level => $bad croaks";
	throws_ok { power_t_test(delta => 0.5, power => $bad, n => undef) }
		qr/'power' must be numeric in \[0, 1\]/, "power => $bad croaks";
}

# nu = (n - 1) * tsample, so below n = 2 there is no variance to estimate. R
# masks the degeneracy with pmax(1e-07, n - 1) and returns a power of 0; this
# used to return a power of 0.99998.
for my $bad (1.9999, 1, 0, -5) {
	throws_ok { power_t_test(n => $bad, delta => 0.5, power => undef) }
		qr/'n' must be at least 2/, "n => $bad croaks";
}
throws_ok { power_t_test(n => 30, delta => 0.5, sd => -1, power => undef) }
	qr/'sd' must not be negative/, 'a negative sd croaks';

# R reaches type and alternative through match.arg(), so a misspelling is an
# error there. Reading an unrecognised type as 'two.sample' turned every typo
# into a plausible answer for the wrong test.
throws_ok { power_t_test(n => 30, delta => 0.5, power => undef, type => 'two') }
	qr/'type' must be/, 'a partial type croaks (R match.arg would accept it)';
throws_ok { power_t_test(n => 30, delta => 0.5, power => undef, type => 'bogus') }
	qr/'type' must be/, 'an unknown type croaks';
throws_ok { power_t_test(n => 30, delta => 0.5, power => undef, alternative => 'two-sided') }
	qr/'alternative' must be/, 'a misspelt alternative croaks';

# unreachable targets croak instead of returning a bracket
# endpoint dressed up as an answer
# power falls to sig_level/tside as sd grows, so 0.01 is below the floor.
# R: "no sign change found in 1000 iterations". Used to return sd = delta * 1e7.
throws_ok { power_t_test(n => 30, delta => 0.5, sig_level => 0.05, power => 0.01, sd => undef) }
	qr/no 'sd' in \[.*\] gives a power of 0\.01/, 'an unreachable sd croaks';
# a one-sided test pointed the wrong way cannot reach 0.8 at any sd.
# Used to return sd = -2500000.
throws_ok { power_t_test(n => 30, delta => -0.5, power => 0.8, sd => undef,
		alternative => 'one.sided') }
	qr/no 'sd' in \[.*\] gives a power of 0\.8/, 'a wrong-signed one-sided sd croaks';
# the sd bracket scales with |delta|, so delta == 0 collapses it to a point.
# R: "lower < upper is not fulfilled". Used to return sd = 0.
throws_ok { power_t_test(n => 30, delta => 0, power => 0.8, sd => undef) }
	qr/cannot solve for 'sd' when 'delta' is 0/, 'solving for sd with delta == 0 croaks';
# likewise the delta bracket scales with sd. Used to return delta = 0.
throws_ok { power_t_test(n => 30, sd => 0, power => 0.8, delta => undef) }
	qr/cannot solve for 'delta' unless 'sd' is positive/,
	'solving for delta with sd == 0 croaks';
# power => 0.2 is already exceeded at n = 2 when delta is 5. R extends the
# bracket below its own lower end and answers n = 1.406729, which is not a
# sample size. Used to return n = 2.00004 with power => 0.2 attached.
# The upper end of the bracket is formatted by perl's %g, which on an MSVCRT
# perl (Strawberry 5.24) writes 1e7 as 1e+007, so take it from perl too.
my $n_hi = quotemeta sprintf('%g', 1e7);
throws_ok { power_t_test(power => 0.2, delta => 5, sd => 1, n => undef) }
	qr/no 'n' in \[2, $n_hi\] gives a power of 0\.2/, 'an unreachable n croaks';
# a sig_level is a probability, so its bracket cannot be widened. R widens it
# anyway (extendInt = "yes") and returns sig.level = 1.071987. Used to return
# 0.99994 with power => 0.99 attached.
throws_ok { power_t_test(power => 0.99, n => 40, delta => 0.5, sd => 1, sig_level => undef) }
	qr/no 'sig_level' in \(0, 1\) gives a power of 0\.99/,
	'a sig_level above 1 croaks rather than being reported';

# R's dotted sig.level is refused, and the result key is sig_level too
{
	throws_ok { power_t_test(n => 30, delta => 0.5, 'sig.level' => 0.01, power => undef) }
		qr/unknown argument 'sig\.level'/, "the dotted 'sig.level' is refused";
	my $a = power_t_test(n => 30, delta => 0.5, sig_level => 0.01, power => undef);
	is($a->{'sig_level'}, 0.01, "result key is 'sig_level'");
	ok(!exists $a->{'sig.level'}, "no dotted 'sig.level' key");
}

# round trip: every solved parameter reproduces its power
for my $solve (qw(n delta sd sig_level)) {
	for my $type ('two.sample', 'one.sample') {
		for my $alt ('two.sided', 'one.sided') {
			my %base = (n => 30, delta => 0.5, sd => 1, sig_level => 0.05,
				type => $type, alternative => $alt);
			my $want = 0.7;
			my $solved = power_t_test(%base, power => $want, $solve => undef);
			# feed the solved value back in and ask for the power
			my %back = (%base, %{{ map { $_ => $solved->{$_} } qw(n delta sd) }},
				sig_level => $solved->{'sig_level'}, power => undef);
			is_rel(power_t_test(%back)->{power}, $want, 1e-9,
				"round trip: $solve, $type, $alt");
		}
	}
}

# leaks: one solver path per free parameter, plus the croak
# paths, which unwind out of the middle of the XS body
unless ($INC{'Devel/Cover.pm'}) {
	my %base = (n => 30, delta => 0.5, sd => 1, sig_level => 0.05, power => 0.7);
	for my $solve (qw(power n delta sd sig_level)) {
		no_leaks_ok {
			eval { power_t_test(%base, $solve => undef) };
		} "no leaks solving for '$solve'";
	}
	no_leaks_ok {
		eval { power_t_test(power => 0.8, delta => 0.5, sd => 1) };
	} "no leaks solving for an omitted 'n'";
	no_leaks_ok {
		eval { power_t_test(n => 30, sd => 1, power => 0.8) };
	} "no leaks solving for an omitted 'delta'";
	no_leaks_ok {
		eval { power_t_test(%base) };                       # nothing left undef
		eval { power_t_test(n => 1, delta => 0.5) };         # n below 2
		eval { power_t_test(n => 30, delta => 0.5, sig_level => 2) };
		eval { power_t_test(n => 30, delta => 0.5, type => 'bogus') };
		eval { power_t_test(n => 30, delta => 0, power => 0.8, sd => undef) };
		eval { power_t_test(power => 0.2, delta => 5, n => undef) };
	} 'no leaks on the croak paths';
}

# alternative => 'greater' and 'less'.  R's power.t.test() has neither -- its
# alternative is "two.sided" or "one.sided", the latter meaning H1: delta > 0.
# 'greater' is that same test.  'less' is H1: delta < 0, whose power at delta
# is the one-sided power at -delta, so a one-sided row of the table above is
# checked again as 'less' with delta's sign flipped, against the same scipy
# value; where delta is what is solved for, it has to come back negated.  Up
# to 0.3217 'less' was computed as 'greater': n => 20, delta => 1 gave 0.9279.
#
# One row per solved parameter, not every one-sided row. power_t_test() maps
# 'greater' onto one.sided's branch outright, and 'less' only negates delta on
# the way in and back on the way out, which is exact; so a mirrored row repeats
# its one.sided row's computation to the bit, and adds only the sign handling
# and the echoed alternative. Mirroring all of them was 182 calls, 96 of them
# solves, for nothing the table had not already checked.
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

# The case TODO.md recorded, at a power small enough that R's own pnt() is off:
# R 4.6.1 gives 1.0041181467412841e-06 for power.t.test(n = 20, delta = -1,
# alternative = "one.sided"), 3.2e-8 relative from the value below, which is
# mpmath 1.3.0 at mp.dps = 40 integrating P(Z + ncp > t_crit sqrt(V/nu)) over Z
# with the regularised incomplete gamma for V, at t_crit = scipy 1.18.0's
# t.isf(0.05, 38) and ncp = -sqrt(10).  scipy's nct.sf gives
# 1.0041181143634293e-06, 3.7e-11 from it.
is_rel(power_t_test(n => 20, delta => 1, alternative => 'less')->{power},
	1.004118114325838652e-06, 1e-12, "'less' at n = 20, delta = 1: about 1e-6, not 0.9279");

done_testing();
