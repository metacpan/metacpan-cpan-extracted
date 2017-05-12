# Test of nonparametric ANOVA for dependent categorical measures - Friedman's test

use strict;
use warnings;
use Test::More tests => 5;
use constant EPS     => 1e-1;

BEGIN { use_ok('Statistics::ANOVA::Friedman') }

my $aov = Statistics::ANOVA::Friedman->new();

# Example from Rice (1995, p. 470) - uses average ranks
my @c1 = ( 174, 224, 260, 255, 165, 237, 191, 100, 115, 189 );
my @c2 = ( 263, 213, 231, 291, 168, 121, 137, 102, 89, 433);
my @c3 = ( 105, 103, 145, 103, 144, 94, 35, 133, 83, 237 );
my @c4 = ( 199, 143, 113, 225, 176, 144, 87, 120, 100, 173 );
my @c5 = ( 141, 168, 78, 164, 127, 114, 96, 222, 165, 168 );
my @c6 = ( 108, 341, 159, 135, 239, 136, 140, 134, 185, 188);
my @c7 = ( 141, 184, 125, 227, 194, 155, 121, 129, 79, 317 );

my @r1 = ( 5, 6, 7, 6, 3, 7, 7, 1, 5, 4 );
my @r2 = ( 7, 5, 6, 7, 4, 3, 5, 2, 3, 7);
my @r3 = ( 1, 1, 4, 1, 2, 1, 1, 5, 2, 5 );
my @r4 = ( 6, 2, 2, 4, 5, 5, 2, 3, 4, 2 );
my @r5 = ( 3.5, 3, 1, 3, 1, 2, 3, 7, 6, 1 );
my @r6 = ( 2, 7, 5, 2, 7, 4, 6, 6, 7, 3 );
my @r7 = ( 3.5, 4, 3, 5, 6, 6, 4, 4, 1, 6 );

my %ref_vals = (
    df_b      => 6,
    chi_value => 14.86,
    ss => 6.935,
);

eval { $aov->load_data( 1 => \@c1, 2 => \@c2, 3 => \@c3, 4 => \@c4, 5 => \@c5, 6 => \@c6, 7 => \@c7 ); };
ok( !$@, $@ );

my ( $chi, $df, $count, $pval ) =
  $aov->chiprob_test();

ok( about_equal( $df, $ref_vals{'df_b'} ),
    "Dependent Nonparametric Categorical:df_b: $df != $ref_vals{'df_b'}" );

ok(
    about_equal( $chi, $ref_vals{'chi_value'} ),
"Dependent Nonparametric Categorical:chi_value: $chi != $ref_vals{'chi_value'}"
);

ok($count == 70, "Dependent Nonparametric Categorical:count: $count != 70");

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
