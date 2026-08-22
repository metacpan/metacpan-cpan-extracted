use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch::Chamber;

my $ch = Physics::Etch::Chamber->new(
    wafer_diameter_mm => 150,
    powered_area_cm2  => 177,
    grounded_area_cm2 => 531,
    gap_cm            => 3,
    volume_l          => 10,
    pressure_mtorr    => 20,
    power_w           => 200,
    flow_sccm         => 50,
);

ok( abs( $ch->area_ratio - 3 ) < 1e-6, 'area ratio 3:1' );
ok( $ch->residence_time_s > 0, 'residence time positive' );
ok( $ch->mean_free_path_m > 0, 'mean free path positive' );
ok( $ch->knudsen > 0,          'Knudsen positive' );
ok( $ch->self_bias_v > 0,      'self bias positive' );
is( $ch->ion_energy_ev, $ch->self_bias_v + $ch->plasma_potential_v,
    'ion energy = bias + plasma potential' );

# --- monotonic trends ------------------------------------------------------
# higher power -> higher bias
my $hp = Physics::Etch::Chamber->new(
    powered_area_cm2 => 177, grounded_area_cm2 => 531, power_w => 500, pressure_mtorr => 20 );
ok( $hp->self_bias_v > $ch->self_bias_v, 'higher power -> higher bias' );

# higher pressure -> lower bias and shorter mean free path
my $hpr = Physics::Etch::Chamber->new(
    powered_area_cm2 => 177, grounded_area_cm2 => 531, power_w => 200, pressure_mtorr => 100 );
ok( $hpr->self_bias_v < $ch->self_bias_v,       'higher pressure -> lower bias' );
ok( $hpr->mean_free_path_m < $ch->mean_free_path_m, 'higher pressure -> shorter mfp' );

# more electrode asymmetry -> higher bias
my $sym = Physics::Etch::Chamber->new(
    powered_area_cm2 => 177, grounded_area_cm2 => 177, power_w => 200, pressure_mtorr => 20 );
ok( $sym->self_bias_v < $ch->self_bias_v, 'symmetric electrodes -> lower bias' );

# higher flow -> shorter residence time
my $flow = Physics::Etch::Chamber->new(
    powered_area_cm2 => 177, volume_l => 10, pressure_mtorr => 20, flow_sccm => 200 );
my $flow0 = Physics::Etch::Chamber->new(
    powered_area_cm2 => 177, volume_l => 10, pressure_mtorr => 20, flow_sccm => 50 );
ok( $flow->residence_time_s < $flow0->residence_time_s,
    'higher flow -> shorter residence time' );

# process_conditions hands back pressure + bias
my %c = $ch->process_conditions;
is( $c{pressure}, 20, 'process_conditions pressure' );
ok( $c{bias} > 0,     'process_conditions bias' );

like( $ch->report, qr/CHAMBER/, 'chamber report renders' );

done_testing;
