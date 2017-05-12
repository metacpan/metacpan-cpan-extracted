# Test of nonparametric ANOVA for dependent categorical measures - Friedman's test

use strict;
use warnings;
use Test::More tests => 6;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::Friedman') }

my $aov = Statistics::ANOVA::Friedman->new();

# Example from Siegal (1956) p. 167ff.

my @c1 = ( 9, 6, 9 );
my @c2 = ( 4, 5, 1 );
my @c3 = ( 1, 2, 2 );
my @c4 = ( 7, 8, 6 );

my %ref_vals = (
    df_b      => 3,
    chi_value => 7.400,
    p_value   => 2 * 0.033,
    mrank_1   => 3.67,
    mrank_2   => 1.67,
    mrank_3   => 1.33,
    mrank_4   => 3.33,
);

eval { $aov->load_data( { 1 => \@c1, 2 => \@c2, 3 => \@c3, 4 => \@c4 } ); };
ok( !$@, $@ );

my ( $chi, $df, $count, $pval ) =
  $aov->chiprob_test();

ok(
    about_equal( $chi, $ref_vals{'chi_value'} ),
"Dependent Nonparametric Categorical:chi_value: $chi != $ref_vals{'chi_value'}"
);

ok( about_equal( $df, $ref_vals{'df_b'} ),
    "Dependent Nonparametric Categorical:df_b: $df != $ref_vals{'df_b'}" );

ok($count == 12, "Dependent Nonparametric Categorical:count: $count != 12");

ok(
    about_equal( $pval, $ref_vals{'p_value'} ),
    "Dependent Nonparametric Categorical:p_value: $pval != $ref_vals{'p_value'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
