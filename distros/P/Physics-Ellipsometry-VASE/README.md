# Physics::Ellipsometry::VASE

Variable Angle Spectroscopic Ellipsometry analysis for Perl / PDL.

## Description

Physics::Ellipsometry::VASE is a complete framework for spectroscopic
ellipsometry data analysis. It includes built-in optical models, a transfer
matrix method, and global optimisation — so you can go from raw VASE data to
fitted film parameters in a few lines of code.

### Core features

- **Data loading** — simple whitespace-delimited files and native J.A. Woollam
  VASE instrument format (auto-detected), with automatic eV ↔ nm conversion
- **Transfer Matrix Method** (`VASE::TMM`) — physics sign convention
  (*e*<sup>+2*iβ*</sup>), Verdet Fresnel coefficients, arbitrary layer counts
- **Dispersion models** (`VASE::Dispersion`) — Cauchy, Sellmeier, Tauc-Lorentz,
  Drude, General Oscillator
- **EMA mixing rules** (`VASE::EMA`) — Linear, Bruggeman, Maxwell-Garnett
- **Material file loader** (`VASE::Materials`) — point-by-point `.mat` files
  with automatic eV/nm unit handling and interpolation
- **Circular Delta residuals** — proper handling of the 0°/360° wrap in the
  Levenberg-Marquardt objective function
- **Parameter bounds & vary/fix** (`VASE::Parameter`) — logit-transformed
  bounded optimisation, fixed-parameter support
- **Global optimiser** (`VASE::Optimizer`) — Differential Evolution
  (DE/rand/1/bin) and grid search for initial parameter estimation
- **Weighted fitting** — uses measured uncertainties (sigma) from Woollam files
- **Numerical Jacobian** — configurable finite-difference step with minimum
  absolute floor
- **Plotting** — multi-angle colour-coded overlays via PDL::Graphics::Gnuplot

## Installation

From source:

```bash
perl Makefile.PL
make
make test
make install
```

## Quick Start

```perl
use PDL;
use PDL::NiceSlice;
use Physics::Ellipsometry::VASE;
use Physics::Ellipsometry::VASE::TMM qw(psi_delta);
use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk);
use Physics::Ellipsometry::VASE::Materials qw(load_material interpolate_material);

# Load data and substrate material
my $vase = Physics::Ellipsometry::VASE->new(
    layers         => 2,
    circular_delta => 1,       # circular Delta residuals
    deriv_step     => 1e-3,
);
$vase->load_data('measurement.dat');

my $substrate = load_material('si_jaw.mat');

# Model: Air / Cauchy film / Si substrate
sub my_model {
    my ($params, $x) = @_;
    my $lambda = $x->(:,0);
    my $theta  = $x->(:,1);

    my ($n_film, $k_film) = cauchy_nk($lambda, $params->at(0), $params->at(1), 0);
    my $N_film = $n_film + i() * $k_film;

    my ($n_sub, $k_sub) = interpolate_material($substrate, $lambda);
    my $N_sub = $n_sub + i() * $k_sub;

    my $N_air = pdl(1.0) + i() * pdl(0.0);
    my $d_nm  = $params->at(2);

    my ($psi, $delta) = psi_delta(
        $lambda, $theta,
        [$N_air, $N_film, $N_sub],
        [$d_nm],
    );
    return $psi->append($delta);
}

$vase->set_model(\&my_model);
my $fitted = $vase->fit(pdl [2.0, 0.01, 100.0]);
my $mse    = $vase->mse($fitted, nparams => 3);
printf "MSE = %.4f, thickness = %.1f nm\n", $mse, $fitted->at(2);

$vase->plot($fitted, output => 'fit.png');
```

## Submodules

### VASE::TMM — Transfer Matrix Method

```perl
use Physics::Ellipsometry::VASE::TMM qw(psi_delta);

my ($psi, $delta) = psi_delta(
    $lambda_nm, $theta_deg,
    [$N_ambient, $N_film1, $N_film2, $N_substrate],  # complex N piddles
    [$d_film1_nm, $d_film2_nm],                       # layer thicknesses
    delta_ref => $measured_delta,                      # optional alignment
);
```

### VASE::Dispersion — Optical dispersion models

All functions use direct-call syntax (no closures) to avoid
`PDL::NiceSlice` source-filter conflicts.

```perl
use Physics::Ellipsometry::VASE::Dispersion qw(cauchy_nk sellmeier_nk
    tauc_lorentz_nk drude_nk genosc_nk);

my ($n, $k) = cauchy_nk($lambda, $A, $B, $C);
my ($n, $k) = sellmeier_nk($lambda, [1.28, 0.01], [0.01, 100]);
my ($n, $k) = tauc_lorentz_nk($lambda, $A, $E0, $Gamma, $Eg, $eps_inf);
my ($n, $k) = drude_nk($lambda, $eps_inf, $omega_p, $gamma);
my ($n, $k) = genosc_nk($lambda, [[100, 4.0, 1.0], [50, 6.0, 2.0]], 1.0);
```

### VASE::EMA — Effective Medium Approximation

```perl
use Physics::Ellipsometry::VASE::EMA qw(ema_linear ema_bruggeman ema_maxwell_garnett);

my $eps_eff = ema_bruggeman($eps_host, $eps_inclusion, $volume_fraction);
my $N_eff   = sqrt($eps_eff);
```

### VASE::Materials — Optical constants loader

```perl
use Physics::Ellipsometry::VASE::Materials qw(load_material interpolate_material);

my $mat = load_material('ta_pbp.mat');   # auto eV→nm, Windows CR stripping
my ($n, $k) = interpolate_material($mat, $lambda_grid);
```

### VASE::Parameter — Bounds & vary/fix control

```perl
use Physics::Ellipsometry::VASE::Parameter qw(param params_to_pdl make_fit_model);

my $params = [
    param(name => 'thickness', value => 200, min => 50, max => 350),
    param(name => 'offset',    value => 0.5, vary => 0),  # fixed
];
my $fit_model = make_fit_model($params, \&full_model);
my $init      = params_to_pdl($params);
```

### VASE::Optimizer — Global optimisation

```perl
use Physics::Ellipsometry::VASE::Optimizer qw(differential_evolution grid_search);

my ($best, $cost) = differential_evolution(
    objective => sub { ... return $chi2 },
    bounds    => [[1.8, 2.5], [0, 0.05], [50, 350]],
    verbose   => 1,
);

my ($best, $cost) = grid_search(
    objective   => $objective,
    base_params => $initial_pdl,
    grid        => [{ index => 0, min => 100, max => 300, steps => 50 }],
);
```

## Data Formats

### Simple format

```
# Wavelength(nm)  Angle(deg)  Psi(deg)  Delta(deg)
400  70  45.0  120.0
410  70  44.5  121.0
```

### Woollam VASE format

Recognised automatically when line 2 begins with `VASEmethod[`.  Header
metadata is stored as object attributes; sigma columns are extracted and used
as fit weights.

```
w1_11012006
VASEmethod[EllipsometerType=4, Isotropic, ...]
Original[w1_11012006.dat]
nm
245.732520	64.999634	14.355849	149.18707	0.04032	0.132363
```

### Material files (.mat)

Woollam-style 3-line header (name, units, count) followed by
wavelength / n / k columns.  Units can be `nm` or `eV` (auto-converted).

## Model Function Contract

```perl
sub model {
    my ($params, $x) = @_;
    # $params — PDL piddle of fit parameters
    # $x      — (npts, 2) piddle: col 0 = wavelength (nm), col 1 = angle (deg)
    #
    # Must return: $psi->append($delta)
    #   — flat piddle of length 2*npts (all psi then all delta)
}
```

## Examples

The `examples/` directory contains working scripts:

| Script | Description |
|--------|-------------|
| `fit_linear.pl` | Minimal linear dispersion model |
| `vase_test_fit.pl` | Cauchy thin-film model (Ta₂O₅ on Si) with Fresnel equations |
| `vase_tauc_lorentz_fit.pl` | Tauc-Lorentz oscillator with numerical Kramers-Kronig |
| `Cap_01242007/fit_vase.pl` | Full 4-medium Ta₂O₅/Ta metal analysis using all v1.00 modules |
| `Cap_01242007/fit_refellips.py` | Same analysis in Python/refellips for comparison |

## Dependencies

- [PDL](https://metacpan.org/pod/PDL) ≥ 2.0
- [PDL::Fit::LM](https://metacpan.org/pod/PDL::Fit::LM)
- [PDL::NiceSlice](https://metacpan.org/pod/PDL::NiceSlice)
- [PDL::Graphics::Gnuplot](https://metacpan.org/pod/PDL::Graphics::Gnuplot) (optional, for plotting)

## Author

Jovan Trujillo <jtrujil1@asu.edu>  
Advanced Electronics and Photonics Core, Arizona State University

## License

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.