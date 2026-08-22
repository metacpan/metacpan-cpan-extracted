#!/usr/bin/perl
# Example: LPCVD Silicon Oxide (SiO₂) from TEOS precursor
#
# Process: Si(OC₂H₅)₄ → SiO₂ + byproducts at 680°C, 40 Pa
# This simulates TEOS-based thermal CVD for interlayer dielectric (ILD)

use strict;
use warnings;
use lib '../lib';
use Physics::CVD;

print "═══════════════════════════════════════════════════════════════\n";
print "  LPCVD SiO₂ from TEOS — Thermal Decomposition\n";
print "  Process: TEOS → SiO₂ + 4C₂H₄ + 2H₂O\n";
print "═══════════════════════════════════════════════════════════════\n\n";

# ─── Setup CVD system ─────────────────────────────────────────────────────────
my $cvd = Physics::CVD->new(
    temperature => 953,     # K (680°C — typical TEOS LPCVD)
    pressure    => 40,      # Pa (300 mTorr)
    verbose     => 1,
);

# ─── Define reactor ───────────────────────────────────────────────────────────
my $reactor = $cvd->reactor(
    type        => 'lpcvd_tube',
    length      => 1.2,         # m
    diameter    => 0.15,        # m (6" tube)
    total_flow  => 150,         # sccm
    carrier_gas => 'N2',
);

printf "  Reactor: LPCVD hot-wall tube\n";
printf "  Gas velocity:    %.2f m/s\n", $reactor->gas_velocity;
printf "  Residence time:  %.3f s\n", $reactor->residence_time;
printf "  Reynolds number: %.1f\n", $reactor->reynolds_number;
printf "  Knudsen number:  %.4f\n", $reactor->knudsen_number;
printf "  Mean free path:  %.2e m\n", $reactor->mean_free_path;
print "\n";

# ─── Gas-phase chemistry ──────────────────────────────────────────────────────
my $chem = $cvd->chemistry;

$chem->add_species(name => 'TEOS', mass => 208.3, formula => 'Si(OC2H5)4',
                   concentration => 1e16);  # molecules/cm³
$chem->add_species(name => 'O2',   mass => 32, concentration => 5e16);
$chem->add_species(name => 'SiOH2', mass => 62, formula => 'Si(OH)2');
$chem->add_species(name => 'C2H4', mass => 28);
$chem->add_species(name => 'H2O',  mass => 18);

# TEOS thermal decomposition (gas phase)
$chem->add_gas_reaction(
    name      => 'TEOS_decomp',
    reactants => ['TEOS'],
    products  => ['SiOH2', 'C2H4'],
    A         => 1.0e15,      # 1/s
    Ea        => 2.9,         # eV (~280 kJ/mol)
);

# Compute gas-phase rate constant
my $k_decomp = $chem->rate_constant(A => 1e15, Ea => 2.9);
printf "  Gas-phase TEOS decomposition:\n";
printf "    k(%.0f K) = %.3e 1/s\n", 953, $k_decomp;
printf "    Ea = 2.9 eV (280 kJ/mol)\n";

# Impingement flux of TEOS on wafer
my $flux_teos = $chem->impingement_flux(
    pressure => 4.0,    # Pa (partial pressure of TEOS)
    mass     => 208.3,
);
printf "    TEOS flux on surface: %.3e molecules/cm²/s\n\n", $flux_teos;

# ─── Surface KMC simulation ──────────────────────────────────────────────────
print "  Running surface KMC growth simulation...\n";
my $kmc = $cvd->kmc(
    lattice_size  => [25, 25, 15],
    lattice_const => 3.2,         # Å (approx SiO₂ tetrahedral spacing)
);

# Silicon-containing intermediate (surface-active)
$kmc->add_species(
    name              => 'Si',
    mass              => 28,
    sticking_coeff    => 0.04,         # TEOS sticking is low
    diffusion_barrier => 0.8,          # eV
    desorption_energy => 4.5,          # eV (strong Si-O bond)
    partial_pressure  => 4.0,          # Pa
);

# Oxygen from TEOS decomposition (incorporated simultaneously)
$kmc->add_species(
    name              => 'O',
    mass              => 16,
    sticking_coeff    => 0.08,
    diffusion_barrier => 0.6,          # eV
    desorption_energy => 3.0,          # eV
    partial_pressure  => 8.0,          # Pa (excess O from TEOS + O₂)
);

# Surface reaction: Si + 2O → SiO₂ (film incorporation)
$kmc->add_surface_reaction(
    reactants => ['Si', 'O'],
    products  => ['SiO2'],
    barrier   => 0.3,    # eV (low barrier, thermally activated)
    name      => 'oxidation',
);

# Deposit for ~500 monolayers worth of attempts
$kmc->deposit(steps => 1200);

# ─── Film analysis ────────────────────────────────────────────────────────────
my $film = $kmc->get_film;
my $stats = $kmc->stats;

printf "\n═══ LPCVD SiO₂ Film Results ═══\n";
printf "  Simulation time:  %.3e s\n", $stats->{time};
printf "  Total events:     %d\n", $stats->{steps};
printf "  Atoms deposited:  %d\n", $stats->{deposited};
printf "  Surface coverage: %.1f%%\n", $stats->{coverage} * 100;
printf "\n";
printf "  Film thickness:   %.2f nm\n", $film->thickness;
printf "  RMS roughness:    %.3f nm\n", $film->roughness;
printf "  Film density:     %.1f%%\n", $film->density * 100;
printf "  Porosity:         %.1f%%\n\n", $film->porosity * 100;

# Composition
my $comp = $film->composition;
printf "  Composition:\n";
for my $sp (sort keys %{$comp->{fractions}}) {
    printf "    %-6s: %5.1f%%\n", $sp, $comp->{fractions}{$sp} * 100;
}
printf "  Si:O ratio: %.2f (ideal: 0.50 for SiO₂)\n",
    $film->stoichiometry('Si', 'O');

# ─── Transport and step coverage ─────────────────────────────────────────────
printf "\n═══ Feature-Scale Transport ═══\n";
my $transport = $cvd->transport(
    feature_type  => 'trench',
    aspect_ratio  => 5.0,
    feature_width => 0.1e-4,   # 100 nm
);

my $D_eff = $transport->effective_diffusivity(
    D_bulk => $reactor->diffusivity(mass2 => 208.3),
    mass   => 208.3,
);
printf "  Feature: 100nm trench, AR=5:1\n";
printf "  Knudsen diffusivity: %.3e cm²/s\n", $transport->knudsen_diffusivity(mass => 208.3);
printf "  Effective diffusivity: %.3e cm²/s\n", $D_eff;
printf "  Step coverage: %.1f%%\n", $transport->step_coverage(sticking_coeff => 0.04) * 100;

# Sweep sticking coefficients
printf "\n  Step coverage vs sticking coefficient:\n";
printf "    %-10s  %s\n", "S (stick)", "SC (%)";
for my $S (0.001, 0.01, 0.04, 0.1, 0.5, 1.0) {
    my $sc = $transport->step_coverage(sticking_coeff => $S);
    printf "    %-10.3f  %.1f%%\n", $S, $sc * 100;
}

# Growth rate estimate
my $gr = $chem->growth_rate(
    flux         => $flux_teos,
    sticking     => 0.04,
    film_density => 2.2e22,  # SiO₂ molecular density
);
printf "\n  Estimated growth rate: %.1f nm/min\n", $gr;

# Export
my $n = $film->export_xyz('sio2_film.xyz');
printf "\n  Exported %d atoms to sio2_film.xyz\n", $n;
print "  (Open with OVITO or VMD for visualization)\n";
