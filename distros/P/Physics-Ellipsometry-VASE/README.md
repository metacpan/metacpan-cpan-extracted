# VASE.pm - Variable Angle Spectroscopic Ellipsometry Analysis

A Perl library for fitting optical models to variable angle spectroscopic ellipsometry (VASE) data using the Levenberg-Marquardt algorithm.

## What is Ellipsometry?

Ellipsometry is an optical technique that measures the change in polarization of light upon reflection from a sample surface. It provides information about the optical properties (refractive index, extinction coefficient) and thickness of thin films and multilayer structures. The measured parameters are:

- **Psi (Ψ)**: Related to the amplitude ratio of p- and s-polarized light
- **Delta (Δ)**: Phase difference between p- and s-polarized light

Variable angle measurements provide additional constraints for more accurate model fitting.

## Features

- **Flexible Model Definition**: Define custom optical models as Perl functions
- **Robust Fitting**: Uses Levenberg-Marquardt algorithm via PDL::Fit::LM
- **Multi-layer Support**: Configurable for single or multi-layer optical systems
- **Standard Data Format**: Reads common ellipsometry data file formats
- **PDL Integration**: Leverages Perl Data Language for efficient numerical computations

## Requirements

- Perl 5.x
- PDL (Perl Data Language)
- PDL::Fit::LM (for Levenberg-Marquardt fitting)
- PDL::NiceSlice (for matrix slicing syntax)

## Installation

```bash
# Install PDL and required modules
cpan PDL PDL::Fit::LM

# Clone or download this repository
# No additional installation needed - use with perl -I.
```

## Quick Start

```perl
use strict;
use warnings;
use PDL;
use VASE;

# Create VASE object
my $vase = VASE->new(layers => 1);

# Load experimental data
$vase->load_data('data/sample.dat');

# Define a simple linear model
sub linear_model {
    my ($params, $x) = @_;
    
    my ($a, $b, $c, $d) = list $params;
    my $wavelength = $x->(:,0);  # Extract wavelength column
    
    my $psi = $a - $b * $wavelength;
    my $delta = $c + $d * $wavelength;
    
    return cat($psi, $delta)->flat;
}

$vase->set_model(\&linear_model);

# Perform fit with initial parameters
my $initial_params = pdl [65, 0.05, 80, 0.1];
my $fit_params = $vase->fit($initial_params);

# Display results
my ($a, $b, $c, $d) = list $fit_params;
print "Fitted parameters:\n";
print "Psi: $a - $b * wavelength\n";
print "Delta: $c + $d * wavelength\n";
```

## Data Format

Input files should contain whitespace-separated columns:

```
# Wavelength(nm) Angle(deg) Psi(deg) Delta(deg)
400 70 45.0 120.0
410 70 44.5 121.0
420 70 44.0 122.0
430 70 43.5 123.0
```

- Lines starting with `#` are treated as comments
- Blank lines are ignored
- Columns: wavelength (nm), incident angle (degrees), Psi (degrees), Delta (degrees)

## API Reference

### Constructor

```perl
my $vase = VASE->new(%args);
```

**Parameters:**
- `layers`: Number of layers in the optical model (default: 1)
- `model`: Optional model function (can be set later with `set_model()`)

### Methods

#### `load_data($filename)`

Loads ellipsometry data from a file.

```perl
$vase->load_data('experimental_data.dat');
```

**Parameters:**
- `$filename`: Path to data file

**Returns:** PDL piddle containing the loaded data

#### `set_model($model_function)`

Sets the optical model function for fitting.

```perl
$vase->set_model(\&my_model);
```

**Parameters:**
- `$model_function`: Code reference to model function

#### `fit($initial_params)`

Performs Levenberg-Marquardt fitting of the model to loaded data.

```perl
my $fitted_params = $vase->fit($initial_params);
```

**Parameters:**
- `$initial_params`: PDL piddle with initial parameter guesses

**Returns:** PDL piddle containing fitted parameters

## Model Function Requirements

Model functions must follow this signature:

```perl
sub model_function {
    my ($params, $x) = @_;
    
    # Extract parameters
    my $param1 = $params->(0);
    my $param2 = $params->(1);
    # ... etc
    
    # Extract input variables
    my $wavelength = $x->(:,0);  # Column 0: wavelength
    my $angle = $x->(:,1);       # Column 1: incident angle
    
    # Calculate Psi and Delta based on your optical model
    my $psi = ...;    # Your Psi calculation
    my $delta = ...;  # Your Delta calculation
    
    # Return concatenated and flattened result
    return cat($psi, $delta)->flat;
}
```

**Key Points:**
- Input `$params` contains fit parameters as a PDL piddle
- Input `$x` contains independent variables (wavelength, angle)
- Must return flattened PDL with [Psi_values, Delta_values]
- Use PDL NiceSlice syntax: `$x->(:,0)` for column extraction

## Example Models

### Linear Model

```perl
sub linear_model {
    my ($params, $x) = @_;
    my ($a, $b, $c, $d) = list $params;
    my $wavelength = $x->(:,0);
    
    my $psi = $a - $b * $wavelength;
    my $delta = $c + $d * $wavelength;
    
    return cat($psi, $delta)->flat;
}
```

### Polynomial Model

```perl
sub polynomial_model {
    my ($params, $x) = @_;
    my ($a0, $a1, $a2, $b0, $b1, $b2) = list $params;
    my $wavelength = $x->(:,0);
    
    my $psi = $a0 + $a1 * $wavelength + $a2 * $wavelength**2;
    my $delta = $b0 + $b1 * $wavelength + $b2 * $wavelength**2;
    
    return cat($psi, $delta)->flat;
}
```

### Angle-Dependent Model

```perl
sub angle_dependent_model {
    my ($params, $x) = @_;
    my ($n, $k, $thickness) = list $params;
    my $wavelength = $x->(:,0);
    my $angle = $x->(:,1);
    
    # Complex optical calculations using both wavelength and angle
    # (This would require implementing Fresnel equations)
    
    return cat($psi, $delta)->flat;
}
```

## Running Examples

```bash
# Run the included example
perl -I. test_fit.pl

# Note: Use -I. to include current directory in module search path
```

## File Structure

```
├── VASE.pm              # Main library module
├── test_fit.pl          # Example usage script
├── data/
│   ├── sample.dat       # Sample data file
│   ├── Jovan_Ellipsometer/  # Equipment-specific datasets
│   └── OTS_on_SiO2/     # Material-specific datasets
└── .github/
    └── copilot-instructions.md
```

## Tips for Model Development

1. **Start Simple**: Begin with linear or polynomial models to verify data loading and fitting
2. **Physical Constraints**: Ensure your model produces physically reasonable values
3. **Parameter Bounds**: Consider reasonable ranges for your initial parameter guesses
4. **Convergence**: The Levenberg-Marquardt algorithm is sensitive to initial conditions
5. **Multi-angle Data**: Use angle-dependent models when you have variable angle measurements

## Contributing

This library is designed for research applications in optical characterization. Feel free to extend the model library or improve the fitting algorithms.

## License

[Add your license information here]