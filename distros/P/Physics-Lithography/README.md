# Physics::Lithography

A Perl library for simulating **Laser Direct Imprint Lithography (LDIL)**, including thermal modeling, ablation, phase change, pattern transfer fidelity, and Laser-Induced Forward Transfer (LIFT).

## Features

- **Laser characterization** — Gaussian/flat-top/ring beam profiles, temporal pulse shapes, Beer-Lambert absorption, thermal confinement regime detection
- **2D thermal solver** — Explicit finite-difference in cylindrical (r,z) coordinates with material database (PMMA, SU-8, polyimide, silicon, gold, copper)
- **Ablation modeling** — Logarithmic blow-off model, multi-pulse incubation, crater geometry, volume removal rate, ablation efficiency
- **Phase change** — Melt pool analysis, resolidification time (Stefan number), HAZ depth, enthalpy method
- **Pattern transfer** — Minimum feature size prediction, edge acuity, aspect ratio limits, process window mapping, scan parameters
- **LIFT** — Vapor recoil pressure, jetting threshold, droplet diameter, transfer regime classification, Weber/Reynolds numbers
- **Interface modules** — OpenFOAM (interFoam for melt dynamics), LAMMPS (TTM + MD for ultrafast ablation)

## Installation

```bash
git clone https://github.com/jtrujil43/Physics-Lithography.git
cd Physics-Lithography
perl Makefile.PL
make
make test
```

### Dependencies

**Required (core Perl):**
- `Carp`, `List::Util`, `File::Path` (all included with Perl)

**Optional (for interface modules):**
- [OpenFOAM](https://www.openfoam.com/) — `apt install openfoam` (Ubuntu) for melt pool CFD
- [LAMMPS](https://www.lammps.org/) — `apt install lammps` for molecular dynamics of laser-matter interaction

## Quick Start

```perl
use Physics::Lithography;

my $litho = Physics::Lithography->new(verbose => 1);

# Create a laser source
my $laser = $litho->laser(
    wavelength  => 355e-9,     # 355 nm (UV)
    pulse_width => 10e-9,      # 10 ns
    fluence     => 0.5,        # J/cm²
    spot_size   => 5e-6,       # 5 µm (1/e² radius)
);

# Solve heat equation
my $thermal = $litho->thermal(material => 'pmma');
$thermal->solve(laser => $laser, time => 100e-9);
printf "Peak T: %.0f K\n", $thermal->T_max;

# Calculate ablation depth
my $abl = $litho->ablation(alpha => 1e5, F_threshold => 0.1);
printf "Depth: %.0f nm\n", $abl->ablation_depth(fluence => 0.5) * 1e9;
```

## API Reference

### Physics::Lithography (main module)

Factory class providing access to all sub-modules:

| Method | Returns | Description |
|--------|---------|-------------|
| `laser(%opts)` | Laser object | Beam/pulse characterization |
| `thermal(%opts)` | Thermal solver | 2D heat equation |
| `ablation(%opts)` | Ablation model | Depth/crater prediction |
| `phase_change(%opts)` | PhaseChange | Melt pool analysis |
| `pattern(%opts)` | Pattern | Feature transfer fidelity |
| `lift(%opts)` | LIFT | Forward transfer model |
| `interface($name, %opts)` | Interface | OpenFOAM/LAMMPS bridge |

### Physics::Lithography::Laser

```perl
my $laser = Physics::Lithography::Laser->new(
    wavelength  => 355e-9,
    pulse_width => 10e-9,
    fluence     => 0.5,        # J/cm²
    spot_size   => 5e-6,       # m
    profile     => 'gaussian', # gaussian|flat_top|ring
    temporal    => 'gaussian', # gaussian|square
    rep_rate    => 1000,       # Hz
);

$laser->peak_intensity;            # W/cm²
$laser->pulse_energy;              # J
$laser->spatial_profile($r);       # normalized I(r)
$laser->temporal_profile($t);      # normalized I(t)
$laser->absorption_profile($z);    # Beer-Lambert I(z)
$laser->thermal_diffusion_length($kappa);  # m
$laser->is_thermal_confinement($kappa, $alpha);  # 1 or 0
$laser->summary;                   # hashref of all parameters
```

### Physics::Lithography::Thermal

```perl
my $thermal = Physics::Lithography::Thermal->new(
    material => 'pmma',    # pmma|su8|polyimide|silicon|gold|copper
    n_r      => 50,        # radial grid points
    n_z      => 50,        # axial grid points
    domain_r => 20e-6,     # radial domain (m)
    domain_z => 10e-6,     # axial domain (m)
);

$thermal->solve(laser => $laser, time => 100e-9);
$thermal->T_max;                   # peak temperature (K)
$thermal->surface_temperature;     # array ref of T(r, z=0)
$thermal->melt_radius;            # m (or undef if no melt)
$thermal->melt_depth;             # m (or undef)
$thermal->decomposition_depth;    # m (polymer only)
$thermal->field;                  # 2D array ref T[r][z]
```

### Physics::Lithography::Ablation

```perl
my $abl = Physics::Lithography::Ablation->new(
    alpha       => 1e5,    # effective absorption (1/m)
    F_threshold => 0.1,    # J/cm²
    incubation_S => 0.85,  # incubation coefficient
);

$abl->ablation_depth(fluence => 0.5);           # m
$abl->multi_pulse_depth(fluence => 0.3, pulses => 10);  # m
$abl->threshold_with_incubation(N => 50, S => 0.85);    # J/cm²
$abl->crater_profile(fluence => 0.5, spot_size => 5e-6);  # hashref
$abl->volume_per_pulse(fluence => 0.5, spot_size => 5e-6); # m³
$abl->ablation_rate_curve(F_min => 0.01, F_max => 5.0);   # array
$abl->calculate_threshold(density => 1200, cp => 1200);   # J/cm²
$abl->efficiency(fluence => 0.5, spot_size => 5e-6);      # kg/J
```

### Physics::Lithography::PhaseChange

```perl
my $pc = Physics::Lithography::PhaseChange->new(
    T_melt   => 600,       # K (or material default)
    L_fusion => 2.5e5,     # J/kg
    density  => 1200,
    cp       => 1200,
);

$pc->analyze_melt_pool(thermal => $thermal);  # sets melt_pool
$pc->resolidification_time;        # s (Stefan problem)
$pc->cooling_rate;                 # K/s
$pc->haz_depth;                    # m
$pc->enthalpy($T);                 # J/kg
$pc->phase_at($T);                 # 'solid'|'mushy'|'liquid'
```

### Physics::Lithography::Pattern

```perl
my $pat = Physics::Lithography::Pattern->new();

$pat->minimum_feature_size(
    spot_size => 5e-6, diffusivity => 1e-7, pulse_width => 10e-9
);  # hashref with thermal_limit_nm, optical_limit_nm, minimum_nm

$pat->edge_acuity(diffusivity => 1e-7, pulse_width => 10e-9, alpha => 1e6);
$pat->max_aspect_ratio(fluence => 1.0, F_threshold => 0.1, ...);
$pat->process_window(F_min => 0.05, F_max => 2.0, ...);  # array of points
$pat->scan_parameters(spot_size => 5e-6, overlap => 0.5, rep_rate => 1e5);
$pat->line_pattern(fluence => 0.5, spot_size => 5e-6, overlap => 0.5);
$pat->resolution_comparison(diffusivity => 1e-7);  # compare pulse widths
```

### Physics::Lithography::LIFT

```perl
my $lift = Physics::Lithography::LIFT->new(
    film_thickness  => 100e-9,  # donor film
    density         => 19300,   # kg/m³
    T_melt          => 1337,
    T_boil          => 3129,
    L_vaporize      => 1.74e6,
    surface_tension => 1.14,
    alpha           => 7e7,
    reflectivity    => 0.37,
    gap             => 50e-6,
);

$lift->transfer_threshold;                    # J/cm²
$lift->transfer_regime(fluence => 0.5);       # no_transfer|sub_threshold|jetting|spray|explosive
$lift->recoil_pressure(fluence => 0.5, pulse_width => 10e-9);  # Pa
$lift->jet_velocity(...);                     # m/s
$lift->droplet_diameter(fluence => 0.5, spot_size => 5e-6);    # m
$lift->weber_number(...);
$lift->reynolds_number(...);
$lift->flight_time(...);                      # s
$lift->fluence_sweep(F_min => 0.01, F_max => 5.0, points => 30);
```

### Interface Modules

```perl
# OpenFOAM: generate interFoam case for melt pool dynamics
my $of = $litho->interface('openfoam', case_dir => './melt_case');
$of->generate_case(dt => 1e-10, end_time => 1e-6);

# LAMMPS: generate TTM-MD script for ultrafast ablation
my $lmp = $litho->interface('lammps', output_dir => './laser_md');
$lmp->generate_script(material => 'gold', fluence => 0.5, pulse_fs => 100);
```

## Examples

### Thermal Imprint (`examples/thermal_imprint.pl`)

Demonstrates resolution analysis, thermal simulation, ablation depth vs fluence, multi-pulse incubation, and scanning parameters.

```bash
perl -Ilib examples/thermal_imprint.pl
```

### LIFT Printing (`examples/lift_gold.pl`)

Characterizes LIFT transfer regimes for gold donor film, including threshold determination, fluence sweep, droplet sizing, and film thickness effects.

```bash
perl -Ilib examples/lift_gold.pl
```

## Physics Background

### Logarithmic Blow-Off Model

Ablation depth follows Beer-Lambert absorption:
```
d = (1/α) × ln(F/F_th)
```

### Multi-Pulse Incubation

Threshold decreases with accumulated pulses:
```
F_th(N) = F_th(1) × N^(S-1),  S < 1
```

### Thermal Confinement

When pulse width τ < 1/(α² × κ), heat doesn't diffuse during the pulse, enabling sharp features.

### LIFT Transfer Regimes

- **Sub-threshold**: Incomplete film release
- **Jetting**: Clean single-droplet transfer (optimal)
- **Spray**: Multiple satellite droplets
- **Explosive**: Plasma-assisted, poor resolution

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

Jovan Trujillo
