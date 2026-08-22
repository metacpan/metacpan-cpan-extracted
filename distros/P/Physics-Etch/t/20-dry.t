use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch::DryEtch;

# --- Nominal dry etch ------------------------------------------------------
my $d = Physics::Etch::DryEtch->new(
    target     => 'silicon_nitride',
    etchant    => 'CF4/O2',
    thickness  => 200,
    rate       => 120,
    anisotropy => 0.90,
    feature_cd => 250,
    overetch   => 0.0,
);

is( $d->process_type, 'Dry', 'process_type' );

# with no knobs supplied, all factors are 1 -> nominal rate
is( $d->vertical_rate, 120, 'vertical rate = nominal when no knobs set' );

# anisotropic: lateral < vertical, A ~ nominal
ok( $d->lateral_rate < $d->vertical_rate, 'anisotropic lateral < vertical' );
ok( abs( $d->anisotropy - 0.90 ) < 1e-9, 'nominal anisotropy' );
is( $d->lateral_rate, 120 * ( 1 - 0.90 ), 'lateral = v*(1-A)' );

# near-vertical sidewalls for high anisotropy
my $p = $d->profile( $d->etch_time );
ok( $p->{sidewall_angle} > 80, 'high-A dry etch has steep sidewalls' );

# --- Process-knob scaling --------------------------------------------------
# higher power -> faster
my $hi_pwr = Physics::Etch::DryEtch->new(
    target => 'x', etchant => 'y', thickness => 200, rate => 120,
    power => 400, power_nom => 200 );
ok( $hi_pwr->vertical_rate > 120, 'higher power increases rate' );
is( $hi_pwr->power_factor, ( 400 / 200 )**0.8, 'power factor exponent' );

# higher pressure + lower bias -> less anisotropic (more undercut)
my $iso = Physics::Etch::DryEtch->new(
    target => 'x', etchant => 'y', thickness => 200, rate => 120,
    anisotropy => 0.90, pressure => 80, pressure_nom => 20,
    bias => 50, bias_nom => 200 );
ok( $iso->anisotropy < $d->anisotropy,
    'high pressure / low bias reduces anisotropy' );

# --- Thermal (hot) dry etch ------------------------------------------------
my $cold = Physics::Etch::DryEtch->new(
    target => 'copper', etchant => 'Cl2', thickness => 300, rate => 60,
    Ea => 0.7, ref_temp => 25, temperature => 25 );
my $warm = Physics::Etch::DryEtch->new(
    target => 'copper', etchant => 'Cl2', thickness => 300, rate => 60,
    Ea => 0.7, ref_temp => 25, temperature => 250 );
ok( $warm->vertical_rate > $cold->vertical_rate,
    'thermal dry etch: hotter is faster' );

# --- Substrate over-etch ---------------------------------------------------
my $sub = Physics::Etch::DryEtch->new(
    target => 'silicon_nitride', etchant => 'CF4', thickness => 200, rate => 120,
    substrate => 'silicon', sel_substrate => 4, overetch => 0.25 );
my $over = $sub->substrate_overetch;
ok( $over > 0, 'over-etch cuts into substrate' );
# 25% over-etch time * (rate/selectivity)
my $expect = ( $sub->etch_time - $sub->time_to_clear ) * ( 120 / 4 );
ok( abs( $over - $expect ) < 1e-6, 'substrate over-etch depth correct' );

done_testing;
