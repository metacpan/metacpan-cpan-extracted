#!/usr/bin/perl
# Example: LPCVD Silicon Nitride (Si₃N₄) from DCS + NH₃
#
# Process: 3 SiH₂Cl₂ + 4 NH₃ → Si₃N₄ + 6 HCl + 6 H₂ at 780°C, 25 Pa
# This simulates stoichiometric LPCVD Si₃N₄ for diffusion barriers

use strict;
use warnings;
use lib '../lib';
use Physics::CVD;

print "═══════════════════════════════════════════════════════════════\n";
print "  LPCVD Si₃N₄ from Dichlorosilane + Ammonia\n";
print "  Process: 3SiH₂Cl₂ + 4NH₃ → Si₃N₄ + 6HCl + 6H₂\n";
print "═══════════════════════════════════════════════════════════════\n\n";

# ─── Setup CVD system ─────────────────────────────────────────────────────────
my $cvd = Physics::CVD->new(
    temperature => 1053,    # K (780°C — standard LPCVD Si₃N₄)
    pressure    => 25,      # Pa (180 mTorr)
    verbose     => 1,
);

# ─── Define reactor ───────────────────────────────────────────────────────────
my $reactor = $cvd->reactor(
    type        => 'lpcvd_tube',
    length      => 1.5,         # m (longer tube for batch)
    diameter    => 0.15,        # m
    total_flow  => 200,         # sccm (DCS:NH₃ = 1:4 ratio)
    carrier_gas => 'N2',
);

printf "  Reactor: LPCVD hot-wall tube (batch, 150 wafers)\n";
printf "  Temperature: 780°C (1053 K)\n";
printf "  Pressure:    25 Pa (180 mTorr)\n";
printf "  Gas velocity:    %.2f m/s\n", $reactor->gas_velocity;
printf "  Residence time:  %.3f s\n", $reactor->residence_time;
printf "  Reynolds number: %.1f\n", $reactor->reynolds_number;
printf "  Mean free path:  %.2e m\n", $reactor->mean_free_path;
printf "  Knudsen number:  %.4f (continuum flow in tube)\n", $reactor->knudsen_number;
print "\n";

# ─── Gas-phase chemistry ──────────────────────────────────────────────────────
my $chem = $cvd->chemistry;

# Precursors
$chem->add_species(name => 'DCS', mass => 101, formula => 'SiH2Cl2',
                   concentration => 5e15);
$chem->add_species(name => 'NH3', mass => 17, formula => 'NH3',
                   concentration => 2e16);
# Intermediates
$chem->add_species(name => 'SiCl2', mass => 99);
$chem->add_species(name => 'NH2',   mass => 16);
$chem->add_species(name => 'SiNH',  mass => 43, formula => 'SiH2NH');
# Byproducts
$chem->add_species(name => 'HCl', mass => 36.5);
$chem->add_species(name => 'H2',  mass => 2);

# Gas-phase reactions
$chem->add_gas_reaction(
    name      => 'DCS_decomp',
    reactants => ['DCS'],
    products  => ['SiCl2', 'H2'],
    A         => 5e13,
    Ea        => 2.5,       # eV (~240 kJ/mol)
);

$chem->add_gas_reaction(
    name      => 'aminosilane_formation',
    reactants => ['SiCl2'],
    products  => ['SiNH', 'HCl'],
    A         => 1e12,
    Ea        => 1.0,       # eV (~100 kJ/mol)
);

# Rate constants at process temperature
printf "  Gas-phase kinetics at 780°C:\n";
my $k1 = $chem->rate_constant(A => 5e13, Ea => 2.5);
my $k2 = $chem->rate_constant(A => 1e12, Ea => 1.0);
printf "    DCS decomposition:    k = %.3e 1/s\n", $k1;
printf "    Aminosilane formation: k = %.3e 1/s\n", $k2;

# Fluxes
my $flux_dcs = $chem->impingement_flux(pressure => 5.0, mass => 101);
my $flux_nh3 = $chem->impingement_flux(pressure => 20.0, mass => 17);
printf "    DCS flux:  %.3e cm⁻²s⁻¹\n", $flux_dcs;
printf "    NH₃ flux:  %.3e cm⁻²s⁻¹\n\n", $flux_nh3;

# ─── Surface KMC simulation ──────────────────────────────────────────────────
print "  Running surface KMC growth simulation...\n";
my $kmc = $cvd->kmc(
    lattice_size  => [30, 30, 20],
    lattice_const => 2.6,         # Å (Si₃N₄ bond length scale)
);

# Silicon from DCS (high sticking on Si₃N₄ surface)
$kmc->add_species(
    name              => 'Si',
    mass              => 28,
    sticking_coeff    => 0.3,          # DCS/SiCl₂ sticking is high
    diffusion_barrier => 1.0,          # eV (less mobile)
    desorption_energy => 5.0,          # eV
    partial_pressure  => 5.0,          # Pa
    is_precursor      => 1,
    decomposition_barrier => 1.5,
    decomp_products   => ['Si'],       # SiCl₂ → Si + Cl₂(g)
);

# Nitrogen from NH₃
$kmc->add_species(
    name              => 'N',
    mass              => 14,
    sticking_coeff    => 0.1,          # NH₃ lower sticking
    diffusion_barrier => 0.7,          # eV
    desorption_energy => 3.5,          # eV
    partial_pressure  => 20.0,         # Pa (excess NH₃)
    is_precursor      => 1,
);

# Surface nitridation reaction: Si + N → Si₃N₄ lattice site
$kmc->add_surface_reaction(
    reactants => ['Si', 'N'],
    products  => ['Si3N4'],
    barrier   => 0.4,    # eV
    name      => 'nitridation',
);

# Deposit (more steps for thicker film, higher sticking = faster growth)
$kmc->deposit(steps => 1500);

# ─── Film analysis ────────────────────────────────────────────────────────────
my $film = $kmc->get_film;
my $stats = $kmc->stats;

printf "\n═══ LPCVD Si₃N₄ Film Results ═══\n";
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
    printf "    %-8s: %5.1f%%\n", $sp, $comp->{fractions}{$sp} * 100;
}
my $si_n_ratio = $film->stoichiometry('Si', 'N');
printf "\n  Si:N ratio: %.2f (ideal: 0.75 for Si₃N₄)\n", $si_n_ratio;

# Compare to ideal stoichiometry
if ($si_n_ratio > 0.75) {
    printf "  → Si-rich film (higher etch rate in HF)\n";
} elsif ($si_n_ratio < 0.75) {
    printf "  → N-rich film (higher tensile stress)\n";
} else {
    printf "  → Stoichiometric Si₃N₄\n";
}

# ─── Transport and step coverage ─────────────────────────────────────────────
printf "\n═══ Feature-Scale Transport ═══\n";
my $transport = $cvd->transport(
    feature_type  => 'trench',
    aspect_ratio  => 3.0,       # moderate AR for Si₃N₄ liner
    feature_width => 0.2e-4,    # 200 nm
);

printf "  Feature: 200nm trench, AR=3:1\n";
printf "  Si₃N₄ is reaction-limited → excellent conformality\n\n";

# Compare DCS vs NH₃ step coverage
my $sc_dcs = $transport->step_coverage(sticking_coeff => 0.3);
my $sc_nh3 = $transport->step_coverage(sticking_coeff => 0.1);
printf "  Step coverage (DCS, S=0.3): %.1f%%\n", $sc_dcs * 100;
printf "  Step coverage (NH₃, S=0.1): %.1f%%\n", $sc_nh3 * 100;
printf "  → Film limited by Si supply at feature bottom\n";

# Conformality profile
my $profile = $transport->conformality_profile(
    sticking_coeff => 0.3,
    aspect_ratio   => 3.0,
    points         => 10,
);
printf "\n  Conformality profile (DCS):\n";
printf "    %-8s  %-15s\n", "Depth", "Relative Rate";
for my $pt (@$profile) {
    my $bar = '█' x int($pt->{flux_ratio} * 30);
    printf "    %.1f      %.3f  %s\n", $pt->{position}, $pt->{flux_ratio}, $bar;
}

# Growth rate
my $gr = $chem->growth_rate(
    flux         => $flux_dcs,
    sticking     => 0.3,
    film_density => 2.8e22,  # Si₃N₄ molecular density
);
printf "\n  Estimated growth rate: %.1f nm/min\n", $gr;
printf "  (Literature: 3-5 nm/min for LPCVD Si₃N₄ at 780°C)\n";

# Damköhler number
my $D_gas = $reactor->diffusivity(mass2 => 101);
my $Da = $reactor->damkohler_number(surface_rate => 0.1);
printf "\n  Damköhler number: %.2f\n", $Da;
printf "  Regime: %s\n", ($Da < 1) ? "Reaction-limited (good uniformity)"
                                    : "Mixed/transport-limited";

# Export
my $n = $film->export_xyz('si3n4_film.xyz');
printf "\n  Exported %d atoms to si3n4_film.xyz\n", $n;
print "  (Open with OVITO or VMD for visualization)\n";
