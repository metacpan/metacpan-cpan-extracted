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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my ($PROJ, $PLAT, $PLON, $ROTA, $OUTLN,$JLIM )
 = ('OR',35.,-105.,0.,'PO','CO' );
my ( $PLIM1, $PLIM2, $PLIM3, $PLIM4 ) = (
  float( [   22.,0. ] ),
  float( [ -122.,0. ] ),
  float( [   47.,0. ] ),
  float( [  -65.,0. ] )
);
my $NUMSTS = 3;
#
# LAT, LON coordinates for Atlanta, Boulder, and Seattle
#
my @LAT = ( 33.5,40.0,47.5 );
my @LON = (-84.5,-105,-122.0 );
my @XCOOR = ( 0.,0.,0. );
my @YCOOR = ( 0.,0.,0. );
my @CITY = ( 'Atlanta, GA', 'Boulder, CO', 'Seattle, WA' );
#
# CMPTRA demonstrates marking points on a map
#
# Set up a color table
#
&DFCLRS ();
#
# Draw Continental, political outlines 
#
&NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR',$OUTLN);
#
# Set up projection
#
&NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
#
# If it's a satellite projection, choose a satellite distance
#
if( $PROJ eq 'SV' ) { &NCAR::mapstr( 'SA - SATELLITE DISTANCE',5.); }
#
# Set limits of map
#
&NCAR::mapset ($JLIM,$PLIM1,$PLIM2,$PLIM3,$PLIM4);
#
# Turn off Grid lines
#
&NCAR::mapstr ('GR',0.);
#
# Draw map
#
&NCAR::mapdrw();
my $INDICE;
for my $I ( 1 .. $NUMSTS ) {
#
# Transform the Coordinates
#
  &NCAR::maptra($LAT[$I-1],$LON[$I-1],my ( $X,$Y ));
  $XCOOR[$I-1] = $X;
  $YCOOR[$I-1] = $Y;
#
# Draw a label
#
  &NCAR::plchhq ($X+.015,$Y,$CITY[$I-1], .015, 0., -1.);
#
# Save last indice
#
  $INDICE = $I;
}

#
# Draw filled circles at selected sites.
#
if( $XCOOR[$INDICE] != 1E12 ) {
  &NCAR::ngdots (float(\@XCOOR),float(\@YCOOR),$NUMSTS,.02,15);
}
#
# Draw stars over the selected sites and connect them with lines.
#
&NCAR::points (float(\@XCOOR), float(\@YCOOR), $NUMSTS, -3, 1);


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
    &NCAR::gscr (1,$I,@{ $RGBV[$I-1] });
  }
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fngngdts.ncgm';
