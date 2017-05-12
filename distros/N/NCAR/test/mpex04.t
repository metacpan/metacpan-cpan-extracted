# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; };
END {print "not ok 1\n" unless $loaded;};
use NCAR;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use PDL;
use NCAR::Test;

&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );


my $plbl = 'OMNIS TERRA IN PARTES TRES';

# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set the outline-dataset parameter.
#
&NCAR::mapstc ('OU','PO');
#
# Use dotted outlines and move the dots a little closer together
# than normal.
#
&NCAR::mapsti ('DO',1);
&NCAR::mapsti ('DD',24);
#
# Do the Mercator projection of the equatorial belt first.
#
&NCAR::mappos (.05,.95,.05,.5);
&NCAR::maproj ('ME',0.,0.,0.);
&NCAR::mapset ('LI',
               float( [ -3.1416, 0 ] ),
	       float( [ +3.1416, 0 ] ),
	       float( [ -1.5708, 0 ] ),
	       float( [ +1.5708, 0 ] )
	       );
&NCAR::mapdrw;
#
# Switch to an elliptical (in this case, circular) boundary.
#
&NCAR::mapsti ('EL',1);
#
# Do a polar stereographic view of the North Pole ...
#
&NCAR::mappos (.07,.48,.52,.93);
&NCAR::maproj ('ST',90.,0.,-90.);
&NCAR::mapset ('AN',
               float( [ 30., 0 ] ),
	       float( [ 30., 0 ] ),
	       float( [ 30., 0 ] ),
	       float( [ 30., 0 ] )
	       );
&NCAR::mapdrw;
#
# and then a similar view of the South Pole.
#
&NCAR::mappos (.52,.93,.52,.93);
&NCAR::maproj ('ST',-90.,0.,-90.);
&NCAR::mapset ('AN',
               float( [ 30., 0 ] ),
	       float( [ 30., 0 ] ),
	       float( [ 30., 0 ] ),
	       float( [ 30., 0 ] )
	       );
&NCAR::mapdrw;
#
# Put the label at the top of the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pwrit (.5,.975, $plbl,26,2,0,0);



&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/mpex04.ncgm';
