#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 28;
use lib '../lib';

# ─── Module loading ──────────────────────────────────────────────────────────
use_ok('Physics::CVD');
use_ok('Physics::CVD::Chemistry');
use_ok('Physics::CVD::KMC');
use_ok('Physics::CVD::Reactor');
use_ok('Physics::CVD::Transport');
use_ok('Physics::CVD::Film');
use_ok('Physics::CVD::Interface::OpenFOAM');
use_ok('Physics::CVD::Interface::LAMMPS');
use_ok('Physics::CVD::Interface::Cantera');

# ─── Main module ─────────────────────────────────────────────────────────────
my $cvd = Physics::CVD->new(temperature => 700, pressure => 100);
isa_ok($cvd, 'Physics::CVD');
is($cvd->{temperature}, 700, 'temperature set');
is_deeply($cvd->methods, [qw(reactor chemistry transport kmc film)], 'methods list');
is_deeply($cvd->interfaces, [qw(openfoam lammps cantera)], 'interfaces list');

# ─── Chemistry ───────────────────────────────────────────────────────────────
my $chem = Physics::CVD::Chemistry->new(temperature => 953, pressure => 40);
isa_ok($chem, 'Physics::CVD::Chemistry');
$chem->add_species(name => 'SiH4', mass => 32, concentration => 1e16);
$chem->add_gas_reaction(
    name => 'decomp', reactants => ['SiH4'], products => ['SiH2'],
    A => 1e14, Ea => 2.5,
);
my $rates = $chem->gas_rates;
cmp_ok($rates->[0]{rate}, '>', 0, 'gas reaction rate > 0');

my $flux = $chem->impingement_flux(pressure => 10, mass => 32);
cmp_ok($flux, '>', 0, 'impingement flux > 0');

# ─── Reactor ─────────────────────────────────────────────────────────────────
my $reactor = Physics::CVD::Reactor->new(
    temperature => 700, pressure => 100, total_flow => 100,
);
isa_ok($reactor, 'Physics::CVD::Reactor');
cmp_ok($reactor->gas_velocity, '>', 0, 'gas velocity > 0');
cmp_ok($reactor->residence_time, '>', 0, 'residence time > 0');
cmp_ok($reactor->mean_free_path, '>', 0, 'mean free path > 0');

# ─── Transport ───────────────────────────────────────────────────────────────
my $transport = Physics::CVD::Transport->new(
    aspect_ratio => 5, feature_width => 0.1e-4,
);
isa_ok($transport, 'Physics::CVD::Transport');
my $sc = $transport->step_coverage(sticking_coeff => 0.1);
cmp_ok($sc, '>', 0, 'step coverage > 0');
cmp_ok($sc, '<=', 1, 'step coverage <= 1');

# ─── KMC ─────────────────────────────────────────────────────────────────────
my $kmc = Physics::CVD::KMC->new(
    temperature => 700, pressure => 100,
    lattice_size => [15, 15, 10],
);
isa_ok($kmc, 'Physics::CVD::KMC');
$kmc->add_species(name => 'Si', mass => 28, sticking_coeff => 0.3,
                  partial_pressure => 10, diffusion_barrier => 0.5);
$kmc->deposit(steps => 200);
my $stats = $kmc->stats;
cmp_ok($stats->{deposited}, '>', 0, 'KMC atoms deposited');
cmp_ok($stats->{coverage}, '>', 0, 'KMC coverage > 0');

# ─── Film ────────────────────────────────────────────────────────────────────
my $film = $kmc->get_film;
isa_ok($film, 'Physics::CVD::Film');
cmp_ok($film->thickness, '>', 0, 'film has thickness');

done_testing();
