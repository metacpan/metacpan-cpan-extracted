#!/usr/bin/env perl
use strict;
use warnings;
use PDL;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Physics::Ellipsometry::VASE::Temperature qw(
    temperature_bandgap temperature_drude
);

my $wavelength_nm = pdl [633];

print "Temperature-dependent silicon and doped-semiconductor model\n";
print " T (K)   Si Eg (eV)       n(633 nm)       k(633 nm)\n";
for my $temperature (300, 400, 500, 600) {
    my $bandgap = temperature_bandgap(
        1.166, $temperature,
        model => 'varshni', alpha => 4.73e-4, beta => 636,
    );
    my ($n, $k) = temperature_drude(
        $wavelength_nm, $temperature,
        eps_inf => 4.0,
        omega_p0 => 2.0,
        gamma_0 => 0.05,
        gamma_ep => 1e-4,
        T_ref => 300,
        n_exp => 1.5,
        activation_energy => 0.12,
    );
    printf "%6d   %10.5f   %13.6f   %13.6f\n",
        $temperature, $bandgap, $n->at(0), $k->at(0);
}
