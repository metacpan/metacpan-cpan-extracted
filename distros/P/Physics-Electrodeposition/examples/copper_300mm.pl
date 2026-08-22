#!/usr/bin/env perl
#
# copper_300mm.pl - Model electrodeposition of copper on a 300 mm wafer.
#
# Run:  perl -Ilib examples/copper_300mm.pl
#
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Physics::Electrodeposition;

#-----------------------------------------------------------------------------
# Recipe: 1.0 um blanket copper on a 300 mm wafer from an acid Cu-sulfate bath
# with a soluble (phosphorized) copper anode and an organic additive package
# (suppressor + accelerator + leveler), plated galvanostatically at 20 mA/cm^2.
#-----------------------------------------------------------------------------
my $cu = Physics::Electrodeposition->new(
    metal            => 'Copper',
    molar_mass       => 63.546,     # g/mol
    valence          => 2,          # Cu2+ + 2e- -> Cu
    density          => 8.96,       # g/cm^3
    E0               => 0.337,      # V vs SHE

    # --- acid copper-sulfate bath ---
    ion_conc         => 0.28,       # M Cu2+  (~18 g/L Cu)
    acid_conc        => 1.8,        # M H2SO4 (~176 g/L)
    conductivity     => 0.54,       # S/cm
    diffusivity      => 7.2e-6,     # cm^2/s  (Cu2+)
    temperature      => 298.15,     # K (25 C)
    j0               => 1.0e-3,     # A/cm^2 exchange current density
    alpha            => 0.5,        # cathodic transfer coefficient
    additive_drop    => 0.20,       # V suppressor/leveler kinetic drop
    additive_use     => 5.0,        # mL per kA*h organic consumption

    # --- 300 mm plating tool geometry ---
    wafer_diameter   => 300,        # mm
    electrode_gap    => 5.0,        # cm anode-cathode spacing
    seed_thickness   => 60,         # nm PVD Cu seed
    seed_resistivity => 1.90e-6,    # Ohm*cm (thin-film Cu)
    boundary_layer   => 0.010,      # cm (100 um) diffusion layer w/ agitation
    anode_type       => 'soluble',

    # --- recipe targets ---
    current_density  => 20,         # mA/cm^2
    target_thickness => 1.0,        # um  (module solves for plating time)
    efficiency       => 0.97,       # cathodic current efficiency
);

print $cu->report;

#-----------------------------------------------------------------------------
# Quick sensitivity sweep: how current density trades against time, power and
# smoothness for the same 1 um target.
#-----------------------------------------------------------------------------
print "\nSENSITIVITY: current density vs time / power / smoothness (1 um target)\n";
printf "%-10s %-10s %-10s %-12s %-10s %-s\n",
       "j[mA/cm2]", "time[s]", "V_cell[V]", "power[W]", "j/j_lim", "smoothness";
print '-' x 90, "\n";

for my $jd (5, 10, 20, 30, 40) {
    my $m = Physics::Electrodeposition->new(
        current_density  => $jd,
        target_thickness => 1.0,
    );
    printf "%-10d %-10.0f %-10.3f %-12.2f %-10.2f %-s\n",
        $jd,
        $m->process_time,
        $m->cell_voltage,
        $m->power,
        $m->current_fraction_of_limit,
        $m->smoothness_verdict;
}
print "\n";

#-----------------------------------------------------------------------------
# Process design: mitigate the 300 mm terminal effect. Compared to the baseline
# above, a production-style recipe uses a thicker/lower-Rs seed, a HIGH-
# resistance (high throwing-power) electrolyte, a gentle cold-entry current, and
# tighter mass transport. Show the improvement in within-wafer non-uniformity.
#-----------------------------------------------------------------------------
my $opt = Physics::Electrodeposition->new(
    metal            => 'Copper',
    wafer_diameter   => 300,
    seed_thickness   => 150,      # nm  thicker PVD/ALD-boosted seed
    conductivity     => 0.08,     # S/cm  high-resistance / high-throwing bath
    ion_conc         => 0.32,     # M    slightly richer to hold j_lim up
    boundary_layer   => 0.006,    # cm   stronger cross-wafer flow (60 um)
    electrode_gap    => 3.0,      # cm   closer, well-baffled gap
    current_density  => 7,        # mA/cm^2  gentle "cold-entry" plating
    target_thickness => 1.0,
    efficiency       => 0.98,
);

printf "PROCESS DESIGN: terminal-effect mitigation for 300 mm (uncompensated WIWNU)\n";
printf "%-22s %-12s %-12s\n", "recipe", "baseline", "optimized";
print '-' x 50, "\n";
printf "%-22s %-12s %-12s\n", "seed thickness [nm]",  $cu->{seed_thickness},  $opt->{seed_thickness};
printf "%-22s %-12s %-12s\n", "conductivity [S/cm]",  $cu->{conductivity},    $opt->{conductivity};
printf "%-22s %-12s %-12s\n", "current dens [mA/cm2]",$cu->{current_density}, $opt->{current_density};
printf "%-22s %-12.3f %-12.3f\n", "seed drop [V]",        $cu->terminal_effect_drop, $opt->terminal_effect_drop;
printf "%-22s %-12.2f %-12.2f\n", "terminal drive",       $cu->terminal_effect_ratio,$opt->terminal_effect_ratio;
printf "%-22s %-12.1f %-12.1f\n", "WIWNU [%]",            $cu->nonuniformity_percent,$opt->nonuniformity_percent;
printf "%-22s %-12.2f %-12.2f\n", "cell voltage [V]",     $cu->cell_voltage,         $opt->cell_voltage;
printf "%-22s %-12.1f %-12.1f\n", "plating time [s]",     $cu->process_time,         $opt->process_time;
print "\n";

