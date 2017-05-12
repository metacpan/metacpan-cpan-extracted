# Test of nonparametric ANOVA for dependent ordinal measures - Page test

use strict;
use warnings;
use Test::More tests => 8;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::Page') };

my $aov = Statistics::ANOVA::Page->new();

my %ref_vals = (
    y_value => 206.5,
	y_exp => 105,
	y_var => 433.2,
    l_value => 158,
    l_exp => 135,
    l_var => 75,
    z_value => 2.66,
    p_value => .0039,
);

# Example from Hollander & Wolfe (1999), p. 286ff:
my @p1 = (7.46, 7.68, 7.21);
my @p2 = (7.17, 7.57, 7.80);
my @p3 = (7.76, 7.73, 7.74);
my @p4 = (8.14, 8.15, 7.87);
my @p5 = (7.63, 8.00, 7.93);

eval {$aov->load_data({ 1 => \@p1, 2 => \@p2, 3 => \@p3, 4 => \@p4, 5 => \@p5});};
ok(!$@, $@);

my $l_obs = $aov->observed();
my $l_exp = $aov->expected();
my $l_var = $aov->variance();
my ($z_value, $p_value) = $aov->zprob_test();

ok( about_equal($l_obs, $ref_vals{'l_value'}), "Dependent Nonparametric Trend:l_value: $l_obs != $ref_vals{'l_value'}" );

ok( about_equal($l_exp, $ref_vals{'l_exp'}), "Dependent Nonparametric Trend:l_exp: $l_exp != $ref_vals{'l_exp'}" );

ok( about_equal($l_var, $ref_vals{'l_var'}), "Dependent Nonparametric Trend:l_var: $l_var != $ref_vals{'l_var'}" );

ok( about_equal($z_value, $ref_vals{'z_value'}), "Dependent Nonparametric Trend:z_value: $z_value != $ref_vals{'z_value'}" );

ok( about_equal($p_value, $ref_vals{'p_value'}), "Dependent Nonparametric Trend:p_value: $p_value != $ref_vals{'p_value'}" );

my $chi_prob = $aov->chiprob_test();

ok( about_equal($chi_prob, $ref_vals{'p_value'}), "Dependent Nonparametric Trend:p_value: $p_value != $ref_vals{'p_value'}" );

sub about_equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;