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
use NCAR::Test qw( bndary min max gendat labtop capsap shader drawcl );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

print STDERR "\n";

#
# Declare an array to hold the data to be contoured.
#
my $ZDAT = zeroes float, 23, 14;
#
# Declare an array to hold dense data (5152=4x4x23x14).
#
my $ZDNS = zeroes float, 5152;
#
# Declare the required real and integer workspaces.
#
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 1000;
#
# Declare an array to hold an area map.
#
my $IAMA = zeroes long, 25000;

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
# Initialize the values in the aspect-source-flag array.
#

#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all the GKS aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Generate an array of test data.
#
&gendat ($ZDAT,23,23,14,20,20,-136.148,451.834);
#
# Example 1-1 ---------------------------------------------------------
#
# Force PLOTCHAR to use characters of the lowest quality.
#
&NCAR::pcseti( 'QU - QUALITY FLAG', 2 );
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,23,23,14,$RWRK,5000,$IWRK,1000);
#
# Draw the default background.
#
&NCAR::cpback ($ZDAT,$RWRK,$IWRK);
#
# Draw contour lines and labels.
#
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Add the informational label and the high/low labels.
#
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line around the edge of the plotter frame.
#
&capsap ('EXAMPLE 1-1',$IAMA,0);
&labtop ('EXAMPLE 1-1',.017);
&bndary();
#
# Advance the frame.
#
&NCAR::frame;
#
# Example 1-2 ---------------------------------------------------------
#
# Make PLOTCHAR use medium-quality characters.
#
&NCAR::pcseti( 'QU - QUALITY FLAG', 1 );
#
# Turn on the positioning of labels by the penalty scheme.
#
&NCAR::cpseti( 'LLP - LINE LABEL POSITIONING', 3 );
#
# Turn on the drawing of the high and low label boxes.
#
&NCAR::cpseti( 'HLB - HIGH/LOW LABEL BOX FLAG', 1 );
#
# Tell CONPACK to delete high/low labels which overlap the informational
# label, another high/low label, or the edge.
#
&NCAR::cpseti( 'HLO - HIGH/LOW LABEL OVERLAP FLAG', 7 );
#
# Tell CONPACK not to choose contour levels, so that the ones chosen
# for example 1-1 will be used.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTION FLAG', 0 );
#
# Increase the line width for labelled levels.
#
&NCAR::cpgeti( 'NCL - NUMBER OF CONTOUR LEVELS', my $NCLV );
#
for my $ICLV ( 1 .. $NCLV ) {
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $ICLV );
&NCAR::cpgeti( 'CLU - CONTOUR LEVEL USE FLAG', my $ICLU );
  if( $ICLU == 3 ) {
&NCAR::cpseti( 'CLL - CONTOUR-LINE LINE WIDTH', 2 );
  }
}
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,23,23,14,$RWRK,5000,$IWRK,1000);
#
# Draw the default background, using a wider line than normal.
#
&NCAR::gslwsc (2.);
&NCAR::cpback ($ZDAT,$RWRK,$IWRK);
&NCAR::gslwsc (1.);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,25000);
#
# Put label boxes into the area map.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Draw contour lines, avoiding drawing them through the label boxes.
#
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&drawcl);
#
# Draw all the labels.
#
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line around the edge of the plotter frame.
#
&capsap ('EXAMPLE 1-2',$IAMA,25000);
&labtop ('EXAMPLE 1-2',.017);
&bndary();
#
# Advance the frame.
#
&NCAR::frame;
#
# Example 1-3 ---------------------------------------------------------
#
# Make PLOTCHAR use high-quality characters.
#
&NCAR::pcseti( 'QU - QUALITY FLAG', 0 );
#
# Tell CONPACK to delete high/low labels which overlap the informational
# label or another high/low label, but to move those which overlap the
# edge inward a little.
#
&NCAR::cpseti( 'HLO - HIGH/LOW LABEL OVERLAP FLAG', 11 );
#
# Turn off the area identifiers for all except the zero contour and set
# its identifiers in such a way that we can shade the areas "below" that
# contour.
#
for my $ICLV ( 1 .. $NCLV ) {        
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $ICLV );
&NCAR::cpgetr( 'CLV - CONTOUR LEVEL VALUE', my $CLEV );
  if( $CLEV != 0 ) {
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LINE', 0 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LINE', 0 );
  } else {
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LINE', 2 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LINE', 1 );
  }
}
#
# Draw the contour plot, using the same calls as for example 1-2.
#
&NCAR::cprect ($ZDAT,23,23,14,$RWRK,5000,$IWRK,1000);
&NCAR::gslwsc (2.);
&NCAR::cpback ($ZDAT,$RWRK,$IWRK);
&NCAR::gslwsc (1.);
&NCAR::arinam ($IAMA,25000);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&drawcl);
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
#
# Now, add the zero contour line to the area map.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Scan the area map.  The routine SHADER will be called to shade the
# areas below the zero contour line.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&shader);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line around the edge of the plotter frame.
#
&capsap ('EXAMPLE 1-3',$IAMA,25000);
&labtop ('EXAMPLE 1-3',.017);
&bndary();
#
# Advance the frame.
#
&NCAR::frame;
#
# Example 1-4 ---------------------------------------------------------
#
# Turn on the 2D smoother.
#
&NCAR::cpsetr( 'T2D - TENSION ON THE 2D SPLINES', 1. );
#
# Draw the contour plot, using the same calls as for example 1-3.
#
&NCAR::cprect ($ZDAT,23,23,14,$RWRK,5000,$IWRK,1000);
&NCAR::gslwsc (2.);
&NCAR::cpback ($ZDAT,$RWRK,$IWRK);
&NCAR::gslwsc (1.);
&NCAR::arinam ($IAMA,25000);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&drawcl);
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&shader);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line around the edge of the plotter frame.
#
&capsap ('EXAMPLE 1-4',$IAMA,25000);
&labtop ('EXAMPLE 1-4',.017);
&bndary();
#
# Advance the frame.
#
&NCAR::frame;
#
# Example 1-5 ---------------------------------------------------------
#
# Make CONPACK set up the contour levels again (the range of the data
# may be increased by 3D interpolation), but force it to use the same
# contour interval and label interval that were used for the first four
# plots.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTION FLAG', 16 );
&NCAR::cpgetr( 'CIU - CONTOUR INTERVAL USED', my $CINU );
&NCAR::cpsetr( 'CIS - CONTOUR INTERVAL SPECIFIER', $CINU );
&NCAR::cpgeti( 'LIU - LABEL INTERVAL USED', my $LINU );
&NCAR::cpseti( 'LIS - LABEL INTERVAL SPECIFIER', $LINU );
#
# Provide more room for storing coordinates used to trace contour
# lines.  The default is slightly too small to hold a complete line,
# and this causes some lines to have a couple of labels right next to
# one another.
#
&NCAR::cpseti( 'RWC - REAL WORKSPACE FOR CONTOUR TRACING', 200 );
#
# Turn off the 2D smoother.
#
&NCAR::cpsetr( 'T2D - TENSION ON THE 2D SPLINES', 0. );
#
# Initialize the drawing of the contour plot.
#
&NCAR::cpsprs ($ZDAT,23,23,14,$RWRK,5000,$IWRK,1000,$ZDNS,5152);
#
# Force the selection of contour levels and tweak associated parameters.
#
&NCAR::cppkcl ($ZDNS,$RWRK,$IWRK);
#
&NCAR::cpgeti( 'NCL - NUMBER OF CONTOUR LEVELS', $NCLV );
#
for my $ICLV ( 1 .. $NCLV ) {
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $ICLV );
&NCAR::cpgeti( 'CLU - CONTOUR LEVEL USE FLAG', my $ICLU );
  if( $ICLU == 3 ) {
&NCAR::cpseti( 'CLL - CONTOUR LINE LINE WIDTH', 2 );
  }
&NCAR::cpgetr( 'CLV - CONTOUR LEVEL VALUE', my $CLEV );
  if( $CLEV != 0 ) {
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LINE', 0 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LINE', 0 );
  } else {
&NCAR::cpseti( 'AIA - AREA IDENTIFIER ABOVE LINE', 2 );
&NCAR::cpseti( 'AIB - AREA IDENTIFIER BELOW LINE', 1 );
  }
}
#
# The rest is pretty much the same as for example 1-4, but the array
# ZDNS is used in place of ZDAT.
#
&NCAR::gslwsc (2.);
&NCAR::perim (0,0,0,0);
&NCAR::gslwsc (1.);
&NCAR::arinam ($IAMA,25000);
&NCAR::cplbam ($ZDNS,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDNS,$RWRK,$IWRK,$IAMA,\&drawcl);
&NCAR::cplbdr ($ZDNS,$RWRK,$IWRK);
&NCAR::cpclam ($ZDNS,$RWRK,$IWRK,$IAMA);
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&shader);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line around the edge of the plotter frame.
#
&capsap ('EXAMPLE 1-5',$IAMA,25000);
&labtop ('EXAMPLE 1-5',.017);
&bndary();
#
# Advance the frame.
#
&NCAR::frame;
#
# Example 1-6 ---------------------------------------------------------
#
# Turn off the selection of contour levels, so that the set picked for
# example 1-5 will be used.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTION FLAG', 0 );
#
# Draw an EZMAP background.  The perimeter and the grid are turned off.
# The "political + U.S. states" dataset is used and it is dotted.  We
# use a satellite-view projection, centered over the U.S., showing
# maximal area.
#
&NCAR::mapsti ('PE - PERIMETER',0);
&NCAR::mapsti ('GR - GRID',0);
&NCAR::mapstc ('OU - OUTLINE DATASET','PS');
&NCAR::mapsti ('DO - DOTTING OF OUTLINES',1);
&NCAR::mapstr ('SA - SATELLITE HEIGHT',1.13);
&NCAR::maproj ('SV - SATELLITE-VIEW',40.,-95.,0.);
&NCAR::mapset ('MA - MAXIMAL AREA',
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] )
	       );
&NCAR::mapdrw;
#
# Tell CONPACK that the SET call has been done, force it to generate X
# coordinates that are longitudes and Y coordinates that are latitudes,
# turn on mapping to an EZMAP background, define the out-of-range value
# (returned by MAPTRN for an unprojectable point), and put the
# informational label in a different place.
#
&NCAR::cpseti( 'SET - DO SET-CALL FLAG', 0 );
&NCAR::cpsetr( 'XC1 - X COORDINATE AT I = 1', -130. );
&NCAR::cpsetr( 'XCM - X COORDINATE AT I = M', -60. );
&NCAR::cpsetr( 'YC1 - Y COORDINATE AT J = 1', 10. );
&NCAR::cpsetr( 'YCN - Y COORDINATE AT J = N', 70. );
&NCAR::cpseti( 'MAP - MAPPING FLAG', 1 );
&NCAR::cpsetr( 'ORV - OUT-OF-RANGE VALUE', 1.E12 );
&NCAR::cpseti( 'ILP - INFORMATIONAL LABEL POSITIONING', 3 );
&NCAR::cpsetr( 'ILX - INFORMATIONAL LABEL X POSITION', .5 );
&NCAR::cpsetr( 'ILY - INFORMATIONAL LABEL Y POSITION', -.02 );
#
# The rest of the calls are just as in example 1-5, except that the
# perimeter is not drawn.
#
&NCAR::cpsprs ($ZDAT,23,23,14,$RWRK,5000,$IWRK,1000,$ZDNS,5152);
&NCAR::arinam ($IAMA,25000);
&NCAR::cplbam ($ZDNS,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDNS,$RWRK,$IWRK,$IAMA,\&drawcl);
&NCAR::cplbdr ($ZDNS,$RWRK,$IWRK);
&NCAR::cpclam ($ZDNS,$RWRK,$IWRK,$IAMA);
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IARA,$IGRA,10,\&shader);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line around the edge of the plotter frame.
#
&capsap ('EXAMPLE 1-6',$IAMA,25000);
&labtop ('EXAMPLE 1-6',.017);
&bndary();
#
# Advance the frame.
#
&NCAR::frame;




&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();





rename 'gmeta', 'ncgm/cpex01.ncgm';
