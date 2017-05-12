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
# Draws a uniform field over an azimuthal projection of the globe
# Continental boundaries are filled with a grayscale value
#
#     EXTERNAL FILL
#
my ( $LMAP, $NWRK, $ISIZ ) = ( 200000, 20000, 5 );
my $MAP   = zeroes long,  $LMAP;
my $IAREA = zeroes long,  $ISIZ;
my $IGRP  = zeroes long,  $ISIZ;
my $XWRK  = zeroes float, $NWRK;
my $YWRK  = zeroes float, $NWRK;
#
my ( $M, $N ) = ( 18, 18 );
my $A   = zeroes float, $M, $N;
my $B   = zeroes float, $M, $N;
my $WRK = zeroes float, $M * $N * 2;
my $NCLRS = 4;
#
my @ICLR = ( 2, 3, 64, 196 );
my $IFILIX;
#
my @RGBV = (
    [  0.0,  1.0,  1.0 ], 
    [ 0.75,  0.0,  1.0 ],
    [ 0.75, 0.75, 0.75 ],
    [  0.5,  0.5,  0.5 ],
);
#
# Give initial value to fill color index stored common block CBFILL
#
$IFILIX = 196;
#
# Set up colors for fixed table grayscale and color workstations
#
&NCAR::gscr(1,0,0.,0.,0.);
&NCAR::gscr(1,1,1.,1.,1.);
for my $I ( 1 .. $NCLRS ) {
  &NCAR::gscr( 1,$ICLR[$I-1], @{ $RGBV[$I-1] } );
}
#     
# Generate uniform field intended for polar input mode.
#
for my $I ( 1 .. $M ) {
  for my $J ( 1 .. $N ) {
     set( $A, $I-1, $J-1,  1.0 );
     set( $B, $I-1, $J-1, 45.0 );
  }
}
#
# Set up the map projection
#
&NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','CO');
&NCAR::maproj ('AE',0.0,0.0,0.0);
&NCAR::mapset ('MA',
                float( [ 0.0, 0 ] ),
                float( [ 0.0, 0 ] ),
                float( [ 0.0, 0 ] ),
                float( [ 0.0, 0 ] )
		);
#
# Initialize Maps and Areas
#
&NCAR::mapint;
&NCAR::arinam ($MAP,$LMAP);
&NCAR::mapbla ($MAP);
#    
# Color fill land masses using a gray scale value
#
&NCAR::gsfais (1);
&NCAR::arscam ($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $ISIZ, \&FILL);
#
# Draw boundaries, including the limb
#
&NCAR::gsplci($ICLR[2]);
&NCAR::mapsti ('C4 - LIMB COLOR',$ICLR[2]);
&NCAR::mapsti('LA - LABEL FLAG',0);
&NCAR::mapsti('EL - ELLIPTICAL-PERIMETER SELECTOR',1);
&NCAR::maplbl;
&NCAR::maplot;
#
# Set up Streamline parameters
#
&NCAR::stseti( 'MAP -- Mapping Flag', 1 );
&NCAR::stseti( 'SET -- Do Set Call Flag', 0 );
&NCAR::stsetr( 'XC1 -- Lower X Bound', -180.0 );
&NCAR::stsetr( 'XCM -- Upper X Bound', 180.0 );
&NCAR::stsetr( 'YC1 -- Lower Y Bound', -90.0 );
&NCAR::stsetr( 'YCN -- Upper Y Bound', 90.0 );
&NCAR::stseti( 'PLR -- Streamline Polar Flag', 1 );
&NCAR::stseti( 'TRP -- Interpolation Method', 1 );
&NCAR::stsetr( 'SSP -- Stream Spacing', 0.005 );
&NCAR::stsetr( 'DFM - Differential Magnitude', 0.005 );
#
# Set up Vectors parameters
#
&NCAR::vvseti( 'MAP -- Mapping Flag', 1 );
&NCAR::vvseti( 'SET -- Do Set Call Flag', 0 );
&NCAR::vvsetr( 'XC1 -- Lower X Bound', -180.0 );
&NCAR::vvsetr( 'XCM -- Upper X Bound', 180.0 );
&NCAR::vvsetr( 'YC1 -- Lower Y Bound', -90.0 );
&NCAR::vvsetr( 'YCN -- Upper Y Bound', 90.0 );
&NCAR::vvseti( 'PLR -- Vector Polar Flag', 1 );
&NCAR::vvsetr( 'VFR -- Vector Fractional Minimum', 0.7 );
&NCAR::vvsetc( 'MNT -- Minimum Vector Text', ' ' );
&NCAR::vvsetc( 'MXT -- Maximum Vector Text', ' ' );
#
# Draw Vectors
#
my $IDM=0;
my $RDM=0.0;
&NCAR::gsplci($ICLR[1]);
&NCAR::vvinit($A,$M,$B,$M,$RDM,$IDM,$M,$N,$RDM,$IDM);
&NCAR::vvectr($A,$B,$RDM,long([]),$IDM,$RDM);
#
# Draw Streamlines
#
&NCAR::gsplci($ICLR[0]);
&NCAR::stinit($A,$M,$B,$M,$RDM,$IDM,$M,$N,$WRK,2*$M*$N);
&NCAR::stream($A,$B,$RDM,long([]),$IDM,$WRK);
#
&NCAR::gsplci(1);
#
# Draw a perimeter and eject the frame
#
&NCAR::perim(1,0,1,0);
&NCAR::frame;
#
sub FILL {
  my ($XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$IDSIZ) = @_;
#
# Retrieve area id for geographic area
#
  my $ID = 0;
  for my $I ( 1 .. $IDSIZ ) {
    if( at( $IGRP, $I-1 ) == 1 ) { $ID = at( $IAREA, $I-1 ); }
  }
#
# If it's not water, draw it
#
  if( ( $ID >= 1 ) && ( &NCAR::mapaci( $ID ) != 1 ) ) {
    &NCAR::gsfaci($IFILIX);
    &NCAR::gfa($NWRK,$XWRK,$YWRK);
  }
#
# Otherwise, do nothing
#
}



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/ffex00.ncgm';
