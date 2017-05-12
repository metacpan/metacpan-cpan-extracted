# Test parametric ANOVA for related groups

use strict;
use warnings;
use Test::More tests => 31;     # 31;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Example from Crowder & Hand (1990) p. 32ff.

my @w1 =
  ( 0.22, 0.18, 0.73, 0.30, 0.54, 0.16, 0.30, 0.70, 0.31, 1.40, 0.60, 0.73 );
my @w2 =
  ( 0.00, 0.00, 0.37, 0.25, 0.42, 0.30, 1.09, 1.30, 0.54, 1.40, 0.80, 0.50 );
my @w3 =
  ( 1.03, 0.96, 1.18, 0.74, 1.33, 1.27, 1.17, 1.80, 1.24, 1.64, 1.02, 1.08 );
my @w4 =
  ( 0.67, 0.96, 0.76, 1.10, 1.32, 1.06, 0.90, 1.80, 0.56, 1.28, 1.28, 1.26 );
my @w5 =
  ( 0.75, 0.98, 1.07, 1.48, 1.30, 1.39, 1.17, 1.60, 0.77, 1.12, 1.16, 1.17 );
my @w6 =
  ( 0.65, 1.03, 0.80, 0.39, 0.74, 0.63, 0.75, 1.23, 0.28, 0.66, 1.01, 0.91 );
my @w7 =
  ( 0.59, 0.70, 1.10, 0.36, 0.56, 0.40, 0.88, 0.41, 0.40, 0.77, 0.67, 0.87 );

my %ref_vals = (
    df_b => 6,
    ss_b => 6.1645,
    df_w => 66,
    ss_w => 4.4491,
);

eval {
    $aov->load_data(
        {
            1 => \@w1,
            2 => \@w2,
            3 => \@w3,
            4 => \@w4,
            5 => \@w5,
            6 => \@w6,
            7 => \@w7
        }
    );
};
ok( !$@, $@ );

eval { $aov->anova( independent => 0, parametric => 1, ordinal => 0 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'df_b'}, $ref_vals{'df_b'} ),
"Dependent Parametric Categorical:df_b: $aov->{'_stat'}->{'df_b'} = $ref_vals{'df_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ss_b'}, $ref_vals{'ss_b'} ),
"Dependent Parametric Categorical:ss_b: $aov->{'_stat'}->{'ss_b'} = $ref_vals{'ss_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'df_w'}, $ref_vals{'df_w'} ),
"Dependent Parametric Categorical:df_w: $aov->{'_stat'}->{'df_w'} = $ref_vals{'df_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ss_w'}, $ref_vals{'ss_w'} ),
"Dependent Parametric Categorical:ss_w: $aov->{'_stat'}->{'ss_w'} = $ref_vals{'ss_w'}"
);

# Example from Gardner (2001):

my @b1 = ( 80, 70, 50, 50, 40, 23 );
my @b2 = ( 70, 54, 62, 43, 34, 27 );
my @b3 = ( 40, 47, 38, 41, 20, 21 );
my @b4 = ( 29, 31, 31, 29, 17, 14 );

%ref_vals = (
    df_b    => 3,
    ss_b    => 2806.458,
    df_w    => 15,
    ss_w    => 970.292,
    ms_b    => 935.486,
    ms_w    => 64.686,
    f_value => 14.462,
    eta_sq  => .743,
    power   => .999,
    noncent => 43.386,
);

eval { $aov->unload(); };
ok( !$@, $@ );

eval { $aov->load_data( { 1 => \@b1, 2 => \@b2, 3 => \@b3, 4 => \@b4 } ); };
ok( !$@, $@ );

eval { $aov->anova( independent => 0, parametric => 1, ordinal => 0 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'df_b'}, $ref_vals{'df_b'} ),
"Dependent Parametric Categorical:df_b: $aov->{'_stat'}->{'df_b'} = $ref_vals{'df_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ss_b'}, $ref_vals{'ss_b'} ),
"Dependent Parametric Categorical:ss_b: $aov->{'_stat'}->{'ss_b'} = $ref_vals{'ss_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'df_w'}, $ref_vals{'df_w'} ),
"Dependent Parametric Categorical:df_w: $aov->{'_stat'}->{'df_w'} = $ref_vals{'df_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ss_w'}, $ref_vals{'ss_w'} ),
"Dependent Parametric Categorical:ss_w: $aov->{'_stat'}->{'ss_w'} = $ref_vals{'ss_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ms_b'}, $ref_vals{'ms_b'} ),
"Dependent Parametric Categorical:ms_b: $aov->{'_stat'}->{'ms_b'} = $ref_vals{'ms_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ms_w'}, $ref_vals{'ms_w'} ),
"Dependent Parametric Categorical:ms_w: $aov->{'_stat'}->{'ms_w'} = $ref_vals{'ms_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'f_value'} ),
"Dependent Parametric Categorical:f_value: $aov->{'_stat'}->{'f_value'} = $ref_vals{'f_value'}"
);

eval { $aov->eta_squared( independent => 0, parametric => 1, ordinal => 0 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'eta_sq'}, $ref_vals{'eta_sq'} ),
"Dependent Parametric Categorical:eta_sq: $aov->{'_stat'}->{'eta_sq'} = $ref_vals{'eta_sq'}"
);

# Example from M&D p. 466
my @m30 = ( 108, 103, 96,  84, 118, 110, 129, 90,  84,  96,  105, 113 );
my @m36 = ( 96,  117, 107, 85, 125, 107, 128, 84,  104, 100, 114, 117 );
my @m42 = ( 110, 127, 106, 92, 125, 96,  123, 101, 100, 103, 105, 132 );
my @m48 = ( 122, 133, 107, 99, 116, 91,  128, 113, 88,  105, 112, 130 );
%ref_vals = (
    df_b    => 3,
    ss_b    => 552,
    df_w    => 33,
    ss_w    => 2006,
    ms_b    => 552 / 3,
    ms_w    => 2006 / 33,
    f_value => 3.03,
    p_value => .042,

);

eval { $aov->unload(); };
ok( !$@, $@ );

eval { $aov->load_data( { 1 => \@m30, 2 => \@m36, 3 => \@m42, 4 => \@m48 } ); };
ok( !$@, $@ );

eval { $aov->anova( independent => 0, parametric => 1, ordinal => 0 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'df_b'}, $ref_vals{'df_b'} ),
"Dependent Parametric Categorical:df_b: $aov->{'_stat'}->{'df_b'} = $ref_vals{'df_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ss_b'}, $ref_vals{'ss_b'} ),
"Dependent Parametric Categorical:ss_b: $aov->{'_stat'}->{'ss_b'} = $ref_vals{'ss_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'df_w'}, $ref_vals{'df_w'} ),
"Dependent Parametric Categorical:df_w: $aov->{'_stat'}->{'df_w'} = $ref_vals{'df_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ss_w'}, $ref_vals{'ss_w'} ),
"Dependent Parametric Categorical:ss_w: $aov->{'_stat'}->{'ss_w'} = $ref_vals{'ss_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ms_b'}, $ref_vals{'ms_b'} ),
"Dependent Parametric Categorical:ms_b: $aov->{'_stat'}->{'ms_b'} = $ref_vals{'ms_b'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'ms_w'}, $ref_vals{'ms_w'} ),
"Dependent Parametric Categorical:ms_w: $aov->{'_stat'}->{'ms_w'} = $ref_vals{'ms_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'f_value'} ),
"Dependent Parametric Categorical:f_value: $aov->{'_stat'}->{'f_value'} = $ref_vals{'f_value'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'p_value'}, $ref_vals{'p_value'} ),
"Dependent Parametric Categorical:p_value: $aov->{'_stat'}->{'p_value'} = $ref_vals{'p_value'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
