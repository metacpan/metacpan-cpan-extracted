# This is meant to produce the pathological effects with regard to 
# autoscaling that precipitated my revamp of the autoscaling code.
# It also uses the exact same value for the y-values, which means that the
# data itself does not have an intrinsic scale. Under such circumstances,
# the min/max methods need to still return something reasonable.

use strict;
use warnings;
use PDL;
use Prima qw(Application);
use PDL::Graphics::Prima;
use PDL::NiceSlice;

my $wDisplay = Prima::MainWindow->create(
	text    => 'Pathological Auto-scaling',
	size	=> [500, 500],
);

$wDisplay->insert('Plot',
	-data => ds::Pair(
		pdl(1, 50), pdl(0,0),
		plotType => ppair::Blobs(radius => pdl(5, 100))
		),
	pack => { fill => 'both', expand => 1},
);

run Prima;


