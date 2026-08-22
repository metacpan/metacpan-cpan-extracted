#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';

use Physics::Lithography::LIFT;

# ═══════════════════════════════════════════════════════════════════════════════
# LIFT (Laser-Induced Forward Transfer) Example
#
# Characterizes transfer regimes for gold film LIFT printing
# ═══════════════════════════════════════════════════════════════════════════════

print "=" x 70, "\n";
print "  LASER-INDUCED FORWARD TRANSFER (LIFT) — Gold Film\n";
print "=" x 70, "\n\n";

# --- Configuration ---
my $lift = Physics::Lithography::LIFT->new(
    film_thickness  => 100e-9,     # 100 nm Au donor film
    density         => 19300,      # kg/m³
    T_melt          => 1337,       # K
    T_boil          => 3129,       # K
    L_vaporize      => 1.74e6,     # J/kg
    surface_tension => 1.14,       # N/m
    viscosity       => 5.0e-3,     # Pa·s
    alpha           => 7.09e7,     # 1/m (Au @ 355nm)
    reflectivity    => 0.37,       # Au @ 355nm
    gap             => 50e-6,      # 50 µm gap
);

printf "Donor: 100nm Au | Gap: 50µm | λ=355nm\n\n";

# --- Transfer threshold ---
my $F_th = $lift->transfer_threshold;
printf "Transfer threshold: %.4f J/cm²\n\n", $F_th;

# --- Fluence sweep ---
print "─── Fluence Sweep ───\n\n";
printf "  %-8s  %-14s  %8s  %8s  %10s\n",
    "F(J/cm²)", "Regime", "Drop(µm)", "V(m/s)", "P(MPa)";
printf "  %s\n", "-" x 56;

my $sweep = $lift->fluence_sweep(
    F_min      => 0.01,
    F_max      => 5.0,
    points     => 20,
    spot_size  => 5e-6,
    pulse_width => 10e-9,
);

for my $pt (@$sweep) {
    printf "  %-8.3f  %-14s  %8.2f  %8.1f  %10.2f\n",
        $pt->{fluence}, $pt->{regime}, $pt->{droplet_um},
        $pt->{velocity_ms}, $pt->{pressure_MPa};
}

# --- Detailed analysis at operating point ---
my $F_op = $F_th * 1.5;  # 1.5× threshold (jetting)
print "\n─── Operating Point: F = ", sprintf("%.3f", $F_op), " J/cm² ───\n\n";

my $regime = $lift->transfer_regime(fluence => $F_op);
my $P = $lift->recoil_pressure(fluence => $F_op, pulse_width => 10e-9);
my $v = $lift->jet_velocity(fluence => $F_op, pulse_width => 10e-9);
my $D = $lift->droplet_diameter(fluence => $F_op, spot_size => 5e-6);
my $We = $lift->weber_number(fluence => $F_op, spot_size => 5e-6, pulse_width => 10e-9);
my $Re = $lift->reynolds_number(fluence => $F_op, spot_size => 5e-6, pulse_width => 10e-9);
my $tof = $lift->flight_time(fluence => $F_op, pulse_width => 10e-9);

printf "  Regime:            %s\n", $regime;
printf "  Recoil pressure:   %.2f MPa\n", $P / 1e6;
printf "  Jet velocity:      %.1f m/s\n", $v;
printf "  Droplet diameter:  %.2f µm\n", $D * 1e6;
printf "  Weber number:      %.1f\n", $We;
printf "  Reynolds number:   %.0f\n", $Re;
printf "  Time of flight:    %.2f µs\n", $tof * 1e6;

# --- Film thickness effect ---
print "\n─── Effect of Donor Film Thickness ───\n\n";
printf "  %-10s  %12s  %12s\n", "Thickness", "F_threshold", 'Regime@0.5';
printf "  %s\n", "-" x 38;

for my $t_nm (20, 50, 100, 200, 500) {
    my $l = Physics::Lithography::LIFT->new(
        film_thickness  => $t_nm * 1e-9,
        density         => 19300,
        T_melt          => 1337,
        T_boil          => 3129,
        L_vaporize      => 1.74e6,
        alpha           => 7.09e7,
        reflectivity    => 0.37,
    );
    my $th = $l->transfer_threshold;
    my $r  = $l->transfer_regime(fluence => 0.5);
    printf "  %6d nm   %10.4f      %-12s\n", $t_nm, $th, $r;
}

print "\n", "=" x 70, "\n";
print "  LIFT analysis complete.\n";
print "=" x 70, "\n";
