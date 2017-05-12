use strict;
use warnings;
use Test::More tests => 11;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

# Example 1: from Maxwell & Delaney (1990) p. 209ff.

my @g1 = ( 2,   3,   1,   2,   0,   4 );
my @g2 = ( 6,   8,   5,   3,   7,   7 );
my @g3 = ( 6,   8,   10,  5,   10,  9 );
my @g4 = ( 11,  10,  7,   9,   8,   9 );
my @g5 = ( 2.6, 2.6, 2.9, 2.0, 2.0, 2.1 );
my @g6 = ( 3.1, 2.9, 3.1, 2.5 );
my @g7 = ( 2.6, 2.2, 2.2, 2.5, 1.2, 1.2 );
my @g8 = ( 2.5, 2.4, 3.0, 1.5 );

eval { $aov->load_data( { 1 => \@g1, 2 => \@g2, 3 => \@g3, 4 => \@g4 } ); };
ok( !$@, $@ );

my %ref_vals = (
    mean_t            => 2.5,
    linear            => 11.5,
    ss_l              => 158.700,
    ss_w              => 71.800,     # SPSS
                                     #ss_b => 172.5,
    ms_b              => 158.700,    # by SPSS
    ms_w              => 2.9,        # 3.264 by SPSS
    df_w              => 20,         # 22 by SPSS
    f_value           => 54.72,      # 48.627 by SPSS
    f_value_nonlinear => 2.38,
    p_value_nonlinear => .118313,
    df_b_nonlinear    => 2,
);

eval { $aov->anova( independent => 1, parametric => 1, ordinal => 1 ); };
ok( !$@, $@ );

#ok( about_equal($aov->{'_stat'}->{'mean_t'}, $ref_vals{'mean_t'}), "Independent Parametric Trend: mean_t: $aov->{'_stat'}->{'mean_t'} = $ref_vals{'mean_t'}" );

#ok( about_equal($aov->{'_stat'}->{'ss_l'}, $ref_vals{'ss_l'}), "Independent Parametric Trend: ss_l: $aov->{'_stat'}->{'ss_l'} = $ref_vals{'ss_l'}" );

##ok( about_equal($aov->{'_stat'}->{'ss_b'}, $ref_vals{'ss_b'}), "Independent Parametric Trend: ss_b: $aov->{'_stat'}->{'ss_b'} = $ref_vals{'ss_b'}" );

ok(
    about_equal( $aov->{'_stat'}->{'ms_w'}, $ref_vals{'ms_w'} ),
"Independent Parametric Trend:ms_w: $aov->{'_stat'}->{'ms_w'} = $ref_vals{'ms_w'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'f_value'} ),
"Independent Parametric Trend (linear): f_value: $aov->{'_stat'}->{'f_value'} = $ref_vals{'f_value'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'df_w'}, $ref_vals{'df_w'} ),
"Independent Parametric Trend (linear): df_w: $aov->{'_stat'}->{'df_w'} = $ref_vals{'df_w'}"
);

eval { $aov->anova( independent => 1, parametric => 1, ordinal => -1 ); };
ok( !$@, $@ );

ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'f_value_nonlinear'} ),
"Independent Parametric Trend (nonlinear): f_value: $aov->{'_stat'}->{'f_value'} = $ref_vals{'f_value_nonlinear'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'df_b'}, $ref_vals{'df_b_nonlinear'} ),
"Independent Parametric Trend (nonlinear): df_b: $aov->{'_stat'}->{'df_b'} = $ref_vals{'df_b_nonlinear'}"
);

ok(
    about_equal( $aov->{'_stat'}->{'p_value'}, $ref_vals{'p_value_nonlinear'} ),
"Independent Parametric Trend (nonlinear): p_value: $aov->{'_stat'}->{'p_value'} = $ref_vals{'p_value_nonlinear'}"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
