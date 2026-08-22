#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';

use Physics::Lithography::Thermal;
use Physics::Lithography::Ablation;
use Physics::Lithography::Pattern;

# ═══════════════════════════════════════════════════════════════════════════════
# Thermal Imprint Example
#
# Simulates laser heating of a PMMA film and predicts ablation profile
# for direct-write lithography
# ═══════════════════════════════════════════════════════════════════════════════

print "=" x 70, "\n";
print "  LASER DIRECT IMPRINT LITHOGRAPHY — Thermal Model\n";
print "=" x 70, "\n\n";

# --- Parameters ---
my $wavelength  = 355e-9;     # nm UV
my $pulse_width = 10e-9;      # 10 ns
my $spot_size   = 5e-6;       # 5 µm radius
my $alpha       = 1e5;        # 1/m (PMMA @ 355nm)
my $F_threshold = 0.1;        # J/cm² PMMA ablation threshold

print "Laser: λ=355nm, τ=10ns, spot=5µm radius\n";
print "Material: PMMA (α=1e5 /m, F_th=0.1 J/cm²)\n\n";

# --- Resolution analysis ---
print "─── Resolution Analysis ───\n\n";
my $pat = Physics::Lithography::Pattern->new();

my $res = $pat->resolution_comparison(diffusivity => 1.1e-7);
printf "  %-15s  %10s  %12s\n", "Config", "L_thermal", "Resolution";
printf "  %-15s  %10s  %12s\n", "-"x15, "-"x10, "-"x12;
for my $r (@$res) {
    printf "  %-15s  %8.1f nm  %10.1f nm\n",
        $r->{name}, $r->{L_thermal_nm}, $r->{resolution_nm};
}

# --- Thermal simulation ---
print "\n─── Thermal Simulation (F=0.5 J/cm²) ───\n\n";

use Physics::Lithography::Laser;

my $thermal_laser = Physics::Lithography::Laser->new(
    wavelength  => 355e-9,
    pulse_width => $pulse_width,
    fluence     => 0.5,
    spot_size   => $spot_size,
);

my $thermal = Physics::Lithography::Thermal->new(
    material => 'pmma',
    n_r      => 50,
    n_z      => 50,
    domain_r => 20e-6,
    domain_z => 10e-6,
);

$thermal->solve(laser => $thermal_laser, time => 100e-9);

printf "  Peak surface temperature: %.0f K\n", $thermal->T_max;
printf "  Melt radius: %.2f µm\n", ($thermal->melt_radius // 0) * 1e6;
printf "  Melt depth:  %.2f µm\n", ($thermal->melt_depth // 0) * 1e6;

# --- Ablation profile ---
print "\n─── Ablation Profile vs. Fluence ───\n\n";

my $abl = Physics::Lithography::Ablation->new(
    alpha       => $alpha,
    F_threshold => $F_threshold,
);

printf "  %-12s  %10s  %10s  %12s\n", "Fluence", "Depth", "Width", "Volume";
printf "  %-12s  %10s  %10s  %12s\n", "(J/cm²)", "(nm)", "(µm)", "(µm³)";
printf "  %s\n", "-" x 50;

for my $F (0.1, 0.2, 0.5, 1.0, 2.0, 5.0) {
    my $d = $abl->ablation_depth(fluence => $F);
    my $crater = $abl->crater_profile(fluence => $F, spot_size => $spot_size, points => 5);
    my $vol = $abl->volume_per_pulse(fluence => $F, spot_size => $spot_size);

    # Crater width from profile
    my $width = 0;
    if ($crater) {
        $width = 2 * $crater->{radius_um} * 1e-6;
    }

    printf "  %-12.2f  %8.1f    %8.2f    %10.3f\n",
        $F, $d * 1e9, $width * 1e6, $vol * 1e18;
}

# --- Multi-pulse patterning ---
print "\n─── Multi-Pulse Incubation ───\n\n";
printf "  %-8s  %12s  %12s\n", "Pulses", "F_th (J/cm²)", "Depth (nm)";
printf "  %s\n", "-" x 36;

for my $N (1, 5, 10, 50, 100) {
    my $F_th_N = $abl->threshold_with_incubation(N => $N, S => 0.85);
    my $d = $abl->ablation_depth(fluence => 0.3, F_threshold_eff => $F_th_N);
    printf "  %-8d  %10.4f      %10.1f\n", $N, $F_th_N, $d * 1e9;
}

# --- Process window ---
print "\n─── Scan Parameters ───\n\n";
my $scan = $pat->scan_parameters(
    spot_size => $spot_size,
    overlap   => 0.5,
    rep_rate  => 100_000,
);
printf "  Pulse pitch:    %.2f µm\n", $scan->{pitch_um};
printf "  Scan velocity:  %.1f mm/s\n", $scan->{velocity_mm_s};
printf "  Throughput:     %.4f cm²/s\n", $scan->{throughput_cm2_s};

# --- Feature prediction ---
print "\n─── Feature Dimensions (F=0.5 J/cm²) ───\n\n";
my $line = $pat->line_pattern(
    fluence     => 0.5,
    spot_size   => $spot_size,
    F_threshold => $F_threshold,
    alpha       => $alpha,
    overlap     => 0.5,
);
printf "  Line width:  %.1f nm\n", $line->{width_nm};
printf "  Line depth:  %.1f nm\n", $line->{depth_nm};
printf "  Aspect ratio: %.3f\n", $line->{aspect_ratio};

print "\n", "=" x 70, "\n";
print "  Simulation complete.\n";
print "=" x 70, "\n";
