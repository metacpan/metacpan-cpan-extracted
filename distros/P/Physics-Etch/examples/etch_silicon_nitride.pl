#!/usr/bin/env perl
#
# Silicon nitride -- hot phosphoric-acid wet etch (and a dry RIE comparison).
#
# Hot H3PO4 (~180 degC) is the classic selective Si3N4 strip: it removes
# nitride while barely touching SiO2, which is why it is used to strip nitride
# hard masks in LOCOS / STI flows. The trade-off is a very slow, strongly
# temperature-activated (high Ea) etch.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### SILICON NITRIDE -- HOT H3PO4 (WET) ###\n\n";

my $wet = Physics::Etch->wet_etch(
    'silicon_nitride',
    etchant     => 'H3PO4',
    thickness   => 120,      # nm Si3N4
    temperature => 180,      # degC
    mask        => 'silicon_dioxide',
    substrate   => 'silicon_dioxide',
    overetch    => 0.25,
);
print $wet->report, "\n";

printf "High Ea (1.9 eV): dropping the bath 180 -> 160 degC nearly %s the rate.\n",
    do {
        my $cool = Physics::Etch->wet_etch( 'silicon_nitride',
            etchant => 'H3PO4', thickness => 120, temperature => 160 );
        sprintf "halves (%.1f -> %.1f nm/min)", $wet->vertical_rate,
            $cool->vertical_rate;
    };

# --- Dry alternative: fast anisotropic fluorocarbon RIE --------------------
print "\n### SILICON NITRIDE -- CF4/O2 RIE (DRY) ###\n\n";
my $dry = Physics::Etch->dry_etch(
    'silicon_nitride',
    thickness      => 120,
    feature_cd     => 200,
    power          => 250,
    pressure       => 30,
    bias           => 280,
    mask           => 'photoresist',
    mask_thickness => 700,
    substrate      => 'silicon',
    overetch       => 0.20,
);
print $dry->report, "\n";

printf "Wet is %s but isotropic & SiO2-selective; RIE is fast & vertical (%.0f deg walls).\n",
    'slow', $dry->profile->{sidewall_angle};
