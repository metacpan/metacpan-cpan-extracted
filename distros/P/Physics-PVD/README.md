# Physics::PVD

**Physical Vapor Deposition simulation framework in Perl**

A comprehensive library for simulating PVD thin film growth using Kinetic Monte Carlo (kMC) for atomistic film formation and Direct Simulation Monte Carlo (DSMC) for vapor-phase transport. Includes optional interfaces to OpenFOAM, LAMMPS, and QuantumATK for multi-scale simulations.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Optional Dependencies](#optional-dependencies)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [Physics::PVD](#physicspvd-main-module)
  - [Physics::PVD::KMC](#physicspvdkmc)
  - [Physics::PVD::DSMC](#physicspvddsmc)
  - [Physics::PVD::Film](#physicspvdfilm)
  - [Physics::PVD::Interface::OpenFOAM](#physicspvdinterfaceopenfoam)
  - [Physics::PVD::Interface::LAMMPS](#physicspvdinterfacelammps)
  - [Physics::PVD::Interface::QuantumATK](#physicspvdinterfacequantumatk)
- [Examples](#examples)
- [Physical Models](#physical-models)
- [License](#license)

---

## Features

### Core Simulation Engines

| Engine | Description |
|--------|-------------|
| **KMC** | BKL rejection-free Kinetic Monte Carlo: adsorption, diffusion, desorption, Ehrlich-Schwoebel barriers, oblique deposition, multi-species |
| **DSMC** | Direct Simulation Monte Carlo: Thompson energy distribution, cos^n angular emission, gas-phase collisions, Knudsen number characterization |
| **Hybrid** | DSMC transport → KMC growth coupling (flux/energy/angle distributions) |

### Film Analysis

- Thickness measurement (average height)
- RMS surface roughness
- Film density and porosity
- Composition profiles along growth direction
- Export to XYZ (OVITO/VMD) and LAMMPS data formats

### External Tool Interfaces

| Tool | Capabilities |
|------|-------------|
| **OpenFOAM** | dsmcFoam+ case generation, mesh, BCs, particle injection, parallel execution |
| **LAMMPS** | Deposition MD, sputtering cascades, post-deposition annealing, EAM/MEAM/Tersoff potentials, dump/log parsing |
| **QuantumATK** | DFT/DFTB binding energies, sputter yield (BCA+MD), adatom diffusion MD, electronic transport |

### Key Physics

- **Arrhenius kinetics**: temperature-dependent rates via `k = ν₀ exp(-Ea/kBT)`
- **Ehrlich-Schwoebel barrier**: step-edge descent asymmetry
- **Thompson energy distribution**: `P(E) ∝ E/(E+Eb)³`
- **Variable hard-sphere collisions**: energy-dependent cross-sections
- **Knudsen number classification**: free-molecular, transitional, continuum regimes
- **Shadow effects**: geometric shadowing for oblique-angle deposition

---

## Installation

### From source (this repository)

```bash
cd Physics-PVD
perl Makefile.PL
make
make test
make install       # or: make install DESTDIR=~/perl5
```

### Using local lib (no root)

```bash
perl Makefile.PL INSTALL_BASE=~/perl5
make && make test && make install
export PERL5LIB=~/perl5/lib/perl5:$PERL5LIB
```

### With cpanm (once published)

```bash
cpanm Physics::PVD
```

### Prerequisites

- **Perl** ≥ 5.16
- Core modules: `Carp`, `POSIX`, `List::Util`, `File::Path`, `File::Spec`, `File::Temp`
- **Test::More** (for running tests)

All core dependencies are included with standard Perl installations.

---

## Optional Dependencies

These are only needed if you use the corresponding interface modules:

### PDL (for visualization examples)

```bash
cpanm PDL PDL::Graphics::Gnuplot
```

### OpenFOAM (for `Physics::PVD::Interface::OpenFOAM`)

```bash
# Ubuntu/Debian
sudo apt install openfoam
# Or from source: https://openfoam.org/download/

# Verify
which blockMesh && which dsmcFoam+
```

Required executables: `blockMesh`, `dsmcInitialise`, `dsmcFoam+`

### LAMMPS (for `Physics::PVD::Interface::LAMMPS`)

```bash
# Ubuntu/Debian
sudo apt install lammps

# From source (recommended for custom packages):
git clone https://github.com/lammps/lammps.git
cd lammps/src
make yes-MANYBODY yes-MOLECULE   # EAM, MEAM potentials
make mpi                          # or: make serial

# Verify
which lmp
```

Required packages: `MANYBODY` (EAM/MEAM/Tersoff potentials)

### QuantumATK (for `Physics::PVD::Interface::QuantumATK`)

QuantumATK requires a commercial license from Synopsys:
- Download: https://www.synopsys.com/silicon/quantumatk.html
- Set environment: `export QUANTUMATK_PATH=/path/to/QuantumATK`
- Python interpreter: `atkpython`

```bash
# Verify
which atkpython
atkpython -c "from QuantumATK import *; print('OK')"
```

### Interatomic Potentials (for LAMMPS)

Download potentials from NIST Interatomic Potentials Repository:
- https://www.ctcms.nist.gov/potentials/

Commonly needed for PVD:
- `Ta.eam.alloy` — Tantalum EAM
- `Cu.eam.alloy` — Copper EAM
- `CuTa.eam.alloy` — Cu-Ta cross-potential
- `TiAl.meam` — Ti-Al MEAM

Place in the `potentials/` directory or set `potential_dir` parameter.

---

## Quick Start

```perl
use Physics::PVD;

# Create simulation
my $pvd = Physics::PVD->new(temperature => 600, pressure => 5e-3);

# KMC film growth
my $kmc = $pvd->kmc(lattice_size => [100, 100, 50]);
$kmc->add_species(name => 'Ta', mass => 180.95, binding_energy => 8.1);
$kmc->deposit(flux => 1e14, time => 60);

# Results
my $film = $kmc->get_film;
printf "Thickness: %.1f nm, Roughness: %.2f nm\n",
       $film->thickness, $film->roughness;
```

---

## API Reference

### Physics::PVD (main module)

The top-level module provides factory methods and orchestrates simulations.

#### `new(%options)`

```perl
my $pvd = Physics::PVD->new(
    method      => 'kmc',       # 'kmc' | 'dsmc' | 'hybrid'
    temperature => 300,          # substrate temperature (K)
    pressure    => 1e-3,         # base pressure (Pa)
    verbose     => 0,            # print progress
    seed        => 12345,        # RNG seed for reproducibility
);
```

#### `configure(%params)`

Update simulation parameters after construction.

```perl
$pvd->configure(temperature => 700, pressure => 2e-3);
```

#### `kmc(%options)` → Physics::PVD::KMC

Get or create the KMC engine instance.

```perl
my $kmc = $pvd->kmc(lattice_size => [100, 100, 50]);
```

#### `dsmc(%options)` → Physics::PVD::DSMC

Get or create the DSMC engine instance.

```perl
my $dsmc = $pvd->dsmc(n_particles => 10000);
```

#### `film(%options)` → Physics::PVD::Film

Get or create the Film analysis object.

```perl
my $film = $pvd->film;
```

#### `interface($name, %options)` → Interface object

Load and instantiate an external interface module.

```perl
my $lmp = $pvd->interface('lammps', executable => '/usr/bin/lmp');
my $foam = $pvd->interface('openfoam', case_dir => './my_case');
my $atk = $pvd->interface('quantumatk', python_path => 'atkpython');
```

#### `run(%options)` → results

Run a complete simulation using the configured method.

```perl
my $film = $pvd->run(method => 'kmc', steps => 50000, flux => 1e14);
```

#### `available_methods()` → list

Returns: `('kmc', 'dsmc', 'hybrid')`

#### `available_interfaces()` → list

Returns: `('lammps', 'openfoam', 'quantumatk')`

---

### Physics::PVD::KMC

Kinetic Monte Carlo engine using the BKL rejection-free algorithm.

#### `new(%options)`

```perl
my $kmc = Physics::PVD::KMC->new(
    lattice_size      => [100, 100, 50],   # [nx, ny, nz] sites
    lattice_type      => 'fcc',             # 'fcc'|'bcc'|'hcp'|'simple_cubic'
    lattice_const     => 3.3,               # Angstrom
    temperature       => 300,               # K
    attempt_freq      => 1e13,              # Hz (Debye frequency)
    diffusion_barrier => 0.7,               # eV
    es_barrier        => 0.15,              # Ehrlich-Schwoebel barrier (eV)
    flux              => 1e14,              # atoms/cm²/s
    deposition_angle  => 0,                 # degrees from surface normal
    seed              => 42,
    verbose           => 1,
);
```

#### `add_species(%spec)`

```perl
$kmc->add_species(
    name              => 'Ta',
    mass              => 180.95,       # amu
    binding_energy    => 8.1,          # eV per atom
    diffusion_barrier => 0.7,          # eV (overrides global)
    desorption_energy => 8.1,          # eV
    sticking_coeff    => 1.0,          # 0–1
);
```

#### `set_rates(%rates)`

```perl
$kmc->set_rates(
    diffusion    => 0.65,   # eV barrier
    es_barrier   => 0.20,   # eV
    attempt_freq => 5e12,   # Hz
);
```

#### `set_flux($flux)`

```perl
$kmc->set_flux(2e14);  # atoms/cm²/s
```

#### `set_angular_distribution($dist)`

Feed a 2D flux map (from DSMC) to bias landing site selection.

```perl
$kmc->set_angular_distribution($dsmc->get_flux_distribution);
```

#### `deposit(%options)`

High-level deposition method. Calculates steps from flux × time.

```perl
$kmc->deposit(
    flux  => 1e14,   # atoms/cm²/s
    angle => 15,     # degrees (oblique deposition)
    time  => 120,    # seconds
);
```

#### `run(steps => $n)`

Low-level: run exactly N KMC steps.

```perl
$kmc->run(steps => 100000);
```

#### `get_film()` → Physics::PVD::Film

Extract current film state as a Film object.

```perl
my $film = $kmc->get_film;
```

#### `get_surface()` → arrayref

Returns the 2D height map `$surface->[$x][$y]` (in lattice layers).

#### `coverage()` → float

Fraction of substrate sites with at least one atom (0–1).

#### `stats()` → hashref

```perl
my $s = $kmc->stats;
# { time => 1.2e-3, steps => 50000, deposited => 1234,
#   coverage => 0.95, events => {adsorption=>1234, diffusion=>45000, desorption=>12} }
```

---

### Physics::PVD::DSMC

Direct Simulation Monte Carlo for vapor transport.

#### `new(%options)`

```perl
my $dsmc = Physics::PVD::DSMC->new(
    domain          => [0.1, 0.1, 0.05],  # [W, D, H] meters
    n_cells         => [50, 50, 25],
    n_particles     => 10000,
    dt              => 1e-7,               # time step (s)

    # Gas
    gas_species     => 'Ar',
    gas_mass        => 39.948,             # amu
    pressure        => 1.0,                # Pa
    temperature     => 300,                # K

    # Target
    target_material => 'Ta',
    target_mass     => 180.95,
    target_diameter => 0.05,               # m
    surface_binding => 8.1,                # eV
    cosine_power    => 1,                  # cos^n distribution
    sputter_yield   => 1.0,

    # Geometry
    substrate_distance => 0.04,            # m

    seed    => 42,
    verbose => 1,
);
```

#### `set_gas(%options)`

```perl
$dsmc->set_gas(species => 'Kr', mass => 83.798, pressure => 3.0, temperature => 350);
```

#### `set_target(%options)`

```perl
$dsmc->set_target(material => 'Cu', mass => 63.546, surface_binding => 3.5, yield => 2.3);
```

#### `set_substrate(%options)`

```perl
$dsmc->set_substrate(distance => 0.06);  # 6 cm throw
```

#### `run(timesteps => $n)`

```perl
$dsmc->run(timesteps => 5000);
```

#### `get_flux_distribution()` → arrayref (2D)

Returns `$flux->[$ix][$iy]` — particle count per cell on substrate.

#### `get_energy_distribution()` → arrayref

List of arrival energies (eV) for all particles that reached the substrate.

#### `get_angular_distribution()` → arrayref

List of arrival angles (degrees from normal) for substrate-arriving particles.

#### `mean_arrival_energy()` → float (eV)

#### `knudsen_number()` → float

Ratio of mean free path to target-substrate distance.

#### `stats()` → hashref

```perl
my $s = $dsmc->stats;
# { total_particles => 10000, arrived => 7500, still_flying => 200,
#   mean_energy_eV => 3.2, knudsen_number => 2.5, time => 5e-4 }
```

---

### Physics::PVD::Film

Film data structure with analysis methods.

#### `new(%options)`

```perl
my $film = Physics::PVD::Film->new(
    lattice_size  => [100, 100, 50],
    lattice_const => 3.3,     # Angstrom
);
```

#### `add_atom(%atom)`

Add atoms explicitly (alternative to lattice-from-KMC mode).

```perl
$film->add_atom(species => 'Ta', x => 5.0, y => 3.2, z => 1.1);
```

#### `thickness()` → float (nm)

Average film thickness.

#### `roughness()` → float (nm)

RMS surface roughness.

#### `density()` → float (0–1)

Occupied fraction of lattice sites below the maximum height.

#### `porosity()` → float (0–1)

`1 - density()`

#### `composition_profile()` → arrayref of hashrefs

```perl
my $prof = $film->composition_profile;
# [ {z_nm => 0.165, total_atoms => 980, Ta => 0.6, Cu => 0.4}, ... ]
```

#### `export_xyz($filename)`

Write film to XYZ format for visualization in OVITO, VMD, or ASE.

```perl
my $n = $film->export_xyz('my_film.xyz');  # returns atom count
```

#### `export_lammps_data($filename)`

Write film as LAMMPS data file for continued MD simulation.

```perl
$film->export_lammps_data('my_film.data');
```

#### `summary()` → hashref

```perl
my $s = $film->summary;
# { thickness_nm => 5.2, roughness_nm => 0.34, density => 0.92,
#   porosity => 0.08, n_atoms => 12500 }
```

---

### Physics::PVD::Interface::OpenFOAM

Interface to OpenFOAM's dsmcFoam+ solver.

#### `new(%options)`

```perl
my $foam = Physics::PVD::Interface::OpenFOAM->new(
    case_dir        => './openfoam_pvd',
    executable      => 'dsmcFoam+',
    n_procs         => 4,
    domain_size     => [0.1, 0.1, 0.05],   # m
    n_cells         => [50, 50, 25],
    gas_species     => 'Ar',
    gas_pressure    => 1.0,                 # Pa
    gas_temperature => 300,                 # K
    target_species  => 'Ta',
    injection_rate  => 1e16,                # particles/s
    dt              => 1e-7,
    end_time        => 1e-3,
);
```

#### `check_availability()` → bool

Returns true if `dsmcFoam+` is found in PATH.

#### `setup_case()`

Generates the complete OpenFOAM case directory:
- `system/blockMeshDict`
- `system/controlDict`
- `system/dsmcInitialiseDict`
- `constant/dsmcProperties`
- `0/boundaryT`

```perl
my $dir = $foam->setup_case;
```

#### `run(%options)`

Runs blockMesh → dsmcInitialise → dsmcFoam+ (optionally parallel).

```perl
$foam->run(n_procs => 8);
```

#### `import_results()` → hashref

Parses the latest time directory and log files.

```perl
my $results = $foam->import_results;
```

---

### Physics::PVD::Interface::LAMMPS

Interface to LAMMPS molecular dynamics.

#### `new(%options)`

```perl
my $lmp = Physics::PVD::Interface::LAMMPS->new(
    executable          => 'lmp',
    n_procs             => 4,
    work_dir            => './lammps_pvd',
    potential_type      => 'eam/alloy',
    potential_file      => 'potentials/CuTa.eam.alloy',
    substrate_material  => 'Cu',
    substrate_size      => [10, 10, 5],     # unit cells
    deposit_species     => 'Ta',
    deposit_energy      => 5.0,             # eV
    deposit_interval    => 1000,            # timesteps between deposits
    timestep            => 1.0,             # fs
    temperature         => 300,             # K
);
```

#### `check_availability()` → bool

#### `generate_input(%options)` → filename

Generate a LAMMPS input script from a template.

Templates: `'deposition'`, `'sputtering'`, `'annealing'`

```perl
my $file = $lmp->generate_input(
    template => 'deposition',
    filename => 'my_run/in.deposit',
    params   => {
        n_deposits  => 200,
        run_between => 2000,
        total_steps => 200000,
    },
);
```

#### `run(%options)`

```perl
$lmp->run(input_file => 'in.pvd', n_procs => 8);
```

#### `parse_dump($filename)` → arrayref of frames

```perl
my $frames = $lmp->parse_dump('dump.lammpstrj');
# [ {timestep => 0, n_atoms => 500, atoms => [{id,type,x,y,z}, ...]}, ... ]
```

#### `parse_log($filename)` → arrayref of hashrefs

```perl
my $thermo = $lmp->parse_log;
# [ {Step => 0, Temp => 300, PotEng => -3.5, ...}, ... ]
```

---

### Physics::PVD::Interface::QuantumATK

Interface to QuantumATK for first-principles calculations.

#### `new(%options)`

```perl
my $atk = Physics::PVD::Interface::QuantumATK->new(
    python_path   => 'atkpython',
    work_dir      => './quantumatk_pvd',
    calculator    => 'DFTB',          # 'DFT'|'DFTB'|'ForceField'
    xc_functional => 'GGA-PBE',
    basis_set     => 'DZP',
    k_points      => [4, 4, 1],
    material      => 'Ta',
    surface       => [1, 1, 0],
    slab_layers   => 6,
    vacuum        => 15,              # Angstrom
);
```

#### `check_availability()` → bool

#### `calculate_binding_energy(%options)` → filename

Generates a Python script for DFT/DFTB binding energy calculation.

```perl
my $script = $atk->calculate_binding_energy(
    adatom => 'Cu',
    site   => 'hollow',    # 'hollow'|'bridge'|'atop'
);
```

#### `setup_sputtering(%options)` → filename

Generates a BCA + MD sputtering yield simulation script.

```perl
my $script = $atk->setup_sputtering(
    ion        => 'Ar',
    ion_energy => 500,     # eV
    angle      => 0,       # normal incidence
    n_ions     => 200,
);
```

#### `run_md(%options)` → filename

Generates an adatom diffusion MD script.

```perl
my $script = $atk->run_md(
    temperature => 600,
    steps       => 100000,
);
```

#### `run_script($filename)`

Execute the generated Python script with `atkpython`.

```perl
$atk->run_script($script);
```

#### `get_results()` → hashref

Parse output log for computed quantities.

```perl
my $r = $atk->get_results;
# { binding_energy_eV => 5.3, sputter_yield => 0.8, diffusion_coeff => 1.2e-7 }
```

---

## Examples

### 1. Basic KMC Film Growth

```perl
use Physics::PVD;

my $pvd = Physics::PVD->new(temperature => 600);
my $kmc = $pvd->kmc(lattice_size => [50, 50, 30]);
$kmc->add_species(name => 'Ta', mass => 180.95, binding_energy => 8.1);
$kmc->deposit(flux => 1e14, time => 30);

my $film = $kmc->get_film;
printf "Thickness: %.1f nm\n", $film->thickness;
$film->export_xyz('ta_film.xyz');
```

See: `examples/kmc_basic.pl`

### 2. DSMC Vapor Transport

```perl
use Physics::PVD;

my $pvd = Physics::PVD->new(pressure => 2.0);
my $dsmc = $pvd->dsmc(n_particles => 5000, target_material => 'Ta');
$dsmc->run(timesteps => 3000);

printf "Knudsen: %.2f\n", $dsmc->knudsen_number;
printf "Mean energy: %.2f eV\n", $dsmc->mean_arrival_energy;
```

See: `examples/dsmc_transport.pl`

### 3. Hybrid DSMC→KMC

```perl
use Physics::PVD;

my $pvd = Physics::PVD->new(method => 'hybrid', temperature => 400, pressure => 1.5);
my $film = $pvd->run(steps => 50000, timesteps => 2000, flux => 5e13);
printf "Film: %.1f nm, roughness: %.2f nm\n", $film->thickness, $film->roughness;
```

See: `examples/hybrid_dsmc_kmc.pl`

### 4. LAMMPS Deposition MD

```perl
use Physics::PVD;

my $pvd = Physics::PVD->new;
my $lmp = $pvd->interface('lammps',
    substrate_material => 'Cu',
    deposit_species    => 'Ta',
    potential_file     => 'CuTa.eam.alloy',
);

$lmp->generate_input(template => 'deposition', params => {n_deposits => 100});
$lmp->run;
my $frames = $lmp->parse_dump;
```

See: `examples/lammps_pvd.pl`

### 5. OpenFOAM DSMC

```perl
use Physics::PVD;

my $pvd = Physics::PVD->new;
my $foam = $pvd->interface('openfoam', gas_pressure => 5.0, target_species => 'Cu');
$foam->setup_case;
$foam->run(n_procs => 4);
my $results = $foam->import_results;
```

### 6. QuantumATK Binding Energy

```perl
use Physics::PVD;

my $pvd = Physics::PVD->new;
my $atk = $pvd->interface('quantumatk', material => 'Ta', surface => [1,1,0]);
my $script = $atk->calculate_binding_energy(adatom => 'Cu', site => 'hollow');
$atk->run_script($script);
my $r = $atk->get_results;
printf "Binding energy: %.2f eV\n", $r->{binding_energy_eV};
```

---

## Physical Models

### Kinetic Monte Carlo (KMC)

The BKL (Bortz-Kalos-Lebowitz, 1975) rejection-free algorithm:

1. **Rate catalog**: All possible events enumerated with Arrhenius rates  
   `k = ν₀ × exp(-Ea / kBT)`

2. **Event selection**: Random event chosen proportional to its rate  
   `P(event_i) = k_i / Σk_j`

3. **Time advancement**: Physical time incremented by  
   `Δt = -ln(u) / R_total` where `u ∈ (0,1)`

Events:
- **Adsorption**: Atom from vapor lands on surface (rate ∝ flux × area)
- **Diffusion**: Surface hop to adjacent site (barrier ~0.3–1.5 eV)
- **Desorption**: Weakly-bound atom evaporates (barrier = binding energy)
- **ES descent**: Extra barrier for downhill step-edge crossing

### Direct Simulation Monte Carlo (DSMC)

Bird's method (1994) for rarefied gas dynamics:

1. **Particle emission**: Thompson energy `P(E) ∝ E/(E+Eb)³`, cosine^n angular
2. **Free flight**: Ballistic motion for time step `dt`
3. **Collision**: Null-collision method with VHS cross-section  
   `P_coll = n_gas × σ × v_rel × dt`
4. **Energy transfer**: Hard-sphere scattering in COM frame

### Knudsen Number Regimes

| Kn | Regime | Transport |
|----|--------|-----------|
| > 10 | Free-molecular | Ballistic, line-of-sight |
| 0.1–10 | Transitional | Partial thermalization |
| < 0.1 | Continuum | Fully diffusive |

---

## Directory Structure

```
Physics-PVD/
├── README.md
├── Makefile.PL
├── lib/
│   └── Physics/
│       ├── PVD.pm                    # Main module
│       └── PVD/
│           ├── KMC.pm                # Kinetic Monte Carlo engine
│           ├── DSMC.pm               # Direct Simulation Monte Carlo
│           ├── Film.pm               # Film analysis & export
│           └── Interface/
│               ├── OpenFOAM.pm       # dsmcFoam+ interface
│               ├── LAMMPS.pm         # LAMMPS MD interface
│               └── QuantumATK.pm     # QuantumATK DFT/DFTB
├── t/
│   └── basic.t                       # Test suite
└── examples/
    ├── kmc_basic.pl                  # Simple KMC deposition
    ├── dsmc_transport.pl             # Vapor transport analysis
    ├── hybrid_dsmc_kmc.pl            # Coupled DSMC→KMC
    └── lammps_pvd.pl                 # LAMMPS MD deposition
```

---

## License

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself (Artistic License 2.0 / GPL v1+).
