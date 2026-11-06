package Physics::Ellipsometry::VASE::Temperature;
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use Exporter 'import';
use Scalar::Util qw(looks_like_number);

our @EXPORT_OK = qw(temperature_bandgap temperature_drude temperature_thermo_optic);

our $VERSION = '1.04';

=encoding utf8

=head1 NAME

Physics::Ellipsometry::VASE::Temperature - Temperature-dependent optical
models for spectroscopic ellipsometry

=head1 SYNOPSIS

    use PDL;
    use Physics::Ellipsometry::VASE::Temperature qw(
        temperature_bandgap temperature_drude temperature_thermo_optic
    );

    # Track bandgap shift with temperature
    my $Eg_300K = temperature_bandgap(1.17, 300,
        model => 'varshni', alpha => 4.73e-4, beta => 636);
    my $Eg_600K = temperature_bandgap(1.17, 600,
        model => 'varshni', alpha => 4.73e-4, beta => 636);

    # Metal optical constants at elevated temperature
    my $lambda = sequence(100) * 10 + 400;
    my ($n, $k) = temperature_drude($lambda, 500,
        omega_p0 => 9.0, gamma_0 => 0.02, gamma_ep => 1e-4);

=head1 DESCRIPTION

Temperature affects optical properties through several mechanisms:

=over 4

=item B<Bandgap narrowing> - Thermal expansion and electron-phonon
interactions reduce the semiconductor bandgap as temperature increases.
This red-shifts absorption edges.

=item B<Increased scattering> - In metals and TCOs, electron-phonon
scattering increases with temperature, broadening the Drude response
and increasing resistivity.

=item B<Thermo-optic effect> - In transparent materials, the refractive
index changes linearly with temperature (dn/dT), typically
10^-6 to 10^-4 per Kelvin.

=item B<Carrier density changes> - In semiconductors, thermal excitation
increases free carrier density exponentially with temperature.

=back

This module provides functions to incorporate these effects into
ellipsometric models, enabling in-situ analysis at non-ambient
temperatures (e.g., CVD monitoring, annealing studies).

=head1 FUNCTIONS

=head2 temperature_bandgap

    my $Eg_T = temperature_bandgap($Eg0, $T,
                                    model => 'varshni',
                                    alpha => $alpha, beta => $beta);

Calculates the temperature-dependent optical bandgap using either:

B<Varshni model> (1967):

    Eg(T) = Eg(0) - alpha * T^2 / (T + beta)

B<Bose-Einstein model:>

    Eg(T) = Eg(0) - 2*aB / (exp(Theta/T) - 1)

B<Parameters:>

=over 4

=item C<$Eg0> - bandgap at T=0 K [eV]

=item C<$T> - temperature [K]

=item C<model> - 'varshni' (default) or 'bose_einstein'

=item C<alpha> - Varshni coefficient [eV/K] (Si: 4.73e-4)

=item C<beta> - Varshni parameter [K] (Si: 636)

=item C<aB> - Bose-Einstein coupling [eV]

=item C<Theta> - characteristic phonon temperature [K]

=back

    # Silicon bandgap at various temperatures
    for my $T (100, 200, 300, 400, 500) {
        my $Eg = temperature_bandgap(1.166, $T,
            model => 'varshni', alpha => 4.73e-4, beta => 636);
        printf "Si Eg(%dK) = %.4f eV\n", $T, $Eg;
    }

=head2 temperature_drude

    my ($n, $k) = temperature_drude($lambda_nm, $T, %params);

Computes the Drude dielectric function with temperature-dependent
scattering rate and optional T-dependent carrier density:

    Gamma(T) = Gamma_0 + Gamma_ep * T + Gamma_ee * T^2

where Gamma_0 is residual (impurity) scattering, Gamma_ep is
electron-phonon, and Gamma_ee is electron-electron.

B<Parameters:>

=over 4

=item C<$T> - temperature [K]

=item C<eps_inf> - high-frequency dielectric constant

=item C<omega_p0> - plasma frequency at reference T [eV]

=item C<gamma_0> - residual scattering rate [eV]

=item C<gamma_ep> - electron-phonon coefficient [eV/K]

=item C<gamma_ee> - electron-electron coefficient [eV/K^2]

=item C<T_ref> - reference temperature [K] (default 300)

=item C<n_exp> - carrier density temperature exponent (0 for metals)

=item C<activation_energy> - optional carrier activation energy [eV].  When
non-zero, the carrier density is normalized to C<T_ref> and follows

    n(T) / n(T_ref) = (T/T_ref)^n_exp
        * exp[-Ea/(2*kB) * (1/T - 1/T_ref)]

This is useful for doped semiconductors.  The default is zero, preserving the
metal-like power-law model.

=back

    # Gold optical constants at 300K vs 600K
    my $lambda = sequence(200) * 5 + 400;
    my ($n_300, $k_300) = temperature_drude($lambda, 300,
        eps_inf => 6.9, omega_p0 => 9.03,
        gamma_0 => 0.02, gamma_ep => 7e-5);
    my ($n_600, $k_600) = temperature_drude($lambda, 600,
        eps_inf => 6.9, omega_p0 => 9.03,
        gamma_0 => 0.02, gamma_ep => 7e-5);

=head2 temperature_thermo_optic

    my $n_T = temperature_thermo_optic($n_ref, $T,
                                        T_ref => 300,
                                        dndt => 1e-5);

Simple polynomial model for the temperature-dependent refractive index
in transparent materials:

    n(T) = n(T0) + (dn/dT)*(T - T0) + (d²n/dT²)/2 * (T - T0)²

B<Typical dn/dT values:>

    Fused silica:  +1.0e-5 /K
    BK7 glass:     +3.0e-6 /K
    Silicon:       +1.8e-4 /K
    Water:         -1.0e-4 /K (negative!)

    # SiO2 thermal lens calculation
    my ($n_ref, $k_ref) = cauchy_nk(pdl(633), 1.4580, 0.003, 0);
    my $n_hot = temperature_thermo_optic($n_ref, 400, T_ref=>300,
                                          dndt => 1.0e-5);

=head1 SEE ALSO

L<Physics::Ellipsometry::VASE::Dispersion>,
L<Physics::Ellipsometry::VASE>

Y.P. Varshni, "Temperature dependence of the energy gap in semiconductors",
I<Physica> B<34>, 149 (1967).

=cut

# Temperature-dependent bandgap shift
# Models how the optical gap changes with temperature using:
# - Varshni: Eg(T) = Eg(0) - alpha*T^2 / (T + beta)
# - Bose-Einstein: Eg(T) = Eg(0) - 2*aB / (exp(Theta/T) - 1)
#
# $Eg0: bandgap at T=0 [eV]
# $T: temperature [K]
# $model: 'varshni' or 'bose_einstein'
# Returns: Eg(T) in eV
sub temperature_bandgap {
    my ($Eg0, $T, %params) = @_;
    _validate_number($Eg0, 'Eg0');
    _validate_temperature($T, allow_zero => 1);
    my $model = $params{model} // 'varshni';

    if ($model eq 'varshni') {
        my $alpha = $params{alpha} // 5.5e-4;  # eV/K (Si: 4.73e-4)
        my $beta  = $params{beta}  // 230;     # K (Si: 636)
        _validate_number($alpha, 'alpha');
        _validate_number($beta, 'beta');
        return $Eg0 if $T == 0;
        die "T + beta must not be zero" if $T + $beta == 0;
        return $Eg0 - $alpha * $T**2 / ($T + $beta);
    }
    elsif ($model eq 'bose_einstein') {
        my $aB    = $params{aB}    // 0.05;    # coupling strength [eV]
        my $Theta = $params{Theta} // 300;     # characteristic temperature [K]
        _validate_number($aB, 'aB');
        _validate_number($Theta, 'Theta');
        die "Theta must be greater than zero" if $Theta <= 0;
        return $Eg0 if $T == 0;
        return $Eg0 - 2 * $aB / (exp($Theta / $T) - 1);
    }
    else {
        die "Unknown bandgap model: $model (use 'varshni' or 'bose_einstein')";
    }
}

# Temperature-dependent Drude model
# Accounts for thermal changes in carrier density and scattering rate:
# - Carrier density: n(T) = n0 * (T/T0)^p * exp(-Ea/(2kT)) for semiconductors
#   or n(T) = n0 for metals
# - Scattering rate: Gamma(T) = Gamma0 + Gamma_ee*T^2 + Gamma_ep*T
#   (electron-electron + electron-phonon contributions)
#
# Returns (n, k) piddles for the given wavelength range
sub temperature_drude {
    my ($lambda_nm, $T, %params) = @_;
    _validate_temperature($T);
    my $lambda = pdl($lambda_nm);
    die "lambda_nm must contain at least one wavelength"
        unless $lambda->nelem;
    die "wavelength values must be finite"
        unless all($lambda->isfinite);
    die "wavelength values must be greater than zero"
        if any($lambda <= 0);

    my $eps_inf  = $params{eps_inf}  // 1.0;
    my $omega_p0 = $params{omega_p0} // 9.0;    # plasma freq at ref T [eV]
    my $gamma_0  = $params{gamma_0}  // 0.02;   # residual scattering [eV]
    my $gamma_ep = $params{gamma_ep} // 1e-4;   # e-phonon coeff [eV/K]
    my $gamma_ee = $params{gamma_ee} // 1e-7;   # e-electron coeff [eV/K^2]
    my $T_ref    = $params{T_ref}    // 300;     # reference temperature [K]
    my $n_exp    = $params{n_exp}    // 0;       # carrier density T-exponent
    my $Ea       = $params{activation_energy} // 0; # carrier activation [eV]

    _validate_temperature($T_ref);
    for my $parameter (
        [ $eps_inf,  'eps_inf' ],
        [ $omega_p0, 'omega_p0' ],
        [ $gamma_0,  'gamma_0' ],
        [ $gamma_ep, 'gamma_ep' ],
        [ $gamma_ee, 'gamma_ee' ],
        [ $n_exp,    'n_exp' ],
        [ $Ea,       'activation_energy' ],
    ) {
        _validate_number(@$parameter);
    }
    die "activation_energy must be non-negative" if $Ea < 0;

    # Temperature-dependent scattering
    my $gamma_T = $gamma_0 + $gamma_ep * $T + $gamma_ee * $T**2;
    _validate_number($gamma_T, 'temperature-dependent scattering rate');

    # Temperature-dependent plasma frequency
    # omega_p^2 ∝ n_carrier/m* ; n_carrier may depend on T
    my $carrier_ratio = ($T / $T_ref)**$n_exp;
    if ($Ea != 0) {
        my $k_boltzmann = 8.617333262e-5; # eV/K
        $carrier_ratio *= exp(
            -$Ea / (2 * $k_boltzmann) * (1 / $T - 1 / $T_ref)
        );
    }
    _validate_number($carrier_ratio, 'carrier density ratio');
    die "carrier density ratio must be non-negative" if $carrier_ratio < 0;
    my $omega_p_T = $omega_p0 * sqrt($carrier_ratio);

    # Compute dielectric function
    my $E = 1239.842 / $lambda;
    my $eps = $eps_inf - $omega_p_T**2 / ($E**2 + i() * $E * $gamma_T);
    my $N = sqrt($eps);
    return ($N->re, $N->im->abs);
}

# Thermo-optic coefficient model
# n(T) = n(T0) + (dn/dT) * (T - T0) + (d2n/dT2)/2 * (T - T0)^2
# Simple polynomial expansion for temperature-dependent refractive index
# Works for transparent materials (glasses, crystals) far from resonances
#
# $n_ref: refractive index at reference temperature (PDL)
# $T: temperature [K]
# $T_ref: reference temperature [K]
# $dndt: first-order thermo-optic coefficient [1/K]
# $d2ndt2: second-order coefficient [1/K^2] (optional)
sub temperature_thermo_optic {
    my ($n_ref, $T, %params) = @_;
    _validate_temperature($T, allow_zero => 1);
    my $T_ref  = $params{T_ref}  // 300;
    my $dndt   = $params{dndt}   // 1e-5;    # typical for glass
    my $d2ndt2 = $params{d2ndt2} // 0;

    _validate_temperature($T_ref, allow_zero => 1);
    _validate_number($dndt, 'dndt');
    _validate_number($d2ndt2, 'd2ndt2');

    my $dT = $T - $T_ref;
    my $n_T = $n_ref + $dndt * $dT + 0.5 * $d2ndt2 * $dT**2;

    return $n_T;
}

sub _validate_temperature {
    my ($temperature, %opts) = @_;
    _validate_number($temperature, 'temperature');
    my $minimum_ok = $opts{allow_zero} ? $temperature >= 0 : $temperature > 0;
    die "temperature must be " . ($opts{allow_zero} ? 'non-negative' : 'greater than zero')
        unless $minimum_ok;
    return $temperature;
}

sub _validate_number {
    my ($value, $name) = @_;
    my $display = defined($value) ? "$value" : '';
    die "$name must be a finite number"
        unless defined($value)
            && looks_like_number($value)
            && $value == $value
            && $display !~ /(?:inf|nan)/i;
    return $value;
}

1;
