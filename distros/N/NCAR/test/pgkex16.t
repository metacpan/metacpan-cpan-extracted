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

my $ID=11;
my $IDM1=$ID-1;
#
#  Coordinate data defining 10 points for a five-pointed star.
#  The ten points specify the tips of the star as well as the
#  points toward the center between the tips.  The first point
#  is set equal to the last point for the purposes of drawing
#  the outline of the points.
#
my $XS = float [
    0.00000, -0.22451, -0.95105, -0.36327, -0.58780,
    0.00000,  0.58776,  0.36327,  0.95107,  0.22453,
    0.00000                                         
];
my $YS = float [
    1.00000,  0.30902,  0.30903, -0.11803, -0.80900,
   -0.38197, -0.80903, -0.11805,  0.30898,  0.30901,
    1.00000                                         
];
#
#  Coordinates for labelling the stars.
#
my $XP = float [
    .243,.180,.025,.138,.098,.243,.385,.345,.457,.320
];
my $YP = float [
    .690,.540,.513,.415,.285,.340,.285,.415,.513,.540 
];
#
#  Define colors.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 1.0);
&NCAR::gscr(1, 2, 0.4, 0.0, 0.4);
&NCAR::gscr(1, 3, 1.0, 0.0, 0.0);
#
#  Draw the star with interior style solid;
#  use ten points in the fill area call.
#
my $X = .25;
my $Y = .45;
my $SCL = .2;

my $XD = zeroes float, $ID;
my $YD = zeroes float, $ID;


for my $I ( 1 .. $ID ) {
  set( $XD, $I - 1, $X+$SCL* at( $XS, $I - 1 ) );
  set( $YD, $I - 1, $Y+$SCL* at( $YS, $I - 1 ) );
}
#
&NCAR::gsfais(1);
&NCAR::gsfaci(1);
&NCAR::gfa(10,$XD,$YD);
#
#  Label the points.
#
for my $I ( 1 .. 10 ) {
  &pltnum ( at( $XP, $I - 1 ),at( $YP, $I - 1 ),$I);
}
#
#  Draw lines connecting the coordinate points.
#
&NCAR::gsplci(3);
&NCAR::gslwsc(4.);
&NCAR::gpl($ID,$XD,$YD);
#
#  Draw the star with interior style solid;
#  use only the five tips of the star as coordinates.
#
$X = .75;
$Y = .45;
$SCL = .2;

$XD = float [ 
      $X+$SCL*at( $XS, 1 ),
      $X+$SCL*at( $XS, 5 ),
      $X+$SCL*at( $XS, 9 ),
      $X+$SCL*at( $XS, 3 ),
      $X+$SCL*at( $XS, 7 ),
      $X+$SCL*at( $XS, 1 ),
];      
$YD = float [ 
      $Y+$SCL*at( $YS, 1 ),
      $Y+$SCL*at( $YS, 5 ),
      $Y+$SCL*at( $YS, 9 ),
      $Y+$SCL*at( $YS, 3 ),
      $Y+$SCL*at( $YS, 7 ),
      $Y+$SCL*at( $YS, 1 ),
];      
&NCAR::gfa(5,$XD,$YD);
&NCAR::gpl(6,$XD,$YD);
#
#  Label the points.
#
&pltnum( at( $XP, 1)+.5, at( $YP, 1),1);
&pltnum( at( $XP, 3)+.5, at( $YP, 3),4);
&pltnum( at( $XP, 5)+.5, at( $YP, 5),2);
&pltnum( at( $XP, 7)+.5, at( $YP, 7),5);
&pltnum( at( $XP, 9)+.5, at( $YP, 9),3);
#
#  Label the plot using Plotchar.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq(.5,.91,'Filled areas',.035,0.,0.);
&NCAR::plchhq(.5,.84,'What\'s inside, what\'s outside?',.035,0.,0.);
#
#  Close picture, deactivate and close the workstation, close GKS.
#
sub pltnum {
  my ($X,$Y,$NUM) = @_;
#
#  Plot the value of the integer NUM at coordinate location (X,Y)
#
  my $LABEL = sprintf( '%2.2i', $NUM );
#
&NCAR::pcseti( 'FN', 22 );
&NCAR::pcseti( 'CC', 2 );
  &NCAR::plchhq($X,$Y,$LABEL,.023,0.,0.);
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex16.ncgm';
