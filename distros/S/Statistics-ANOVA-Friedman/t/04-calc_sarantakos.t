# Test of nonparametric ANOVA for dependent categorical measures - Friedman's test

use strict;
use warnings;
use Test::More tests => 5;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::Friedman') }

my $aov = Statistics::ANOVA::Friedman->new();

# Example from Siegal (1956) p. 167ff.

my @c1 = ( 8, 7, 11, 14, 9 );
my @c2 = ( 11, 9, 8, 11, 13 );
my @c3 = ( 7, 13, 12, 8, 10);

my %ref_vals = (
    df_b      => 2,
    chi_value => .4,
);

eval { $aov->load_data( { 1 => \@c1, 2 => \@c2, 3 => \@c3 } ); };
ok( !$@, $@ );

my ( $chi, $df, $count, $pval ) =
  $aov->chiprob_test();

ok( about_equal( $df, $ref_vals{'df_b'} ),
    "Dependent Nonparametric Categorical:df_b: $df != $ref_vals{'df_b'}" );

ok(
    about_equal( $chi, $ref_vals{'chi_value'} ),
"Dependent Nonparametric Categorical:chi_value: $chi != $ref_vals{'chi_value'}"
);

ok($count == 15, "Dependent Nonparametric Categorical:count: $count != 15");

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
