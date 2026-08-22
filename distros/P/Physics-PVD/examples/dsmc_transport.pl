#!/usr/bin/perl
# Example: DSMC vapor transport simulation — Ta sputtering through Ar gas
use strict;
use warnings;
use lib '../lib';
use Physics::PVD;

# Create PVD simulation
my $pvd = Physics::PVD->new(
    temperature => 300,
    pressure    => 2.0,     # Pa (15 mTorr) — transitional regime
    verbose     => 1,
);

# Initialize DSMC engine
my $dsmc = $pvd->dsmc(
    domain      => [0.10, 0.10, 0.06],  # 10cm × 10cm × 6cm chamber
    n_cells     => [40, 40, 20],
    n_particles => 5000,

    # Background gas
    gas_species    => 'Ar',
    gas_mass       => 39.948,       # amu
    pressure       => 2.0,          # Pa
    temperature    => 300,          # K

    # Sputtering target (Ta)
    target_material => 'Ta',
    target_mass     => 180.95,      # amu
    target_diameter => 0.05,        # 5 cm diameter target
    surface_binding => 8.1,         # eV

    # Emission characteristics
    cosine_power    => 1,           # cos(θ) distribution
    sputter_yield   => 0.6,

    # Target-substrate geometry
    substrate_distance => 0.04,     # 4 cm throw distance
);

# Run transport simulation
$dsmc->run(timesteps => 3000);

# Get results
my $stats = $dsmc->stats;
printf "\n═══ DSMC Transport Results ═══\n";
printf "  Particles emitted:     %d\n", $stats->{total_particles};
printf "  Arrived at substrate:  %d (%.1f%%)\n",
       $stats->{arrived}, 100*$stats->{arrived}/$stats->{total_particles};
printf "  Still in flight:       %d\n", $stats->{still_flying};
printf "  Mean arrival energy:   %.2f eV\n", $stats->{mean_energy_eV};
printf "  Knudsen number:        %.2f\n", $stats->{knudsen_number};

if ($stats->{knudsen_number} > 10) {
    print "  Regime: Free-molecular (ballistic transport)\n";
} elsif ($stats->{knudsen_number} > 0.1) {
    print "  Regime: Transitional (partial thermalization)\n";
} else {
    print "  Regime: Continuum (fully thermalized)\n";
}

# Analyze flux uniformity
my $flux = $dsmc->get_flux_distribution;
my $energy_dist = $dsmc->get_energy_distribution;
my $angle_dist  = $dsmc->get_angular_distribution;

# Simple uniformity metric
my ($total_flux, $n_cells, $max_flux) = (0, 0, 0);
for my $row (@$flux) {
    for my $val (@$row) {
        $total_flux += $val;
        $n_cells++;
        $max_flux = $val if $val > $max_flux;
    }
}
my $mean_flux = $total_flux / $n_cells;
printf "\n  Flux uniformity:\n";
printf "    Mean: %.1f particles/cell\n", $mean_flux;
printf "    Max:  %.0f particles/cell\n", $max_flux;
printf "    Uniformity (mean/max): %.1f%%\n", 100*$mean_flux/$max_flux if $max_flux;

# Energy distribution summary
if (@$energy_dist) {
    my @sorted_E = sort { $a <=> $b } @$energy_dist;
    printf "\n  Energy distribution:\n";
    printf "    Median: %.2f eV\n", $sorted_E[int(@sorted_E/2)];
    printf "    P10:    %.2f eV\n", $sorted_E[int(@sorted_E*0.1)];
    printf "    P90:    %.2f eV\n", $sorted_E[int(@sorted_E*0.9)];
}
