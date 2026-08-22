#!/usr/bin/env perl
#
# copper_through_mask_gdsii.pl
#
# Model through-mask copper electrodeposition (e.g. Cu pillar / micro-bump / RDL
# plating) on a 300 mm wafer, taking the plating-opening geometry from a GDSII
# file. The script first SYNTHESISES a representative GDSII reticle (so it is
# self-contained), then loads it and runs the patterned plating model.
#
# Run:  perl -Ilib examples/copper_through_mask_gdsii.pl
#
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Physics::Electrodeposition;
use Physics::Electrodeposition::GDSII;

my $gds_path = "$RealBin/through_mask_reticle.gds";

#-----------------------------------------------------------------------------
# 1) Build a representative reticle on layer 10 (photoresist openings):
#    - a DENSE micro-bump array (25 um pads on 50 um pitch) on the left, and
#    - a SPARSE / isolated bump field (25 um pads on 150 um pitch) on the right.
#    The density contrast is what drives the loading (pattern-density) effect.
#-----------------------------------------------------------------------------
sub square { my ($x, $y, $s) = @_;
    return { layer => 10, pts => [[$x,$y],[$x+$s,$y],[$x+$s,$y+$s],[$x,$y+$s]] }; }

my @openings;
my $pad = 25;                                  # opening CD, um
# dense region: x in [0,1500), 50 um pitch
my $dense_pitch = 50;
for (my $x = 0; $x < 1500; $x += $dense_pitch) {
    for (my $y = 0; $y < 3000; $y += $dense_pitch) {
        push @openings, square($x + ($dense_pitch-$pad)/2, $y + ($dense_pitch-$pad)/2, $pad);
    }
}
# sparse region: x in [1500,3000), 150 um pitch
my $sparse_pitch = 150;
for (my $x = 1500; $x < 3000; $x += $sparse_pitch) {
    for (my $y = 0; $y < 3000; $y += $sparse_pitch) {
        push @openings, square($x + ($sparse_pitch-$pad)/2, $y + ($sparse_pitch-$pad)/2, $pad);
    }
}
Physics::Electrodeposition::GDSII->write_boundaries($gds_path, \@openings,
    libname => 'RETICLE', sname => 'THRU_MASK');
printf "Wrote %d openings to %s\n\n", scalar @openings, $gds_path;

#-----------------------------------------------------------------------------
# 2) Model 40 um-tall copper pillars plated through the resist at 10 mA/cm^2
#    ACTIVE (in-opening) current density from an acid Cu-sulfate bath.
#-----------------------------------------------------------------------------
my $cu = Physics::Electrodeposition->new(
    metal            => 'Copper',
    wafer_diameter   => 300,          # mm

    # --- pattern from GDSII ---
    gdsii            => $gds_path,
    pattern_layer    => 10,           # photoresist-opening layer
    pattern_scope    => 'die',        # reticle stepped across the wafer
    resist_thickness => 50,           # um  (mask height for 40 um pillars)
    loading_exponent => 0.5,          # pattern-density coupling

    # --- bath / recipe (through-mask bumping chemistry) ---
    ion_conc         => 0.63,         # M Cu2+ (~40 g/L, high for bumping)
    acid_conc        => 0.5,          # M H2SO4 (low-acid, high-Cu bumping bath)
    conductivity     => 0.30,         # S/cm
    boundary_layer   => 0.008,        # cm (80 um) with paddle agitation
    additive_drop    => 0.15,         # V
    seed_thickness   => 200,          # nm thick Cu seed for bumping

    current_density        => 10,     # mA/cm^2 ...
    current_density_basis  => 'active', # ... referenced to the OPENINGS (ASD)
    target_thickness       => 40,     # um pillar height (solves for time)
    efficiency             => 0.98,
);

print $cu->report;

#-----------------------------------------------------------------------------
# 3) Design sweep: how open area (pattern density) sets the tool current and the
#    in-feature current density for a fixed 10 mA/cm^2 active-density recipe.
#-----------------------------------------------------------------------------
print "\nPATTERN-DENSITY SWEEP (fixed 10 mA/cm^2 active density, 40 um pillars)\n";
printf "%-14s %-12s %-14s %-12s %-10s\n",
       "open_frac", "cell_I[A]", "j_active[mA]", "time[min]", "smoothness";
print '-' x 74, "\n";

for my $frac (0.05, 0.10, 0.20, 0.40) {
    # synth a uniform pad field at the requested density on layer 10
    my $p = _uniform_field($frac, $pad);
    my $f = "/tmp/ecd_density_$frac.gds";
    Physics::Electrodeposition::GDSII->write_boundaries($f, $p);
    my $m = Physics::Electrodeposition->new(
        gdsii => $f, pattern_layer => 10,
        current_density => 10, current_density_basis => 'active',
        target_thickness => 40, efficiency => 0.98,
        ion_conc => 0.63, conductivity => 0.30, boundary_layer => 0.008,
    );
    printf "%-14.3f %-12.2f %-14.2f %-12.2f %-10s\n",
        $m->open_fraction, $m->current, $m->j_active_mA,
        $m->process_time/60, $m->smoothness_verdict;
    unlink $f;
}
print "\n";

# helper: a uniform square-pad field at a target open fraction over ~2x2 mm
sub _uniform_field {
    my ($frac, $cd) = @_;
    my $pitch = $cd / sqrt($frac);                 # area fraction = (cd/pitch)^2
    my @polys;
    for (my $x = 0; $x < 2000; $x += $pitch) {
        for (my $y = 0; $y < 2000; $y += $pitch) {
            push @polys, square($x, $y, $cd);
        }
    }
    return \@polys;
}
