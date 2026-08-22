#!/usr/bin/env perl
#
# Chamber geometry input: how reactor geometry and operating point set the
# plasma conditions (DC bias, ion energy, mean free path, residence time) that
# the etch model consumes -- and how those propagate to rate and anisotropy.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### CHAMBER GEOMETRY -> ETCH CONDITIONS ###\n\n";

# A baseline reactor
my $chamber = Physics::Etch->chamber(
    reactor_type   => 'CCP-RIE',
    wafer_diameter_mm => 150,
    powered_area_cm2  => 177,      # ~150 mm electrode
    grounded_area_cm2 => 530,      # asymmetric (walls + lid)
    gap_cm         => 3.0,
    volume_l       => 10,
    pressure_mtorr => 20,
    power_w        => 200,
    flow_sccm      => 50,
    gas            => 'CF4', gas_mass_amu => 88, gas_diameter_m => 4.7e-10,
);
print $chamber->report, "\n";

# Feed the chamber conditions straight into a nitride etch
my %cond = $chamber->process_conditions;
my $etch = Physics::Etch->dry_etch( 'silicon_nitride',
    thickness => 200, feature_cd => 300, %cond,
    mask => 'photoresist', mask_thickness => 700 );
printf "Chamber sets pressure=%.0f mTorr, bias=%.0f V -> rate %.0f nm/min, A=%.3f\n\n",
    $cond{pressure}, $cond{bias}, $etch->vertical_rate, $etch->anisotropy;

# --- Geometry / operating sweeps -------------------------------------------
print "Effect of chamber knobs on bias, ion energy, mfp, and etch anisotropy:\n";
printf "  %-26s %-8s %-9s %-9s %-8s\n",
    'condition', 'bias V', 'ion eV', 'mfp mm', 'aniso';

my @cases = (
    [ 'baseline',              {} ],
    [ 'low pressure  (5 mTorr)',  { pressure_mtorr => 5 } ],
    [ 'high pressure (100 mTorr)', { pressure_mtorr => 100 } ],
    [ 'high power    (500 W)',     { power_w => 500 } ],
    [ 'symmetric electrodes',      { grounded_area_cm2 => 177 } ],
    [ 'more asymmetric (6x)',      { grounded_area_cm2 => 1062 } ],
);

for my $case (@cases) {
    my ( $label, $ov ) = @$case;
    my $ch = Physics::Etch->chamber(
        wafer_diameter_mm => 150, powered_area_cm2 => 177,
        grounded_area_cm2 => 530, gap_cm => 3.0, volume_l => 10,
        pressure_mtorr => 20, power_w => 200, flow_sccm => 50,
        gas => 'CF4', gas_mass_amu => 88, gas_diameter_m => 4.7e-10, %$ov );
    my %c = $ch->process_conditions;
    my $e = Physics::Etch->dry_etch( 'silicon_nitride',
        thickness => 200, feature_cd => 300, %c );
    printf "  %-26s %-8.0f %-9.0f %-9.2f %-8.3f\n",
        $label, $ch->self_bias_v, $ch->ion_energy_ev,
        $ch->mean_free_path_mm, $e->anisotropy;
}

print "\n=> Lower pressure & higher asymmetry raise bias/ion energy and lengthen\n",
    "   the mean free path -> more directional ions -> higher anisotropy.\n";
