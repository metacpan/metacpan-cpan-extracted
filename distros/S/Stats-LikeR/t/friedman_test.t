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

# Reference values from R's stats::friedman.test.

# --- no ties --------------------------------------------------------------
{
	my $r = friedman_test([[1,2,3],[2,3,1],[1,3,2],[3,2,1],[1,2,3],[2,1,3]]);
	is_approx($r->{statistic}, 1.0,          'no-ties statistic');
	is($r->{parameter}, 2,                   'no-ties df');
	is_approx($r->{p_value}, 0.60653066,     'no-ties p-value', 1e-7);
	is($r->{n}, 6,                           'no-ties block count');
}

# --- with ties (tie correction) ------------------------------------------
{
	my $r = friedman_test([[7,9,8],[6,6,7],[9,10,9],[8,8,6],[7,9,10],[5,7,6],[8,8,8]]);
	is_approx($r->{statistic}, 4.09523810,   'tied statistic', 1e-7);
	is_approx($r->{p_value},   0.12904178,   'tied p-value', 1e-7);
}

# --- four treatments (df = 3) --------------------------------------------
{
	my $r = friedman_test([[1,2,3,4],[2,3,4,1],[1,2,4,3],[4,3,2,1],[1,3,2,4]]);
	is_approx($r->{statistic}, 2.28,         'k=4 statistic', 1e-7);
	is($r->{parameter}, 3,                   'k=4 df');
	is_approx($r->{p_value}, 0.51636320,     'k=4 p-value', 1e-7);
}

# --- incomplete blocks are dropped (like R's complete.cases) --------------
{
	my $r = friedman_test([[1,2,3],[2,3,1],[1,3,2],[3,2,1],[1,2,3],[2,1,3],[undef,1,2]]);
	is($r->{n}, 6, 'incomplete block dropped');
	is_approx($r->{statistic}, 1.0, 'statistic unaffected by dropped block');
}

# --- error handling -------------------------------------------------------
throws_ok { friedman_test([[1,2,3]]) }        qr/at least two blocks/, 'needs >= 2 blocks';
throws_ok { friedman_test([[1],[2]]) }        qr/at least two treatments/, 'needs >= 2 treatments';
throws_ok { friedman_test([[1,2,3],[1,2]]) }  qr/same number of columns/, 'ragged rows rejected';
throws_ok { friedman_test(42) }               qr/Usage/, 'non-matrix rejected';

no_leaks_ok {
	friedman_test([[1,2,3],[2,3,1],[1,3,2],[3,2,1]]);
	friedman_test([[7,9,8],[6,6,7],[9,10,9],[8,8,6],[8,8,8]]);
} 'friedman_test does not leak';

done_testing();
