#!/usr/bin/env perl
#
# Aluminum silicide (Al-Si metallization) -- dry Cl2/BCl3 RIE.
#
# Al-Si (typically Al with ~1% Si to suppress junction spiking) is patterned
# by chlorine-based RIE. BCl3 scavenges the native Al2O3 so etching can start;
# Cl2 does the bulk removal via volatile AlCl3. Post-etch corrosion control is
# essential because residual chlorine attacks aluminum in air.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### ALUMINUM SILICIDE -- DRY Cl2/BCl3 RIE ###\n\n";

my $rie = Physics::Etch->dry_etch(
    'aluminum_silicide',
    thickness      => 800,     # nm Al-Si line
    feature_cd     => 500,     # nm line width
    power          => 300,     # W
    pressure       => 8,       # mTorr (low -> anisotropic)
    bias           => 250,     # V
    mask           => 'photoresist',
    mask_thickness => 1200,
    substrate      => 'silicon_dioxide',
    overetch       => 0.30,    # clear stringers on topography
    uniformity     => 0.07,
);
print $rie->report, "\n";

my $p = $rie->profile;
printf "Anisotropic RIE: %.1f deg sidewalls, only %.0f nm undercut on a %.0f nm line.\n",
    $p->{sidewall_angle}, $p->{undercut}, $p->{feature_cd};

# Contrast with the classic wet PAN etch (fully isotropic -> undercut)
my $pan = Physics::Etch->wet_etch(
    'aluminum_silicide',
    etchant     => 'PAN',
    thickness   => 800,
    temperature => 50,
    feature_cd  => 500,
);
printf "Wet PAN etch would undercut ~%.0f nm per side (isotropic) -- unusable at 500 nm.\n",
    $pan->undercut;
