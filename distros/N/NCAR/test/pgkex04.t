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
#  Define color indices, color index 0 defines the background color.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 1.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.2);
&NCAR::gscr(1, 3, 0.4, 0.0, 0.4);
#
#  Create the data for a spiral in the world coordinate square
#  bounded by (-10.,-10.) and (10.,10.) .
#
my $J = 0;
for( my $I = 0; $I <= 720; $I += 6 ) {
  my $SCALE = $I/75.;
  $J = $J+1;
  set( $PLX, $J - 1 , $SCALE*cos(($I-1)*$RADC) );
  set( $PLY, $J - 1 , $SCALE*sin(($I-1)*$RADC) );
}
#
#  Define a normalization transformation that does not preserve
#  aspect ratio.  Draw the transformed spiral with a box bounding
#  the viewport.
#
my $XL = -10.;
my $XR =  10.;
my $YB = -10.;
my $YT =  10.;
&NCAR::gsvp(1,.55,.95,.4,.65);
&NCAR::gswn(1,$XL,$XR,$YB,$YT);
&NCAR::gselnt(1);
&NCAR::gsplci(1);
&NCAR::gpl(121,$PLX,$PLY);
&box($XL,$XR,$YB,$YT);
#
#  Draw an image representing the window to the left of the viewport.
#
&NCAR::gsvp(1,.05,.45,.3,.70);
&NCAR::gswn(1,$XL,$XR,$YB,$YT);
&NCAR::gselnt(1);
&NCAR::gsplci(1);
&NCAR::gpl(121,$PLX,$PLY);
&box($XL,$XR,$YB,$YT);
#
#  Draw dashed lines between the outlines.
#
&dline(.05,.30,.55,.40);
&dline(.45,.30,.95,.40);
&dline(.05,.70,.55,.65);
&dline(.45,.70,.95,.65);
#
#  Label the plot using Plotchar.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 3 );
&NCAR::plchhq(.5,.83,'Normalization transformation',.035,0.,0.);
#
&NCAR::pcseti( 'FN', 21 );
&NCAR::pcseti( 'CC', 3 );
&NCAR::plchhq(.07,.650,'Window',.022,0.,-1.);
&NCAR::plchhq(.57,.625,'Viewport',.022,0.,-1.);
#
&NCAR::pcseti( 'FN', 9 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq(.5,.22,'Normalization transformation defined by',.0275,0.,0.);
#
&NCAR::pcseti( 'FN', 29 );
&NCAR::pcseti( 'CC', 3 );
&NCAR::plchhq(.50,.15,'CALL GSWN(1,-10., 10.,-10., 10.)',.015,0.,0.);
&NCAR::plchhq(.50,.10,'CALL GSVP(1, .55, .95, .40, .65)',.015,0.,0.);
#
&NCAR::frame;
#
#  Deactivate and close the workstation, close GKS.
#
&NCAR::gdawk (1);
&NCAR::gclwk (1);
&NCAR::gclks;
#

sub box {
  my ( $XL,$XR,$YB,$YT ) = @_;
#
#  Draw a box with corner points (XL,YB) and (XR,YT).
#
#
  my $XA = float [ $XL, $XR, $XR, $XL, $XL ];
  my $YA = float [ $YB, $YB, $YT, $YT, $YB ];
#
  &NCAR::gsplci(1);
  &NCAR::gpl(5,$XA,$YA);
#
}

sub dline {
  my ($X1,$Y1,$X2,$Y2) = @_;
#
#  Draw a dashed line with color index 2 between the coordinates
#  (X1,Y1) and (X2,Y2) .
#
  my $XA = float [ $X1, $X2 ];
  my $YA = float [ $Y1, $Y2 ];
  &NCAR::gselnt(0);
  &NCAR::gsplci(2);
  &NCAR::gsln(2);
  &NCAR::gpl(2,$XA,$YA);
  &NCAR::gsln(1);
#
}





rename 'gmeta', 'ncgm/pgkex04.ncgm';
