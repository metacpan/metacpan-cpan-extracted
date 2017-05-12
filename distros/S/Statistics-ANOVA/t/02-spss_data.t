# Tests of eta_squared methods

use strict;
use warnings;
use Test::More tests => 5;
use constant EPS     => 1e-4;

BEGIN { use_ok('Statistics::ANOVA::EffectSize') }

my $aov_es = Statistics::ANOVA::EffectSize->new();

# SPSS output:

my @c1 = ( 9, 6, 9 );
my @c2 = ( 4, 5, 1 );
my @c3 = ( 1, 2, 2 );

my %ref_vals = (
    df_b      => 1,
    df_w    => 77,
    ss_b => 1.49892557715836,
    ss_w => 4.71271766128144,
    ms_b => 1.49892557715836,
    ms_w => 0.0612041254711875,
    f_value => 24.4905970899624,
    eta_sq_p => 0.241309025586417,
    omega_sq_p => 0.231455896,
    count => 78,
);

#eval { $aov_es->load_data( { 1 => \@c1, 2 => \@c2, 3 => \@c3, 4 => \@c4 } ); };
#ok( !$@, $@ );

my $es;

## ... and no given data:
#eval { $h_value = $aov_es->h_value(); };
#ok( !$@, $@ );

$es = $aov_es->eta_sq_partial_by_ss(ss_b => $ref_vals{'ss_b'}, ss_w => $ref_vals{'ss_w'});
#diag("eta = $es");
ok( about_equal( $es, $ref_vals{'eta_sq_p'} ),
    "eta_sq_partial_by_ss: $es != $ref_vals{'eta_sq_p'}" );

$es = $aov_es->eta_sq_partial_by_f(f_value => $ref_vals{'f_value'} , df_b => $ref_vals{'df_b'}, df_w => $ref_vals{'df_w'});
#diag("eta = $es");
ok( about_equal( $es, $ref_vals{'eta_sq_p'} ),
    "eta_sq_partial_by_ss: $es != $ref_vals{'eta_sq_p'}" );

$es = $aov_es->omega_sq_partial_by_ms(ms_b => $ref_vals{'ms_b'}, ms_w => $ref_vals{'ms_w'}, df_b => $ref_vals{'df_b'}, count => $ref_vals{'count'});
#diag("omega = $es");
ok( about_equal( $es, $ref_vals{'omega_sq_p'} ),
    "omega_sq_partial_by_ms: $es != $ref_vals{'omega_sq_p'}" );
    
#$es = $aov_es->omega_sq_partial_by_f(f_value => $ref_vals{'f_value'} , df_b => $ref_vals{'df_b'}, df_w => $ref_vals{'df_w'});
#diag("omega = $es");
#ok( about_equal( $es, $ref_vals{'omega_sq_p'} ),
#    "omega_sq_partial_by_f: $es != $ref_vals{'omega_sq_p'}" );
    
$es = $aov_es->eta_to_omega(df_b => $ref_vals{'df_b'}, df_w => $ref_vals{'df_w'}, eta_sq => $ref_vals{'eta_sq_p'});
#diag("eta-2-omega = $es");
ok( about_equal( $es, $ref_vals{'omega_sq_p'} ),
    "eta_to_omega: $es != $ref_vals{'omega_sq_p'}" );

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
