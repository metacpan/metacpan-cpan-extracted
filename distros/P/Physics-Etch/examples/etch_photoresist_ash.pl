#!/usr/bin/env perl
#
# Photoresist -- dry O2 plasma ash.
#
# O2 plasma "ashing" oxidises the organic resist to CO2/H2O. It is the clean,
# residue-free alternative to a wet strip and is also used for descum and for
# controlled resist trimming. With low DC bias the etch is nearly isotropic.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### PHOTORESIST -- DRY O2 ASH ###\n\n";

my $ash = Physics::Etch->dry_etch(
    'photoresist',
    etchant   => 'O2',
    thickness => 1500,    # nm resist
    power     => 400,     # W  (high power -> fast ash)
    pressure  => 300,     # mTorr (barrel-asher regime)
    bias      => 50,      # V  (low bias -> gentle, isotropic)
    overetch  => 0.40,
);
print $ash->report, "\n";

printf "Ash rate %.0f nm/min; low bias keeps it nearly isotropic (A = %.2f).\n",
    $ash->vertical_rate, $ash->anisotropy;

# Same chemistry, but as an anisotropic RIE descum / trim step
my $trim = Physics::Etch->dry_etch(
    'photoresist',
    etchant  => 'O2',
    thickness => 1500,
    power    => 200,
    pressure => 20,       # low pressure
    bias     => 300,      # high bias -> directional
    time     => 0.5,      # short timed trim
    feature_cd => 500,
);
printf "Directional O2 RIE trim: %.0f nm removed in 0.5 min, A = %.2f.\n",
    $trim->etch_depth(0.5), $trim->anisotropy;
