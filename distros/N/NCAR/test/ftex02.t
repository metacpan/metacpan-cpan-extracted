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
#	$Id: ftex02.f,v 1.1 1998/02/06 19:40:52 fred Exp $
#
#
#  Example of CURVP1, CURVPI.
#
#  Define dimensions, declare arrays.
#
my ( $IDIM, $IOUT ) = ( 10, 201 );
my $YP = zeroes float, $IDIM;
my $TEMP = zeroes float, $IDIM, 2;
my $XO = zeroes float, $IOUT;
my $YO = zeroes float, $IOUT;
my $YI = zeroes float, $IOUT;
#
# Specify the input data.
#
my $X = float [ 0.000, 0.210, 0.360, 0.540, 1.000, 
                1.500, 1.970, 2.300, 2.500, 2.700 ];
my $Y = float [ 0.000, 2.600, 3.000, 2.500, 0.000,
               -1.000, 0.000, 0.800, 0.920, 0.700 ];
#
#  Call CURVP1 setup.
#
my $PERIOD = 3.;
my $SIGMA  = 1.;
&NCAR::curvp1($IDIM, $X, $Y, $PERIOD, $YP, $TEMP, $SIGMA, my $IERR);
#
#  Call CURVP2 and calculate the interpolated values and the integrals.
#
my $XR =  5.;
my $XL = -1.;
my $XINC = ($XR-$XL)/($IOUT-1);
for my $I ( 1 .. $IOUT ) {
  my $xo =  $XL+($I-1)*$XINC;
  set( $XO, $I-1, $xo );
  set( $YO, $I-1, &NCAR::curvp2($xo,$IDIM,$X,$Y,$PERIOD,$YP,$SIGMA) );
  set( $YI, $I-1, &NCAR::curvpi(0.,$xo,$IDIM,$X,$Y,$PERIOD,$YP,$SIGMA) );
}
#
#  Draw a plot of the interpolated functions and mark the original points.
#
&DRWFT2($XL,$XR,$IDIM,$X,$Y,$IOUT,$XO,$YO,$YI);
#
sub DRWFT2 {
  my ($XL,$XR,$II,$X,$Y,$IO,$XO,$YO,$YI) = @_;
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
  my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
  my $YPOS_TOP = 0.85;
#
#  Open GKS, open and activate a workstation.
#
  &NCAR::gopks ($IERRF, my $ISZDM);
  &NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
  &NCAR::gacwk ($IWKID);
#
#  Define a color table.
#
  &NCAR::gscr($IWKID, 0, 1.0, 1.0, 1.0);
  &NCAR::gscr($IWKID, 1, 0.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 2, 1.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 3, 0.0, 1.0, 0.0);
  &NCAR::gscr($IWKID, 4, 0.0, 0.0, 1.0);
  &NCAR::gsclip(0);
#
#  Plot main title.
#
  &NCAR::plchhq(0.50,0.95,':F25:Demo for curvp1, curvpi',0.032,0.,0.);
#
#  Graph the interpolated function values and mark the original
#  input data points.
#
  my $YB = -2.0;
  my $YT =  3.0;
  &BKGFT2($XL,$XR,$YPOS_TOP,'Function',0.42,$YB,$YT);
  &NCAR::gridal(6,5,5,1,1,1,10,$XL,$YB);
#
#  Mark the original data points.
#
  &NCAR::gsmksc(2.);
  &NCAR::gspmci(4);
  &NCAR::gpm($II,$X,$Y);
#
#  Graph the interpolated function values.
#
  &NCAR::gpl($IO,$XO,$YO);
#
#  Graph the integral.
#
  $YB = -1.0;
  $YT =  4.0;
  &BKGFT2($XL,$XR,$YPOS_TOP-0.47,'Integral (from X = 0.)',0.2,$YB,$YT);
  &NCAR::gridal(6,5,5,1,1,1,10,$XL,$YB);
  &NCAR::gpl($IO,$XO,$YI);
  &NCAR::gsplci(1);
#
#  Indicate the period.
#
  &DRWPRD(0.,3.,6.5);
#
  &NCAR::frame();
#
  &NCAR::gdawk($IWKID);
  &NCAR::gclwk($IWKID);
  &NCAR::gclks();
#
}
sub BKGFT2 {
  my ($XL,$XR,$YPOS,$LABEL,$XLP,$YB,$YT) = @_;
#
  &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
  &NCAR::pcseti('FN',21);
  &NCAR::plchhq($XLP,$YPOS - 0.03,$LABEL,0.025,0.,-1.);
  &NCAR::set(0.13,0.93,$YPOS-0.25,$YPOS,$XL,$XR,$YB,$YT,1);
  my $XX = float [ $XL, $XR ];
  my $YY = float [   0,   0 ];
  &NCAR::gsplci(2);
  &NCAR::gpl(2,$XX,$YY);
  &NCAR::gsplci(1);

  &NCAR::gaseti('LTY',1);
  &NCAR::pcseti('FN',21);
  &NCAR::gasetr('XLS',0.02);
  &NCAR::gasetc('XLF','(F4.1)');
  &NCAR::gasetr('YLS',0.02);
  &NCAR::gasetc('YLF','(F5.2)');
  &NCAR::gasetr('XMJ',0.02);
  &NCAR::gasetr('YMJ',0.02);
#
}

sub DRWPRD {
  my ($XL,$XR,$Y) = @_;
#
#  Draws a bounding indicator for the period of the function.
#
#
  my $YOFF = 0.4;
  &NCAR::gsplci(2);
  my $XMID = 0.5*($XR-$XL);
  &NCAR::plchhq($XMID,$Y,':F25:Period',0.02,0.,0.);
#
#  Vertical lines at the period limits.
#
  my $XX = float [ $XL, $XL ];
  my $YY = float [ $Y+$YOFF, $Y-$YOFF ];
  &NCAR::gpl(2,$XX,$YY);
  $XX = float [ $XR, $XR ]; 
  &NCAR::gpl(2,$XX,$YY);
#
#  Horizontal lines between label and vertical lines.
#
  &NCAR::pcseti('TE',1);
  &NCAR::pcgetr('XB',my $XB);
  &NCAR::pcgetr('XE',my $XE);
  $XX = float [ $XL, &NCAR::cfux($XB)-0.09 ];
  $YY = float [ $Y, $Y ];
  &NCAR::gpl(2,$XX,$YY);
#
#  Left arrow.
#
  $YI = 0.5*$YOFF;
  $XX = float [ $XL, $XL+$YI ];
  $YY = float [  $Y,  $Y+$YI ];
  &NCAR::gpl(2,$XX,$YY);
  set( $YY, 1, $Y-$YI );
  &NCAR::gpl(2,$XX,$YY);
#
  $XX = float [ $XR, &NCAR::cfux($XE)+0.09 ];
  $YY = float [ $Y, $Y ];
  &NCAR::gpl(2,$XX,$YY);
#
#  Right arrow.
#
  $XX = float [ $XR, $XR-$YI ];
  $YY = float [ $Y, $Y+$YI ];
  &NCAR::gpl(2,$XX,$YY);
  set( $YY, 1, $Y-$YI );
  &NCAR::gpl(2,$XX,$YY);
#
}

rename 'gmeta', 'ncgm/ftex02.ncgm';

