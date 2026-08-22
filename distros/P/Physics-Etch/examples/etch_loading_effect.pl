#!/usr/bin/env perl
#
# Loading effects: how open area (macro loading) and local pattern density
# (micro loading) change the etch rate.  Uses the GDSII sample mask plus a
# sweep of synthetic open fractions.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;
use Physics::Etch::Loading;

print "### ETCH LOADING EFFECTS ###\n\n";

my $chamber = Physics::Etch->chamber(
    wafer_diameter_mm => 200, pressure_mtorr => 20, power_w => 300, flow_sccm => 80 );
my $wafer = $chamber->wafer_area_cm2;
my $loading = Physics::Etch::Loading->from_chamber($chamber);

printf "%s\n%s\nWafer area = %.0f cm^2\n\n",
    $loading->describe,
    sprintf( 'Residence time %.1f ms -> loading kappa %.4g /cm^2',
    1000 * $chamber->residence_time_s, $loading->kappa ),
    $wafer;

# --- Macro loading: rate vs open fraction ----------------------------------
my $etch = Physics::Etch->dry_etch( 'aluminum_silicide', thickness => 800 );
my $R0   = $etch->vertical_rate;
printf "Macro loading (base rate %.0f nm/min, %s):\n", $R0, $etch->target->label;
printf "  %-10s %-12s %-10s %-10s\n", 'open %', 'A_load cm^2', 'rate', 'clear min';
for my $frac ( 0.02, 0.05, 0.10, 0.25, 0.50, 0.80 ) {
    my $A = $frac * $wafer;
    my $f = $loading->macro_factor($A);
    my $R = $R0 * $f;
    printf "  %-10.0f %-12.1f %-10.1f %-10.2f\n",
        100 * $frac, $A, $R, $etch->thickness / $R;
}

# --- Micro loading: local rate vs local density ----------------------------
print "\nMicro loading (local rate relative to a 25%-open mean field):\n";
printf "  %-14s %-10s\n", 'local open %', 'rel. rate';
for my $d ( 0.05, 0.15, 0.25, 0.50, 0.75 ) {
    printf "  %-14.0f %-10.3f\n", 100 * $d, $loading->micro_relative( $d, 0.25 );
}

# --- Micro-loading map from the real GDSII pattern -------------------------
my $mask = "$FindBin::Bin/sample_mask.gds";
do "$FindBin::Bin/make_sample_mask.pl" unless -e $mask;
my $layout = Physics::Etch->layout_from_gds( $mask,
    layer => 1, structure => 'TOP', tone => 'clear', field => [ 200, 200 ] );
my $den = $layout->density_map( cell_um => 20 );
printf "\nGDSII pattern: open fraction %.1f%%, local density %.0f%%-%.0f%% "
    . "(mean %.0f%%)\n",
    100 * $layout->open_fraction,
    100 * $den->{min}, 100 * $den->{max}, 100 * $den->{mean};
printf "=> dense regions etch ~%.0f%% as fast as sparse regions (micro loading).\n",
    100 * $loading->micro_relative( $den->{max}, $den->{min} );
