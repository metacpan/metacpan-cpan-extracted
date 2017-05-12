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

#
#  Demonstration of the GKS CELL ARRAY entry.
#
my ( $IDX, $IDY ) = ( 2, 3 );
my $COLIA = zeroes long, $IDX, $IDY;
#
#  Define the X and Y extents for a rectangle.
#
my ( $XL,$XR,$YB,$YT ) = ( 0.10, 0.90, 0.25, 0.75 );
my @LABEL = (
  [ '  Red  ', ' Cyan  ' ],
  [ ' Green ', 'Magenta' ],
  [ ' Blue  ', 'Yellow ' ],
);
#
#  Set up a color table and define the color index array.
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,1.,1.,1.);
&NCAR::gscr(1,2,1.,0.,0.);
&NCAR::gscr(1,3,0.,1.,0.);
&NCAR::gscr(1,4,0.,0.,1.);
&NCAR::gscr(1,5,0.,1.,1.);
&NCAR::gscr(1,6,1.,0.,1.);
&NCAR::gscr(1,7,1.,1.,0.);
#
for my $I ( 1 .. $IDX ) {
  for my $J ( 1 .. $IDY ) {
     set( $COLIA, $I-1, $J-1, $IDY*($I-1)+$J+1 );
  }
}
#
#  Draw the cell array.
#
&NCAR::gca(0.10, 0.25, 0.90, 0.75, $IDX, $IDY, 1, 1, $IDX, $IDY, $COLIA);
#
#  Label the cells using PLOTCHAR font 26 with the foreground color.
#
my $DX = ($XR-$XL)/$IDX;
my $DY = ($YT-$YB)/$IDY;
&NCAR::pcseti('FN',26);
&NCAR::pcseti('CC',1);
for my $I ( 1 .. $IDX ) {
  my $XCENT = $XL+0.5*$DX+($I-1)*$DX;
  for my $J ( 1 .. $IDY ) {
    my $YCENT = $YB+0.5*$DY+($J-1)*$DY;
    &NCAR::plchhq($XCENT,$YCENT,$LABEL[$J-1][$I-1],.033,0.,0.);
  }
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fcell0.ncgm';
