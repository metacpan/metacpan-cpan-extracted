# Test of nonparametric ANOVA for dependent categorical measures - Friedman's test

use strict;
use warnings;
use Test::More tests => 14;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

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

eval {
    $aov->anova(
        independent => 0,
        parametric  => 0,
        ordinal     => 0,
        f_equiv     => 0
    );
};
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'df_b'}, $ref_vals{'df_b'} ),
"Dependent Nonparametric Categorical:df_b: $aov->{'_stat'}->{'df_b'} = $ref_vals{'df_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'chi_value'}, $ref_vals{'chi_value'} ),
"Dependent Nonparametric Categorical:chi_value: $aov->{'_stat'}->{'chi_value'} = $ref_vals{'chi_value'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'p_value'}, $ref_vals{'p_value'} ),
"Dependent Nonparametric Categorical:p_value: $aov->{'_stat'}->{'p_value'} = $ref_vals{'p_value'}"
);

# Example from Hollander & Wolfe (1999), p. 274ff:

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

%ref_vals = (
    df_b             => 2,
    chi_value_uncorr => 10.64,
    chi_value        => 11.14,
    p_value          => .004,
);

eval { $aov->load_data( { 1 => \@p1, 2 => \@p2, 3 => \@p3 } ); };
ok( !$@, $@ );

eval {
    $aov->anova(
        independent => 0,
        parametric  => 0,
        ordinal     => 0,
        f_equiv     => 0
    );
};
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'df_b'}, $ref_vals{'df_b'} ),
"Dependent Nonparametric Categorical:df_b: $aov->{'_stat'}->{'df_b'} = $ref_vals{'df_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'chi_value'}, $ref_vals{'chi_value'} ),
"Dependent Nonparametric Categorical:chi_value: $aov->{'_stat'}->{'chi_value'} = $ref_vals{'chi_value'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'p_value'}, $ref_vals{'p_value'} ),
"Dependent Nonparametric Categorical:p_value: $aov->{'_stat'}->{'p_value'} = $ref_vals{'p_value'}"
);

eval {
    $aov->anova(
        independent  => 0,
        parametric   => 0,
        ordinal      => 0,
        f_equiv      => 0,
        correct_ties => 0
    );
};
ok( !$@, $@ );

ok(
    about_equal(
        $aov->{'_stat'}->{'chi_value'}, $ref_vals{'chi_value_uncorr'}
    ),
"Dependent Nonparametric Categorical:chi_value: $aov->{'_stat'}->{'chi_value'} = $ref_vals{'chi_value_uncorr'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
