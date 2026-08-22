#!/usr/bin/env perl
#
# Tantalum -- dry SF6 RIE.
#
# Ta (and TaN) are common diffusion barriers / capacitor and RF-MEMS metals.
# Fluorine plasmas etch Ta via volatile TaF5. SF6 gives a fast, reasonably
# anisotropic etch; a little O2 tunes the profile and selectivity.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### TANTALUM -- DRY SF6 RIE ###\n\n";

my $ta = Physics::Etch->dry_etch(
    'tantalum',
    thickness      => 150,     # nm Ta
    feature_cd     => 400,     # nm
    power          => 200,     # W
    pressure       => 20,      # mTorr
    bias           => 150,     # V
    mask           => 'photoresist',
    mask_thickness => 900,
    substrate      => 'silicon_dioxide',
    overetch       => 0.25,
);
print $ta->report, "\n";

printf "Volatile product TaF5; clears %.0f nm Ta in %.2f min at %.0f nm/min.\n",
    $ta->thickness, $ta->time_to_clear, $ta->vertical_rate;

# What if we raise pressure? -> more radicals, less directional -> undercut
my $hi_p = Physics::Etch->dry_etch(
    'tantalum',
    thickness  => 150,
    feature_cd => 400,
    power      => 200,
    pressure   => 80,       # high pressure
    bias       => 80,       # low bias
);
printf "Raising pressure 20->80 mTorr & dropping bias drops A from %.2f to %.2f (more undercut).\n",
    $ta->anisotropy, $hi_p->anisotropy;
