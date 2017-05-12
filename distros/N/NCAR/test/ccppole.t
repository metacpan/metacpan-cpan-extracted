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
use NCAR::Test;
use strict;

my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Parameterize the number of latitudes, the number of longitudes, the
# sizes of the real and integer workspaces, the size of the area map,
# and the size of the arrays used by ARSCAM for X and Y coordinates.
#
my ( $NLON, $NLAT, $LRWK, $LIWK, $LAMA, $NCRA ) = ( 361, 181, 5000, 5000, 600000, 20000 );
#
# Declare the data array.
#
my $ZDAT = zeroes float, $NLON, $NLAT;
#
# Declare the area map array.
#
my $IAMA = zeroes long, $LAMA;
#
# Declare the real and integer workspace arrays for CONPACK.
#
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;
#
# Declare arrays for ARSCAM and MAPGRM to use in calls to COLRAM and
# COLRLL, respectively.  XCRA and YCRA hold X and Y coordinates; IAIA
# and IGIA hold area identifiers and group identifiers.
#
my $XCRA = zeroes float, $NCRA;
my $YCRA = zeroes float, $NCRA;
my $IAIA = zeroes long, 10;
my $IGIA = zeroes long, 10;

#
# Declare a routine to color the areas represented by the area map.
#
#     EXTERNAL COLRAM
#
# Declare a routine to draw contour lines over land only.
#
#     EXTERNAL COLRCL
#
# Declare a routine to draw lat/lon lines over ocean only.
#
#     EXTERNAL COLRLL
#
# Define the values to be used for GKS aspect source flags.
#
my $IASF = long [ ( 1 ) x 13 ];
#
# Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
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
# Define 16 different color indices, for indices 0 through 15.  The
# color corresponding to index 0 is black and the color corresponding
# to index 1 is white.  Colors 2 and 3 are used for alternate contour
# bands over ocean.  Colors 4 through 16 are used for contour bands
# over land.
#
&NCAR::gscr ($IWKID, 0,0.000,0.000,0.000);
&NCAR::gscr ($IWKID, 1,1.000,1.000,1.000);
&NCAR::gscr ($IWKID, 2,0.000,1.000,1.000);
&NCAR::gscr ($IWKID, 3,0.000,0.850,0.850);
&NCAR::gscr ($IWKID, 4,0.700,0.700,0.700);
&NCAR::gscr ($IWKID, 5,0.750,0.500,1.000);
&NCAR::gscr ($IWKID, 6,0.500,0.000,1.000);
&NCAR::gscr ($IWKID, 7,0.000,0.000,1.000);
&NCAR::gscr ($IWKID, 8,0.000,0.500,1.000);
&NCAR::gscr ($IWKID, 9,0.000,1.000,0.600);
&NCAR::gscr ($IWKID,10,0.000,1.000,0.000);
&NCAR::gscr ($IWKID,11,0.700,1.000,0.000);
&NCAR::gscr ($IWKID,12,1.000,1.000,0.000);
&NCAR::gscr ($IWKID,13,1.000,0.750,0.000);
&NCAR::gscr ($IWKID,14,1.000,0.380,0.380);
&NCAR::gscr ($IWKID,15,1.000,0.000,0.380);
&NCAR::gscr ($IWKID,16,1.000,0.000,0.000);
#
# Generate an array of test data.  It is important that the data should
# represent a continous function around the globe.  What is used here
# is a simple trigonometric function of latitude and longitude.
#
my $ZMIN= 1.E36;
my $ZMAX=-1.E36;
#
for my $I ( 1 .. $NLON ) {
  my $RLON=.017453292519943*(-180.+360.*($I-1)/($NLON-1));
  for my $J ( 1 .. $NLAT ) {
    my $RLAT=.017453292519943*(-90.+180.*($J-1)/($NLAT-1));
    set( $ZDAT, $I-1, $J-1, .5*cos(8.*$RLAT)+.25*cos($RLAT)*sin(4.*$RLON) );
    $ZMIN=&NCAR::Test::min($ZMIN,at( $ZDAT, $I-1, $J-1));
    $ZMAX=&NCAR::Test::max($ZMAX,at( $ZDAT, $I-1, $J-1));
  }
}
#
# Reduce the test data to the desired range.
#
for my $I ( 1 .. $NLON ) {
  for my $J ( 1 .. $NLAT ) {
    set( $ZDAT, $I-1, $J-1, ((at($ZDAT, $I-1, $J-1)-$ZMIN)/($ZMAX-$ZMIN))*130.-10. );
  }
}
#
# Put a label at the top of the plot.
#
&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq (.5,.975,'CONTOUR BANDS ON A STEREOGRAPHIC PROJECTION',.02,0.,0.);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,$LAMA);
#
# Tell Ezmap where to put the plot on the plotter frame.
#
&NCAR::mappos (.03,.97,.01,.95);
#
# Tell Ezmap to use a stereographic projection.
#
&NCAR::maproj ('ST',90.,0.,0.);
#
# Tell Ezmap to use a 90-degree distance to each of the four edges
# of the map.
#
&NCAR::mapset ('AN - ANGLES',
               float( [ 90., 0 ] ),
               float( [ 90., 0 ] ),
               float( [ 90., 0 ] ),
               float( [ 90., 0 ] )
	       );
#
# Initialize Ezmap.
#
&NCAR::mapint;
#
# Put continental outlines in the area map.
#
&NCAR::mapbla ($IAMA);
#
# Tell CONPACK not to do the SET call (since it's already been done)
# and to use mapping function 1 (EZMAP background).
#
&NCAR::cpseti ('SET - DO-SET-CALL FLAG',0);
&NCAR::cpseti ('MAP - MAPPING FLAG',1);
#
# Tell CONPACK what ranges of X and Y coordinates to send into the
# mapping function.
#
&NCAR::cpsetr ('XC1 - X COORDINATE AT I=1',-180.);
&NCAR::cpsetr ('XCM - X COORDINATE AT I=M',+180.);
&NCAR::cpsetr ('YC1 - Y COORDINATE AT J=1', -90.);
&NCAR::cpsetr ('YCN - Y COORDINATE AT J=N', +90.);
#
# Tell CONPACK exactly what contour levels to use.
#
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTOR',1);
&NCAR::cpsetr ('CMN - CONTOUR LEVEL MINIMUM',0.);
&NCAR::cpsetr ('CMX - CONTOUR LEVEL MAXIMUM',110.);
&NCAR::cpsetr ('CIS - CONTOUR INTERVAL SPECIFIER',10.);
#
# Tell CONPACK what to use as the out-of-range flag.  This is the
# value returned by the Ezmap routine MAPTRA for off-map points.
#
&NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',1.E12);
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,$NLON,$NLON,$NLAT,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Add contour lines to the area map.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Color the map.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,$NCRA,$IAIA,$IGIA,10,\&COLRAM);
#
# Switch the current polyline color to black.
#
&NCAR::gsplci (0);
#
# Outline the continents and draw lines of latitude and longitude over
# the ocean only.
#
&NCAR::mapgrm ($IAMA,$XCRA,$YCRA,$NCRA,$IAIA,$IGIA,10,\&COLRLL);
&NCAR::mapstc ('OU - OUTLINE DATASET','CO');
&NCAR::maplot();
#
# Draw the contour lines over land only.
#
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&COLRCL);
#
# Advance the frame.
#
&NCAR::frame();
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
# Done.
#


sub COLRAM {
  my ($XCRA,$YCRA,$NCRA,$IAIA,$IGIA,$NAGI) = @_;
#
# This routine is called to color an area from an area map.  Its
# coordinates are given by the NCRA coordinates in the arrays XCRA and
# YCRA.  For each I from 1 to NAGI, IAIA(I) is the area identifier of
# the area relative to the group whose group identifier is IGIA(I).
#
# Find the area identifier for the area relative to groups 1 and 3.
# The first of these tells us whether the area is over land or water,
# and the second tells us what contour band the area is in.
#
  my $IAI1=-1;
  my $IAI3=-1;
#
  for my $I ( 1 .. $NAGI ) {
    if( at( $IGIA, $I-1 ) == 1 ) { $IAI1 = at( $IAIA, $I-1 ); }
    if( at( $IGIA, $I-1 ) == 3 ) { $IAI3 = at( $IAIA, $I-1 ); }
  }
#
# Color-fill the area, using two slightly-different shades of blue
# over water (so that the contour bands will be minimally visible)
# and brighter colors over land.
#
  if( $IAI1 > 0 ) {
    if( &NCAR::mapaci( $IAI1 ) == 1 ) {
      &NCAR::gsfaci (2+($IAI3 % 2));
      &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
    } else {
      if( ( $IAI3 >= 1 ) && ( $IAI3 <= 13 ) ) {
        &NCAR::gsfaci ($IAI3+3);
        &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
      }
    }
  }
#
# Done.
#
}

sub COLRCL {
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
    if( at( $IGIA, $I-1 ) == 1 ) { $IAI1 = at( $IAIA, $I-1 ); }
    if( at( $IGIA, $I-1 ) == 3 ) { $IAI3 = at( $IAIA, $I-1 ); }
  }
#
# Draw the line only if the area it is in is over land.
#
  if( ( $IAI1 > 0 ) && ( &NCAR::mapaci( $IAI1 ) != 1 ) ) { &NCAR::gpl($NCRA,$XCRA,$YCRA); }
#
# Done.
#
}

sub COLRLL {
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
    if( ( at( $IGIA, $I-1 ) == 1 ) && ( at( $IAIA, $I-1 ) > 0 ) ) { $IAI1 = at( $IAIA, $I-1 ); }
  }
#
# Draw the line only if it is over water.
#
  if( ( $IAI1 > 0 ) && ( &NCAR::mapaci( $IAI1 ) == 1 ) ) { &NCAR::gpl($NCRA,$XCRA,$YCRA); }
#
# Done.
#
}
   
rename 'gmeta', 'ncgm/ccppole.ncgm';
