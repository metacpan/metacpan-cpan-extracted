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
#       $Id: csex07.f,v 1.3 1999/02/09 20:19:19 fred Exp $
#
#
#  Do a 2D approximation using a list of output coordinates.  
#
#
#  The dimensionality of the problem.
#
my $NDIM = 2;
#
#  The number of input data points.
#
my $NDATA = 500;
#
#  The number of output data points in the X coordinate direction.
#
my $NX = 29;
#
#  The number of output data points in the Y coordinate direction.
#
my $NY = 25;
#
#  The number of output data points.
#
my $NO = $NX*$NY;
#
#  Specifty the number of knots in the X direction.
#
my $N1 = 10;
#
#  Specifty the number of knots in the Y direction.
#
my $N2 = 10;
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
my $NODES = zeroes long, $NDIM;
my $WORK = zeroes float, $NWRK;
my ( $XMIN, $YMIN, $XMAX, $YMAX ) = ( -1.4, -1.2, 1.4, 1.2 );
my $XO = zeroes float, $NO;
my $YO = zeroes float, $NO;
my $OUTPUT = zeroes float, $NO;
my $XP = zeroes float, $NX;
my $YP = zeroes float, $NY;
my $OPLOT = zeroes float, $NX, $NY;
#
#  Create the data array for the surface.
#
for my $I ( 1 .. $NDATA ) {
  set( $XDATA, 0, $I-1, $XMIN+($XMAX-$XMIN)*&DSRND1() );
  set( $XDATA, 1, $I-1, $YMIN+($YMAX-$YMIN)*&DSRND1() );
  set( $YDATA, $I-1, at( $XDATA, 0, $I-1 ) + at( $XDATA, 1, $I-1 ) );
  my $T1 = 1.0/((abs(at( $XDATA, 0, $I-1 )-0.1))**2.75 +abs(at( $XDATA, 1, $I-1 ))**2.75+0.09);
  my $T2 = 1.0/((abs(at( $XDATA, 0, $I-1 )+0.1))**2.75 +abs(at( $XDATA, 1, $I-1 ))**2.75+0.09);
  set( $YDATA, $I-1, 0.3*( at( $YDATA, $I-1 ) + $T1 - $T2 ) );
}
#
#  Create the output arrays.
#
my $INDX = 0;
for my $J ( 1 .. $NY ) {
  for my $I ( 1 .. $NX ) {
    $INDX = $INDX+1;
    set( $XO, $INDX-1, $XMIN+(($I-1)/($NX-1))*($XMAX-$XMIN) );
    set( $YO, $INDX-1, $YMIN+(($J-1)/($NY-1))*($YMAX-$YMIN) );
  }
}
#
#  Specify the numbers of nodes in each coordinate.
#
set( $NODES, 0, $N1 );
set( $NODES, 1, $N2 );
#
&NCAR::csa2ls ($NDATA,$XDATA,$YDATA,$NODES,$NO,$XO,$YO,$OUTPUT,$NWRK,$WORK,my $IER);
#
#  Plot the 2D surface approximation.
#
# Open GKS and define the foreground and background color.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Convert the linear output array to a 2D array.
#
for my $I ( 1 .. $NX ) {
  for my $J ( 1 .. $NY ) {
    set( $OPLOT, $I-1, $J-1, at( $OUTPUT, ($J-1)*$NX + $I-1 ) );
  }
}
#
#  Create the output grid for plotting.
#
for my $I ( 1 .. $NX ) {
  set( $XP, $I-1, $XMIN+(($I-1)/($NX-1))*($XMAX-$XMIN) );
}
for my $J ( 1 .. $NY ) {
  set( $YP, $J-1, $YMIN+(($J-1)/($NY-1))*($YMAX-$YMIN) );
}
#
#  Plot the surface.
#
&NCAR::tdez2d($NX, $NY, $XP, $YP, $OPLOT, 2.5, -154., 80., 6);
&NCAR::frame();
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
sub DSRND1() {
  return rand();
}

rename 'gmeta', 'ncgm/csex07.ncgm';
