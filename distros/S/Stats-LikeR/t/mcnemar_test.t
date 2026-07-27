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

# Reference values from R's stats::mcnemar.test and binom.test.

# --- 2x2 with continuity correction (default) -----------------------------
{
	my $r = mcnemar_test([[794, 86], [150, 570]]);
	is_approx($r->{statistic}, 16.81779661, '2x2 cc statistic', 1e-7);
	is($r->{parameter}, 1, '2x2 df');
	is_approx($r->{p_value}, 4.115e-05, '2x2 cc p-value', 1e-8);
	like($r->{method}, qr/continuity correction/, '2x2 cc method label');
}

# --- 2x2 without continuity correction ------------------------------------
{
	my $r = mcnemar_test([[794, 86], [150, 570]], correct => 0);
	is_approx($r->{statistic}, 17.35593220, '2x2 no-cc statistic', 1e-7);
	unlike($r->{method}, qr/continuity/, 'no-cc method label');
}

# --- 3x3 (no continuity correction, df = 3) -------------------------------
{
	my $r = mcnemar_test([[20, 10, 5], [3, 30, 7], [8, 4, 25]]);
	is_approx($r->{statistic}, 5.27972028, '3x3 statistic', 1e-7);
	is($r->{parameter}, 3, '3x3 df');
	is_approx($r->{p_value}, 0.15242374, '3x3 p-value', 1e-7);
}

# --- exact binomial (2x2 only) --------------------------------------------
{
	my $r = mcnemar_test([[794, 86], [150, 570]], exact => 1);
	is_approx($r->{p_value}, 3.716e-05, 'exact p-value', 1e-8);
	like($r->{method}, qr/exact/, 'exact method label');
	ok(!exists $r->{parameter}, 'exact has no df');
}

# --- paired-vector input builds the same table ----------------------------
{
	my @x = ((('neg') x 25), (('pos') x 25));
	my @y = ((('pos') x 18), (('neg') x 7), (('pos') x 4), (('neg') x 21));
	my $r = mcnemar_test(\@x, \@y);
	is_approx($r->{statistic}, 0.10256410, 'vector-form statistic', 1e-7);
	is_approx($r->{p_value},   0.74877404, 'vector-form p-value', 1e-7);
}

# --- error handling -------------------------------------------------------
throws_ok { mcnemar_test([[1,2,3],[4,5,6]]) } qr/square/, 'non-square rejected';
throws_ok { mcnemar_test([[1,2],[3,4],[5,6]]) } qr/square/, 'non-square rejected (rows)';
throws_ok { mcnemar_test([[1,2,0],[3,4,0],[0,0,1]], exact => 1) } qr/2x2/, 'exact requires 2x2';

no_leaks_ok {
	mcnemar_test([[794, 86], [150, 570]]);
	mcnemar_test([[794, 86], [150, 570]], exact => 1);
	mcnemar_test([qw(a a b b a)], [qw(a b b a a)]);
} 'mcnemar_test does not leak';

done_testing();
