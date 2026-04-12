# Physics::Ellipsometry::VASE

Variable Angle Spectroscopic Ellipsometry data fitting for Perl / PDL.

## Description

Physics::Ellipsometry::VASE provides a framework for fitting optical thin-film
models to VASE data using the Levenberg-Marquardt algorithm.  It handles:

- **Data loading** — simple whitespace-delimited files and native J.A. Woollam
  VASE instrument format (auto-detected)
- **Weighted fitting** — uses measured uncertainties (sigma) from Woollam files
- **Numerical Jacobian** — automatic relative-step finite differences
- **Plotting** — multi-angle color-coded overlays via PDL::Graphics::Gnuplot

## Installation

From CPAN:

```bash
cpanm Physics::Ellipsometry::VASE
```

From source:

```bash
perl Makefile.PL
make
make test
make install
```

## Synopsis

```perl
use PDL;
use PDL::NiceSlice;
use Physics::Ellipsometry::VASE;

my $vase = Physics::Ellipsometry::VASE->new(layers => 1);
$vase->load_data('measurement.dat');

sub my_model {
    my ($params, $x) = @_;
    my $wavelength = $x->(:,0);   # nm
    my $angle      = $x->(:,1);   # degrees

    my $psi   = $params->(0) + $params->(1) / $wavelength**2;
    my $delta = $params->(2) + $params->(3) * $wavelength;

    return cat($psi, $delta)->flat;
}

$vase->set_model(\&my_model);
my $fitted = $vase->fit(pdl [45, 1e4, 120, 0.01]);

# Optional: plot results (requires PDL::Graphics::Gnuplot)
$vase->plot($fitted, output => 'fit.png');
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

## Examples

The `examples/` directory contains working scripts:

| Script | Description |
|--------|-------------|
| `fit_linear.pl` | Minimal linear dispersion model |
| `vase_test_fit.pl` | Cauchy thin-film model (Ta₂O₅ on Si) with complex Fresnel equations |
| `vase_tauc_lorentz_fit.pl` | Tauc-Lorentz oscillator with numerical Kramers-Kronig |

## Model Function Contract

```perl
sub model {
    my ($params, $x) = @_;
    # $params — PDL piddle of fit parameters
    # $x      — (npts, 2) piddle: col 0 = wavelength (nm), col 1 = angle (deg)
    #
    # Must return: cat($psi, $delta)->flat
    #   — flat piddle of length 2*npts (all psi then all delta)
}
```

## Dependencies

- [PDL](https://metacpan.org/pod/PDL) ≥ 2.0
- [PDL::Fit::LM](https://metacpan.org/pod/PDL::Fit::LM)
- [PDL::NiceSlice](https://metacpan.org/pod/PDL::NiceSlice)
- [PDL::Graphics::Gnuplot](https://metacpan.org/pod/PDL::Graphics::Gnuplot) (optional, for plotting)

## Author

Jovan Trujillo <jtrujil1@asu.edu>

## License

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.