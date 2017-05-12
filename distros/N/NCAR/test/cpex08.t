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
use NCAR::Test qw( bndary gendat drawcl dfclrs capsap labtop );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

print STDERR "\n";

#
# Declare required data arrays and workspace arrays.
#

my $ZDAT = zeroes float, 40, 40;
my $RWRK = zeroes float, 1000;
my $IWRK = zeroes long, 1000;
my $IAMA = zeroes long, 125000;
my $IASF = long [ ( 1 ) x 13 ];
my $XCRA = zeroes float, 5000;
my $YCRA = zeroes float, 5000;
my $IAIA = zeroes long, 10;
my $IGIA = zeroes long, 10;
#
# Declare arrays to hold the list of indices and the list of labels
# required by the label-bar routine.
#
#
# Declare a routine to color the areas represented by the area map.
#
#       EXTERNAL COLRAM;
#
# Declare a routine to draw contour lines over land only.
#
#       EXTERNAL COLRCL;
#
# Declare a routine to draw lat/lon lines over ocean only.
#
#       EXTERNAL COLRLL;
#
# Define the list of indices required by the label-bar routine.
#
my $LIND = long [ 7,2,3,4,5,6,8,9,10,11,12,13,14,15 ];
#
# Define the list of labels required by the label-bar routine.
#
my @LLBS = ( 'OCEAN  ' , 'LAND   ' , '< 0    ' , '0-10   '  ,
             '10-20  ' , '20-30  ' , '30-40  ' , '40-50  '  ,
             '50-60  ' , '60-70  ' , '70-80  ' , '80-90  '  ,
             '90-100 ' , '> 100  ' );
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Define color indices.
#
&dfclrs(1);
#
# Generate an array of test data.
#
&gendat ($ZDAT,40,40,40,15,15,-10.,110.);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,125000);
#
# Use EZMAP and EZMAPA to create a background.
#
&NCAR::mappos (.01,.74,.01,.99);
&NCAR::maproj ('OR - ORTHOGRAPHIC PROJECTION',15.,15.,0.);
&NCAR::mapset ('MA - MAXIMAL AREA',
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] )
	       );
&NCAR::mapsti ('EL - ELLIPTICAL BOUNDARY',1);
&NCAR::mapstc ('OU - OUTLINE DATASET','CO');
&NCAR::mapsti ('VS - VERTICAL STRIPPING',0);
&NCAR::mapint;
&NCAR::mapbla ($IAMA);
#
# Add a line segment to the area map to separate Africa from Eurasia.
# Because this line segment is added last, it will determine the area
# identifier for all of Africa (223).  Also, add a line cutting
# Madagascar in two, with the same area identifier on both sides, so
# that it will be treated as a part of Africa.
#
&NCAR::mapita (26.0,35.0,0,$IAMA,1,223,0);
&NCAR::mapita (28.8,33.0,1,$IAMA,1,223,0);
&NCAR::mapita (33.0,30.0,1,$IAMA,1,223,0);
&NCAR::mapiqa ($IAMA,1,223,0);
#
&NCAR::mapita (-20.0,42.5,0,$IAMA,1,223,223);
&NCAR::mapita (-20.0,50.0,1,$IAMA,1,223,223);
&NCAR::mapiqa ($IAMA,1,223,223);
#
# Tell CONPACK not to do the SET call (since it's already been done),
# to use mapping function 1 (EZMAP background), and what range of X and
# Y coordinates to send into the mapping function.  The X coordinates
# will be treated as latitudes and will range from 40 degrees west of
# Greenwich to 55 degrees east of Greenwich, and the Y coordinates will
# be treated as latitudes and will range from 45 degrees south of the
# equator to 45 degrees north of the equator.
#
&NCAR::cpseti( 'SET - DO-SET-CALL FLAG', 0 );
&NCAR::cpseti( 'MAP - MAPPING FLAG', 1 );
&NCAR::cpsetr( 'XC1 - X COORDINATE AT I=1', -18. );
&NCAR::cpsetr( 'XCM - X COORDINATE AT I=M', +52. );
&NCAR::cpsetr( 'YC1 - Y COORDINATE AT J=1', -35. );
&NCAR::cpsetr( 'YCN - Y COORDINATE AT J=N', +38. );
#
# Tell CONPACK exactly what contour levels to use.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTOR', 1 );
&NCAR::cpsetr( 'CMN - CONTOUR LEVEL MINIMUM', 0. );
&NCAR::cpsetr( 'CMX - CONTOUR LEVEL MAXIMUM', 100. );
&NCAR::cpsetr( 'CIS - CONTOUR INTERVAL SPECIFIER', 10. );
#
# Tell CONPACK what value EZMAP uses to signal that a projected point
# has disappeared around the limb.  Strictly speaking, this call is
# not necessary here; it has been inserted for the benefit of users
# who modify the example to use global data.
#
&NCAR::cpsetr( 'ORV - OUT-OF-RANGE VALUE', 1.E12 );
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,40,40,40,$RWRK,1000,$IWRK,1000);
#
# Add contour lines to the area map.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Color the map.
#


&NCAR::arscam ($IAMA,$XCRA,$YCRA,5000,$IAIA,$IGIA,10,\&colram);
#
# Outline the continents in black, put black contour lines over the
# color map, and put gray lines of latitude and longitude over the
# ocean.
#
&NCAR::gsplci (0);
&NCAR::maplot;


&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&colrcl);
&NCAR::gsplci (2);

&NCAR::mapgrm ($IAMA,$XCRA,$YCRA,5000,$IAIA,$IGIA,10,\&colrll);
&NCAR::gsplci (1);

#
# Draw a label bar for the plot, relating colors to values.
#
&NCAR::lbseti( 'CBL - COLOR OF BOX LINES', 0 );
&NCAR::lblbar (1,.76,.99,.13,.87,14,.5,1.,$LIND,0,\@LLBS,14,1);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line at the edge of the plotter frame.
#


&capsap ('EXAMPLE 8',$IAMA,125000);
&labtop ('EXAMPLE 8',.017);
&bndary;


sub colram {
  my ($XCRA,$YCRA,$NCRA,$IAIA,$IGIA,$NAGI) = @_;
#
# This routine is called to color an area from an area map.  Its
# coordinates are given by the NCRA coordinates in the arrays XCRA and
# YCRA.  For each I from 1 to NAGI, IAIA(I) is the area identifier of
# the area relative to the group whose group identifier is IGIA(I).
#
# Define an array of color indices associated with area identifiers.
#
  my $IOCI = long [ 3,4,5,6,8,9,10,11,12,13,14,15 ];
#
# Find the area identifier for the area relative to groups 1 and 3.
# The first of these tells us whether the area is over land or water,
# and the second tells us what contour band the area is in.
#
  my $IAI1=-1;
  my $IAI3=-1;
#
  for my $I ( 1 .. $NAGI ) {
     if( at( $IGIA, $I - 1 ) == 1 ) { $IAI1 = at( $IAIA, $I - 1 ); }
     if( at( $IGIA, $I - 1 ) == 3 ) { $IAI3 = at( $IAIA, $I - 1 ); }
  }
#
# Color-fill the area, using blue for any area over water, gray for any
# area over land which is not over Africa or is outside the contour
# plot, and a color depending on the contour level elsewhere.
#
  if( $IAI1 > 0 ) {
    if( &NCAR::mapaci( $IAI1 ) == 1 ) {
      &NCAR::gsfaci (7);
      &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
    } else {
      if( ( $IAI1 != 223 ) || ( $IAI3 <= 0 ) ) {
        &NCAR::gsfaci (2);
        &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
      } else {
        &NCAR::gsfaci ( at( $IOCI, $IAI3 - 1 ) );
        &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
      }
    }
  }
}

sub colrcl {
  my ($XCRA,$YCRA,$NCRA,$IAIA,$IGIA,$NAGI) = @_;
#
# This routine is called to draw a portion of a contour line which is
# wholly contained in some area of an area map.  Its coordinates are
# given by the NCRA coordinates in the arrays XCRA and YCRA.  For each
# I from 1 to NAGI, IAIA(I) is the area identifier of the area relative
# to the group whose group identifier is IGIA(I).
#
# Find the area identifier for the area relative to groups 1 and 3.
# The first of these tells us whether the area is over land or water,
# and the second tells us what contour band the area is in.
#
  my $IAI1=-1;
  my $IAI3=-1;
#


  for my $I ( 1 .. $NAGI ) {
    if( at( $IGIA, $I - 1 ) == 1 )  { $IAI1 = at( $IAIA, $I - 1 ); }
    if( at( $IGIA, $I - 1 ) == 3 )  { $IAI3 = at( $IAIA, $I - 1 ); }
  }
#
# Draw the line only if the area it is in is over Africa and within
# the boundary of the contour plot.
#
  if( ( $IAI1 == 223 ) && ( $IAI3 > 0 ) ) {
    &NCAR::gpl( $NCRA, $XCRA, $YCRA ); 
  }
}

sub colrll {
  my ($XCRA,$YCRA,$NCRA,$IAIA,$IGIA,$NAGI) = @_;
#
# This routine is called to draw a portion of a line of latitude or
# longitude which is wholly contained in some area of an area map.  Its
# coordinates are given by the NCRA coordinates in the arrays XCRA and
# YCRA.  For each I from 1 to NAGI, IAIA(I) is the area identifier of
# the area relative to the group whose group identifier is IGIA(I).
#
# Find the area identifier for the area relative to group 1, which will
# tell us whether the area is over land or water.
#
  my $IAI1=-1;
#
  for my $I ( 1 .. $NAGI ) {
    if( ( at( $IGIA, $I - 1 ) == 1 ) && ( at( $IAIA, $I - 1 ) > 0 ) )
    { $IAI1 = at( $IAIA, $I - 1 ); }
  }
#
# Draw the line only if it is over water.
#
  if( ( $IAI1 > 0 ) && ( &NCAR::mapaci( $IAI1 ) == 1 ) ) {
    &NCAR::gpl( $NCRA, $XCRA, $YCRA );
  }
#
# Done.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/cpex08.ncgm';
