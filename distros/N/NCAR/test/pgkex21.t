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
#  Illustrate line joins, caps, and miter limits.
#
#
#  Specify certain key points on the plot (indices 1-3 for vertices 
#  of joins; 4-6 for vertices of caps; 7-8 for vertices of miter 
#  limits).
#
my @X = ( 0.20, 0.50, 0.80, 0.28, 0.28, 0.28, 0.75, 0.75 );
my @Y = ( 0.80, 0.67, 0.80, 0.35, 0.19, 0.03, 0.35, 0.14 );
#
#  Define color indices.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 0.0);
#
#  Set workstation "1" as the one involved in subsequent NGSETI settings.
#
&NCAR::ngseti( 'Workstation', 1 );
#
#  Line joins.
#
# 
#  Labels.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 1 );
&NCAR::plchhq(.5,$Y[0]+0.15,'Line joins',.032,0.,0.);
&NCAR::plchhq($X[0],$Y[0]+0.07,'miter',.025,0.,0.);
&NCAR::plchhq($X[1],$Y[0]+0.07,'round',.025,0.,0.);
&NCAR::plchhq($X[2],$Y[0]+0.07,'bevel',.025,0.,0.);
#
#  Loop through the three types of line join.
#
for my $I ( 1 .. 3 ) {
&NCAR::ngseti( 'Joins', $I-1 );
&DRAWV($X[$I-1],$Y[$I-1],($I-1)%2,0,90.,0.7,1,25.);
&DRAWV($X[$I-1],$Y[$I-1],($I-1)%2,1,90.,0.7,0,1.);
}
#
#  Line caps.
#
# 
#  Labels.
#
&NCAR::plchhq($X[3],$Y[3]+0.15,'Line caps',.032,0.,0.);
&NCAR::plchhq($X[3],$Y[3]+0.06,'butt',.025,0.,0.);
&NCAR::plchhq($X[3],$Y[4]+0.06,'round',.025,0.,0.);
&NCAR::plchhq($X[3],$Y[5]+0.06,'square',.025,0.,0.);
#
#  Loop through the three types of line caps.
#
for my $I ( 4 .. 6 ) {
&NCAR::ngseti( 'Caps', $I-4 );
&DRAWV($X[$I-1],$Y[$I-1],0,0,180.,0.75,1,25.);
&DRAWV($X[$I-1],$Y[$I-1],0,2,180.,0.75,0,1.);
}
#
#  Miter limits.
# 
#  Labels.
#
&NCAR::plchhq($X[6],$Y[6]+0.15,'Miter limits',.032,0.,0.);
&NCAR::plchhq($X[6],$Y[6]+0.07,'default (= 10.)',.025,0.,0.);
&NCAR::plchhq($X[6],$Y[7]+0.04,'limit = 1.',.025,0.,0.);
#
#  Set line join to miter.
#
&NCAR::ngseti( 'Join', 0 );
#
#  Default.
#
&DRAWV($X[6],$Y[6],0,0,35.,0.5,1,20.);
#
#  Limit = 1.
#
&NCAR::ngsetr( 'Miter', 1. );
&DRAWV($X[7],$Y[7],0,0,35.,0.5,1,20.);
#
&NCAR::frame;


sub DRAWV {
  my ( $X,$Y,$IORIEN,$IDOT,$ANG,$SCALE,$ICOLOR,$THICK) = @_;
#
#  Draw a "V" where:
#
#       (X,Y)   is the coordinate of the vertex.
#       IORIEN  flags whether the "V" is up (=1) or down (=0).
#       IDOT    flags whether dots are to be drawn at coordinates.
#               = 0 no dots.
#               = 1 dots at all coordinates
#               = 2 dots only at the end points
#       ANG     is the angle (in degrees) at the vertex of the "V".
#       SCALE   scales how big the "V" is.
#       ICOLOR  is the color index to be used for the lines.
#       THICK   is the linewidth scale factor.
#
  my ( $RADC, $DSIZ ) = ( .0174532, 0.25 );
#
  &NCAR::gsplci($ICOLOR);
  &NCAR::gslwsc($THICK);
#
  my $BETA = $RADC*(90.-0.5*$ANG);
  my $XOFF = $SCALE*$DSIZ*cos($BETA);
  my $YOFF = $SCALE*$DSIZ*sin($BETA);
  my $SIGN;
  if( $IORIEN == 0 ) {
    $SIGN =  1.;
  } else {
    $SIGN = -1.;
  }
#
  my $XV = float [ $X-$XOFF, $X, $X+$XOFF ];
  my $YV = float [ $Y-$SIGN*$YOFF, $Y, $Y-$SIGN*$YOFF ];
#
  &NCAR::gpl(3,$XV,$YV);
#
  if( $IDOT == 1 ) {
    &NCAR::ngdots($XV,$YV,3,0.005*$THICK,$ICOLOR);
  } elsif( $IDOT == 2 ) {
    &NCAR::ngdots(at($XV, 0),at($YV, 0),1,0.005*$THICK,$ICOLOR);
    &NCAR::ngdots(at($XV, 2),at($YV, 2),1,0.005*$THICK,$ICOLOR);
  }
#
}
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/pgkex21.ncgm';
