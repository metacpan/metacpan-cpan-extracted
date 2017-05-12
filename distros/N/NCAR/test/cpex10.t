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


sub Asin { 
  my $x = shift;
  return 
   atan2($x, sqrt(1 - $x * $x)) 
}


#
# This program shows a view of the area around Boulder, Colorado, as
# seen from a satellite directly above Washington, D.C.  Within a
# circular area near Boulder, color-filled contour bands are shown;
# state boundaries are drawn in black over them.  Outside that area,
# the surface of the globe is shaded gray, state boundaries are drawn
# in white, and lines of latitude and longitude are drawn in a light
# gray.  Two-letter mnemonics are used to identify the states; each
# is written using new mapping capabilities of the package PLOTCHAR.
#
#
# Define parameters specifying the lengths of the two area maps and
# the real and integer workspaces that are used.
#
my ( $LAM1, $LAM2, $LRWK, $LIWK ) = ( 2000, 30000, 200, 100 );
#
# Declare an array in which to put an area map that will be used to
# distinguish the circular area near Boulder from the rest of the globe
# and another array in which to put an area map that will be used to
# color contour bands within that area.  This program could be written
# using a single area map; it is being done this way for illustrative
# purposes.
#
my $IAM1 = zeroes long, $LAM1;
my $IAM2 = zeroes long, $LAM2;
#
# Declare scratch arrays required by the routines ARSCAM, MAPBLM, and
# MAPGRM.
#
my $XCRA = zeroes float, 1000;
my $YCRA = zeroes float, 1000;
my $IAIA = zeroes long, 10;
my $IAGI = zeroes long, 10;
#
# Declare arrays in which to get the latitudes and longitudes of points
# defining a circle around Boulder on the surface of the globe.
#
my $CLAT = zeroes float, 100;
my $CLON = zeroes float, 100;
#
# Declare arrays in which to get the latitudes and longitudes of points
# defining a star over Boulder.
#
my $XLAT = zeroes float, 6;
my $XLON = zeroes float, 6;
#
# Define an array in which to generate some dummy data to contour and
# workspace arrays required by CONPACK.
#
my $ZDAT = zeroes float, 41, 41;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long,  $LIWK;
#
# Declare external the routines that will draw the masked grid lines
# and geographical outlines and the routine that will color the contour
# bands in the circular area around Boulder.
#
#       EXTERNAL DRAWGL,DRAWGO,COLRCB
#
# Declare the common block in which the angle at which the label of a
# point on the globe is to be written and the latitude and longitude
# of the point being labelled are transmitted to the routine PCMPXY, in
# the package PLOTCHAR.
#
#       COMMON /PCMP04/ PANG,PLAT,PLON
use NCAR::COMMON qw( %PCMP04 );
#       SAVE   /PCMP04/
#
# Define arrays to hold a list of state names, two-character mnemonics
# for the states, and the latitude and longitude of a point where the
# mnemonic may be placed to label the state.
#
# Define the state-labelling data.
#

my @SNAM = (
  'Alabama       ' ,
  'Alaska        ' ,
  'Arizona       ' ,
  'Arkansas      ' ,
  'California    ' ,
  'Colorado      ' ,
  'Connecticut   ' ,
  'Delaware      ' ,
  'Florida       ' ,
  'Georgia       ' ,
  'Hawaii        ' ,
  'Idaho         ' ,
  'Illinois      ' ,
  'Indiana       ' ,
  'Iowa          ' ,
  'Kansas        ' ,
  'Kentucky      ' ,
  'Louisiana     ' ,
  'Maine         ' ,
  'Maryland      ' ,
  'Massachusetts ' ,
  'Michigan      ' ,
  'Minnesota     ' ,
  'Mississippi   ' ,
  'Missouri      ' ,
  'Montana       ' ,
  'Nebraska      ' ,
  'Nevada        ' ,
  'New Hampshire ' ,
  'New Jersey    ' ,
  'New Mexico    ' ,
  'New York      ' ,
  'North Carolina' ,
  'North Dakota  ' ,
  'Ohio          ' ,
  'Oklahoma      ' ,
  'Oregon        ' ,
  'Pennsylvania  ' ,
  'Rhode Island  ' ,
  'South Carolina' ,
  'South Dakota  ' ,
  'Tennessee     ' ,
  'Texas         ' ,
  'Utah          ' ,
  'Vermont       ' ,
  'Virginia      ' ,
  'Washington    ' ,
  'West Virginia ' ,
  'Wisconsin     ' ,
  'Wyoming       ' ,
);

my @SMNE = (
  'AL' ,
  'AK' ,
  'AZ' ,
  'AR' ,
  'CA' ,
  'CO' ,
  'CT' ,
  'DE' ,
  'FL' ,
  'GA' ,
  'HI' ,
  'ID' ,
  'IL' ,
  'IN' ,
  'IA' ,
  'KS' ,
  'KY' ,
  'LA' ,
  'ME' ,
  'MD' ,
  'MA' ,
  'MI' ,
  'MN' ,
  'MS' ,
  'MO' ,
  'MT' ,
  'NE' ,
  'NV' ,
  'NH' ,
  'NJ' ,
  'NM' ,
  'NY' ,
  'NC' ,
  'ND' ,
  'OH' ,
  'OK' ,
  'OR' ,
  'PA' ,
  'RI' ,
  'SC' ,
  'SD' ,
  'TN' ,
  'TX' ,
  'UT' ,
  'VT' ,
  'VA' ,
  'WA' ,
  'WV' ,
  'WI' ,
  'WY' ,
);

my @SLAT = (
  33.0 ,
  65.0 ,
  34.7 ,
  35.0 ,
  37.5 ,
  39.0 ,
  41.6 ,
  39.0 ,
  28.5 ,
  32.5 ,
  20.0 ,
  43.5 ,
  40.2 ,
  40.0 ,
  42.0 ,
  38.5 ,
  37.4 ,
  31.2 ,
  45.5 ,
  39.2 ,
  42.3 ,
  44.0 ,
  46.0 ,
  32.5 ,
  38.5 ,
  47.0 ,
  41.5 ,
  39.8 ,
  43.2 ,
  39.7 ,
  34.7 ,
  43.0 ,
  35.5 ,
  47.5 ,
  40.2 ,
  35.6 ,
  44.0 ,
  40.8 ,
  41.7 ,
  34.0 ,
  44.5 ,
  36.0 ,
  32.0 ,
  39.5 ,
  44.2 ,
  37.6 ,
  47.5 ,
  38.5 ,
  44.5 ,
  43.0 ,
);

my @SLON = (
   -86.5 ,
  -152.0 ,
  -111.5 ,
   -92.5 ,
  -120.5 ,
  -105.8 ,
   -72.6 ,
   -75.5 ,
   -82.0 ,
   -83.0 ,
  -157.0 ,
  -114.0 ,
   -89.2 ,
   -86.0 ,
   -93.2 ,
   -98.2 ,
   -84.5 ,
   -92.5 ,
   -69.0 ,
   -76.5 ,
   -72.0 ,
   -85.0 ,
   -94.5 ,
   -89.5 ,
   -92.5 ,
  -109.5 ,
   -99.5 ,
  -117.0 ,
   -71.6 ,
   -74.5 ,
  -106.0 ,
   -75.0 ,
   -79.5 ,
  -100.5 ,
   -82.5 ,
   -97.5 ,
  -120.2 ,
   -77.6 ,
   -71.5 ,
   -80.5 ,
  -100.5 ,
   -86.5 ,
  -100.0 ,
  -111.5 ,
   -72.5 ,
   -78.6 ,
  -120.5 ,
   -80.8 ,
   -89.5 ,
  -107.5 ,
);
#
# Define multiplicative constants to convert from degrees to radians
# and from radians to degrees.
#
my $DTOR = .017453292519943;
my $RTOD = 57.2957795130823;
#
# Get the latitudes and longitudes of 100 points defining a circle on
# the globe centered at the point (40.0,-105.3) - the approximate
# latitude and longitude of Boulder, Colorado - and having a radius
# of 7 degrees.
#
&NCAR::nggcog (40.0,-105.3,7.0,$CLAT,$CLON,100);
#
# Generate some dummy data to contour later.
#
for my $I ( 1 .. 41 ) {
  my $X=($I-1)/40.;
  for my $J ( 1 .. 41 ) {
    my $Y=($J-1)/40.;
    set( $ZDAT, $I-1, $J-1, $X*$X+$Y*$Y+$X*$Y+sin(9.*$X)*cos(9.*$Y) );
  }
}
#
# Turn off clipping.
#

&NCAR::gsclip (0);
#
# Turn on solid fill.
#
&NCAR::gsfais (1);
#
# Define some colors to use.  Color index 2 is for grid lines far from
# Boulder, color index 3 is for geographical objects near Boulder, and
# color index 4 is for geographical objects far from Boulder.  Color
# index 5 is used for that part of the earth which is not within the
# circle around Boulder.  Color index 6 is used for the star over
# Boulder.  Color indices 101 through 116 are to be used for contour
# bands in the area near Boulder; they are evenly distributed between
# pure red and pure blue.
#
&NCAR::gscr   (1,0,0.,0.,0.);
&NCAR::gscr   (1,1,1.,1.,1.);
&NCAR::gscr   (1,2,.6,.6,.6);
&NCAR::gscr   (1,3,0.,0.,0.);
&NCAR::gscr   (1,4,1.,1.,1.);
&NCAR::gscr   (1,5,.4,.4,.4);
&NCAR::gscr   (1,6,1.,1.,0.);
#
for my $I ( 101 .. 116 ) {
&NCAR::gscr (1,$I,(116-$I)/15.,0.,($I-101)/15.);
}
#
# Put a label at the top of the plot.
#

&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq (.5,.975, ':F25:SATELLITE VIEW OF CONTOUR BANDS IN A LIMITED AREA',.018,0.,0.);
#
# Tell EZMAP where to put the map on the plotter frame.
#
&NCAR::mappos (.05,.95,.05,.95);
#
# Tell EZMAP to use the view from a satellite above Washington, D.C.
# The basic satellite-view projection is rotated clockwise by 75
# degrees so that the direction a little north of due west is toward
# the top of the projection.
#
&NCAR::maproj ('SV',38.,-76.,75.);
#
# Tell EZMAP how far the satellite is from the center of earth and
# make it look in a direction about 7/8 of the way between looking
# straight down and looking directly at the horizon.  We end up
# looking roughly in the direction of Boulder.
#
my $DFCE=1.3;
#
&NCAR::mdsetr( 'SA', $DFCE );
#
&NCAR::mdsetr( 'S1', 7. * $RTOD * Asin( 1./$DFCE ) / 8. );
#
# Set the parameter 'S2' so that the line of sight is displaced toward
# the top of the basic satellite view - that is to say, in the direction
# a little north of due west that the setting of ROTA implies - by the
# angle specified by 'S1'.
#
&NCAR::mdsetr( 'S2', 90. );
#
# Tell EZMAP the satellite has a total field of view of 40 degrees.
#
&NCAR::mapset ('AN',
               float( [ 20., 0. ] ),
               float( [ 20., 0. ] ),
               float( [ 20., 0. ] ),
               float( [ 20., 0. ] )
	       );
#
# Tell EZMAP to use the outline with political and state boundaries.
#
&NCAR::mdsetc( 'OU', 'PS' );
#
# Tell EZMAP to use a one-degree grid.
#
&NCAR::mdseti( 'GR', 1 );
#
# Initialize EZMAP.
#
&NCAR::mapint;
#
# Tell CONPACK not to call SET (because MAPINT has already done it).
#
&NCAR::cpseti( 'SET - DO-SET-CALL FLAG', 0 );
#
# Tell CONPACK to map the contour lines using EZMAP.
#
&NCAR::cpseti( 'MAP - MAPPING FLAG.', 1 );
#
# Tell CONPACK what longitudes the minimum and maximum values of the
# first array index correspond to.
#
&NCAR::cpsetr( 'XC1 - X COORDINATE AT I=1', -115. );
&NCAR::cpsetr( 'XCM - X COORDINATE AT I=M', -95. );
#
# Tell CONPACK what latitudes the minimum and maximum values of the
# second array index correspond to.
#
&NCAR::cpsetr( 'YC1 - Y COORDINATE AT J=1', 32. );
&NCAR::cpsetr( 'YCN - Y COORDINATE AT J=N', 48. );
#
# Tell CONPACK to use exactly 15 contour levels, splitting the range
# from the minimum value to the maximum value into 16 equal bands.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTOR', -15 );
#
# Tell CONPACK where the data to be contoured are, where the real and
# integer workspaces are, and how big each array is.
#
&NCAR::cprect ($ZDAT,41,41,41,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Initialize the first area-map array.
#
&NCAR::arinam ($IAM1,$LAM1);

#
# Put the projection of the circle around Boulder into the area map.
# The information goes into edge group 1.  The area inside the projected
# circle is characterized as area 1 and the area outside the circle as
# area 2.
#
&NCAR::mapita (at($CLAT, 0),at( $CLON, 0),0,$IAM1,1,1,2);
#
for my $I ( 2 .. 100 ) {
  &NCAR::mapita (at( $CLAT,$I-1),at( $CLON,$I-1),1,$IAM1,1,1,2);
}
#
&NCAR::mapiqa ($IAM1,1,1,2);
#
# Copy the information from the first area-map array to the second one.
# Note that the routine we use to do this, despite the "move" implied
# by its name, can actually be used in this way.
#
&NCAR::armvam ($IAM1,$IAM2,$LAM2);
#
# Add to the second area map the limb line and the perimeter for the
# satellite-view projection.  This is done by temporarily using no
# outline dataset, so that MAPBLA will put only the lines we want into
# the area map.  The edges will go in edge group 1.
#
&NCAR::mdsetc( 'OU', 'NO' ); 
&NCAR::mapbla ($IAM2);

&NCAR::mdsetc( 'OU', 'PS' );

#
# Add to the second area map the contour lines for the area near
# Boulder.  They will go in edge group 3.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAM2);
#
# Scan the second area map to color the contour bands near Boulder.
#
&NCAR::arscam ($IAM2,$XCRA,$YCRA,1000,$IAIA,$IAGI,10,\&COLRCB);
#
# Double the line width.
#
&NCAR::gslwsc (2.);
#
# Draw a masked latitude/longitude grid and masked outlines.
#
&NCAR::mapgrm ($IAM1,$XCRA,$YCRA,1000,$IAIA,$IAGI,10,\&DRAWGL);
&NCAR::mapblm ($IAM1,$XCRA,$YCRA,1000,$IAIA,$IAGI,10,\&DRAWGO);
#
# Set the current polyline color index to draw a black line.
#
&NCAR::gsplci (0);
#
# Draw the circle around Boulder.
#
&NCAR::mapit (at( $CLAT, 0),at( $CLON, 0),0);
#
for my $I ( 2 .. 100 ) {
&NCAR::mapit (at( $CLAT, $I-1),at( $CLON, $I-1),1);
}
#
&NCAR::mapiq;
#
# Set the current polyline color index to draw a yellow line.
#
&NCAR::gsplci (6);
#
# Put a star at the position of Boulder.
#
&NCAR::nggsog (40.,-105.,.25,$XLAT,$XLON);
#
&NCAR::mapit (at($XLAT, 0),at($XLON,0),0);
#
for my $I ( 2 .. 6 ) {
&NCAR::mapit (at($XLAT, $I-1),at( $XLON, $I-1),1);
}
#
&NCAR::mapiq;
#
# Label the states using two-character mnemonics for them.
#
&NCAR::pcseti( 'MAP', 4 );
&NCAR::pcsetr( 'ORV', 1.E12 );
$PCMP04{PANG}=45.;
#
for my $I ( 1 .. 50 ) {
  $PCMP04{PLAT}=$SLAT[$I-1];
  $PCMP04{PLON}=$SLON[$I-1];
  &NCAR::plchhq (0.,0.,$SMNE[$I-1],.5,0.,0.);
}
#
# Advance the frame.
#
&NCAR::frame;
#
# Compute or get information about the amount of space used in each
# area-map array and in the real and integer workspace arrays and
# print it.
#
&NCAR::cpgeti( 'RWU - INTEGER WORKSPACE USED', my $IRWS );
&NCAR::cpgeti( 'IWU - INTEGER WORKSPACE USED', my $IIWS );
#
printf( STDERR "
NUMBER OF WORDS USED IN REAL WORKSPACE:    %d
NUMBER OF WORDS USED IN INTEGER WORKSPACE: %d
NUMBER OF WORDS USED IN AREA-MAP ARRAY 1:  %d
NUMBER OF WORDS USED IN AREA-MAP ARRAY 2:  %d
", $IRWS, $IIWS, $LAM1-(at($IAM1,5)-at($IAM1,4)-1), $LAM2-(at($IAM2,5)-at($IAM2,4)-1) );

sub DRAWGL {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NOGI) = @_;
#
# The routine DRAWGL draws the polyline defined by the points
# ((XCRA(I),YCRA(I)),I=1,NCRA) using color index 2 if the area
# identifier relative to edge group 1 is a 2, implying that the
# polyline is outside the circle around Boulder, Colorado; otherwise,
# it does not draw the polyline at all.
#
# Find the area identifier relative to edge group 1.
#
  my $IAI1=-1;
#
  for my $I ( 1 .. $NOGI ) {
    if( at( $IAGI, $I-1 ) == 1 ) { $IAI1 = at( $IAGI, $I-1 ); }
  }
#
# If the polyline is outside the circle, draw it.
#
  if( $IAI1 == 2 ) {
    &NCAR::gsplci (2);
    &NCAR::curve ($XCRA,$YCRA,$NCRA);
  }
#
# Done.
#
}


sub DRAWGO {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NOGI) = @_;
#
# The routine DRAWGO draws the polyline defined by the points
# ((XCRA(I),YCRA(I)),I=1,NCRA) using color index 3 if the area
# identifier relative to edge group 1 is a 1, implying that the
# polyline is inside the circle around Boulder, Colorado, and
# using color index 4, otherwise.
#
# Find the area identifier relative to edge group 1.
#
  my $IAI1=-1;
#
  for my $I ( 1 .. $NOGI ) {
     if( $IAGI == 1) { $IAI1 = at( $IAAI, $I-1 ); }
  }
#
# Draw the polyline if the area identifier is a 1 or a 2, but not
# otherwise.
#
  if ($IAI1 == 1) {
   &NCAR::gsplci (3);
  } elsif( $IAI1 == 2 ) {
   &NCAR::gsplci (4);
  }
#
  &NCAR::curve ($XCRA,$YCRA,$NCRA);
#
# Done.
#
}

sub COLRCB {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NOGI) = @_;
#
# The routine COLRCB colors the polygon defined by the points
# ((XCRA(I),YCRA(I)),I=1,NCRA) if and only if it is inside the
# circle around Boulder and it is a portion of one of the contour
# bands defined by the dummy data array.
#
# Find the area identifiers for the polygon relative to edge groups 1
# and 3.
#
  my $IAI1=-1;
  my $IAI3=-1;
#
  for my $I ( 1 .. $NOGI ) {
    if( at( $IAGI, $I-1 ) == 1 ) { $IAI1 = at( $IAAI, $I-1 ); }
    if( at( $IAGI, $I-1 ) == 3 ) { $IAI3 = at( $IAAI, $I-1 ); }
  }
#
# Fill the polygon using a color implied by the contour level if it
# is inside the circle around Boulder and is part of a contour band.
# If it is outside the circle around Boulder, but is still on the
# globe, use color index 5 for it.
#
  if( ( $IAI1 == 1 ) && ( $IAI3 >= 1 ) && ( $IAI3 <= 16 ) ) {
    &NCAR::gsfaci (100+$IAI3);
    &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
  } elsif( $IAI1 == 2 ) {
    &NCAR::gsfaci (5);
    &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
  }
#
# Done.
#
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/cpex10.ncgm';
