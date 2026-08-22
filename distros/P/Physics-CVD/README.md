# Physics::CVD — Chemical Vapor Deposition Simulation Framework

A Perl library for simulating Chemical Vapor Deposition (CVD) processes, including
gas-phase chemistry, surface kinetics, mass transport, and film growth modeling.

## Features

- **Gas-phase chemistry** — Arrhenius kinetics, reaction networks, precursor decomposition
- **Surface KMC** — Multi-species deposition-centric Kinetic Monte Carlo for film growth
- **Reactor modeling** — LPCVD/PECVD/MOCVD geometry, flow, Reynolds/Knudsen numbers
- **Mass transport** — Boundary layer, Knudsen diffusion, feature-scale step coverage
- **Film analysis** — Thickness, roughness, density, composition profiles, stoichiometry
- **Interface: OpenFOAM** — reactingFoam case generation for reactor-scale CFD
- **Interface: LAMMPS** — ReaxFF scripts for surface reaction MD
- **Interface: Cantera** — YAML mechanism files and Python reactor scripts

## Installation

```bash
cd Physics-CVD
perl Makefile.PL
make
make test
make install    # optional, installs system-wide
```

### Optional Dependencies

| Package | Purpose | Install |
|---------|---------|---------|
| OpenFOAM | Reactor-scale CFD | `sudo apt install openfoam` |
| LAMMPS | Surface reaction MD | `sudo apt install lammps` |
| Cantera | Detailed chemistry | `pip install cantera` |
| PDL | Numerical arrays | `cpanm PDL` |
| PDL::Graphics::Gnuplot | Plotting | `cpanm PDL::Graphics::Gnuplot` |

## Quick Start

```perl
use Physics::CVD;

my $cvd = Physics::CVD->new(
    temperature => 953,    # K (680°C)
    pressure    => 40,     # Pa
);

# Gas-phase chemistry
my $chem = $cvd->chemistry;
$chem->add_species(name => 'TEOS', mass => 208, concentration => 1e16);
$chem->add_gas_reaction(
    reactants => ['TEOS'], products => ['SiO2_g'],
    A => 1e15, Ea => 2.9,
);

# Surface growth simulation
my $kmc = $cvd->kmc(lattice_size => [30, 30, 15]);
$kmc->add_species(name => 'Si', sticking_coeff => 0.04,
                  partial_pressure => 4.0, diffusion_barrier => 0.8);
$kmc->deposit(steps => 1000);

# Analysis
my $film = $kmc->get_film;
printf "Thickness: %.2f nm\n", $film->thickness;
printf "Roughness: %.3f nm\n", $film->roughness;
```

## API Reference

### Physics::CVD (main module)

| Method | Description |
|--------|-------------|
| `new(%opts)` | Create CVD simulation (temperature, pressure, verbose) |
| `chemistry(%opts)` | Create Chemistry engine |
| `kmc(%opts)` | Create surface KMC engine |
| `reactor(%opts)` | Create Reactor model |
| `transport(%opts)` | Create Transport model |
| `film(%opts)` | Create Film analysis object |
| `interface($name, %opts)` | Load interface (openfoam, lammps, cantera) |

### Physics::CVD::Chemistry

| Method | Description |
|--------|-------------|
| `add_species(%spec)` | Add gas/surface species (name, mass, concentration) |
| `add_gas_reaction(%rxn)` | Add gas-phase reaction (Arrhenius: A, Ea) |
| `add_surface_reaction(%rxn)` | Add surface reaction (LH or ER mechanism) |
| `rate_constant(%opts)` | Compute k = A×exp(-Ea/kT) |
| `gas_rates()` | Compute all gas-phase reaction rates |
| `surface_rates(%opts)` | Compute surface reaction rates given coverages |
| `impingement_flux(%opts)` | Hertz-Knudsen flux (molecules/cm²/s) |
| `sticking_coefficient(%opts)` | Temperature-dependent S(T) |
| `evolve(%opts)` | Integrate chemistry over time (Euler) |
| `growth_rate(%opts)` | Estimate deposition rate (nm/min) |

### Physics::CVD::KMC

| Method | Description |
|--------|-------------|
| `new(%opts)` | Create KMC engine (lattice_size, lattice_const, temperature) |
| `add_species(%spec)` | Add depositing species (sticking, barriers, pressure) |
| `add_surface_reaction(%rxn)` | Add co-adsorbed species reaction |
| `deposit(%opts)` | Run deposition (steps or time) |
| `run(%opts)` | Run KMC steps directly |
| `get_film()` | Extract Film object from lattice |
| `coverage()` | Fraction of surface sites occupied |
| `stats()` | Simulation statistics |

### Physics::CVD::Reactor

| Method | Description |
|--------|-------------|
| `new(%opts)` | Create reactor (type, geometry, flow) |
| `gas_velocity()` | Mean gas velocity (m/s) |
| `residence_time()` | Gas residence time (s) |
| `reynolds_number()` | Re for flow characterization |
| `knudsen_number()` | Kn for flow regime |
| `mean_free_path()` | λ in meters |
| `diffusivity(%opts)` | Binary Chapman-Enskog D₁₂ (cm²/s) |
| `damkohler_number(%opts)` | Da = reaction/transport rate ratio |
| `step_coverage(%opts)` | Conformality from Thiele modulus |

### Physics::CVD::Transport

| Method | Description |
|--------|-------------|
| `new(%opts)` | Create transport model (feature geometry) |
| `knudsen_diffusivity(%opts)` | D_Kn in features (cm²/s) |
| `effective_diffusivity(%opts)` | Bosanquet D_eff (cm²/s) |
| `step_coverage(%opts)` | Bottom/top rate ratio |
| `conformality_profile(%opts)` | Flux vs depth in feature |
| `boundary_layer_thickness(%opts)` | δ (cm) |
| `mass_transfer_coeff(%opts)` | h_m (cm/s) |
| `wafer_uniformity(%opts)` | Radial rate profile |
| `regime(%opts)` | Reaction-limited vs transport-limited |

### Physics::CVD::Film

| Method | Description |
|--------|-------------|
| `thickness()` | Average film thickness (nm) |
| `roughness()` | RMS roughness (nm) |
| `density()` | Fraction of occupied sites |
| `porosity()` | 1 - density |
| `composition()` | Species counts and fractions |
| `composition_profile(%opts)` | Depth-resolved composition |
| `stoichiometry($A, $B)` | Atomic ratio A:B |
| `export_xyz($file)` | Export to XYZ format |
| `export_lammps_data($file)` | Export to LAMMPS data |

### Physics::CVD::Interface::OpenFOAM

| Method | Description |
|--------|-------------|
| `generate_case(%opts)` | Create full OpenFOAM case directory |
| `run(%opts)` | Execute OpenFOAM solver |

### Physics::CVD::Interface::LAMMPS

| Method | Description |
|--------|-------------|
| `generate_surface_reaction(%opts)` | ReaxFF CVD reaction script |
| `generate_stress_analysis(%opts)` | Film stress calculation script |
| `run(%opts)` | Execute LAMMPS |
| `parse_log($file)` | Parse thermo output |

### Physics::CVD::Interface::Cantera

| Method | Description |
|--------|-------------|
| `generate_sio2_mechanism()` | TEOS/O₂ → SiO₂ YAML |
| `generate_si3n4_mechanism()` | DCS/NH₃ → Si₃N₄ YAML |
| `generate_reactor_script(%opts)` | Python Cantera reactor script |

## Examples

```bash
cd examples/
perl -I../lib sio2_teos.pl       # TEOS CVD SiO₂
perl -I../lib si3n4_lpcvd.pl     # DCS+NH₃ LPCVD Si₃N₄
```

## Physical Models

### Gas-Phase Chemistry
- **Arrhenius kinetics**: k = A × exp(-Ea/kT)
- **Hertz-Knudsen impingement**: Φ = P / √(2πmkT)
- **Binary diffusion**: Chapman-Enskog with collision integrals

### Surface Kinetics
- **Langmuir-Hinshelwood**: rate ∝ θ_A × θ_B × k(T)
- **Eley-Rideal**: rate ∝ P_gas × θ_surface × S(T)
- **Sticking coefficient**: S(T) = S₀ × exp(-Ea/kT)

### Mass Transport
- **Knudsen diffusion**: D_Kn = (w/3)√(8kT/πm)
- **Bosanquet interpolation**: 1/D_eff = 1/D_bulk + 1/D_Kn
- **Step coverage**: SC = 1/(1 + φ²/6) where φ = AR×√(S/(2-S))
- **Boundary layer**: δ = √(DL/v)

### Reactor Physics
- **Reynolds number**: Re = ρvD/μ
- **Knudsen number**: Kn = λ/L
- **Damköhler number**: Da = k_s×L/D (reaction vs transport)
- **Thiele modulus**: φ = L×√(k_s/D)

## CVD Process Reference

| Process | Precursors | T (°C) | P (Pa) | Rate (nm/min) |
|---------|-----------|--------|--------|----------------|
| TEOS SiO₂ | TEOS + O₂ | 680 | 40 | 10-30 |
| PE-SiO₂ | SiH₄ + N₂O | 350 | 300 | 50-200 |
| LP-Si₃N₄ | DCS + NH₃ | 780 | 25 | 3-5 |
| PE-SiNₓ | SiH₄ + NH₃ | 350 | 200 | 10-50 |
| Poly-Si | SiH₄ | 620 | 30 | 10-20 |
| W-CVD | WF₆ + SiH₄ | 400 | 5000 | 100-300 |

## License

This module is free software; you can redistribute it under the same terms as Perl itself.
