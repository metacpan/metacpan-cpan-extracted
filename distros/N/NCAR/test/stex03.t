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
my $IDM;
#
# Example STEX03 draws a uniform southwesterly field on ten
# different EZMAP projections. A streamline representation overlays
# a rendering using vectors. Polar input mode is employed: all members
# of the U array, representing magnitude, are set to 1.0, while the
# V array contains the directional component, -135.0 degrees.
#
# All projections use the maximum possible extent of the globe, except
# except for frame 3, a Lambert Conical projection, for which a full
# globe projection is impossible.
#
#  
my ( $M, $N ) = ( 25, 25 );
my $A = zeroes float, $N, $M;
my $B = zeroes float, $N, $M;
my $WRK = zeroes float, $M*$N*2;
#
#     Generate the polar input mode component arrays.
#
for my $I ( 1 .. $M ) {
  for my $J ( 1 .. $N ) {
    set( $A, $J-1, $I-1, 1 );
    set( $B, $J-1, $I-1, -135 );
  }
}
#
# Set up a GKS color table
#
&DFCLRS();
#
# Do 10 different EZMAP projections, with Vectors and Streamlines
# superimposed
#
for my $I ( 1 .. 10 ) {
#
# Draw the map projections
#
  if( $I == 3 ) {
    &NCAR::supmap (3,0.,80.,70.,
                   float( [ 90., 0 ] ),
		   float( [ 80., 0 ] ),
		   float( [  0., 0 ] ),
		   float( [  0., 0 ] ),
		   2,20,4,0,my $IERS);
  } else {
    &NCAR::supmap ($I,0.,0.,0.,
                   float( [ 0., 0 ] ),
		   float( [ 0., 0 ] ),
		   float( [ 0., 0 ] ),
		   float( [ 0., 0 ] ),
		   1,20,2,0,my $IERS);
  }
#
# Set the Vectors coordinate parameters appropriately for a full
# globe polar input mode dataset projected using EZMAP
#
  &NCAR::vvseti('MAP -- Mapping Flag', 1);
  &NCAR::vvseti('SET -- Set Call Flag', 0);
  &NCAR::vvsetr('XC1 -- Lower X Bound', -180.0);
  &NCAR::vvsetr('XCM -- Upper X Bound', 180.0);
  &NCAR::vvsetr('YC1 -- Lower Y Bound', -90.0);
  &NCAR::vvsetr('YCN -- Upper Y Bound', 90.0);
  &NCAR::vvseti('PLR -- Vector Polar Flag', 1);
#
# Set the Streamlines coordinate parameters appropriately for a full
# globe polar input mode dataset projected using EZMAP
#
  &NCAR::stseti('MAP -- Mapping Flag', 1);
  &NCAR::stseti('SET -- Set Call Flag', 0);
  &NCAR::stsetr('XC1 -- Lower X Bound', -180.0);
  &NCAR::stsetr('XCM -- Upper X Bound', 180.0);
  &NCAR::stsetr('YC1 -- Lower Y Bound', -90.0);
  &NCAR::stsetr('YCN -- Upper Y Bound', 90.0);
  &NCAR::stseti('PLR -- Vector Polar Flag', 1);
#
# Draw the Vectors in one color
#
  &NCAR::gsplci(3);
  &NCAR::vvinit($A,$M,$B,$M,float([]),$IDM,$M,$N,float([]),$IDM);
  &NCAR::vvectr($A,$B,float([]),long([]),$IDM,float([]));
#
# Draw the Streamlines in another color
#
  &NCAR::gsplci(7);
  &NCAR::stinit($A,$M,$B,$M,float([]),$IDM,$M,$N,$WRK,2*$M*$N);
  &NCAR::stream($A,$B,float([]),long([]),$IDM,$WRK);
#
# Reset the color to the default color index and advance the frame.
#
  &NCAR::gsplci(1);
  &NCAR::frame;
#
}
#
# ==============================================================
#
sub DFCLRS {
#
# Define a set of RGB color triples for colors 0 through 15.
#
  my $NCLRS = 16;
#
# Define the RGB color triples needed below.
#
  my @RGBV = (
     [ 0.00 , 0.00 , 0.00 ],
     [ 1.00 , 1.00 , 1.00 ],
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
  for my $I ( 1 .. $NCLRS ) {
    &NCAR::gscr (1,$I-1,@{ $RGBV[$I-1] });
  }
#
# Done.
#
}
#


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/stex03.ncgm';
