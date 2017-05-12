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

use NCAR::COMMON qw( %TEMPRT %SRFIP1 );
#
# Declare arrays in which to define the surface to be drawn by
# SRFACE and to provide the workspace it needs.
#
my $U = zeroes float, 21;
my $V = zeroes float, 21;
my $W = zeroes float, 21, 21;
my $RWRK = zeroes long, 882;
#
# Declare a function W(U,V) that defines the surface to be drawn.
#
sub WFUN {
  my ( $UU, $VV ) = @_;
  return .5+.25*sin(5.*$UU)+.25*cos(5.*$VV);
}
#
# Turn off frame advances by SRFACE.
#
$SRFIP1{IFR}=0;
#
# Turn on the drawing of skirts by SRFACE and set the base value
# for the skirts.
#
$SRFIP1{ISKIRT}=1;
$SRFIP1{HSKIRT}=0.;
#
# Define the surface to be drawn.
#
for my $I ( 1 .. 21 ) {
  set( $U, $I-1, ( $I-1 ) / 20 );
}
#
for my $J ( 1 .. 21 ) {
  set( $V, $J-1, ( $J-1 ) / 20 );
}
#
for my $I ( 1 .. 21 ) {
  my $UTMP=($I-1)/20.;
  for my $J ( 1 .. 21 ) {
    my $VTMP=($J-1)/20.;
    set( $W, $I-1, $J-1, &WFUN( $UTMP, $VTMP ) );
  }
}
#
# Make the tick marks drawn by PERIM3 twice as long as the default.
#
&NCAR::tick43 (24,16,24,16,24,16);
#
# Define the boundaries of the box to be projected from 3-space to
# 2-space.
#
my $UMIN=0.;
my $UMAX=1.;
my $VMIN=0.;
my $VMAX=1.;
my $WMIN=0.;
my $WMAX=1.;
#
# Define the distance from which the box, when viewed from the direction
# that makes it biggest, should just fill the screen.
#
$TEMPRT{RZERO}=8.;
#
# Define the position of the eye.
#
my $PEYE = float [ 7.,5.,3.,.5*($UMIN+$UMAX),.5*($VMIN+$VMAX),.5*($WMIN+$WMAX) ];
#
# Communicate to SRFACE the dimensions of the box and the distance from
# which it is to be viewed.
#
&NCAR::setr   ($UMIN,$UMAX,$VMIN,$VMAX,$WMIN,$WMAX, $TEMPRT{RZERO});
#
# Initialize THREED, using arguments that will make it use exactly the
# same projection as SRFACE.
#
&NCAR::set3   (.0087976,.9902248,.0087976,.9902248,
               $UMIN,$UMAX,$VMIN,$VMAX,$WMIN,$WMAX,$PEYE);
#
# Draw perimeters in each of the three coordinate planes.
#
&NCAR::perim3 (10,2,10,2,1,0.);
&NCAR::perim3 (10,2,10,2,2,0.);
&NCAR::perim3 (10,2,10,2,3,0.);
#
# Put some labels on the plot.  First, the U axis.
#
&NCAR::pwrzt (.5,0.,1.1,'U',1,3,-1,+3,0);
# 
my $IEND;
for my $ILAB ( 0 .. 10 ) {
  my $UPOS=($ILAB)/10.;
  my $CHRS = sprintf( '%8.1f', $UPOS );
  my $IBEG=0;
  for my $ICHR ( 1 .. 8 ) {
    if( substr( $CHRS, $ICHR-1, 1 ) ne ' ' ) {
      if( $IBEG == 0 ) {
        $IBEG=$ICHR;
      }
      $IEND=$ICHR;
    }
  }
  &NCAR::pwrzt ($UPOS,0.,1.05,substr( $CHRS, $IBEG-1, $IEND-$IBEG+1 ),$IEND-$IBEG+1,3,-1,+3,0);
}
#
# Next, the V axis.
#  
&NCAR::pwrzt (0.,.5,1.1,'V',1,3,+2,+3,0);
#  
for my $ILAB ( 1 .. 10 ) {
  my $VPOS=($ILAB)/10.;
  my $CHRS = sprintf( '%8.1f', $VPOS );
  my $IBEG=0;
  for my $ICHR ( 1 .. 8 ) {
    if( substr( $CHRS, $ICHR-1, 1 ) ne ' ' ) {
      if( $IBEG == 0 ) {
        $IBEG=$ICHR;
      }
      $IEND=$ICHR;
    }
  }
  &NCAR::pwrzt (0.,$VPOS,1.05,substr( $CHRS, $IBEG-1, $IEND-$IBEG+1 ),$IEND-$IBEG+1,3,+2,+3,0);
}
# 
# Finally, the W axis.
# 
&NCAR::pwrzt (1.2,0.,.5,'W',1,3,-1,+3,1);
# 
for my $ILAB ( 0 .. 10 ) {
  my $WPOS=($ILAB)/10.;
  my $CHRS = sprintf( '%8.1f', $WPOS );
  my $IBEG=0;
  for my $ICHR ( 1 .. 8 ) {
    if( substr( $CHRS, $ICHR-1, 1 ) ne ' ' ) {
      if( $IBEG == 0 ) {
        $IBEG=$ICHR;
      }
      $IEND=$ICHR;
    }
  }
  &NCAR::pwrzt (1.05,0.,$WPOS,substr( $CHRS, $IBEG-1, $IEND-$IBEG+1 ),$IEND-$IBEG+1,3,-1,+3,1);
}
# 
# Using POINT3, draw grids inside the perimeters drawn by PERIM3.
# 
for my $I ( 1 .. 11 ) {
  my $PTMP=($I-1)/10.;
  for my $J ( 1 .. 101 ) {
    my $QTMP=($J-1)/100.;
    &NCAR::point3 ($PTMP,$QTMP,0.);
    &NCAR::point3 ($QTMP,$PTMP,0.);
    &NCAR::point3 ($PTMP,0.,$QTMP);
    &NCAR::point3 ($QTMP,0.,$PTMP);
    &NCAR::point3 (0.,$PTMP,$QTMP);
    &NCAR::point3 (0.,$QTMP,$PTMP);
  }
}
# 
#  Double the line width and draw the surface.
# 
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (2.);
# 
&NCAR::srface ($U,$V,$W,$RWRK,21,21,21,$PEYE,0.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fthex05.ncgm';
