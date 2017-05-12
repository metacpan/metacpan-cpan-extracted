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
#	$Id: ftex01.f,v 1.1 1998/02/06 19:40:51 fred Exp $
#
#
#  Example of CURV1, CURV2, CURVD, CURVI.
#
#  Define dimensions, declare arrays.
#
my ( $IDIM, $IOUT ) = ( 11, 201 );
my $X = zeroes float, $IDIM;
my $Y = zeroes float, $IDIM;
my $YP = zeroes float, $IDIM;
my $TEMP = zeroes float, $IDIM, 2;
my $XO = zeroes float, $IOUT;
my $YO = zeroes float, $IOUT;
my $YD = zeroes float, $IOUT;
my $YI = zeroes float, $IOUT;
#
# Specify the input data.
#
#
my $X = float [  0.00,   2.00,   5.00,   8.00,  10.00,  13.00,
                15.00,  18.00,  21.00,  23.00,  30.00 ];
my $Y = float [  1.00,   0.81,   0.00,  -0.81,  -1.00,  -0.84,
                -0.56,   0.04,   0.73,   1.18,   2.0  ];
#
#  Call CURV1 setup, specifying that the derivatives should be
#  zero at the end points.
#
my $SLP1   = 0.;
my $SLPN   = 0.;
my $ISLPSW = 0;
my $SIGMA  = 1.;
&NCAR::curv1($IDIM, $X, $Y, $SLP1, $SLPN, $ISLPSW, $YP, $TEMP, $SIGMA, my $IERR);
#
#  Call CURV2 and calculate the interpolated values, the derivatives,
#  and the integrals.
#
my $XINC = 30./($IOUT-1);
for my $I ( 1 .. $IOUT ) {
  my $xo = ($I-1)*$XINC;
  set( $XO, $I-1, $xo );
  set( $YO, $I-1, &NCAR::curv2( $xo, $IDIM, $X, $Y, $YP, $SIGMA ) );
  set( $YD, $I-1, &NCAR::curvd( $xo, $IDIM, $X, $Y, $YP, $SIGMA ) );
  set( $YI, $I-1, &NCAR::curvi( at( $XO, 0 ), $xo, $IDIM, $X, $Y, $YP, $SIGMA ) );
}
#
#  Draw a plot of the interpolated functions and mark the original points.
#
&DRWFT1($IDIM,$X,$Y,$IOUT,$XO,$YO,$YD,$YI);
#
sub DRWFT1 {
  my ($II,$X,$Y,$IO,$XO,$YO,$YD,$YI) = @_;
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
  my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
  my $YPOS_TOP = 0.88;
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
  &NCAR::plchhq(0.50,0.95,':F25:Demo for CURV, CURVD, CURVI',0.030,0.,0.);
#
#  Graph the interpolated function values and mark the original
#  input data points.
#
  my $YB = -1.0;
  my $YT =  2.0;
  &BKGFT1($YPOS_TOP,'Function',$YB,$YT);
  &NCAR::gridal(6,5,3,1,1,1,10,0.0,$YB);
#
#  Mark the original data points.
#
  &NCAR::gsmksc(2.);
  &NCAR::gspmci(4);
  &NCAR::gslwsc(1.);
  &NCAR::gpm($II,$X,$Y);
#
#  Graph the interpolated function values.
#
  &NCAR::gpl($IO,$XO,$YO);
#
#  Graph the derivative.
#
  $YB = -0.3;
  $YT =  0.3;
  &BKGFT1($YPOS_TOP-0.3,'Derivative',$YB,$YT);
  &NCAR::gridal(6,5,3,1,1,1,10,0.0,$YB);
  &NCAR::gpl($IO,$XO,$YD);
  &NCAR::gsplci(1);
#
#  Graph the integral.
#
  $YB = -6.0;
  $YT = 10.0;
  &BKGFT1($YPOS_TOP-0.6,'Integral',$YB,$YT);
  &NCAR::gridal(6,5,4,1,1,1,10,0.0,$YB);
  &NCAR::gpl($IO,$XO,$YI);
  &NCAR::gsplci(1);
  &NCAR::frame();
#
  &NCAR::gdawk($IWKID);
  &NCAR::gclwk($IWKID);
  &NCAR::gclks();
#
}
sub BKGFT1 {
  my ($YPOS,$LABEL,$YB,$YT) = @_;
#
  &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
  &NCAR::pcseti('FN',21);
  &NCAR::plchhq(0.20,$YPOS - 0.03,$LABEL,0.025,0.,-1.);
  &NCAR::set(0.13,0.93,$YPOS-0.2,$YPOS,0.0,30.0, $YB, $YT, 1);
  my $XX = float [ 0., 30. ];
  my $YY = float [ 0.,  0. ];
  &NCAR::gsplci(2);
  &NCAR::gpl(2,$XX,$YY);
  &NCAR::gsplci(1);

  &NCAR::gaseti('LTY',1);
  &NCAR::pcseti('FN',21);
  &NCAR::gasetr('XLS',0.02);
  &NCAR::gasetc('XLF','(I3)');
  &NCAR::gasetr('YLS',0.02);
  &NCAR::gasetc('YLF','(F5.1)');
  &NCAR::gasetr('XMJ',0.02);
  &NCAR::gasetr('YMJ',0.02);
#
}

rename 'gmeta', 'ncgm/ftex01.ncgm';
