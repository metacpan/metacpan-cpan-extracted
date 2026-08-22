#!/usr/bin/perl
# Example: Hybrid DSMC + KMC simulation for realistic PVD
# DSMC computes vapor transport → feeds angular/energy distributions into KMC
use strict;
use warnings;
use lib '../lib';
use Physics::PVD;

my $pvd = Physics::PVD->new(
    method      => 'hybrid',
    temperature => 400,
    pressure    => 1.5,    # Pa
    verbose     => 1,
);

# ─── Step 1: DSMC Transport ──────────────────────────────────────────────────
print "═══ Phase 1: DSMC Vapor Transport ═══\n\n";

my $dsmc = $pvd->dsmc(
    n_particles     => 3000,
    target_material => 'Ta',
    target_mass     => 180.95,
    surface_binding => 8.1,
    target_diameter => 0.075,       # 75 mm target
    substrate_distance => 0.05,     # 50 mm throw
    cosine_power    => 1,
    gas_species     => 'Ar',
    gas_mass        => 39.948,
    pressure        => 1.5,
    temperature     => 300,
);

$dsmc->run(timesteps => 2000);
my $flux_dist = $dsmc->get_flux_distribution;
my $dsmc_stats = $dsmc->stats;

printf "  Transport efficiency: %.1f%%\n",
       100 * $dsmc_stats->{arrived} / $dsmc_stats->{total_particles};
printf "  Mean arrival energy: %.2f eV\n", $dsmc_stats->{mean_energy_eV};
printf "  Knudsen number: %.2f\n\n", $dsmc_stats->{knudsen_number};

# ─── Step 2: KMC Film Growth with DSMC flux input ────────────────────────────
print "═══ Phase 2: KMC Film Growth ═══\n\n";

my $kmc = $pvd->kmc(
    lattice_size  => [60, 60, 40],
    lattice_type  => 'bcc',
    lattice_const => 3.3,
    temperature   => 400,
);

$kmc->add_species(
    name            => 'Ta',
    mass            => 180.95,
    binding_energy  => 8.1,
    diffusion_barrier => 0.7,
    sticking_coeff  => 0.95,
);

# Feed DSMC angular distribution into KMC
$kmc->set_angular_distribution($flux_dist);

# Run growth
$kmc->deposit(flux => 5e13, time => 60);

# ─── Results ──────────────────────────────────────────────────────────────────
print "\n═══ Final Film Properties ═══\n\n";

my $film = $kmc->get_film;
my $summary = $film->summary;

printf "  Thickness:  %.2f nm\n", $summary->{thickness_nm};
printf "  Roughness:  %.3f nm\n", $summary->{roughness_nm};
printf "  Density:    %.1f%%\n", $summary->{density} * 100;
printf "  Atoms:      %d\n", $summary->{n_atoms};

# Export for external visualization
$film->export_xyz('hybrid_ta_film.xyz');
$film->export_lammps_data('hybrid_ta_film.data');
print "\n  Exported: hybrid_ta_film.xyz, hybrid_ta_film.data\n";
