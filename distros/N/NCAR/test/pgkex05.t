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

my $ILD=121;
my $PLX = zeroes float, $ILD;
my $PLY = zeroes float, $ILD;

my $RADC = .0174532;
#
#  Center positions for spirals.
#
my @XC = (  .31007, .67052  );
my @YC = (  .62000, .20000  );
#
#  Clipping rectangles.
#
my @CX = ( [ .20, .77 ], [ .20, .77 ] );
my @CY = ( [ .50, .76 ], [ .08, .34 ] );
#
#  Define indices, color index 0 defines the background color.
#
&NCAR::gscr(1,0, 1.0, 1.0, 1.0);
&NCAR::gscr(1,1, 0.0, 0.0, 0.0);
&NCAR::gscr(1,2, 0.4, 0.0, 0.4);
&NCAR::gscr(1,3, 0.0, 0.0, 1.0);
#
#  Set the line width to 2 times the nominal width.  This setting
#  may not be honored by all hardware devices.
#
&NCAR::gslwsc(2.0);
for my $K ( 1, 2 ) {
#
#  Define the clipping rectangle.
#
&NCAR::gswn(1,$CX[$K-1][0],$CX[$K-1][1],$CY[$K-1][0],$CY[$K-1][1]);
&NCAR::gsvp(1,$CX[$K-1][0],$CX[$K-1][1],$CY[$K-1][0],$CY[$K-1][1]);
&NCAR::gselnt(1);
#
#  Clipping is on for the second curve only.
#
&NCAR::gsclip($K-1);
#
#  Draw a boundary around the clipping rectangle.
#
my $AX = float [ $CX[$K-1][0], $CX[$K-1][1], 
                 $CX[$K-1][1], $CX[$K-1][0], $CX[$K-1][0] ];
my $AY = float [ $CY[$K-1][0], $CY[$K-1][0], 
                 $CY[$K-1][1], $CY[$K-1][1], $CY[$K-1][0] ];
&NCAR::gsplci(1);
&NCAR::gpl(5,$AX,$AY);
#
#  Draw the spirals.
#
&NCAR::gsplci(3);
my $J = 0;
for( my $I = 0; $I <= 720; $I += 6 ) {
  my $SCALE = $I / 4000;
  $J++;
  set( $PLX, $J-1, $XC[0]+$SCALE*cos(($I-1)*$RADC) );
  set( $PLY, $J-1, $YC[$K-1]+$SCALE*sin(($I-1)*$RADC) );
}
 #
&NCAR::gpl(121,$PLX,$PLY);
#
$J = 0;
for( my $I = 0; $I <= 720; $I += 6 ) {
  my $SCALE = $I / 4000;
  $J++;
  set( $PLX, $J-1, $XC[1]+$SCALE*cos(($I-1)*$RADC) );
  set( $PLY, $J-1, $YC[$K-1]+$SCALE*sin(($I-1)*$RADC) );
}
#
&NCAR::gpl(121,$PLX,$PLY);
}
#
#  Turn clipping back off.
#
&NCAR::gsclip(0);
#
#  Label the plot using Plotchar.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq(.5,.9,'Clipping',.035,0.,0.);
&NCAR::pcseti( 'FN', 21 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq(.2,.80,'Clipping off',.022,0.,-1.);
&NCAR::plchhq(.2,.38,'Clipping on' ,.022,0.,-1.);

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex05.ncgm';
