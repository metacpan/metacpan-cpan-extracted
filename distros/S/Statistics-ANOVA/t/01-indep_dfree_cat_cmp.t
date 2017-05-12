# Test of post-Kruskal-Wallis nonparametric multi-comparison procedure for categorical factor with independent groups (Dwass)

use strict;
use warnings;
use Test::More tests => 16;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Example from Hollander & Wolfe (1999) pp. 200, 242ff.

my @g1 = ( 46, 28, 46, 37, 32, 41, 42, 45, 38, 44 );
my @g2 = ( 42, 60, 32, 42, 45, 58, 27, 51, 42, 52 );
my @g3 = ( 38, 33, 26, 25, 28, 28, 26, 27, 27, 27 );
my @g4 = ( 31, 30, 27, 29, 30, 25, 25, 24, 27, 30 );

eval { $aov->load_data( { g1 => \@g1, g2 => \@g2, g3 => \@g3, g4 => \@g4 } ); };
ok( !$@, $@ );

my %ref_vals = (
    s12 => 120.5,
    s13 => 61.5,
    s14 => 60,
    s23 => 62.5,
    s24 => 61,
    s34 => 105,
    z12 => 1.67,
    z13 => -4.67,
    z14 => -4.82,
    z23 => -4.57,
    z24 => -4.73,
    z34 => 0,
);

#$aov->anova(independent => 1, parametric => 0, ordinal =>0);

my $pair_dat = $aov->compare( independent => 1, parametric => 0, ordinal => 0 );
ok( !$@, $@ );

ok(
    about_equal( $pair_dat->{"g1,g2"}->{'s_value'}, $ref_vals{'s12'} ),
"Dwass nonparametric comparison: g1,g2: $pair_dat->{'g1,g2'}->{'s_value'} = $ref_vals{'s12'}"
);

ok(
    about_equal( $pair_dat->{"g1,g3"}->{'s_value'}, $ref_vals{'s13'} ),
"Dwass nonparametric comparison: g1,g3: $pair_dat->{'g1,g3'}->{'s_value'} = $ref_vals{'s13'}"
);

ok(
    about_equal( $pair_dat->{"g1,g4"}->{'s_value'}, $ref_vals{'s14'} ),
"Dwass nonparametric comparison: g1,g4: $pair_dat->{'g1,g4'}->{'s_value'} = $ref_vals{'s14'}"
);

ok(
    about_equal( $pair_dat->{"g2,g3"}->{'s_value'}, $ref_vals{'s23'} ),
"Dwass nonparametric comparison: g2,g3: $pair_dat->{'g2,g3'}->{'s_value'} = $ref_vals{'s23'}"
);

ok(
    about_equal( $pair_dat->{"g2,g4"}->{'s_value'}, $ref_vals{'s24'} ),
"Dwass nonparametric comparison: g2,g4:  $pair_dat->{'g2,g4'}->{'s_value'} = $ref_vals{'s24'}"
);

ok(
    about_equal( $pair_dat->{"g3,g4"}->{'s_value'}, $ref_vals{'s34'} ),
"Dwass nonparametric comparison g3,g4: $pair_dat->{'g3,g4'}->{'s_value'} = $ref_vals{'s34'}"
);

ok(
    about_equal( $pair_dat->{"g1,g2"}->{'z_value'}, $ref_vals{'z12'} ),
"Dwass nonparametric comparison: g1,g2:  $pair_dat->{'g1,g2'}->{'z_value'} = $ref_vals{'z12'}"
);

ok(
    about_equal( $pair_dat->{"g1,g3"}->{'z_value'}, $ref_vals{'z13'} ),
"Dwass nonparametric comparison: g1,g3:  $pair_dat->{'g1,g3'}->{'z_value'} = $ref_vals{'z13'}"
);

ok(
    about_equal( $pair_dat->{"g1,g4"}->{'z_value'}, $ref_vals{'z14'} ),
"Dwass nonparametric comparison: g1,g4:  $pair_dat->{'g1,g4'}->{'z_value'} = $ref_vals{'z14'}"
);

ok(
    about_equal( $pair_dat->{"g2,g3"}->{'z_value'}, $ref_vals{'z23'} ),
"Dwass nonparametric comparison: g2,g3:  $pair_dat->{'g2,g3'}->{'z_value'} = $ref_vals{'z23'}"
);

ok(
    about_equal( $pair_dat->{"g2,g4"}->{'z_value'}, $ref_vals{'z24'} ),
"Dwass nonparametric comparison: g2,g4:  $pair_dat->{'g2,g4'}->{'z_value'} = $ref_vals{'z24'}"
);

ok(
    about_equal( $pair_dat->{"g3,g4"}->{'z_value'}, $ref_vals{'z34'} ),
"Dwass nonparametric comparison: g3,g4:  $pair_dat->{'g3,g4'}->{'z_value'} = $ref_vals{'z34'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
