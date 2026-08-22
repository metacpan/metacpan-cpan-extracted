use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch::Loading;
use Physics::Etch::Chamber;

my $L = Physics::Etch::Loading->new( kappa => 0.01, k_micro => 0.5, arde_length => 8 );

# --- macro loading ---------------------------------------------------------
is( $L->macro_factor(0), 1, 'no load -> factor 1' );
ok( $L->macro_factor(100) < 1, 'loaded -> factor < 1' );
ok( $L->macro_factor(200) < $L->macro_factor(100),
    'more area -> more loading' );
# exact: 1/(1+0.01*100) = 1/2
ok( abs( $L->macro_factor(100) - 0.5 ) < 1e-9, 'macro factor value' );
# from fraction
ok( abs( $L->macro_factor_from_fraction( 0.5, 200 ) - $L->macro_factor(100) ) < 1e-9,
    'macro_factor_from_fraction' );

# --- micro loading ---------------------------------------------------------
is( $L->micro_factor(0), 1, 'zero density -> factor 1' );
ok( $L->micro_factor(0.5) < 1, 'dense -> slower' );
ok( $L->micro_factor(0.8) < $L->micro_factor(0.2), 'denser -> slower still' );
ok( $L->micro_relative( 0.5, 0.5 ) == 1, 'relative to same density is 1' );
ok( $L->micro_relative( 0.8, 0.2 ) < 1, 'denser than mean -> < 1' );

# --- ARDE / RIE lag --------------------------------------------------------
is( $L->arde_factor(0), 1, 'AR 0 -> no lag' );
ok( $L->arde_factor(4) < 1, 'AR>0 -> lag' );
ok( $L->arde_factor(8) < $L->arde_factor(4), 'higher AR -> more lag' );
ok( abs( $L->arde_factor(8) - 0.5 ) < 1e-9, 'arde half at AR=arde_length' );
# lateral is less suppressed than vertical (-> tapering)
ok( $L->arde_lateral_factor(8) > $L->arde_factor(8),
    'lateral ARDE milder than vertical' );

# --- from_chamber ----------------------------------------------------------
my $slow = Physics::Etch::Chamber->new( volume_l => 10, flow_sccm => 20, pressure_mtorr => 50 );
my $fast = Physics::Etch::Chamber->new( volume_l => 10, flow_sccm => 200, pressure_mtorr => 50 );
my $Ls   = Physics::Etch::Loading->from_chamber($slow);
my $Lf   = Physics::Etch::Loading->from_chamber($fast);
ok( $Ls->kappa > $Lf->kappa,
    'longer residence (low flow) -> stronger loading' );

like( $L->describe, qr/kappa/, 'describe renders' );

done_testing;
