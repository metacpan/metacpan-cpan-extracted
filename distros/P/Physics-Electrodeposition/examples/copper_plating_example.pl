#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Physics::Electrodeposition::CopperPlating;

my $simulator = Physics::Electrodeposition::CopperPlating->new(
    seed_layer => {
        aluminum_nm => 300,
        titanium_nm => 50,
    },
    bath => {
        copper_sulfate_g_l => 200,
        sulfuric_acid_g_l  => 60,
        chloride_mg_l      => 50,
        suppressor         => 'PEG',
        accelerator        => 'SPS',
        leveler            => 'Janus Green B',
    },
);

print "Copper electroplating example for an Al/Ti seed layer\n";
print "===================================================\n\n";
print "Process notes\n";
print "-------------\n";
print "- Bath chemistry: 200 g/L CuSO4, 60 g/L H2SO4, 50 mg/L chloride, plus PEG suppressor, SPS accelerator, and Janus Green B leveler.\n";
print "- Seed layer: 300 nm Al with 50 nm Ti; this example assumes the surface oxide is removed before plating.\n";
print "- Pattern assumptions: compare copper studs against redistribution lines because the patterned area fraction changes the current load and the thickness uniformity.\n";
print "- Wafer sizes: 200 mm and 300 mm.\n";
print "- Voltage window: 0.85 V to 0.95 V in these examples, with the current estimated from the exposed patterned area.\n";
print "- Growth rate: calculated from Faraday-law scaling and reported in um/min.\n";
print "- Convection: low, medium, and high bath motion change ion replenishment, which shifts both growth rate and uniformity.\n";
print "- Uniformity expectation: studs are usually easier to plate uniformly than redistribution lines because RDL features expose more area and are more transport-limited.\n\n";

my @scenarios = (
    {
        wafer_diameter_mm   => 200,
        pattern_type        => 'studs',
        voltage_v           => 0.85,
        convection          => 'medium',
        target_thickness_um => 15,
    },
    {
        wafer_diameter_mm   => 200,
        pattern_type        => 'redistribution_lines',
        voltage_v           => 0.90,
        convection          => 'high',
        target_thickness_um => 8,
    },
    {
        wafer_diameter_mm   => 300,
        pattern_type        => 'studs',
        voltage_v           => 0.90,
        convection          => 'high',
        target_thickness_um => 20,
    },
    {
        wafer_diameter_mm   => 300,
        pattern_type        => 'redistribution_lines',
        voltage_v           => 0.95,
        convection          => 'high',
        target_thickness_um => 10,
    },
);

for my $scenario (@scenarios) {
    my $result = $simulator->simulate(%{$scenario});

    print "$result->{wafer_diameter_mm} mm wafer / $result->{pattern_type}\n";
    print "  Voltage: $result->{voltage_v} V\n";
    print "  Expected current: $result->{expected_current_a} A\n";
    print "  Growth rate: $result->{growth_rate_um_min} um/min\n";
    print "  Estimated plating time for $result->{target_thickness_um} um: $result->{estimated_plating_time_min} min\n";
    print "  Estimated uniformity: $result->{estimated_uniformity_percent} %\n";
    print "  Convection: $result->{convection}\n";

    for my $note (@{ $simulator->process_notes(%{$scenario}) }) {
        print "    note: $note\n";
    }

    print "\n";
}
