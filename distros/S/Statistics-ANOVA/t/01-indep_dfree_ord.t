use strict;
use warnings;
use Test::More tests => 9;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Example from Hollander & Wolfe (1999) p. 205ff.

my @g1 = ( 40, 35, 38, 43, 44, 41 );
my @g2 = ( 38, 40, 47, 44, 40, 42 );
my @g3 = ( 48, 40, 45, 43, 46, 44 );

eval { $aov->load_data( { 1 => \@g1, 2 => \@g2, 3 => \@g3 } ); };
ok( !$@, $@ );

my %ref_vals = (
    j_value => 79,
    j_exp   => 54,
    j_var   => 150.29,
    z_value => 2.04,
    p_value => 2 * .0207,
);

eval { $aov->anova( independent => 1, parametric => 0, ordinal => 1 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'j_value'}, $ref_vals{'j_value'} ),
"Independent Nonparametric Trend: j_value: $aov->{'_stat'}->{'j_value'} = $ref_vals{'j_value'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'j_exp'}, $ref_vals{'j_exp'} ),
"Independent Nonparametric Trend: j_exp: $aov->{'_stat'}->{'j_exp'} = $ref_vals{'j_exp'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'j_var'}, $ref_vals{'j_var'} ),
"Independent Nonparametric Trend: j_var: $aov->{'_stat'}->{'j_var'} = $ref_vals{'j_var'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'z_value'}, $ref_vals{'z_value'} ),
"Independent Nonparametric Trend: z_value: $aov->{'_stat'}->{'z_value'} = $ref_vals{'z_value'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'p_value'}, $ref_vals{'p_value'} ),
"Independent Nonparametric Trend: p_value: $aov->{'_stat'}->{'p_value'} = $ref_vals{'p_value'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
