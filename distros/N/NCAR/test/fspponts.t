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
#
# Create a line plot with connected markers using points.
#
my $XDRA = zeroes float, 20;
my $YDRA = zeroes float, 20;
my $X2DRA = zeroes float, 20;
my $Y2DRA = zeroes float, 20;
my $X3DRA = zeroes float, 20;
my $Y3DRA = zeroes float, 20;
my $NPTS = 20;
#
# Set up a color table
#
&DFCLRS;
#
# Fill the data arrays.
#
for my $I ( 1 .. $NPTS ) {
  set( $XDRA, $I-1, sin($I));
  set( $YDRA, $I-1, cos($I));
  set( $X2DRA, $I-1, at( $XDRA, $I-1 ) * .66 );
  set( $Y2DRA, $I-1, at( $YDRA, $I-1 ) * .66 );
  set( $X3DRA, $I-1, at( $XDRA, $I-1 ) * .3 );
  set( $Y3DRA, $I-1, at( $YDRA, $I-1 ) * .3 );
}
#
# Draw a boundary around the edge of the plotter frame.
#
&bndary;
#
# Suppress the frame advance.
#
&NCAR::agseti ('FRAME.',2);
#
# Suppress the drawing of curves by the EZ... routines.
#
&NCAR::agseti ('SET.',-1);
#
# Draw the background, using EZXY.
#
&NCAR::ezxy ($XDRA,$YDRA,$NPTS,'POINTS EXAMPLE$');
#
# Increase the size of the polymarkers
#
&NCAR::gsmksc(2.0);
#
# Set the color of the polymarker
#
&NCAR::gsplci(7);
#
# Set the line width of the lines connecting the polymarkers.
#
&NCAR::gslwsc(3.0);
#
# Put a plus sign at each of the x-y positions.
#
&NCAR::points ($XDRA,$YDRA,$NPTS,-2,1);
#
# Set the color of the polymarker
#
&NCAR::gsplci(9);
#
# Put a circle at each of the x2-y2 positions.
#
&NCAR::points ($X2DRA,$Y2DRA,$NPTS,-4,1);
#
# Put an asterix at each of the x3-y3 positions,
# and do not connect with lines.
#
&NCAR::points ($X3DRA,$Y3DRA,$NPTS,-3,0);
#
# Advance the frame.
#
&NCAR::frame;

sub DFCLRS {
#
# Define the RGB color triples needed below.
#
  my @RGBV = (
     [ 0.00 , 0.00 , 0.00 ],
     [ 0.70 , 0.70 , 0.70 ],
     [ 0.75 , 0.50 , 1.00 ],
     [ 0.50 , 0.00 , 1.00 ],
     [ 0.00 , 0.00 , 1.00 ],
     [ 0.00 , 0.50 , 1.00 ],
     [ 0.00 , 1.00 , 1.00 ],
     [ 0.00 , 1.00 , 0.60 ],
     [ 0.00 , 1.00 , 0.00 ],
     [ 0.70 , 1.00 , 0.00 ],
     [ 1.00 , 1.00 , 0.00 ],
     [ 1.00 , 0.75 , 0.00 ],
     [ 1.00 , 0.38 , 0.38 ],
     [ 1.00 , 0.00 , 0.38 ],
     [ 1.00 , 0.00 , 0.00 ],
  );
#
# Define 16 different color indices, for indices 0 through 15.  The
# color corresponding to index 0 is black and the color corresponding
# to index 1 is white.
#
  &NCAR::gscr (1,0,1.,1.,1.);
#
  for my $I ( 1 .. 15 ) {
    &NCAR::gscr (1,$I-1,@{ $RGBV[$I-1] });
  }
#
# Done.
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fspponts.ncgm';
