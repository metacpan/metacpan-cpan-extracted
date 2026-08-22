use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch::WetEtch;

# --- Basic isotropic wet etch ----------------------------------------------
my $w = Physics::Etch::WetEtch->new(
    target     => 'copper',
    etchant    => 'FeCl3',
    thickness  => 500,
    rate       => 800,
    ref_temp   => 25,
    Ea         => 0.43,
    feature_cd => 2000,
    overetch   => 0.0,
);

is( $w->process_type, 'Wet', 'process_type' );

# at reference temperature the Arrhenius factor is 1
ok( abs( $w->arrhenius_factor - 1 ) < 1e-9, 'Arrhenius = 1 at ref temp' );
is( $w->vertical_rate, 800, 'vertical rate = base at ref temp' );

# isotropic: lateral == vertical, anisotropy ~ 0
is( $w->lateral_rate, $w->vertical_rate, 'isotropic lateral == vertical' );
ok( $w->anisotropy < 1e-9, 'wet anisotropy ~ 0' );

# clear time = thickness / rate ; no overetch -> etch_time == clear time
is( $w->time_to_clear, 500 / 800, 'time to clear' );
is( $w->etch_time,     $w->time_to_clear, 'etch_time == clear at 0 overetch' );

# undercut equals depth for a fully isotropic etch
my $t = $w->time_to_clear;
ok( abs( $w->undercut($t) - $w->etch_depth($t) ) < 1e-9,
    'isotropic undercut == depth' );

# isotropic sidewall angle ~ 45 deg when depth == undercut
my $p = $w->profile($t);
ok( abs( $p->{sidewall_angle} - 45 ) < 0.5, 'isotropic sidewall ~45 deg' );
is( $p->{etch_bias}, 2 * $p->{undercut}, 'etch bias = 2 * undercut' );

# --- Temperature dependence (Arrhenius) ------------------------------------
my $hot = Physics::Etch::WetEtch->new(
    target => 'copper', etchant => 'FeCl3',
    thickness => 500, rate => 800, ref_temp => 25, Ea => 0.43,
    temperature => 45,
);
ok( $hot->vertical_rate > $w->vertical_rate, 'higher temp -> faster' );
ok( $hot->arrhenius_factor > 1, 'Arrhenius > 1 above ref temp' );

# concentration & agitation scale linearly
my $conc = Physics::Etch::WetEtch->new(
    target => 'copper', etchant => 'FeCl3', thickness => 500,
    rate => 800, concentration => 2, agitation => 1.5 );
is( $conc->vertical_rate, 800 * 2 * 1.5, 'concentration*agitation scaling' );

# --- Selectivity / mask survival -------------------------------------------
my $masked = Physics::Etch::WetEtch->new(
    target => 'copper', etchant => 'FeCl3', thickness => 500, rate => 800,
    mask => 'photoresist', mask_thickness => 100, sel_mask => 80, overetch => 0 );
is( $masked->mask_etch_rate, 800 / 80, 'mask etch rate = rate/selectivity' );
ok( $masked->mask_survives, 'thick mask survives' );

done_testing;
