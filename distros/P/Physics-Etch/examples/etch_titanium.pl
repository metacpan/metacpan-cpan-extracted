#!/usr/bin/env perl
#
# Titanium -- wet dilute-HF etch.
#
# Thin Ti adhesion / barrier layers are often cleared in dilute HF (or HF:H2O2).
# Ti etches quickly and isotropically; the catch is poor selectivity to an SiO2
# under-layer, which HF also attacks -- so timing and end-point matter.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Physics::Etch;

print "### TITANIUM -- WET DILUTE-HF ETCH ###\n\n";

my $ti = Physics::Etch->wet_etch(
    'titanium',
    etchant        => 'DHF',
    thickness      => 60,       # nm Ti adhesion layer
    temperature    => 25,
    feature_cd     => 1500,
    mask           => 'photoresist',
    mask_thickness => 1000,
    substrate      => 'silicon_dioxide',
    overetch       => 0.20,
);
print $ti->report, "\n";

printf "Ti clears in %.2f min; being isotropic the undercut equals the etch depth (%.0f nm).\n",
    $ti->time_to_clear, $ti->undercut( $ti->time_to_clear );

# Selectivity warning: how much SiO2 is lost during the 20% over-etch?
my $ox_loss = $ti->substrate_overetch;
printf "During over-etch the SiO2 under-layer loses ~%.1f nm (selectivity %d:1) -- watch end-point.\n",
    $ox_loss, $ti->sel_substrate;
