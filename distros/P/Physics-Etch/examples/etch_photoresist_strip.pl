#!/usr/bin/env perl
#
# Photoresist -- wet solvent strip (blanket removal).
#
# After a resist has served as an etch/implant mask it is stripped. A solvent
# such as acetone (or a proprietary stripper) dissolves the whole film; there
# is no pattern to preserve, so the figure of merit is simply clear time.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### PHOTORESIST -- WET SOLVENT STRIP ###\n\n";

my $strip = Physics::Etch->wet_etch(
    'photoresist',
    etchant     => 'acetone',
    thickness   => 1500,    # nm resist
    temperature => 25,
    overetch    => 0.50,    # generous over-strip to ensure a clean surface
);
print $strip->report, "\n";

printf "Clear time %.2f min at %.0f degC; strip is isotropic (A = %.2f).\n",
    $strip->time_to_clear, $strip->temperature, $strip->anisotropy;

# A hotter, more aggressive piranha strip for comparison
my $piranha = Physics::Etch->wet_etch(
    'photoresist',
    etchant     => 'piranha',
    thickness   => 1500,
    temperature => 110,
);
printf "Piranha (110 degC) clears the same film in %.2f min.\n",
    $piranha->time_to_clear;
