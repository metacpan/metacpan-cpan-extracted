# Test that the example given in the POD's SYNOPSIS section actually works:

use strict;
use warnings;
use Test::More tests => 49;
use constant EPS     => 1e-7;

BEGIN { use_ok('Statistics::ANOVA') }

my $aov = Statistics::ANOVA->new();
isa_ok( $aov, 'Statistics::ANOVA' );

my @gp1 = (qw/8 7 11 14 9/);
my @gp2 = (qw/11 9 8 11 13/);

eval { $aov->load( 1, @gp1 ); };    # simple but useless load
ok( !$@, $@ );

eval { $aov->load( 1, \@gp1 ); };    # another simple but useless load
ok( !$@, $@ );

eval { $aov->load_data( { 1 => \@gp1, 2 => \@gp2 } ); };
ok( !$@, $@ );

eval { $aov->unload() };             # going to try an alternative load
ok( !$@, $@ );

eval { $aov->load_data( [ [ 1, \@gp1 ], [ 2, \@gp2 ] ] ); };
ok( !$@, $@ );

eval { $aov->unload() }; # another anonymous unload; going to try yet another alternative load
ok( !$@, $@ );

eval { $aov->load_data( [ [ 1, @gp1 ], [ 2, @gp2 ] ] ); };
ok( !$@, $@ );

my @gp3 = (qw/7 13 12 8 10/);

eval { $aov->add_data( 3 => \@gp3 ); };
ok( !$@, $@ );

eval { $aov->unload(3) };  # a named unload; going to try yet an alternative add
ok( !$@, $@ );

eval { $aov->add_data( [ 3, \@gp3 ] ); };
ok( !$@, $@ );
ok(
    $aov->ndata() == 3,
    "Number of data-keys after unload/add should be 3; is "
      . scalar( keys( %{ $aov->{'data'} } ) )
);

eval { $aov->unload(3) };    # going to try yet an alternative add
ok( !$@, $@ );
ok(
    $aov->ndata() == 2,
    "Number of remaining data-keys should be 2; is "
      . scalar( keys( %{ $aov->{'data'} } ) )
);

eval { $aov->add_data( [ [ 3, \@gp3 ] ] ); };
ok( !$@, $@ );

eval { $aov->unload(3) };    # going to try yet an alternative add
ok( !$@, $@ );

eval { $aov->add_data( 3, \@gp3 ); };
ok( !$@, $@ );

eval { $aov->unload(3) };    # going to try yet an alternative add
ok( !$@, $@ );

eval { $aov->add_data( 3, @gp3 ); };
ok( !$@, $@ );

my %ref_vals = (
    obrien_f             => 0.386222473178995,
    levene_f             => 0.388785046728972,
    indep_param_f        => 0.0777777777777777,
    indep_dfree_h        => 0.265209471,
    indep_param_trend_f  => 0.01666666666,
    indep_param_ntrend_f => 0.1388888,
    dep_param_f          => 0.060475161987041,
    dep_dfree_chi        => 0.400000000000006,
    dep_dfree_f          => 0.166666666666669,
);

eval { $aov->obrien(); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'obrien_f'} ),
    "Obrien f-value $aov->{'_stat'}->{'f_value'} != $ref_vals{'obrien_f'}"
);

eval { $aov->levene(); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'levene_f'} ),
    "Levene f-value $aov->{'_stat'}->{'f_value'} != $ref_vals{'levene_f'}"
);

eval { $aov->anova( independent => 1, parametric => 1 ); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'indep_param_f'} ),
"Indep param f-value $aov->{'_stat'}->{'f_value'} != $ref_vals{'indep_param_f'}"
);

eval { $aov->anova( independent => 1, parametric => 0 ); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'h_value'}, $ref_vals{'indep_dfree_h'} ),
"Indep non-param f-value $aov->{'_stat'}->{'h_value'} != $ref_vals{'indep_dfree_h'}"
);

# or test the linear trend over the levels instead of the group-wise variance:
eval { $aov->anova( independent => 1, parametric => 1, ordinal => 1 ) };
ok( !$@, $@ );
ok(
    about_equal(
        $aov->{'_stat'}->{'f_value'},
        $ref_vals{'indep_param_trend_f'}
    ),
"Indep param f-value $aov->{'_stat'}->{'f_value'} != $ref_vals{'indep_param_trend_f'}"
);

eval { $aov->anova( independent => 1, parametric => 1, ordinal => -1 ) };
ok( !$@, $@ );
ok(
    about_equal(
        $aov->{'_stat'}->{'f_value'},
        $ref_vals{'indep_param_ntrend_f'}
    ),
"Indep param f-value $aov->{'_stat'}->{'f_value'} != $ref_vals{'indep_param_ntrend_f'}"
);

eval { $aov->anova( independent => 1, parametric => 0, ordinal => 1 ); };
ok( !$@, $@ );

# or if they are repeated measures:
eval { $aov->anova( independent => 0, parametric => 1 ); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'dep_param_f'} ),
    "Dep f-value $aov->{'_stat'}->{'f_value'} != $ref_vals{'dep_param_f'}"
);

eval { $aov->anova( independent => 0, parametric => 0, f_equiv => 0 ); };
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'chi_value'}, $ref_vals{'dep_dfree_chi'} ),
    "Dep f-value $aov->{'_stat'}->{'chi_value'} != $ref_vals{'dep_dfree_chi'}"
);

eval {
    $aov->anova(
        independent => 0,
        parametric  => 0,
        ordinal     => 0,
        f_equiv     => 1
    );
};
ok( !$@, $@ );
ok(
    about_equal( $aov->{'_stat'}->{'f_value'}, $ref_vals{'dep_dfree_f'} ),
    "Dep f-value $aov->{'_stat'}->{'f_value'} != $ref_vals{'dep_dfree_f'}"
);

eval { $aov->unload('3'); };
ok( !$@, $@ );
ok(
    $aov->ndata() == 2,
    "Number of remaining data-keys should be 2; is "
      . scalar( keys( %{ $aov->{'data'} } ) )
);

foreach my $indep ( 1, 0 ) {
    foreach my $param ( 1, 0 ) {
        foreach my $ord ( 0, 1 ) {
            eval {
                $aov->anova(
                    independent => $indep,
                    parametric  => $param,
                    ordinal     => $ord,
                    f_equiv     => 0
                )->table();
            };
            ok( !$@, $@ );
        }
    }
}

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
