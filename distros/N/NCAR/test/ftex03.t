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
#	$Id: ftex03.f,v 1.1 1998/02/06 19:40:53 fred Exp $
#
#
#  Example of CURVS, CURVPS.
#
#  Define dimensions, declare arrays.
#
my ( $IDIM, $IOUT ) = ( 10, 201 );
my $YS = zeroes float, $IDIM;
my $YSP = zeroes float, $IDIM;
my $TEMP = zeroes float, $IDIM, 11;
my $XO = zeroes float, $IOUT;
my $YOS = zeroes float, $IOUT;
my $YOSP = zeroes float, $IOUT;
#
# Specify the input data.
#
#
my $X = float [  0.000, 0.210, 0.360, 0.540, 1.000, 
        1.500, 1.970, 2.300, 2.500, 2.700 ];
my $Y = float [  0.000, 2.600, 3.000, 2.500, 0.000,
       -1.000, 0.000, 0.800, 0.920, 0.700 ];
#
#  Call CURVS setup.
#
my $SIGMA = 1.0;
my $D     = float [ 0.3, ( 0 ) x ( $IDIM-1 ) ];
my $ISW   = 1;
my $S     = $IDIM;
my $EPS   = sqrt(2./$S);
&NCAR::curvs($IDIM,$X,$Y,$D,$ISW,$S,$EPS,$YS,$YSP,$SIGMA,$TEMP,my $IERR);
#
#  Call CURVP2 and calculate the interpolated values and the integrals.
#
my $XR =  5.;
my $XL = -1.;
my $XINC = ($XR-$XL)/($IOUT-1);
for my $I ( 1 .. $IOUT ) {
  my $xo = $XL+($I-1)*$XINC;
  set( $XO, $I-1, $xo );
  set( $YOS, $I-1, &NCAR::curv2( $xo, $IDIM, $X, $YS, $YSP, $SIGMA ) );
}
#
#  Call CURVPS setup.
#
my $P = 3.;
&NCAR::curvps($IDIM,$X,$Y,$P,$D,$ISW,$S,$EPS,$YS,$YSP,$SIGMA,$TEMP,my $IERR);
#
#  Call CURVP2 and calculate the interpolated values.
#
for my $I ( 1 .. $IOUT ) {
  set( $YOSP, $I-1, &NCAR::curvp2( at( $XO, $I-1 ), $IDIM,$X,$YS,$P,$YSP,$SIGMA) );
}
#
#  Plot the results.
#
&DRWFT3($XL,$XR,$IDIM,$X,$Y,$IOUT,$XO,my $YO,$YOS,$YOSP);
#
sub DRWFT3 {
  my ($XL,$XR,$II,$X,$Y,$IO,$XO,$YO,$YOS,$YOSP) = @_;
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
  my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
  my $YPOS_TOP = 0.95;
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
  &NCAR::gsclip(1);
#
#  Graph the interpolated function values and mark the original
#  input data points.
#
  my $YB = -2.0;
  my $YT =  4.0;
  &BKGFT3($XL,$XR,$YPOS_TOP,'CURVS',0.42,$YB,$YT);
  &NCAR::gridal(6,5,3,1,1,1,10,$XL,$YB);
#
#  Mark the original data points.
#
  &NCAR::gsmksc(2.);
  &NCAR::gspmci(4);
  &NCAR::gpm($II,$X,$Y);
#
#  Graph the interpolated function values.
#
  &NCAR::gpl($IO,$XO,$YOS);
#
#  Graph the periodic function.
#
  &BKGFT3($XL,$XR,$YPOS_TOP-0.5,'CURVPS',0.42,$YB,$YT);
  &NCAR::gridal(6,5,3,1,1,1,10,$XL,$YB);
  &NCAR::gpl($IO,$XO,$YOSP);
  &NCAR::gsplci(1);
#
#  Mark the original data points.
#
  &NCAR::gsmksc(2.);
  &NCAR::gspmci(4);
  &NCAR::gpm($II,$X,$Y);
#
  &NCAR::frame();
#
  &NCAR::gdawk($IWKID);
  &NCAR::gclwk($IWKID);
  &NCAR::gclks();
#
}

sub BKGFT3 {
  my ($XL,$XR,$YPOS,$LABEL,$XLP,$YB,$YT) = @_;
#
  &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
  &NCAR::pcseti('FN',21);
  &NCAR::plchhq($XLP,$YPOS - 0.03,$LABEL,0.025,0.,-1.);
  &NCAR::set(0.13,0.93,$YPOS-0.35,$YPOS,$XL,$XR,$YB,$YT,1);
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

rename 'gmeta', 'ncgm/ftex03.ncgm';

