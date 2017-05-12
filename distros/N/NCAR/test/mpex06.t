# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
ok(1); # If we made it this far, we're ok.;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
use NCAR::Test qw( bndary gendat drawcl );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my $PLBL = 'THE EARTH IS SPINNING, TOTO';
#
# Set the outline-dataset parameter.
#
&NCAR::mapstc ('OU','PS');
#
# Use a satellite-view projection.
#
&NCAR::mapstr ('SA',1.25);
#
# Aim the camera 15 degrees away from straight down.
#
&NCAR::mapsti ('S1',15);
#
# Turn off the perimeter and reduce the number of grid lines.
#
&NCAR::mapsti ('PE',0);
&NCAR::mapsti ('GR',15);
#
# Center the first map over Kansas.  Rotate by 0 degrees and look
# to the upper left.
#
&NCAR::mappos (.05,.475,.525,.95);
&NCAR::maproj ('SV',38.,-98.,0.);
&NCAR::mapsti ('S2',135);
&NCAR::mapdrw();
#
# Repeat, but rotate by 90 degrees and look to the upper right.
#
&NCAR::mappos (.525,.95,.525,.95);
&NCAR::maproj ('SV',38.,-98.,90.);
&NCAR::mapsti ('S2',45);
&NCAR::mapdrw();
#
# Repeat, but rotate by 180 degrees and look to the lower left.
#
&NCAR::mappos (.05,.475,.05,.475);
&NCAR::maproj ('SV',38.,-98.,180.);
&NCAR::mapsti ('S2',-135);
&NCAR::mapdrw();
#
# Repeat, but rotate by 270 degrees and look to the lower right.
#
&NCAR::mappos (.525,.95,.05,.475);
&NCAR::maproj ('SV',38.,-98.,270.);
&NCAR::mapsti ('S2',-45);
&NCAR::mapdrw();
#
# Put the label at the top of the plot ...
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pwrit (.5,.975,$PLBL,27,2,0,0);
#
# and the ones below each sub-plot.
#
&NCAR::pwrit (.2625,.5,'ROTA = 0',8,1,0,0);
&NCAR::pwrit (.7375,.5,'ROTA = 90',9,1,0,0);
&NCAR::pwrit (.2625,.025,'ROTA = 180',10,1,0,0);
&NCAR::pwrit (.7375,.025,'ROTA = 270',10,1,0,0);
#
# Draw a boundary around the edge of the plotter frame.
#
&NCAR::Test::bndary;


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex06.ncgm';
