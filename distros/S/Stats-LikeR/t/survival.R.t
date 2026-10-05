#!/usr/bin/env perl
# logrank_test() and survfit() against R 4.6.1 with survival 3.8-12.
#
# Provenance.  Every expected value is R 4.6.1 survdiff() or survfit() at
# options(digits = 17), from t/survival.R.R, which is committed next to this
# file; re-run it with
#     Rscript t/survival.R.R
# and paste its two blocks over %LR and %KM.  This test never invokes R.  The
# data sets are:
#   aml, aml3      survival 3.8-12 tests/difftest.R: aml, then aml with a
#                  "Dummy" group of seven censorings before the first event.
#                  The upstream comment: "These should give the same result
#                  (chisq, df), but the second has an extra group."
#   test1          survival 3.8-12 tests/quantile.R, less its status = NA row,
#                  which survfit()'s na.omit drops and survfit() here refuses
#                  (see t/croak.leaks.t).
#   early_censor, flat62, flat108, flat148
#                  random data from the fuzz that found the two bugs below;
#                  the numbers are the fuzz seeds.
#   dead_middle, one_live, flat_end, flat_censored
#                  written here to reach a branch the others do not.
#
# What it pins.
#
# 1. logrank_test() with a group that has no expected events.  A group that is
#    never at risk at an event time has E = 0 and a zero row and column in the
#    variance matrix.  Through 0.3212 every group was kept and the last one
#    dropped, so the reduced matrix was singular, the solve failed, and the
#    statistic was left at 0: aml3 gave chisq 0 on 2 df, p = 1, where
#    survdiff() gives 3.396 on 1 df, p = 0.065 -- the aml answer, as
#    difftest.R says it must be.  Such groups are now left out of the test, as
#    survdiff() does.
#
# 2. survfit()'s median when S(t) is exactly 0.5.  survival:::survmean() takes
#    the midpoint of that time and the time of the next drop; through 0.3212
#    the median was the left end of the flat stretch (flat62: 5, not 5.5).
#
# Departures from R, deliberate and recorded so that changing one is too:
#   * With no events at all survdiff() reports df = -1 and a NaN p-value with a
#     warning.  logrank_test() reports df = 0 and the NaN.
#   * std_err is the standard error of S, R's std.err * surv, as in
#     t/survival.t.
#
# Tolerance.  1e-12 relative (absolute below 1) on every real-valued field;
# the counts and the df are compared exactly.  Worst observed, on 2026-10-01
# with AUTHOR_TESTING=1, which reports it: 1.05e-15 on the double build and
# 8.66e-16 on long double and quadmath, where what is left is R's own double
# rounding.  That is about 1000x headroom.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use lib 'blib/lib', 'blib/arch';
use Stats::LikeR qw(logrank_test survfit);

my $TOL = 1e-12;   # relative; justified in the header

my $worst = 0;	#largest relative error seen, reported by diag() for the header
sub near {
	my ($got, $want, $name) = @_;
	if (!defined $want) { return ok(!defined $got, "$name is undef, as R gives NA") }
	if (!defined $got) { return fail("$name: got undef, want $want") }
	my $err = abs($got - $want) / (abs($want) > 1 ? abs($want) : 1);
	$worst = $err if $err > $worst;
	ok($err <= $TOL, $name) or diag("got $got, want $want, relative error $err");
}

my %LR = (
	aml => {
		time => [9, 13, 13, 18, 23, 28, 31, 34, 45, 48, 161, 5, 5, 8, 8, 12, 16, 23, 27, 30, 33, 43, 45],
		status => [1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1],
		group => ['Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained'],
		statistic => 3.3963886989776011, parameter => 1, p => 0.065339322040505132,
		levels => ['Maintained', 'Nonmaintained'],
		observed => [7, 11],
		expected => [10.689335992300725, 7.3106640076992759],
	},
	aml3 => {
		time => [9, 13, 13, 18, 23, 28, 31, 34, 45, 48, 161, 5, 5, 8, 8, 12, 16, 23, 27, 30, 33, 43, 45, 1, 2, 2, 3, 3, 3, 4],
		status => [1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
		group => ['Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Dummy', 'Dummy', 'Dummy', 'Dummy', 'Dummy', 'Dummy', 'Dummy'],
		statistic => 3.3963886989776011, parameter => 1, p => 0.065339322040505132,
		levels => ['Dummy', 'Maintained', 'Nonmaintained'],
		observed => [0, 7, 11],
		expected => [0, 10.689335992300725, 7.3106640076992759],
	},
	early_censor => {
		time => [1, 5, 4, 3, 6, 3, 5, 4],
		status => [0, 1, 1, 1, 1, 0, 0, 0],
		group => ['a', 'c', 'c', 'c', 'b', 'b', 'b', 'b'],
		statistic => 4.7779630579784502, parameter => 1, p => 0.028826199036310743,
		levels => ['a', 'b', 'c'],
		observed => [0, 1, 3],
		expected => [0, 2.8380952380952378, 1.161904761904762],
	},
	dead_middle => {
		time => [2, 3, 5, 1, 1, 4, 6, 7, 8],
		status => [1, 0, 1, 0, 0, 1, 1, 0, 1],
		group => ['a', 'a', 'a', 'b', 'b', 'c', 'c', 'c', 'c'],
		statistic => 2.1229006976143294, parameter => 1, p => 0.14511148308549168,
		levels => ['a', 'b', 'c'],
		observed => [2, 0, 3],
		expected => [0.87857142857142856, 0, 4.121428571428571],
	},
	one_live => {
		time => [1, 2, 5, 6],
		status => [0, 0, 1, 1],
		group => ['a', 'a', 'b', 'b'],
		statistic => 0, parameter => 0, p => 1,
		levels => ['a', 'b'],
		observed => [0, 2],
		expected => [0, 2],
	},
);

my %KM = (
	test1 => {
		time => [9, 1, 1, 6, 6, 8, 10],
		status => [1, 1, 0, 1, 1, 0, 0],
		group => ['0', '1', '1', '1', '0', '0', '0'],
		strata => {
			'0' => {
				time => [6, 8, 9, 10],
				'n_risk' => [4, 3, 2, 1],
				'n_event' => [1, 0, 1, 0],
				'n_censor' => [0, 1, 0, 1],
				surv => [0.75, 0.75, 0.375, 0.375],
				'std_err' => [0.21650635094610965, 0.21650635094610965, 0.28641098093474004, 0.28641098093474004],
				lower => [0.42593226849798205, 0.42593226849798205, 0.083929638104579832, 0.083929638104579832],
				upper => [1, 1, 1, 1],
				median => 9,
			},
			'1' => {
				time => [1, 6],
				'n_risk' => [3, 1],
				'n_event' => [1, 1],
				'n_censor' => [1, 0],
				surv => [0.66666666666666663, 0],
				'std_err' => [0.27216552697590868, undef],
				lower => [0.29950713035902232, undef],
				upper => [1, undef],
				median => 6,
			},
		},
	},
	aml => {
		time => [9, 13, 13, 18, 23, 28, 31, 34, 45, 48, 161, 5, 5, 8, 8, 12, 16, 23, 27, 30, 33, 43, 45],
		status => [1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1],
		group => ['Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Maintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained', 'Nonmaintained'],
		strata => {
			'Maintained' => {
				time => [9, 13, 18, 23, 28, 31, 34, 45, 48, 161],
				'n_risk' => [11, 10, 8, 7, 6, 5, 4, 3, 2, 1],
				'n_event' => [1, 1, 1, 1, 0, 1, 1, 0, 1, 0],
				'n_censor' => [0, 1, 0, 0, 1, 0, 0, 1, 0, 1],
				surv => [0.90909090909090906, 0.81818181818181812, 0.71590909090909083, 0.61363636363636354, 0.61363636363636354, 0.49090909090909085, 0.36818181818181817, 0.36818181818181817, 0.18409090909090908, 0.18409090909090908],
				'std_err' => [0.08667841720414475, 0.11629129983033294, 0.13966497055722782, 0.152632331027312, 0.152632331027312, 0.16419326722113581, 0.16266888582709479, 0.16266888582709479, 0.15349274578629368, 0.15349274578629368],
				lower => [0.75413384508152548, 0.61924898739936352, 0.48842628742212846, 0.37686705950167976, 0.37686705950167976, 0.25485995119931731, 0.15487711789719105, 0.15487711789719105, 0.035917898489185258, 0.035917898489185258],
				upper => [1, 1, 1, 0.99915760022847266, 0.99915760022847266, 0.94558495520042918, 0.87526067814390762, 0.87526067814390762, 0.94352576947455202, 0.94352576947455202],
				median => 31,
			},
			'Nonmaintained' => {
				time => [5, 8, 12, 16, 23, 27, 30, 33, 43, 45],
				'n_risk' => [12, 10, 8, 7, 6, 5, 4, 3, 2, 1],
				'n_event' => [2, 2, 1, 0, 1, 1, 1, 1, 1, 1],
				'n_censor' => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
				surv => [0.83333333333333337, 0.66666666666666674, 0.58333333333333337, 0.58333333333333337, 0.48611111111111116, 0.38888888888888895, 0.29166666666666674, 0.19444444444444448, 0.097222222222222238, 0],
				'std_err' => [0.1075828707279838, 0.13608276348795437, 0.14231876063832777, 0.14231876063832777, 0.14813006255348293, 0.14698618394803281, 0.13871516913498738, 0.12187450538044615, 0.091866364967520514, undef],
				lower => [0.64703698701336165, 0.44684608115026392, 0.36161370521038472, 0.36161370521038472, 0.26751824885826658, 0.18539652609555676, 0.1148311501524704, 0.056921552571604174, 0.015256527170865199, undef],
				upper => [1, 0.99462536025909154, 0.9409980121738093, 0.9409980121738093, 0.88331922533955765, 0.81573571569127235, 0.74082201851580376, 0.66422365988256338, 0.61954862911905562, undef],
				median => 23,
			},
		},
	},
	flat62 => {
		time => [3, 6, 6, 4, 1, 5, 4, 1, 4, 4, 4],
		status => [0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1],
		group => ['all', 'all', 'all', 'all', 'all', 'all', 'all', 'all', 'all', 'all', 'all'],
		strata => {
			'all' => {
				time => [1, 3, 4, 5, 6],
				'n_risk' => [11, 9, 8, 3, 2],
				'n_event' => [0, 0, 2, 1, 2],
				'n_censor' => [2, 1, 3, 0, 0],
				surv => [1, 1, 0.75, 0.5, 0],
				'std_err' => [0, 0, 0.15309310892394862, 0.2282177322938192, undef],
				lower => [1, 1, 0.50270184129404694, 0.20438613565726943, undef],
				upper => [1, 1, 1, 1, undef],
				median => 5.5,
			},
		},
	},
	flat108 => {
		time => [6, 2, 4, 2, 1, 5, 2, 3, 1, 6, 1, 2],
		status => [0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0],
		group => ['all', 'all', 'all', 'all', 'all', 'all', 'all', 'all', 'all', 'all', 'all', 'all'],
		strata => {
			'all' => {
				time => [1, 2, 3, 4, 5, 6],
				'n_risk' => [12, 9, 5, 4, 3, 2],
				'n_event' => [3, 3, 1, 1, 0, 1],
				'n_censor' => [0, 1, 0, 0, 1, 1],
				surv => [0.75, 0.5, 0.40000000000000002, 0.30000000000000004, 0.30000000000000004, 0.15000000000000002],
				'std_err' => [0.125, 0.14433756729740643, 0.14605934866804429, 0.13964240043768944, 0.13964240043768944, 0.12698425099200297],
				lower => [0.54099635561655635, 0.28395484566532136, 0.19554428775888424, 0.12047820791701994, 0.12047820791701994, 0.028542805383752565],
				upper => [1, 0.88042167202407362, 0.81822896405589662, 0.74702306380576344, 0.74702306380576344, 0.78828971775870671],
				median => 2.5,
			},
		},
	},
	flat148 => {
		time => [1, 5, 3, 3, 2, 2, 4, 5],
		status => [1, 0, 0, 0, 0, 1, 1, 1],
		group => ['all', 'all', 'all', 'all', 'all', 'all', 'all', 'all'],
		strata => {
			'all' => {
				time => [1, 2, 3, 4, 5],
				'n_risk' => [8, 7, 5, 3, 2],
				'n_event' => [1, 1, 0, 1, 1],
				'n_censor' => [0, 1, 2, 0, 1],
				surv => [0.875, 0.75, 0.75, 0.5, 0.25],
				'std_err' => [0.11692679333668568, 0.15309310892394862, 0.15309310892394862, 0.2282177322938192, 0.21040635288254328],
				lower => [0.67338193650595535, 0.50270184129404694, 0.50270184129404694, 0.20438613565726943, 0.048033823681815815],
				upper => [1, 1, 1, 1, 1],
				median => 4.5,
			},
		},
	},
	flat_end => {
		time => [1, 2, 3, 4],
		status => [1, 1, 0, 0],
		group => ['all', 'all', 'all', 'all'],
		strata => {
			'all' => {
				time => [1, 2, 3, 4],
				'n_risk' => [4, 3, 2, 1],
				'n_event' => [1, 1, 0, 0],
				'n_censor' => [0, 0, 1, 1],
				surv => [0.75, 0.5, 0.5, 0.5],
				'std_err' => [0.21650635094610965, 0.25, 0.25, 0.25],
				lower => [0.42593226849798205, 0.18765892870658832, 0.18765892870658832, 0.18765892870658832],
				upper => [1, 1, 1, 1],
				median => 2,
			},
		},
	},
	flat_censored => {
		time => [1, 1, 2, 2, 2, 3, 4, 5],
		status => [1, 1, 0, 0, 0, 1, 0, 1],
		group => ['all', 'all', 'all', 'all', 'all', 'all', 'all', 'all'],
		strata => {
			'all' => {
				time => [1, 2, 3, 4, 5],
				'n_risk' => [8, 6, 3, 2, 1],
				'n_event' => [2, 0, 1, 0, 1],
				'n_censor' => [0, 3, 0, 1, 0],
				surv => [0.75, 0.75, 0.5, 0.5, 0],
				'std_err' => [0.15309310892394862, 0.15309310892394862, 0.2282177322938192, 0.2282177322938192, undef],
				lower => [0.50270184129404694, 0.50270184129404694, 0.20438613565726943, 0.20438613565726943, undef],
				upper => [1, 1, 1, 1, undef],
				median => 4,
			},
		},
	},
);

# ---- logrank_test() ----
for my $name (sort keys %LR) {
	my $c = $LR{$name};
	my $r = logrank_test($c->{time}, $c->{status}, $c->{group});
	near($r->{statistic}, $c->{statistic}, "$name: statistic");
	is($r->{parameter}, $c->{parameter}, "$name: parameter");
	near($r->{'p_value'}, $c->{p}, "$name: p_value");
	# R orders the groups by sorted level, logrank_test() by first appearance
	my %idx; @idx{ @{ $r->{groups} } } = 0 .. $#{ $r->{groups} };
	is_deeply([sort @{ $r->{groups} }], $c->{levels}, "$name: the same groups");
	for my $i (0 .. $#{ $c->{levels} }) {
		my $lev = $c->{levels}[$i];
		near($r->{observed}[$idx{$lev}], $c->{observed}[$i], "$name: observed for $lev");
		near($r->{expected}[$idx{$lev}], $c->{expected}[$i], "$name: expected for $lev");
	}
}

# difftest.R's own assertion: the dummy group changes nothing
{
	my ($a, $b) = map { logrank_test(@{ $LR{$_} }{qw(time status group)}) } qw(aml aml3);
	near($b->{statistic}, $a->{statistic}, 'aml3 and aml: same statistic');
	is($b->{parameter}, $a->{parameter}, 'aml3 and aml: same df');
}

# the dead group's position in the label order does not matter
for my $perm ([qw(a b c)], [qw(b a c)], [qw(c b a)]) {
	my $c = $LR{early_censor};
	my %map; @map{qw(a b c)} = @$perm;
	my $r = logrank_test($c->{time}, $c->{status}, [ map { $map{$_} } @{ $c->{group} } ]);
	near($r->{statistic}, $c->{statistic}, "early_censor relabelled @$perm: statistic");
	is($r->{parameter}, 1, "early_censor relabelled @$perm: parameter");
}

# no events at all: survdiff() gives df = -1 and NaN; this gives df = 0 and NaN
{
	my $r = logrank_test([1, 2, 3, 4], [0, 0, 0, 0], [qw(a a b b)]);
	is($r->{statistic}, 0, 'no events: statistic 0');
	is($r->{parameter}, 0, 'no events: parameter 0');
	ok($r->{'p_value'} != $r->{'p_value'}, 'no events: p_value is NaN, as survdiff() gives');
}

# every event time empties the risk set, so V is zero: survdiff() stops with
# "system is exactly singular", and so does this, rather than reporting p = 1
{
	my @args = ([5, 5, 5, 5], [1, 1, 1, 1], [qw(a a b b)]);
	my $lived = eval { logrank_test(@args); 1 };
	ok(!$lived, 'singular variance: croaks');
	like($@, qr/logrank_test: the variance matrix is singular/, 'singular variance: says why');
	no_leaks_ok { eval { logrank_test(@args) } } 'singular variance: no SV leak on the croak path';
}

# ---- survfit() ----
for my $name (sort keys %KM) {
	my $c = $KM{$name};
	my $f = survfit($c->{time}, $c->{status}, group => $c->{group});
	is_deeply([sort keys %{ $f->{strata} }], [sort keys %{ $c->{strata} }], "$name: the same strata");
	for my $g (sort keys %{ $c->{strata} }) {
		my ($got, $want) = ($f->{strata}{$g}, $c->{strata}{$g});
		for my $k (qw(time n_risk n_event n_censor)) {
			is_deeply($got->{$k}, $want->{$k}, "$name [$g]: $k");
		}
		for my $k (qw(surv std_err lower upper)) {
			is(scalar @{ $got->{$k} }, scalar @{ $want->{$k} }, "$name [$g]: $k length");
			near($got->{$k}[$_], $want->{$k}[$_], "$name [$g]: $k\[$_]") for 0 .. $#{ $want->{$k} };
		}
		near($got->{median}, $want->{median}, "$name [$g]: median");
	}
}

# the one-curve call, with no group, keys its stratum '' and takes the same rule
{
	my $c = $KM{flat62};
	my $f = survfit($c->{time}, $c->{status});
	near($f->{strata}{''}{median}, $c->{strata}{all}{median}, 'flat62 with no group: median');
}

diag(sprintf 'worst relative error %.3g', $worst) if $ENV{AUTHOR_TESTING};
done_testing();
