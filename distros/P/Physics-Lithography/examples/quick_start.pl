#!usr/bin/env perl
use Physics::Lithography;

my $litho = Physics::Lithography->new(verbose => 1);

# Create a laser source
my $laser = $litho->laser(
	wavelength  => 355e-9,  # 355 nm (UV)
	pulse_width => 10e-9,   # 10 ns
	fluence     => 0.5,	# J/cm^2
	spot_size   => 5e-6,	# 5 um (1/e^2 radius)
);

# Solve heat equation
my $thermal = $litho->thermal(material => 'pmma');
$thermal->solve(laser => $laser, time => 100e-9);
printf "Peak T: %.0f K\n", $thermal->T_max;

# Calculate ablation depth
my $abl = $litho->ablation(alpha => 1e5, F_threshold => 0.1);
printf "Depth: %.0f nm\n", $abl->ablation_depth(fluence => 0.5) * 1e9;


