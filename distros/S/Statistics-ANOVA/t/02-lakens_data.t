# Tests of eta_squared methods

use strict;
use warnings;
use Test::More tests => 6;
use constant EPS     => 1e-2;

BEGIN { use_ok('Statistics::ANOVA::EffectSize') }

my $aov_es = Statistics::ANOVA::EffectSize->new();
require Statistics::ANOVA;
my $aov = Statistics::ANOVA->new();

# Example from Lakens (2013) pp. 7-8:

my @m1 = ( 9, 7, 8, 9, 8, 9, 9, 10, 9, 9 );
my @m2 = ( 9, 6, 7, 8, 7, 9, 8, 8, 8, 7 );
my @m3 = ( 0, 1, 1, 1, 1, 0, 1, 2, 1, 2);

my %ref_vals = (
    df_b      => 1,
    df_w    => 18,
    #ss_b => 1.49892557715836,
    #ss_w => 4.71271766128144,
    #ms_b => 1.49892557715836,
    #ms_w => 0.0612041254711875,
    f_value => 6.34,
    eta_sq_p => 0.26,
    omega_sq_p => 0.21,
 );

eval { $aov->load_data( { 1 => \@m1, 2 => \@m2 } ); };
ok( !$@, $@ );

my %stats = $aov->anova(independent => 1, parametric => 1, ordinal => 0);

my $es;

#diag("ss_b => $stats{'ss_b'}, ss_w => $stats{'ss_w'}");
$es = $aov_es->eta_sq_partial_by_ss(ss_b => $stats{'ss_b'}, ss_w => $stats{'ss_w'});
ok( about_equal( $es, $ref_vals{'eta_sq_p'} ),
    "eta_sq_partial_by_ss: $es != $ref_vals{'eta_sq_p'}" );

$es = $aov_es->eta_sq_partial_by_f(f_value => $ref_vals{'f_value'} , df_b => $ref_vals{'df_b'}, df_w => $ref_vals{'df_w'});
ok( about_equal( $es, $ref_vals{'eta_sq_p'} ),    "eta_sq_partial_by_ss: $es != $ref_vals{'eta_sq_p'}" );

#$es = $aov_es->omega_sq_partial_by_ms(ms_b => $ref_vals{'ms_b'}, ms_w => $ref_vals{'ms_w'}, df_b => $ref_vals{'df_b'}, count => $ref_vals{'count'});
#diag("omega = $es");
#ok( about_equal( $es, $ref_vals{'omega_sq_p'} ),    "omega_sq_partial_by_ms: $es != $ref_vals{'omega_sq_p'}" );
    
$es = $aov_es->omega_sq_partial_by_f(f_value => $ref_vals{'f_value'} , df_b => $ref_vals{'df_b'}, df_w => $ref_vals{'df_w'});
ok( about_equal( $es, $ref_vals{'omega_sq_p'} ),
    "omega_sq_partial_by_f: $es != $ref_vals{'omega_sq_p'}" );
    
$es = $aov_es->eta_to_omega(df_b => $ref_vals{'df_b'}, df_w => $ref_vals{'df_w'}, eta_sq => $ref_vals{'eta_sq_p'});
ok( about_equal( $es, $ref_vals{'omega_sq_p'} ),    "eta_to_omega: $es != $ref_vals{'omega_sq_p'}" );

# as repeated measures (Lakens, 2013, p. 8)
@m1 = ( 9, 7, 8, 9, 8, 9, 9, 10, 9, 9 );
@m2 = ( 9, 6, 7, 8, 7, 9, 8, 8, 8, 7 );
$aov->load_data( { 1 => \@m1, 2 => \@m2 } );
%stats = $aov->anova(independent => 0, parametric => 1, ordinal => 0);
#diag("f => $stats{'f_value'}, ss_b => $stats{'ss_b'}, ss_w => $stats{'ss_w'}");

%ref_vals = (
    df_b      => 1,
    df_w    => 18,
    f_value => 6.34,
    p_value => 0.022,
    eta_sq_p => 0.26,
    omega_sq_p => 0.21,
 );


sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
