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
use NCAR::Test qw( bndary drawcl gendat capsap labtop );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

print STDERR "\n";

#
# Declare an array to hold the data to be contoured.
#
my $ZDAT = zeroes float, 53, 37;
#
# Declare the required real and integer workspaces.
#
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 1000;
#
# Declare an array to hold an area map.
#
my $IAMA = zeroes long, 30000;
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
# Declare an array to hold line labels.
#
 my $LABL;
#
# Declare the routine which will draw contour lines, avoiding labels.
#
#       EXTERNAL DRAWCL;
#
# Declare the routine which does the shading.
#
#       EXTERNAL SHADAM;
#
# Define a set of line labels.
#
my @LABL = (
     '0-1 ','1-2 ','2-3 ','3-4 ','4-5 ',
     '5-6 ','6-7 ','7-8 ','8-9 ','9-10',
);
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all the GKS aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Generate a relatively smooth array of test data, with values ranging
# from 0 to 10.
#
&gendat ($ZDAT,53,53,37,10,10,0.,10.);
#
# Initialize the software fill package to do the desired type of fill.
#
&NCAR::sfseti( 'TYPE OF FILL', -2 );
&NCAR::sfseti( 'ANGLE OF FILL LINES', 45 );
&NCAR::sfsetr( 'SPACING OF FILL LINES', .000625 );
#
# Turn on the positioning of labels by the penalty scheme and provide a
# little more room for X and Y coordinates defining contour lines, so
# as not to have labels right next to each other on a contour line.
#
&NCAR::cpseti( 'LLP - LINE LABEL POSITIONING', 3 );
&NCAR::cpseti( 'RWC - REAL WORKSPACE FOR CONTOURS', 200 );
#
# Turn off the drawing of high and low labels.
#
&NCAR::cpsetc( 'HLT - HIGH/LOW LABEL TEXT', ' ' );
#
# Turn on the drawing of the grid edge ("contour line number -1") and
# thicken it somewhat.
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -1 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
#
# Turn off the informational label.
#
&NCAR::cpsetc( 'ILT - INFORMATIONAL LABEL TEXT', ' ' );
#
# Turn on line-label boxes.
#
&NCAR::cpseti( 'LLB - LINE LABEL BOXES', 1 );
#
# Force the use of contour lines at the values 1, 2, 3, ... 9 and
# provide for labelling, but not drawing, contour lines at levels
# .5, 1.5, 2.5, ... 9.5, with labels of the form "0-1", "1-2", ...,
# "9-10".  Arrange for the areas between contour lines drawn to be
# shaded.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTION', 0 );
#
&NCAR::cpseti( 'NCL - NUMBER OF CONTOUR LEVELS', 19 );
#
for my $I ( 1 .. 9 ) {
&NCAR::cpseti( 'PAI - PARAMETER ARRAY IDENTIFIER', $I );
&NCAR::cpsetr( 'CLV - CONTOUR LEVEL VALUE', $I );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LINE', $I+1 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LINE', $I );
}
#
for my $I ( 10 .. 19 ) {
&NCAR::cpseti( 'PAI - PARAMETER ARRAY IDENTIFIER', $I );
&NCAR::cpsetr( 'CLV - CONTOUR LEVEL VALUE', ($I-10)+.5 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE', 2 );
&NCAR::cpsetc( 'LLT - LINE LABEL TEXT', $LABL[$I-10] );
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LINE', 0 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LINE', 0 );
}
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,53,53,37,$RWRK,5000,$IWRK,1000);
#
# Draw the contour plot.
#
&NCAR::arinam ($IAMA,30000);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&drawcl);
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&shadam);
#
# Compute and print statistics for the plot and label it.
#
&capsap ('EXAMPLE 4',$IAMA,30000);
&labtop ('EXAMPLE 4',.017);
#

#
# Put a boundary line at the edge of the plotter frame.
#
&bndary;


sub shadam {
  my ( $XCS, $YCS, $NCS, $IAI, $IAG, $NAI ) = @_;
#
# This version of SHADAM shades the polygon whose edge is defined by
# the points ((XCS(I),YCS(I)),I=1,NCS) if and only, relative to edge
# group 3, its area identifier is between 1 and 10.  The package
# SOFTFILL is used to do the shading; the density of the shading
# increases with the value of the area identifier.
#
#
# Define workspaces for the shading routine.
#
  my $DST = zeroes float, 1100;
  my $IND = zeroes long, 1200; 
#
# Turn off shading.
#
  my $ISH=0;
#
# If the area identifier for group 3 is in the right range, turn on
# shading.
#
  for my $I ( 1 .. $NAI ) {
    if( ( at( $IAG, $I - 1 ) == 3 ) 
     && ( at( $IAI, $I - 1 ) >= 1 ) 
     && ( at( $IAI, $I - 1 ) <= 10 ) ) {
       $ISH = at( $IAI, $I - 1 );
    }
  }
#
# If shading is turned on, shade the area.  The last point of the
# edge is redundant and may be omitted.
#
  if( $ISH != 0 ) {
    &NCAR::sfsgfa( $XCS, $YCS, $NCS, $DST, 1100, $IND, 1200, $ISH - 1 );
  }
#
# Done.
#
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/cpex04.ncgm';
