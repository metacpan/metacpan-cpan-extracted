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
#	$Id: ftex04.f,v 1.2 1998/02/09 23:41:20 haley Exp $
#
#
#  Example of KURV1, KURV2, KURVD.
#
my ( $IDIM, $IOUT ) = ( 11 , 201 );
my $IDTEMP = 9*$IDIM;
my $X = zeroes float, $IDIM;
my $Y = zeroes float, $IDIM;
my $TEMP = zeroes float, $IDTEMP;
my $U = zeroes float, $IOUT;
my $XO = zeroes float, $IOUT;
my $YO = zeroes float, $IOUT;
my $XS = zeroes float, $IOUT;
my $YS = zeroes float, $IOUT;
my $XD = zeroes float, $IOUT;
my $YD = zeroes float, $IOUT;
my $XDD = zeroes float, $IOUT;
my $YDD = zeroes float, $IOUT;
my $XP = zeroes float, $IOUT;
my $YP = zeroes float, $IOUT;
my $S = zeroes float, $IOUT;
#
my $X = float [ 3.,  4.,  9., 16., 21., 27., 34., 36., 34., 26., 18. ];
my $Y = float [ 2.4,  9.6, 14.4, 12.0,  9.6,  8.4,13.2, 21.6, 30.0, 37.2, 38.4 ];
#
#  Do KURV1 set up.
#
my $SIGMA = 1.;
my $ISF   = 3;
&NCAR::kurv1($IDIM,$X,$Y,my $SLOP1,my $SLOP2,$ISF,$XP,$YP,$TEMP,$S,$SIGMA,my $IERR);
if( $IERR != 0 ) {
  print STDERR "Error return from KURV1 =$IERR\n";
  exit( 0 );
}
#
#  Get interpolated points using KURV2.
#
my $TINC = 1.0/($IOUT-1);
for my $I ( 1 .. $IOUT ) {
  my ( $u, $xo, $yo );
  $u = ($I-1)*$TINC;
  set( $U, $I-1, $u );
  &NCAR::kurv2($u,$xo,$yo,$IDIM,$X,$Y,$XP,$YP,$S,$SIGMA);
  set( $XO, $I-1, $xo );
  set( $YO, $I-1, $yo );
}
#
#  Get the derivatives.
#
for my $I ( 1 .. $IOUT ) {
  my $u = at( $U, $I-1 );
  my ( $xs, $ys, $xd, $yd, $xdd, $ydd );
  &NCAR::kurvd($u,$xs,$ys,$xd,$yd,$xdd,$ydd,$IDIM,$X,$Y,$XP,$YP,$S,$SIGMA);
  set( $XS, $I-1, $xs );
  set( $YS, $I-1, $ys );
  set( $XD, $I-1, $xd );
  set( $YD, $I-1, $yd );
  set( $XDD, $I-1, $xdd );
  set( $YDD, $I-1, $ydd );
}
#
#  Draw plot.
#
&DRWFT4($IDIM,$X,$Y,$IOUT,$XO,$YO,$U,$XD,$YD);
#
sub DRWFT4 {
  my ($II,$X,$Y,$IOUT,$XO,$YO,$U,$XD,$YD) = @_;
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
  my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
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
#
#  Draw markers at original points.
#
  &BKGFT4(0.,40.,0.,40.,0.15,0.85,'Demo for KURV1/KURV2',0.035,0.5,0.93,0);
  &NCAR::gridal(4,5,4,5,1,1,10,0.,0.);
  &NCAR::gsmksc(2.);
  &NCAR::gspmci(4);
  &NCAR::gpm($II,$X,$Y);
#
#  Draw the interpolated curve
#
  &NCAR::curve($XO,$YO,$IOUT);
  &NCAR::frame();
#
#  Plot the first derivatives of X and Y with respect to the parametric
#  variable U.
#
  &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
  &NCAR::pcseti('FN',21);
  &NCAR::plchhq(0.5,0.95,'Derivatives from KURVD',0.035,0.,0.);
  &BKGFT4(0.,1.,-80.,80.,0.55,0.87,'dx/du',0.030,0.65,0.82,1);
  &NCAR::gridal(5,5,4,5,1,1,10,0.,-80.);
  &NCAR::curve($U,$XD,$IOUT);
  &BKGFT4(0.,1.,-40.,80.,0.10,0.42,'dy/du',0.030,0.39,0.37,1);
  &NCAR::gridal(5,5,3,5,1,1,10,0.,-40.);
  &NCAR::curve($U,$YD,$IOUT);
  &NCAR::frame();
#
  &NCAR::gdawk ($IWKID);
  &NCAR::gclwk ($IWKID);
  &NCAR::gclks();
#
}

sub BKGFT4 {
  my ($XL,$XR,$YB,$YT,$YPB,$YPT,$LABEL,$SIZL,$POSXL,$POSYL,$IZL) = @_;
#
  &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
  &NCAR::pcseti('FN',21);
  &NCAR::plchhq($POSXL,$POSYL,$LABEL,$SIZL,0.,0.);
  &NCAR::set(0.17,0.87,$YPB,$YPT,$XL,$XR,$YB,$YT,1);
  if( $IZL != 0 ) {
    my $XX = float [ $XL, $XR ];
    my $YY = float [   0,   0 ];
    &NCAR::gsplci(2);
    &NCAR::gpl(2,$XX,$YY);
    &NCAR::gsplci(1);
  }
# 
  &NCAR::gaseti('LTY',1);
  &NCAR::pcseti('FN',21);
  &NCAR::gasetr('XLS',0.02);
  &NCAR::gasetc('XLF','(F4.1)');
  &NCAR::gasetr('YLS',0.02);
  &NCAR::gasetc('YLF','(F5.1)');
  &NCAR::gasetr('XMJ',0.02);
  &NCAR::gasetr('YMJ',0.02);
#
}

rename 'gmeta', 'ncgm/ftex04.ncgm';

