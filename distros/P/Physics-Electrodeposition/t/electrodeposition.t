#!/usr/bin/env perl
#
# electrodeposition.t - sanity tests for Physics::Electrodeposition
#
# Run:  perl -Ilib t/electrodeposition.t     (or: prove -Ilib t/)
#
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Physics::Electrodeposition;

use constant F => 96485.33212;

# helper: relative closeness
sub near {
    my ($got, $exp, $tol, $name) = @_;
    $tol //= 1e-3;
    my $ok = abs($got - $exp) <= $tol * (abs($exp) > 1e-12 ? abs($exp) : 1);
    ok($ok, $name) or diag("got $got, expected $exp (tol $tol)");
}

#--- geometry: 300 mm wafer area = pi * 15^2 cm^2 -----------------------------
my $cu = Physics::Electrodeposition->new(
    wafer_diameter => 300, current_density => 20, target_thickness => 1.0,
);
near($cu->wafer_area, 3.14159265*15*15, 1e-4, '300 mm wafer area = pi*r^2');
near($cu->wafer_radius, 15.0, 1e-9, '300 mm wafer radius = 15 cm');

#--- current: I = j * A -------------------------------------------------------
near($cu->current, 0.020 * $cu->wafer_area, 1e-6, 'I = j * A');

#--- Faraday's law: independent analytic check of deposited mass --------------
# m = Q * M * CE / (n * F);   Q = I * t
my $Q = $cu->current * $cu->process_time;
near($cu->charge, $Q, 1e-9, 'charge = I * t');
my $m_expected = $Q * 63.546 * 0.97 / (2 * F);
near($cu->mass_deposited, $m_expected, 1e-6, "Faraday's law mass balance");

#--- thickness closes with mass: m = rho * A * h ------------------------------
my $h_cm = $cu->film_thickness;          # cm
my $m_from_h = 8.96 * $cu->wafer_area * $h_cm;
near($cu->mass_deposited, $m_from_h, 1e-6, 'mass = rho * area * thickness');
near($cu->film_thickness_um, 1.0, 1e-6, 'solves time to hit 1.0 um target');

#--- deposition rate * time = thickness ---------------------------------------
near($cu->deposition_rate * $cu->process_time, $h_cm, 1e-9, 'rate * time = h');

#--- limiting current density: j_lim = n F D C / delta ------------------------
my $jl_expected = 2 * F * 7.2e-6 * (0.28e-3) / 0.010;   # A/cm^2
near($cu->limiting_current_density, $jl_expected, 1e-6, 'j_lim = nFDC/delta');
ok($cu->current_fraction_of_limit < 1, 'operating below limiting current');

#--- power: P = V * I ---------------------------------------------------------
near($cu->power, $cu->cell_voltage * $cu->current, 1e-9, 'P = V * I');
near($cu->energy, $cu->power * $cu->process_time, 1e-9, 'E = P * t');
ok($cu->cell_voltage > 0, 'cell voltage positive');

#--- specific energy sanity: within a physical band for copper ----------------
ok($cu->specific_energy_kWh_kg > 0.2 && $cu->specific_energy_kWh_kg < 5,
   'specific energy in physical band for Cu');

#--- mass balance: soluble anode nearly closes the ion loop -------------------
my $mb = $cu->mass_balance;
# ion replenished by anode minus consumed at cathode = H2 side-reaction deficit
near($mb->{ion_replenished_mol} - $mb->{ion_consumed_mol},
     $mb->{net_ion_change_mol}, 1e-9, 'soluble-anode ion loop closes');
ok($mb->{H2_evolved_mol} > 0, 'H2 side reaction present at CE < 100%');

#--- inert anode: bath depletes, O2 + acid generated --------------------------
my $inert = Physics::Electrodeposition->new(
    anode_type => 'inert', current_density => 20, target_thickness => 1.0,
);
my $imb = $inert->mass_balance;
ok($imb->{net_ion_change_mol} < 0, 'inert anode depletes metal ion');
ok($imb->{O2_evolved_mol} > 0,     'inert anode evolves O2');
ok($imb->{Hplus_generated_anode_mol} > 0, 'inert anode generates acid');

#--- monotonic physics: higher current density -> more power, less time -------
my $lo = Physics::Electrodeposition->new(current_density => 10, target_thickness => 1);
my $hi = Physics::Electrodeposition->new(current_density => 30, target_thickness => 1);
ok($hi->power > $lo->power,               'higher j -> higher power');
ok($hi->process_time < $lo->process_time, 'higher j -> shorter time');
near($lo->film_thickness_um, $hi->film_thickness_um, 1e-6,
     'same target thickness regardless of j');

#--- terminal effect scales with wafer radius^2 -------------------------------
my $w200 = Physics::Electrodeposition->new(wafer_diameter => 200, current_density => 20);
my $w300 = Physics::Electrodeposition->new(wafer_diameter => 300, current_density => 20);
my $ratio = $w300->terminal_effect_drop / $w200->terminal_effect_drop;
near($ratio, (15.0/10.0)**2, 1e-6, 'terminal-effect drop ~ R^2');

#--- thicker seed lowers sheet resistance and terminal effect -----------------
my $thin  = Physics::Electrodeposition->new(seed_thickness => 50,  current_density => 20);
my $thick = Physics::Electrodeposition->new(seed_thickness => 200, current_density => 20);
ok($thick->terminal_effect_drop < $thin->terminal_effect_drop,
   'thicker seed -> smaller terminal effect');

#--- report renders and contains the required sections ------------------------
my $rep = $cu->report;
like($rep, qr/FILM THICKNESS/,  'report has film thickness section');
like($rep, qr/MASS BALANCE/,    'report has mass balance section');
like($rep, qr/POWER INPUT/,     'report has power section');
like($rep, qr/UNIFORMITY/,      'report has uniformity section');
like($rep, qr/INSIGHT/,         'report has insight section');

done_testing();
