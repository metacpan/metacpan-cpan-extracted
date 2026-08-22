#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 22;
use lib 'lib';

# ─── Module loading ───────────────────────────────────────────────────────────
use_ok('Physics::PVD');
use_ok('Physics::PVD::KMC');
use_ok('Physics::PVD::DSMC');
use_ok('Physics::PVD::Film');
use_ok('Physics::PVD::Interface::OpenFOAM');
use_ok('Physics::PVD::Interface::LAMMPS');
use_ok('Physics::PVD::Interface::QuantumATK');

# ─── Physics::PVD main module ────────────────────────────────────────────────
my $pvd = Physics::PVD->new(temperature => 500, pressure => 2e-3);
isa_ok($pvd, 'Physics::PVD');
is($pvd->{temperature}, 500, 'temperature set correctly');
is_deeply([sort $pvd->available_methods], [sort qw(kmc dsmc hybrid)], 'methods list');
is_deeply([sort $pvd->available_interfaces], [sort qw(lammps openfoam quantumatk)], 'interfaces list');

# ─── KMC engine ──────────────────────────────────────────────────────────────
my $kmc = Physics::PVD::KMC->new(
    lattice_size => [20, 20, 10],
    temperature  => 600,
);
isa_ok($kmc, 'Physics::PVD::KMC');
$kmc->add_species(name => 'Ta', mass => 180.95, binding_energy => 8.1);
is(scalar(keys %{$kmc->{species}}), 1, 'species added');

# Run a short simulation
$kmc->run(steps => 500);
ok($kmc->{steps} > 0, 'KMC ran steps');
ok($kmc->{deposited} > 0, 'atoms deposited');
cmp_ok($kmc->coverage, '>', 0, 'coverage > 0');

# ─── Film analysis ───────────────────────────────────────────────────────────
my $film = $kmc->get_film;
isa_ok($film, 'Physics::PVD::Film');
cmp_ok($film->thickness, '>', 0, 'film has thickness');
cmp_ok($film->roughness, '>=', 0, 'roughness non-negative');

# ─── DSMC engine ─────────────────────────────────────────────────────────────
my $dsmc = Physics::PVD::DSMC->new(
    n_particles => 500,
    pressure    => 0.5,     # lower pressure = longer mean free path = more arrivals
    temperature => 300,
);
isa_ok($dsmc, 'Physics::PVD::DSMC');
$dsmc->run(timesteps => 1000);
my $stats = $dsmc->stats;
cmp_ok($stats->{arrived}, '>', 0, 'DSMC particles arrived');
cmp_ok($dsmc->knudsen_number, '>', 0, 'Knudsen number computed');

done_testing();
