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

# All reference values computed in base R.

# --- cohen_d (pooled SD, Hedges g, normal-approx CI) ----------------------
{
	my @x = (5,6,7,8,9,7,8);
	my @y = (3,4,5,6,4,5,3);
	my $d = cohen_d(\@x, \@y);
	is_approx($d->{estimate},   2.31455025, 'cohen d');
	is_approx($d->{pooled_sd},  1.23442680, 'cohen pooled sd');
	is_approx($d->{hedges_g},   2.16681300, 'hedges g');
	is_approx($d->{se},         0.69068141, 'cohen d se');
	is_approx($d->{'conf.int'}[0], 0.96083955, 'cohen d CI lower');
	is_approx($d->{'conf.int'}[1], 3.66826095, 'cohen d CI upper');
	is($d->{n1}, 7, 'n1'); is($d->{n2}, 7, 'n2');
}

# --- smd differs from cohen_d when n1 != n2 -------------------------------
{
	my @x = (5,6,7,8,9,7,8,9,10);
	my @y = (3,4,5,6,4);
	is_approx(cohen_d(\@x, \@y)->{estimate}, 2.25421416, 'cohen d (unequal n)');
	is_approx(smd(\@x, \@y),                 2.36988908, 'smd (unequal n)');
}

# --- cramers_v: table form ------------------------------------------------
{
	my $v = cramers_v([[10,20,30],[15,25,10]]);
	is_approx($v->{chisq},          10.73518519, 'cramers chi-square');
	is_approx($v->{estimate},        0.31239813, 'cramers V');
	is_approx($v->{bias_corrected},  0.28280330, 'cramers V bias-corrected');
	is($v->{df}, 2, 'cramers df');
	is($v->{n}, 110, 'cramers N');
}

# --- cramers_v: two-vector form -------------------------------------------
{
	my @a = (qw(L L H H H L M M H L M H));
	my @b = (qw(y n y y n n y n y y n n));
	my $v = cramers_v(\@a, \@b);
	is_approx($v->{chisq},    0.53333333, 'cramers (vectors) chi-square');
	is_approx($v->{estimate}, 0.21081851, 'cramers (vectors) V');
	is($v->{n}, 12, 'cramers (vectors) N');
}

# --- eta_squared: from raw data -------------------------------------------
{
	my $e = eta_squared([5.1,4.9,6.2,6.1,6.9,7.2,8,9,10], [qw(A A A B B B C C C)]);
	is_approx($e->{eta_sq},         0.84568835, 'eta squared');
	is_approx($e->{partial_eta_sq}, 0.84568835, 'partial eta squared');
	is_approx($e->{omega_sq},       0.77433628, 'omega squared');
}

# --- eta_squared: from an aov() result ------------------------------------
{
	my $aov = aov({ value => [5.1,4.9,6.2,6.1,6.9,7.2,8,9,10], grp => [qw(A A A B B B C C C)] },
	              'value ~ grp');
	my $e = eta_squared($aov);
	is_approx($e->{eta_sq}, 0.84568835, 'eta squared from aov result');
	is($e->{term}, 'grp', 'eta squared identifies the effect term');
}

# --- error handling -------------------------------------------------------
throws_ok { cohen_d([1], [2,3]) } qr/at least two/, 'cohen_d needs >=2 per group';
throws_ok { cramers_v([[1,2]]) }  qr/two rows/,     'cramers_v needs >=2 rows';
throws_ok { eta_squared(42) }     qr/expected/,     'eta_squared rejects bad input';

no_leaks_ok {
	cohen_d([5,6,7,8], [3,4,5,6]);
	smd([5,6,7,8], [3,4,5,6]);
	cramers_v([[10,20],[30,15]]);
	eta_squared([1,2,3,4,5,6], [qw(A A B B C C)]);
} 'effect-size functions do not leak';

done_testing();
