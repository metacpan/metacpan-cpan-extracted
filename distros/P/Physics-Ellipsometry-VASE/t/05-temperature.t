use strict;
use warnings;
use Test::More;
use PDL;

use Physics::Ellipsometry::VASE::Temperature qw(
    temperature_bandgap temperature_drude temperature_thermo_optic
);

sub pdl_close {
    my ($got, $expected, $tolerance, $name) = @_;
    my $error = abs($got - $expected)->max;
    ok($error <= $tolerance, "$name (maximum error $error)");
}

subtest 'temperature-dependent bandgap models' => sub {
    my $eg0 = 1.166;
    my $expected = $eg0 - 4.73e-4 * 300**2 / (300 + 636);
    my $actual = temperature_bandgap(
        $eg0, 300,
        model => 'varshni', alpha => 4.73e-4, beta => 636,
    );
    ok(abs($actual - $expected) < 1e-12, 'Varshni model matches equation');
    is(temperature_bandgap($eg0, 0, model => 'bose_einstein'),
        $eg0, 'Bose-Einstein model has the correct zero-Kelvin limit');

    eval { temperature_bandgap($eg0, -1) };
    like($@, qr/non-negative/, 'negative absolute temperature is rejected');
    eval { temperature_bandgap($eg0, 300, model => 'unknown') };
    like($@, qr/Unknown bandgap model/, 'unknown model is rejected');
    eval { temperature_bandgap($eg0, 300, model => 'varshni', beta => -300) };
    like($@, qr/T \+ beta must not be zero/,
        'singular Varshni parameters are rejected');
    eval { temperature_bandgap($eg0, 300, model => 'bose_einstein', Theta => 0) };
    like($@, qr/Theta must be greater than zero/,
        'non-positive phonon temperature is rejected');
};

subtest 'thermo-optic polynomial' => sub {
    my $reference = pdl [1.45, 2.00];
    my $actual = temperature_thermo_optic(
        $reference, 400,
        T_ref => 300, dndt => 1e-5, d2ndt2 => 2e-8,
    );
    pdl_close($actual, $reference + 0.0011, 1e-12,
        'linear and quadratic coefficients are applied element-wise');

    eval { temperature_thermo_optic($reference, 300, T_ref => -1) };
    like($@, qr/non-negative/, 'negative reference temperature is rejected');
    eval { temperature_thermo_optic($reference, 300, dndt => 'slope') };
    like($@, qr/dndt must be a finite number/,
        'non-numeric thermo-optic coefficient is rejected');
};

subtest 'temperature-dependent Drude model' => sub {
    my $wavelength = pdl [500, 750, 1000];
    my %common = (
        eps_inf => 4.0, omega_p0 => 2.0,
        gamma_0 => 0.05, gamma_ep => 0, gamma_ee => 0,
        T_ref => 300, n_exp => 1.5,
    );

    my ($n_plain, $k_plain) = temperature_drude($wavelength, 300, %common);
    my ($n_ref, $k_ref) = temperature_drude(
        $wavelength, 300, %common, activation_energy => 0.12,
    );
    is($n_ref->nelem, 3, 'one optical constant is returned per wavelength');
    pdl_close($n_ref, $n_plain, 1e-12,
        'activation model is normalized at the reference temperature (n)');
    pdl_close($k_ref, $k_plain, 1e-12,
        'activation model is normalized at the reference temperature (k)');

    my ($n_hot_plain) = temperature_drude($wavelength, 600, %common);
    my ($n_hot_active) = temperature_drude(
        $wavelength, 600, %common, activation_energy => 0.12,
    );
    ok(abs($n_hot_active - $n_hot_plain)->max > 1e-4,
        'activation energy changes the elevated-temperature response');

    my ($n_scalar) = temperature_drude(633, 300, %common);
    is($n_scalar->nelem, 1, 'a scalar wavelength is accepted');

    eval { temperature_drude(pdl([500, 0]), 300, %common) };
    like($@, qr/wavelength.*greater than zero/i,
        'non-positive wavelengths are rejected');
    eval { temperature_drude(pdl('Inf'), 300, %common) };
    like($@, qr/wavelength.*finite/i,
        'non-finite wavelengths are rejected');
    eval { temperature_drude($wavelength, 0, %common) };
    like($@, qr/greater than zero/, 'zero Kelvin is rejected for Drude model');
    eval { temperature_drude($wavelength, 300, %common, n_exp => 'power') };
    like($@, qr/n_exp must be a finite number/,
        'non-numeric carrier exponent is rejected');
    eval {
        temperature_drude(
            $wavelength, 300, %common, activation_energy => -0.1,
        );
    };
    like($@, qr/activation_energy must be non-negative/,
        'negative activation energy is rejected');
};

done_testing();
