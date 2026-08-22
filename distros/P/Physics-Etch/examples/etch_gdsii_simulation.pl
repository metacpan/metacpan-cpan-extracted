#!/usr/bin/env perl
#
# GDSII-driven etch simulation: pattern-dependent anisotropy, loading and
# RIE lag.  Reads a photoresist mask from a GDSII file, sets up a chamber and
# loading model, and simulates the silicon-nitride RIE feature by feature.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;
use Physics::Etch::Loading;

my $mask = "$FindBin::Bin/sample_mask.gds";
unless ( -e $mask ) {
    do "$FindBin::Bin/make_sample_mask.pl";      # generate if missing
}

print "### GDSII-DRIVEN NITRIDE RIE SIMULATION ###\n\n";

# 1) the etch process (200 nm Si3N4, 20% target over-etch)
my $etch = Physics::Etch->dry_etch( 'silicon_nitride',
    thickness => 200, overetch => 0.20 );

# 2) the reactor: an SF6/O2 CCP-RIE on 200 mm
my $chamber = Physics::Etch->chamber(
    reactor_type   => 'CCP-RIE',
    wafer_diameter_mm => 200,
    gap_cm         => 2.5,
    pressure_mtorr => 20,
    power_w        => 300,
    flow_sccm      => 80,
    gas            => 'SF6', gas_mass_amu => 146, gas_diameter_m => 4.8e-10,
);

# 3) the mask pattern from GDSII (layer 1 = openings)
my $layout = Physics::Etch->layout_from_gds( $mask,
    layer => 1, structure => 'TOP', tone => 'clear', field => [ 200, 200 ] );

# 4) loading strength derived from chamber transport, sharp RIE lag
my $loading = Physics::Etch::Loading->from_chamber( $chamber, arde_length => 5 );

# 5) simulate
my $sim = Physics::Etch->simulate(
    process => $etch, chamber => $chamber,
    layout  => $layout, loading => $loading, micro_cell_um => 10 );

print $sim->report;

# highlight the pattern-dependent anisotropy / CD control
print "\nPer-feature CD control (relative etch bias):\n";
for my $row ( @{ $sim->features_by_cd } ) {
    printf "  %5.0f nm line  x%-2d : AR %.2f, undercut %.1f nm, "
        . "CD bias %.1f%%, wall %.0f deg%s\n",
        $row->{cd_nm}, $row->{count}, $row->{aspect_ratio},
        $row->{undercut}, 100 * $row->{etch_bias} / $row->{cd_nm},
        $row->{sidewall_angle},
        ( $row->{cleared} ? '' : '  (RIE lag: not cleared!)' );
}
