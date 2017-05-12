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

my $plbl = 'THE U.S. ON A LAMBERT CONFORMAL CONIC';
#
# Set the outline-dataset parameter.
#
&NCAR::mapstc ('OU','US');
#
# Set the projection-type parameters.
#
&NCAR::maproj ('LC',30.,-100.,45.);
#
# Set the limits parameters.
#
&NCAR::mapset ('CO',
               float( [  22.6, 0 ] ),
	       float( [ -120., 0 ] ),
	       float( [  46.9, 0 ] ),
	       float( [ -64.2, 0 ] )
	       );
#
# Draw the map.
#
&NCAR::mapdrw;
#
# Put the label at the top of the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pwrit (.5,.925, $plbl ,37,2,0,0);

&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/mpex01.ncgm';
