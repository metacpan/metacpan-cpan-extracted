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
#       $Id: csex04.f,v 1.3 1999/02/09 20:19:18 fred Exp $
#
#
#  Do a 2D approximation and find mixed second order partial derivatives.
#
#
#  The dimensionality of the problem.
#
my $NDIM = 2;
#
#  The number of input data points.
#
my $NDATA = 1000;
#
#  The number of output data points in the X coordinate direction.
#
my $NX = 29;
#
#  The number of output data points in the Y coordinate direction.
#
my $NY = 25;
#
#  Specifty the number of knots in the X direction.
#
my $N1 = 4;
#
#  Specifty the number of knots in the Y direction.
#
my $N2 = 4;
#
#  The size of the workspace.
#
my $NCF = $N1*$N2;
my $NWRK = $NCF*($NCF+3);
#
#  Define error file, Fortran unit number, workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Dimension the arrays.
#
my $XDATA = zeroes float, $NDIM, $NDATA;
my $YDATA = zeroes float, $NDATA;
my $KNOTS = zeroes long, $NDIM;
my $WORK = zeroes float, $NWRK;
my $NDERIV = long [ 0, 0 ];
my ( $XMIN, $YMIN, $XMAX, $YMAX ) = ( -1.0, -1.0, 1.0, 1.0 );
my $XO = zeroes float, $NX;
my $YO = zeroes float, $NY;
my $FUNC = zeroes float, $NX, $NY;
my $FUNCD = zeroes float, $NX, $NY;
#
#  Generate input data using the functiuon f(x,y) = y**2 - 0.5*y*x**2
#
my $INDX = $NDATA;
for my $I ( 1 .. $INDX ) {
  set( $XDATA, 0, $I-1, $XMIN+($XMAX-$XMIN)*&DSRND1() );
  set( $XDATA, 1, $I-1, $YMIN+($YMAX-$YMIN)*&DSRND1() );
  my $XX = at( $XDATA, 0, $I-1 );
  my $YY = at( $XDATA, 1, $I-1 );
  set( $YDATA, $I-1, $YY*$YY - 0.5*$YY*$XX*$XX );
}
#
#  Create the output grid.
#
for my $I ( 1 .. $NX ) {
  set( $XO, $I-1, $XMIN+(($I-1)/($NX-1))*($XMAX-$XMIN) );
}
for my $J ( 1 .. $NY ) {
  set( $YO, $J-1, $YMIN+(($J-1)/($NY-1))*($YMAX-$YMIN) );
}
#
#  Specify the numbers of knots in each coordinate direction.
#
set( $KNOTS, 0, $N1 );
set( $KNOTS, 1, $N2 );
#
#  Calculate the approximated functuion values.
#
&NCAR::csa2s ($INDX,$XDATA,$YDATA,$KNOTS,$NX,$NY,$XO,$YO,$FUNC,$NWRK,$WORK,my $IER);
#
#  Calculate the second order mixed partial derivative.
#
set( $NDERIV, 0, 1 );
set( $NDERIV, 1, 1 );
my $WTS = float [ ( -1 ) x $INDX ];
&NCAR::csa2xs ($INDX,$XDATA,$YDATA,$WTS,$KNOTS,0.,$NDERIV,$NX,$NY,$XO,$YO,$FUNCD,$NWRK,$WORK,$IER);
#
#  Plot a surface.
#
#  Open GKS and define the foreground and background color.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Approximated function.
#
&NCAR::tdez2d($NX, $NY, $XO, $YO, $FUNC, 2.7, 45., 78., 6);
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.5,0.85,':F25:z = f(x,y) = y:S:2:E:  - -:H-10::S:1:E::B::V-6:2:E:  y:V-6:*:V+6:x:S:2:E:',0.04,0.,0.);
&NCAR::frame();
#
#  Mixed partial.
#
&NCAR::tdez2d($NX, $NY, $XO, $YO, $FUNCD, 2.7, 45., 78., 6);
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.5,0.88,':F25:z =  :F34::S::H8:6:F25::S:2:E::E::F34:>:B::F34::H-35::V-6:6:F25:x:F34:6:F25:y:E:  f(x,y) = - x',0.04,0.,0.);
&NCAR::frame();
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
sub DSRND1 {
  return rand();
}


rename 'gmeta', 'ncgm/csex04.ncgm';
