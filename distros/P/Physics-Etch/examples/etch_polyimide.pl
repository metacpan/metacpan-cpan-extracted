#!/usr/bin/env perl
#
# Polyimide -- dry O2 RIE (thick-film via etch).
#
# Polyimide is a thick (multi-micron) dielectric/passivation polymer. Vias are
# opened by O2 RIE (a little CF4 helps with any filler): the oxygen plasma
# combusts the polymer fast and, with DC bias, quite anisotropically. Because
# O2 also attacks resist, a metal hard mask (here Al-Si) is used.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### POLYIMIDE -- DRY O2 RIE VIA ETCH ###\n\n";

my $pi = Physics::Etch->dry_etch(
    'polyimide',
    thickness      => 5000,     # nm  (5 um polyimide)
    feature_cd     => 15000,    # nm  (15 um via)
    power          => 300,      # W
    pressure       => 50,       # mTorr
    bias           => 250,      # V
    mask           => 'aluminum_silicide',   # metal hard mask
    mask_thickness => 600,
    substrate      => 'silicon',
    overetch       => 0.30,     # topography / via clearing
    uniformity     => 0.06,
);
print $pi->report, "\n";

my $p = $pi->profile;
printf "Opens a %.1f um via through %.1f um polyimide in %.1f min; sidewall %.0f deg.\n",
    $p->{feature_cd} / 1000, $pi->thickness / 1000, $pi->etch_time,
    $p->{sidewall_angle};
printf "Metal hard mask loses only %.0f nm (selectivity %d:1) -- resist would be consumed.\n",
    $pi->mask_loss, $pi->sel_mask;
