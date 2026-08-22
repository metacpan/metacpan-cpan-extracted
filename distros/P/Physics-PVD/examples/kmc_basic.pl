#!/usr/bin/perl
# Example: Basic KMC film growth of Ta on a substrate
use strict;
use warnings;
use lib '../lib';
use Physics::PVD;

# Create PVD simulation at 600K substrate temperature
my $pvd = Physics::PVD->new(
    temperature => 600,    # K
    pressure    => 5e-3,   # Pa (5 mTorr Ar)
    verbose     => 1,
);

# Initialize KMC engine with a 20×20×20 lattice (small for fast demo)
my $kmc = $pvd->kmc(
    lattice_size => [20, 20, 20],
    lattice_type => 'bcc',       # Ta is BCC
    lattice_const => 3.3,        # Angstrom
);

# Define depositing species
$kmc->add_species(
    name            => 'Ta',
    mass            => 180.95,         # amu
    binding_energy  => 8.1,            # eV
    diffusion_barrier => 0.7,          # eV (surface hopping)
    sticking_coeff  => 0.95,           # high sticking probability
);

# Set kinetic parameters
$kmc->set_rates(
    diffusion    => 0.7,    # eV barrier for surface diffusion
    es_barrier   => 0.15,   # Ehrlich-Schwoebel step-edge barrier
    attempt_freq => 1e13,   # Debye frequency (Hz)
);

# Deposit at 1×10¹⁵ atoms/cm²/s flux (high rate), normal incidence
# Use explicit steps for quick demo (~800 atoms = ~2 monolayers on 20×20)
$kmc->deposit(
    flux  => 1e15,          # atoms/cm²/s (high rate sputtering)
    angle => 0,             # normal incidence
    steps => 800,           # deposit 800 atoms explicitly
);

# Analyze the film
my $film = $kmc->get_film;
my $stats = $kmc->stats;

printf "\n═══ KMC Simulation Results ═══\n";
printf "  Simulation time:  %.3e s\n", $stats->{time};
printf "  Total steps:      %d\n", $stats->{steps};
printf "  Atoms deposited:  %d\n", $stats->{deposited};
printf "  Surface coverage: %.1f%%\n", $stats->{coverage} * 100;
printf "\n  Film thickness:   %.2f nm\n", $film->thickness;
printf "  RMS roughness:    %.3f nm\n", $film->roughness;
printf "  Film density:     %.1f%%\n", $film->density * 100;
printf "  Porosity:         %.1f%%\n", $film->porosity * 100;

# Export to XYZ for visualization
my $n_exported = $film->export_xyz('ta_film.xyz');
printf "\n  Exported %d atoms to ta_film.xyz\n", $n_exported;
printf "  (Open with OVITO, VMD, or ASE for visualization)\n";
