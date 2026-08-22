#!/usr/bin/env perl
#
# Patterned copper -- wet ferric-chloride etch vs. dry Ar ion-beam milling.
#
# Copper has no volatile etch product with common plasmas near room
# temperature, so it is usually wet etched (isotropic -> undercut) or
# physically milled. This example contrasts the two on the same 600 nm
# patterned film.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### PATTERNED COPPER ###\n\n";

# --- Wet: ferric chloride, run slightly warm -------------------------------
my $wet = Physics::Etch->wet_etch(
    'copper',
    thickness      => 600,      # nm Cu
    temperature    => 35,       # degC
    feature_cd     => 2000,     # nm line/space
    mask           => 'photoresist',
    mask_thickness => 1500,     # nm resist
    overetch       => 0.25,
);
print $wet->report, "\n";

# --- Dry: argon ion-beam milling (physical, directional) -------------------
my $dry = Physics::Etch->dry_etch(
    'copper',
    thickness      => 600,
    feature_cd     => 2000,
    power          => 400,      # W
    pressure       => 1,        # mTorr
    bias           => 600,      # V ion energy
    mask           => 'photoresist',
    mask_thickness => 1500,
    overetch       => 0.25,
);
print $dry->report, "\n";

# --- Side-by-side pattern fidelity -----------------------------------------
printf "Undercut per side  : wet %.0f nm   vs   dry %.0f nm\n",
    $wet->undercut, $dry->undercut;
printf "Etch bias (CD loss): wet %.0f nm   vs   dry %.0f nm\n",
    2 * $wet->undercut, 2 * $dry->undercut;
print "=> Isotropic wet etch badly undercuts fine Cu lines; ion milling\n",
    "   preserves the pattern but is slow and only mildly selective.\n";
