#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub is_approx {
	my ($got, $expected, $name, $eps) = @_;
	$eps = 1e-7 if not defined $eps;
	if (abs($got - $expected) <= $eps) { pass("$name: within $eps"); return 1; }
	fail($name); diag("  got: $got\n  expected: $expected");
	return 0;
}

# All reference values from R's stats::prop.test.

# --- 1 sample, default (H0: p = 0.5, Yates) -------------------------------
{
	my $r = prop_test(83, 100);
	is_approx($r->{statistic}, 42.25,        '1-sample statistic');
	is($r->{parameter}, 1,                   '1-sample df');
	is_approx($r->{estimate}[0], 0.83,       '1-sample estimate');
	is_approx($r->{'conf.int'}[0], 0.738913, '1-sample CI lower', 1e-6);
	is_approx($r->{'conf.int'}[1], 0.895067, '1-sample CI upper', 1e-6);
}

# --- 1 sample vs given p --------------------------------------------------
{
	my $r = prop_test(83, 100, p => 0.7);
	is_approx($r->{statistic}, 7.44047619, '1-sample given-p statistic');
	is_approx($r->{p_value},   0.00637730, '1-sample given-p p-value', 1e-7);
}

# --- 1 sample, one-sided 'less' -------------------------------------------
{
	my $r = prop_test(83, 100, alternative => 'less');
	is_approx($r->{p_value},       1.0,      '1-sample less p-value');
	is_approx($r->{'conf.int'}[0], 0.0,      '1-sample less CI lower');
	is_approx($r->{'conf.int'}[1], 0.887062, '1-sample less CI upper', 1e-6);
}

# --- 1 sample, no continuity correction -----------------------------------
{
	my $r = prop_test(83, 100, correct => 0);
	is_approx($r->{statistic},     43.56,    '1-sample no-correction statistic');
	is_approx($r->{'conf.int'}[0], 0.744520, '1-sample no-correction CI lower', 1e-6);
	like($r->{method}, qr/without continuity correction/, 'no-correction method label');
}

# --- 2 samples ------------------------------------------------------------
{
	my $r = prop_test([83, 90], [100, 100]);
	is_approx($r->{statistic}, 1.54142582, '2-sample statistic', 1e-7);
	is($r->{parameter}, 1,                 '2-sample df');
	is_approx($r->{p_value},   0.21440570, '2-sample p-value', 1e-7);
	is_approx($r->{'conf.int'}[0], -0.174221, '2-sample CI lower', 1e-6);
	is_approx($r->{'conf.int'}[1],  0.034221, '2-sample CI upper', 1e-6);
}

# --- 2 samples, one-sided 'greater' ---------------------------------------
{
	my $r = prop_test([90, 83], [100, 100], alternative => 'greater');
	is_approx($r->{p_value}, 0.10720285, '2-sample greater p-value', 1e-7);
}

# --- 3 samples (chi-square, df=2, no CI) ----------------------------------
{
	my $r = prop_test([83, 90, 75], [100, 100, 100]);
	is_approx($r->{statistic}, 7.86290323, '3-sample statistic', 1e-7);
	is($r->{parameter}, 2,                 '3-sample df');
	is_approx($r->{p_value}, 0.01961518,   '3-sample p-value', 1e-7);
	ok(!exists $r->{'conf.int'},           '3-sample has no conf.int');
}

# --- error handling -------------------------------------------------------
throws_ok { prop_test(120, 100) } qr/must not exceed/, 'x > n rejected';
throws_ok { prop_test([1,2], [10]) } qr/same length/,  'length mismatch rejected';
throws_ok { prop_test(5, 100, alternative => 'sideways') } qr/alternative/, 'bad alternative rejected';

no_leaks_ok {
	prop_test(83, 100);
	prop_test([83, 90], [100, 100]);
	prop_test([83, 90, 75], [100, 100, 100], correct => 0);
} 'prop_test does not leak';

done_testing();
