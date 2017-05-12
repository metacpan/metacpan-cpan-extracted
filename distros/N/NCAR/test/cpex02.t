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
use NCAR::Test qw( bndary gendat capsap labtop shader drawcl );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

print STDERR "\n";

#
# Declare an array to hold the data to be contoured.
#
my $ZDAT = zeroes float, 33, 33;
#
# Declare the required real and integer workspaces.
#
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 5000;
#
# Declare an array to hold an area map.
#
my $IAMA = zeroes long, 20000;
#
# Declare the arrays needed by ARSCAM for x/y coordinates.
#
my $XCRA = zeroes float, 1000;
my $YCRA = zeroes float, 1000;
#
# Declare the arrays needed by ARSCAM for area and group identifiers.
#
my $IARA = zeroes long, 10;
my $IGRA = zeroes long, 10;
#
# Declare an array to hold the GKS "aspect source flags".
#
my $IASF = long [ ( 1 ) x 13 ];
#
# Declare the routine which will draw contour lines, avoiding labels.
#
#       EXTERNAL DRAWCL
#
# Declare the routine which does the shading.
#
#       EXTERNAL SHADER
#
# Dimension a character variable to hold plot labels.
#
my $LABL;
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all the GKS aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Turn on the drawing of the grid edge ("contour line number -1") and
# thicken it somewhat.
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -1 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
#
# Turn on the positioning of labels by the penalty scheme and provide a
# little more room for X and Y coordinates defining contour lines, so
# as not to have labels right next to each other on a contour line.
#
&NCAR::cpseti( 'LLP - LINE LABEL POSITIONING', 3 );
&NCAR::cpseti( 'RWC - REAL WORKSPACE FOR CONTOURS', 200 );
#
# Turn on the drawing of the high and low label boxes.
#
&NCAR::cpseti( 'HLB - HIGH/LOW LABEL BOX FLAG', 1 );
#
# Tell CONPACK to delete high/low labels which overlap the informational
# label or another high/low label, but to move those which overlap the
# edge inward a little.
#
&NCAR::cpseti( 'HLO - HIGH/LOW LABEL OVERLAP FLAG', 11 );
#
# Make all CONPACK-written characters a little bigger.
#
&NCAR::cpsetr( 'CWM - CHARACTER WIDTH MULTIPLIER', 1.25 );
#
# Move the informational label into the lower left-hand corner and
# turn on the box around it, making the box thicker than normal.
#
&NCAR::cpsetr( 'ILX - INFORMATIONAL LABEL X POSITION', .02 );
&NCAR::cpsetr( 'ILY - INFORMATIONAL LABEL Y POSITION', .02 );
&NCAR::cpseti( 'ILP - INFORMATIONAL LABEL POSIIONING', -4 );
&NCAR::cpseti( 'ILB - INFORMATIONAL LABEL BOX', 1 );
&NCAR::cpsetr( 'ILL - INFORMATIONAL LABEL LINE WIDTH', 2. );
#
# Change the text of the informational label.
#
&NCAR::cpsetc( 'ILT - INFORMATIONAL LABEL TEXT', 'CONTOUR FROM $CMN$ TO $CMX$ BY $CIU$ (X $SFU$)' );
#
# Do four different plots, one in each quadrant.
#
for my $IPLT ( 1 .. 4 ) {
#
# Generate an array of test data.
#
&gendat ($ZDAT,33,33,33,20,20,.000025,.000075);
#
# Move the viewport to the proper quadrant.
#
&NCAR::cpsetr( 'VPL - VIEWPORT LEFT EDGE', .0250 + .4875 * ( ( $IPLT-1 ) % 2 ) );
&NCAR::cpsetr( 'VPR - VIEWPORT RIGHT EDGE', .4875 + .4875 * ( ( $IPLT-1 ) % 2 ) );
&NCAR::cpsetr( 'VPB - VIEWPORT BOTTOM EDGE', .0250 + .4875 * int( ( 4-$IPLT ) / 2 ) );
&NCAR::cpsetr( 'VPT - VIEWPORT TOP EDGE', .4875 + .4875 * int( ( 4-$IPLT ) / 2 ) );
#
# Specify how the scale factor is to be selected.
#
&NCAR::cpseti( 'SFS - SCALE FACTOR SELECTION', -$IPLT );
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,33,33,33,$RWRK,5000,$IWRK,1000);
#
# Force the selection of contour levels, so that associated quantities
# may be tweaked.
#
&NCAR::cppkcl ($ZDAT,$RWRK,$IWRK);
#
# Increase the line width for labelled levels and turn off the area
# identifiers for all levels.
#
&NCAR::cpgeti( 'NCL - NUMBER OF CONTOUR LEVELS', my $NCLV );
#

  for my $ICLV ( 1 .. $NCLV ) {
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $ICLV );
&NCAR::cpgeti( 'CLU - CONTOUR LEVEL USE FLAG', my $ICLU );
   if( $ICLU == 3 ) {
&NCAR::cpseti( 'CLL - CONTOUR-LINE LINE WIDTH', 2 );
   }
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LEVEL', 0 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LEVEL', 0 );
  }
#
# Add two new levels for which no contour lines are to be drawn, but
# between which shading is to be done.
#
$NCLV=$NCLV+2;
&NCAR::cpseti( 'NCL - NUMBER OF CONTOUR LEVELS', $NCLV );
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $NCLV-1 );
&NCAR::cpsetr( 'CLV - CONTOUR LEVEL VALUE', .000045 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 0 );
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LEVEL', 1 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LEVEL', 2 );
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $NCLV );
&NCAR::cpsetr( 'CLV - CONTOUR LEVEL VALUE', .000055 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 0 );
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LEVEL', 3 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LEVEL', 1 );
#
# Draw the contour plot.
#
&NCAR::arinam ($IAMA,20000);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&drawcl);
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&shader);
#
# Compute and print statistics for the plot and label it.
#
$LABL='EXAMPLE 2-' . $IPLT;
&capsap ($LABL,$IAMA,20000);
&labtop ($LABL,.017);
#
}
#
# Put a boundary line at the edge of the plotter frame.
#
&bndary();




&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/cpex02.ncgm';
