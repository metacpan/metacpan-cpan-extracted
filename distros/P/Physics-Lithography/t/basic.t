#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 35;

use lib 'lib';

# ─── Module loading ───────────────────────────────────────────────────────────
use_ok('Physics::Lithography');
use_ok('Physics::Lithography::Laser');
use_ok('Physics::Lithography::Thermal');
use_ok('Physics::Lithography::Ablation');
use_ok('Physics::Lithography::PhaseChange');
use_ok('Physics::Lithography::Pattern');
use_ok('Physics::Lithography::LIFT');
use_ok('Physics::Lithography::Interface::OpenFOAM');
use_ok('Physics::Lithography::Interface::LAMMPS');

# ─── Laser module ────────────────────────────────────────────────────────────
my $laser = Physics::Lithography::Laser->new(
    wavelength  => 355e-9,
    pulse_width => 10e-9,
    fluence     => 0.5,
    spot_size   => 5e-6,
);
isa_ok($laser, 'Physics::Lithography::Laser');

my $profile = $laser->spatial_profile(0);
ok($profile > 0, 'Beam profile at center > 0');

my $profile_edge = $laser->spatial_profile(20e-6);
ok($profile_edge < $profile, 'Beam profile falls off from center');

# ─── Thermal module ──────────────────────────────────────────────────────────
my $thermal = Physics::Lithography::Thermal->new(
    material => 'pmma',
    n_r      => 20,
    n_z      => 20,
    domain_r => 15e-6,
    domain_z => 5e-6,
);
isa_ok($thermal, 'Physics::Lithography::Thermal');

my $thermal_laser = Physics::Lithography::Laser->new(
    wavelength  => 355e-9,
    pulse_width => 10e-9,
    fluence     => 0.5,
    spot_size   => 5e-6,
);
$thermal->solve(laser => $thermal_laser, time => 50e-9, steps => 200);
my $T_surf = $thermal->T_max;
ok($T_surf > 300, "Surface heated: T_max = $T_surf K");

# ─── Ablation module ─────────────────────────────────────────────────────────
my $abl = Physics::Lithography::Ablation->new(
    alpha       => 1e5,
    F_threshold => 0.1,
);
isa_ok($abl, 'Physics::Lithography::Ablation');

my $depth = $abl->ablation_depth(fluence => 0.5);
ok($depth > 0, "Ablation depth > 0: $depth m");

my $depth_below = $abl->ablation_depth(fluence => 0.05);
is($depth_below, 0, 'No ablation below threshold');

my $crater = $abl->crater_profile(fluence => 0.5, spot_size => 5e-6, points => 20);
ok(defined $crater, 'Crater profile returned');
ok(scalar(@{$crater->{profile}}) == 20, 'Crater profile has correct number of points');
ok($crater->{max_depth_nm} > 0, 'Crater has depth at center');

my $vol = $abl->volume_per_pulse(fluence => 0.5, spot_size => 5e-6);
ok($vol > 0, "Ablation volume > 0: $vol m³");

# ─── Phase Change module ─────────────────────────────────────────────────────
my $pc = Physics::Lithography::PhaseChange->new();
isa_ok($pc, 'Physics::Lithography::PhaseChange');

# ─── Pattern module ──────────────────────────────────────────────────────────
my $pat = Physics::Lithography::Pattern->new();
isa_ok($pat, 'Physics::Lithography::Pattern');

my $feat = $pat->minimum_feature_size(
    spot_size   => 5e-6,
    diffusivity => 1e-7,
    pulse_width => 10e-9,
);
ok($feat->{minimum_nm} > 0, "Min feature size: $feat->{minimum_nm} nm");
ok($feat->{L_thermal_nm} > 0, "L_thermal: $feat->{L_thermal_nm} nm");

my $edge = $pat->edge_acuity(diffusivity => 1e-7, pulse_width => 10e-9, alpha => 1e6);
ok($edge->{edge_width_nm} > 0, "Edge width: $edge->{edge_width_nm} nm");

my $ar = $pat->max_aspect_ratio(fluence => 1.0, F_threshold => 0.1, alpha => 1e6, spot_size => 5e-6);
ok($ar > 0, "Max aspect ratio: $ar");

my $scan = $pat->scan_parameters(spot_size => 5e-6, rep_rate => 10000);
ok($scan->{pitch_um} > 0, "Scan pitch: $scan->{pitch_um} µm");
ok($scan->{velocity_mm_s} > 0, "Scan velocity: $scan->{velocity_mm_s} mm/s");

# ─── LIFT module ─────────────────────────────────────────────────────────────
my $lift = Physics::Lithography::LIFT->new(
    film_thickness => 100e-9,
    density        => 19300,
    T_melt         => 1337,
    T_boil         => 3129,
    L_vaporize     => 1.74e6,
    surface_tension => 1.14,
);
isa_ok($lift, 'Physics::Lithography::LIFT');

my $F_th = $lift->transfer_threshold;
ok($F_th > 0, "LIFT threshold: $F_th J/cm²");

my $regime = $lift->transfer_regime(fluence => $F_th * 2);
is($regime, 'jetting', "LIFT regime at 2×F_th: $regime");

my $regime_low = $lift->transfer_regime(fluence => $F_th * 0.5);
is($regime_low, 'no_transfer', "LIFT regime below threshold: $regime_low");

my $P = $lift->recoil_pressure(fluence => 0.5, pulse_width => 10e-9);
ok($P > 0, "Recoil pressure: $P Pa");

my $D = $lift->droplet_diameter(fluence => 0.5, spot_size => 5e-6);
ok($D >= 0, "Droplet diameter: $D m");

done_testing();
