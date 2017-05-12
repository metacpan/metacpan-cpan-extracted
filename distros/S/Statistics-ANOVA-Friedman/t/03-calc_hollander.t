# Test of nonparametric ANOVA for dependent categorical measures - Friedman's test

use strict;
use warnings;
use Test::More tests => 7;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::Friedman') }

my $aov = Statistics::ANOVA::Friedman->new();

# Example from Hollander & Wolfe (1999), p. 274ff: 
# - using direct passing of data and checking tie correction:

my @p1 = (
    5.40, 5.85, 5.20, 5.55, 5.90, 5.45, 5.40, 5.45, 5.25, 5.85, 5.25, 5.65,
    5.60, 5.05, 5.50, 5.45, 5.55, 5.45, 5.50, 5.65, 5.70, 6.30
);
my @p2 = (
    5.50, 5.70, 5.60, 5.50, 5.85, 5.55, 5.40, 5.50, 5.15, 5.80, 5.20, 5.55,
    5.35, 5.00, 5.50, 5.55, 5.55, 5.50, 5.45, 5.60, 5.65, 6.30
);
my @p3 = (
    5.55, 5.75, 5.50, 5.40, 5.70, 5.60, 5.35, 5.35, 5.00, 5.70, 5.10, 5.45,
    5.45, 4.95, 5.40, 5.50, 5.35, 5.55, 5.25, 5.40, 5.55, 6.25
);

my %ref_vals = (
    df_b             => 2,
    chi_value_uncorr => 10.64,
    chi_value        => 11.14,
    p_value          => .004,
);

my ( $chi, $df, $count, $pval ) =
  $aov->chiprob_test( data => { 1 => \@p1, 2 => \@p2, 3 => \@p3 } );
ok( !$@, $@ );

ok(
    about_equal( $chi, $ref_vals{'chi_value'} ),
"Dependent Nonparametric Categorical:chi_value: $chi != $ref_vals{'chi_value'}"
);

ok( about_equal( $df, $ref_vals{'df_b'} ),
    "Dependent Nonparametric Categorical:df_b: $df != $ref_vals{'df_b'}" );

ok(
    about_equal( $pval, $ref_vals{'p_value'} ),
    "Dependent Nonparametric Categorical:p_value: $pval != $ref_vals{'p_value'}"
);

ok($count == 66, "Dependent Nonparametric Categorical:count: $count != 66");

($chi) = $aov->chiprob_test(
    data         => { 1 => \@p1, 2 => \@p2, 3 => \@p3 },
    correct_ties => 0
);
ok(
    about_equal( $chi, $ref_vals{'chi_value_uncorr'} ),
"Dependent Nonparametric Categorical:chi_value: $chi != $ref_vals{'chi_value_uncorr'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
