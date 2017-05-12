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

my $plbl = 'CAN YOU NAME THE COUNTRIES';

# Use an elliptical perimeter.
#
&NCAR::mapsti ('EL',1);
#
# Dot the outlines, using dots a quarter as far apart as the default.
#
&NCAR::mapsti ('DO',1);
&NCAR::mapsti ('DD',24);
#
# Show continents and international boundaries.
#
&NCAR::mapstc ('OU','PO');
#
# Use a stereographic projection.
#
&NCAR::maproj ('ST',0.,0.,0.);
#
# Specify where two corners of the map are.
#
&NCAR::mapset ('CO',
               float( [ -38., 0 ] ),
	       float( [ -28., 0 ] ),
	       float( [  40., 0 ] ),
	       float( [  62., 0 ] )
	       );
#
# Draw the map.
#
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



rename 'gmeta', 'ncgm/mpex02.ncgm';
