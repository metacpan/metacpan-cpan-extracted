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

#
#  $Id: shex01.f,v 1.3 1999/08/21 20:20:07 fred Exp $
#
#
#  Test SHGETNP in package Shgrid.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Number of points in the dataset, number of near points, 
#  number of far points.
#
my ( $N, $NEAREST ) = ( 1331, 500 );
my $NFARTHER = $N-$NEAREST;
my @NPTS;
my @MPTS;
#
my $X = zeroes float, $N;
my $Y = zeroes float, $N;
my $Z = zeroes float, $N;
my $IWK = zeroes long, 2 * $N;
my $RWK = zeroes float, 11*$N+6;
#
#  Workspace arrays for Tdpack.
#
my $MTRI = 150000;
my $RTRI = zeroes float, 10, $MTRI;
my $RTWK = zeroes float, $MTRI, 2;
my $ITWK = zeroes long, $MTRI;
#
#  Generate an array of randomly-positioned points in the unit cube.
#
for my $I ( 1 .. $N ) {
  set( $X, $I-1, &DSRND1() );
  set( $Y, $I-1, &DSRND1() );
  set( $Z, $I-1, &DSRND1() );
}
#
#  Specify the reference point from which we want to find the NEAREST
#  nearest points.
#
my $PX = 0.5;
my $PY = 0.5;
my $PZ = 0.5;
#
#  Plot the points.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Initialize Tdpack parameters.
#
#
#  Move the plot up a bit.
#
&NCAR::tdsetr('VPB',0.09);
&NCAR::tdsetr('VPT',0.99);
&NCAR::tdsetr('VPL',0.11);
&NCAR::tdsetr('VPR',1.00);
&NCAR::tdinit (4.6,  3.0, 3.3, 0.5, 0.5, 0.5, 0.5, 0.5, 2.7,0.);
#
#  Set up some colors using the standard Tdpack entry for that.
#
&NCAR::tdclrs ($IWKID, 1, 0., 0.8, 8, 37, 8);
#
#  Define style indices for shades of gray, green, and red.
#
&NCAR::tdstrs (1,  8, 37,   8,  37, 1, 1, 0, 0.05, 0.05, 0.);
&NCAR::tdstrs (3,  8, 37,  68,  97, 1, 1, 0, 0.05, 0.05, 0.);
&NCAR::tdstrs (4,  8, 37,  98, 127, 1, 1, 0, 0.05, 0.05, 0.);
#
#  Store the indices of the nearest points in NPTS and the complement
#  of that set (with respect to the entire input dataset) in MPTS.
#
&NCAR::shgetnp($PX,$PY,$PZ,$N,$X,$Y,$Z,0,$IWK,$RWK,$NPTS[0],my $IER);
for my $I ( 2 .. $N ) {
  if( $I <= $NEAREST ) {
    &NCAR::shgetnp($PX,$PY,$PZ,$N,$X,$Y,$Z,1,$IWK,$RWK,$NPTS[$I-1],$IER);
  } else {
    &NCAR::shgetnp($PX,$PY,$PZ,$N,$X,$Y,$Z,1,$IWK,$RWK,$MPTS[$I-$NEAREST-1],$IER);
  }
}
#
#  Plot the near points in green.
#
my $NTRI = 0;
my $DOTSIZE = 0.02;
for my $I ( 1 .. $NEAREST ) {
  my $INX = $NPTS[$I-1];
  &NCAR::tdmtri(-5, at( $X, $INX-1 ), at( $Y, $INX-1 ), at( $Z, $INX-1 ),$DOTSIZE,$RTRI,$MTRI,$NTRI,4,0.,0.,0.,1.,1.,1.);
}
#
#  Plot the farther points in gray.
#
for my $I ( 1 .. $NFARTHER ) {
  my $INX = $MPTS[$I-1];
  &NCAR::tdmtri(-5, at( $X, $INX-1 ), at( $Y, $INX-1 ), at( $Z, $INX-1 ),$DOTSIZE,$RTRI,$MTRI,$NTRI,1,0.,0.,0.,1.,1.,1.);
}
#
#  Mark the reference point in red.
#
&NCAR::tdmtri(-5,$PX,$PY,$PZ,1.2*$DOTSIZE,$RTRI,$MTRI,$NTRI,3,0.,0.,0.,1.,1.,1.);
#
#  Draw.
#
&NCAR::tdotri($RTRI,$MTRI,$NTRI,$RTWK,$ITWK,0) ;
&NCAR::tddtri($RTRI,$MTRI,$NTRI,$ITWK) ;
#
#  Draw a box around the perimeter.
#
&NCAR::tdgrds (0., 1., 0., 1., 0., 1., -1., -1., -1.,11,0);
&NCAR::tdgrds (0., 1., 0., 1., 0., 1., -1., -1., -1.,11,1);
#
#  Label the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.5,0.95,':F26:Find the nearest N points in three space',0.025,0.,0.);
&NCAR::plchhq(0.05,0.17,':F22:Red ball = reference point',0.02,0.,-1.);
&NCAR::plchhq(0.05,0.12,':F22:Green balls = near points',0.02,0.,-1.);
&NCAR::plchhq(0.05,0.07,':F22:Gray balls = far points',0.02,0.,-1.);
#
&NCAR::frame();
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


sub DSRND1 {
  return rand();
}


rename 'gmeta', 'ncgm/shex01.ncgm';
