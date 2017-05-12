use strict;
use warnings;
use Test::More tests => 27;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Example 1: from Gardner (2000) p. 81ff.

my @g1 = ( 50, 54, 55, 68, 66, 76, 75, 63, 62, 61, 75, 63, 62, 77, 68 );
my @g2 = ( 72, 75, 65, 60, 69, 64, 56, 57, 55, 63, 54, 63, 51, 72, 78 );
my @g3 = ( 60, 60, 70, 72, 64, 79, 73, 75, 72, 77, 67, 83, 60, 77, 70 );
my @g4 = ( 68, 65, 76, 74, 75, 83, 82, 76, 85, 75, 63, 64, 77, 62, 83 );

my %ref_vals = (
    ss_b    => 1038.800,
    ss_w    => 3498.93,
    ms_b    => 346.267,
    ms_w    => 62.481,
    df_b    => 3,
    df_w    => 56,
    f_value => 5.542,
    p_value => .002,
);

eval { $aov->load_data( { 1 => \@g1, 2 => \@g2, 3 => \@g3, 4 => \@g4 } ); };
ok( !$@, $@ );
my %lev = (
    f_levene => .139,
    p_levene => .936,    # from SPSS
);
eval { $aov->levene(); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $lev{'f_levene'} ),
"Independent Parametric Categorical: f_value (Levene): $aov->{'_stat'}->{'f_value'} != $lev{'f_levene'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'p_value'}, $lev{'p_levene'} ),
"Independent Parametric Categorical: p_value (Levene): $aov->{'_stat'}->{'p_value'} != $lev{'p_levene'}"
);
eval { $aov->anova( parametric => 1, independent => 1, ordinal => 0 ); };
ok( !$@, $@ );

for ( keys %ref_vals ) {
    ok(
        about_equal( $aov->{'_stat'}->{$_}, $ref_vals{$_} ),
"Independent Parametric Categorical: $_: $aov->{'_stat'}->{$_} != $ref_vals{$_}"
    );
}

my %es = (
    eta_sq   => .229,
    omega_sq => .19,
);

eval { $aov->eta_squared( parametric => 1, independent => 1, ordinal => 0 ); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'eta_sq'}, $es{'eta_sq'} ),
"Independent Parametric Categorical: eta_sq: $aov->{'_stat'}->{'eta_sq'} = $es{'eta_sq'}"
);

my $omg =
  $aov->omega_squared( independent => 1, parametric => 1, ordinal => 0 );
ok(
    about_equal( $aov->{'_stat'}->{'omega_sq'}, $es{'omega_sq'} ),
"Independent Parametric Categorical: omega_sq: $aov->{'_stat'}->{'omega_sq'} = $es{'omega_sq'}"
);

# Example 2: from Maxwell & Delaney (1999), p. 88ff

%ref_vals = (
    ss_b    => 46.67,
    ss_w    => 26,
    ms_b    => 23.33,
    ms_w    => .963,
    df_b    => 2,
    df_w    => 27,
    f_value => 24.23,
);

@g1 = ( 6, 5, 4, 7, 7, 5, 5, 7, 7, 7 );
@g2 = ( 5, 4, 4, 3, 4, 3, 4, 4, 4, 5 );
@g3 = ( 3, 3, 4, 4, 4, 3, 1, 2, 2, 4 );

eval { $aov->load_data( { 1 => \@g1, 2 => \@g2, 3 => \@g3 } ); };
ok( !$@, $@ );

eval { $aov->anova( parametric => 1, independent => 1, ordinal => 0 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'ss_b'}, $ref_vals{'ss_b'} ),
"Independent Parametric Categorical: ss_b: $aov->{'_stat'}->{'ss_b'} = $ref_vals{'ss_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ss_w'}, $ref_vals{'ss_w'} ),
"Independent Parametric Categorical: ss_w: $aov->{'_stat'}->{'ss_w'} = $ref_vals{'ss_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ms_b'}, $ref_vals{'ms_b'} ),
"Independent Parametric Categorical: ms_b: $aov->{'_stat'}->{'ms_b'} = $ref_vals{'ms_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ms_w'}, $ref_vals{'ms_w'} ),
"Independent Parametric Categorical: ms_w: $aov->{'_stat'}->{'ms_w'} = $ref_vals{'ms_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'df_b'}, $ref_vals{'df_b'} ),
"Independent Parametric Categorical: df_b: $aov->{'_stat'}->{'df_b'} = $ref_vals{'df_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'df_w'}, $ref_vals{'df_w'} ),
"Independent Parametric Categorical: df_w: $aov->{'_stat'}->{'df_w'} = $ref_vals{'df_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'f_value'} ),
"Independent Parametric Categorical: f_value: $aov->{'_stat'}->{'f_value'} = $ref_vals{'f_value'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
