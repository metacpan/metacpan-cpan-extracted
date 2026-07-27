#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub is_approx {
	my ($got, $expected, $name, $eps) = @_;
	$eps = 1e-6 if not defined $eps;
	if (abs($got - $expected) <= $eps) { pass("$name: within $eps"); return 1; }
	fail($name); diag("  got: $got\n  expected: $expected");
	return 0;
}

# --- vif ------------------------------------------------------------------
# Reference: 1/(1 - R^2) from regressing each predictor on the others in R.
{
	my %d = (
		x1 => [1,2,3,4,5,6,7,8,9,10],
		x2 => [1.2,1.9,3.1,4.2,4.8,6.3,6.9,8.1,9.2,9.8],
		x3 => [5,3,6,2,7,1,8,4,9,2],
	);
	my $v = vif(\%d, [qw(x1 x2 x3)]);
	is_approx($v->{x1}, 281.73713604, 'VIF x1', 1e-3);
	is_approx($v->{x2}, 281.17926952, 'VIF x2', 1e-3);
	is_approx($v->{x3},   1.03529944, 'VIF x3', 1e-5);

	# formula form gives the same result
	my $v2 = vif(\%d, 'y ~ x1 + x2 + x3');
	is_approx($v2->{x1}, $v->{x1}, 'VIF formula form matches list form', 1e-9);
}

# --- hosmer_lemeshow ------------------------------------------------------
# Reference: ResourceSelection::hoslem.test algorithm replicated in base R.
{
	my @y  = (0,0,1,0,1,0,1,1,0,1, 0,1,1,0,1,1,0,1,1,1);
	my @pr = (0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5,0.55,
	          0.6,0.62,0.65,0.68,0.7,0.75,0.8,0.85,0.9,0.95);
	my $h = hosmer_lemeshow(\@y, \@pr, g => 5);
	is_approx($h->{statistic}, 3.25860820, 'HL statistic (g=5)', 1e-6);
	is($h->{parameter}, 3, 'HL df = g-2');
	is_approx($h->{p_value}, 0.35344529, 'HL p-value', 1e-6);
	is($h->{groups}, 5, 'HL used 5 groups');
	is(scalar(@{$h->{table}}), 5, 'HL returns per-group table');
}

# --- error handling -------------------------------------------------------
throws_ok { vif(\%{{x1=>[1,2]}}, ['x1']) } qr/at least two predictors/, 'vif needs >=2 predictors';
throws_ok { hosmer_lemeshow([1,0,1],[0.5,0.5,0.5], g => 2) } qr/at least 3/, 'HL needs g>=3';
throws_ok { hosmer_lemeshow([1,0],[0.5,0.5,0.5]) } qr/same length/, 'HL length mismatch';

no_leaks_ok {
	my %d = (x1 => [1,2,3,4,5,6], x2 => [1.1,2.2,2.9,4.1,5.0,6.2], x3 => [2,5,1,4,3,6]);
	vif(\%d, [qw(x1 x2 x3)]);
	hosmer_lemeshow([0,0,1,0,1,0,1,1,0,1,1,1],
	                [0.1,0.2,0.3,0.4,0.5,0.55,0.6,0.7,0.75,0.8,0.9,0.95], g => 4);
} 'vif / hosmer_lemeshow do not leak';

done_testing();
