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

unlink( 'gmeta' );

use PDL;
use NCAR::Test;

&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my $xt1 = float [ 10.0, 90.0, 50.0 ];
my $xt2 = float [ 10.0, 90.0, 50.0 ];
my $yt1 = float [  0.2,  0.2,  0.3 ];
my $yt2 = float [  0.5,  0.5,  0.4 ];
#
#  Define a normalization transformation and select it.
#
&NCAR::gswn (1, 0.00, 100.00, 0.10, 0.50);
&NCAR::gsvp (1, 0.05,   0.95, 0.05, 0.95);
&NCAR::gselnt (1);
#
#  Set up a color table.
#
&NCAR::gscr (1, 0, 1., 1., 1.);
&NCAR::gscr (1, 1, 1., 0., 0.);
&NCAR::gscr (1, 2, 0., 0., 1.);
&NCAR::gscr (1, 3, 0., 0., 0.);

#
#  Set fill area interior style to solid.
#
&NCAR::gsfais (1);
#
#  Fill triangle 1 with red and triangle 2 with blue.
#
&NCAR::gsfaci (1);
&NCAR::gfa (3, $xt1, $yt1);
&NCAR::gsfaci (2);
&NCAR::gfa (3, $xt2, $yt2);
#
#  Select normalization transformation 0 for drawing the text
#  to avoid effects of the non-square aspect ratio of the 
#  normalizartion transformation on the plotted characters.
#

&NCAR::gselnt(0);
#
#  Set text color to red; align the text as (center, half); 
#  specify the text size; and draw it.
#
&NCAR::gstxci (3);
&NCAR::gstxal (2,3);
&NCAR::gschh  (.025);
&NCAR::gtx (.5,.125,'Output from a GKS program');



&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex01.ncgm';
