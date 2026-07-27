#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Floating-point comparison helper (mirrors t/cor.t).
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) { pass("$test_name: within $epsilon"); return 1; }
	fail($test_name);
	diag("         got: $got\n    expected: $expected; diff = $diff");
	return 0;
}

#--------------------------------------------------------------------------
# epi_2x2 — Wald odds ratio / risk ratio / risk difference + 95% CIs.
# Reference values from R (qnorm(0.975)-based Wald formulas), table
#          outcome+  outcome-
#   exp+      30        70
#   exp-      20        80
#--------------------------------------------------------------------------
my $e = epi_2x2(30, 70, 20, 80);
is_approx($e->{odds_ratio},        1.7142857143, 'OR point estimate');
is_approx($e->{odds_ratio_ci}[0],  0.8945793467, 'OR CI lower');
is_approx($e->{odds_ratio_ci}[1],  3.2850920614, 'OR CI upper');
is_approx($e->{risk_ratio},        1.5000000000, 'RR point estimate');
is_approx($e->{risk_ratio_ci}[0],  0.9159608293, 'RR CI lower');
is_approx($e->{risk_ratio_ci}[1],  2.4564369217, 'RR CI upper');
is_approx($e->{risk_diff},         0.1000000000, 'RD point estimate');
is_approx($e->{risk_diff_ci}[0],  -0.0192199549, 'RD CI lower');
is_approx($e->{risk_diff_ci}[1],   0.2192199549, 'RD CI upper');
is_approx($e->{nnt},              10.0000000000, 'number needed to treat');
is($e->{correction}, 0, 'no Haldane correction on a full table');

# Nested [[a,b],[c,d]] form must agree with the flat form.
my $e2 = epi_2x2([[30,70],[20,80]]);
is_approx($e2->{odds_ratio}, $e->{odds_ratio}, 'nested 2x2 form matches flat form');

# Zero cell forces the Haldane-Anscombe +0.5 correction (no div-by-zero).
my $z = epi_2x2(0, 10, 5, 10);
is($z->{correction}, 1, 'zero cell triggers +0.5 correction');
ok($z->{odds_ratio} > 0 && $z->{odds_ratio} < 'inf'+0, 'corrected OR is finite');

#--------------------------------------------------------------------------
# cmh_test — Cochran-Mantel-Haenszel across 3 strata (2x2x3).
# Reference from R: mantelhaen.test(array(c(10,5,3,12, 20,8,6,15, 7,9,4,11),
#                                          dim=c(2,2,3)), correct=TRUE)
# R's column-major fill => stratum k as [a,b,c,d] = [10,3,5,12] etc.
#--------------------------------------------------------------------------
my $m = cmh_test([[10,3,5,12],[20,6,8,15],[7,4,9,11]]);
is_approx($m->{statistic},   13.1996978868, 'CMH chi-squared statistic');
is_approx($m->{p_value},      0.0002799942, 'CMH p-value');
is_approx($m->{estimate},     4.7735261124, 'MH common odds ratio');
is_approx($m->{conf_int}[0],  2.0969889497, 'MH OR CI lower');
is_approx($m->{conf_int}[1], 10.8663193239, 'MH OR CI upper', 1e-6);
is($m->{parameter}, 1, 'CMH has 1 degree of freedom');
is($m->{k}, 3, 'reports the number of strata');

#--------------------------------------------------------------------------
# error paths
#--------------------------------------------------------------------------
dies_ok { epi_2x2(30, 70, 20) }              'epi_2x2: too few counts dies';
dies_ok { epi_2x2(-1, 70, 20, 80) }          'epi_2x2: negative count dies';
dies_ok { epi_2x2(30, 70, 20, 80, bogus=>1) }'epi_2x2: unknown option dies';
dies_ok { epi_2x2(30, 70, 20, 80, conf_level=>1.5) } 'epi_2x2: bad conf_level dies';
dies_ok { cmh_test([[1,2,3]]) }              'cmh_test: malformed stratum dies';
dies_ok { cmh_test("nope") }                 'cmh_test: non-arrayref dies';

#--------------------------------------------------------------------------
# leak checks
#--------------------------------------------------------------------------
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { eval { epi_2x2(30, 70, 20, 80) } }             'epi_2x2: no leaks';
	no_leaks_ok { eval { cmh_test([[10,3,5,12],[20,6,8,15]]) } } 'cmh_test: no leaks';
}

done_testing();
