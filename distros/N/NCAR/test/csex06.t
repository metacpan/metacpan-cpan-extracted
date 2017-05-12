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
#       $Id: csex06.f,v 1.3 1999/02/09 20:19:19 fred Exp $
#
#
#  Do a 3D approximation and plot an isosurface.
#
#
#  The dimensionality of the problem.
#
my $NDIM = 3;
#
#  The number of input data points.
#
my $NDATA = 1000;
#
#  The number of output data points in the X coordinate direction.
#
my $NX = 21;
#
#  The number of output data points in the Y coordinate direction.
#
my $NY = 31;
#
#  The number of output data points in the Z coordinate direction.
#
my $NZ = 41;
#
#  Specifty the number of knots in the X direction.
#
my $N1 = 4;
#
#  Specifty the number of knots in the Y direction.
#
my $N2 = 4;
#
#  Specifty the number of knots in the Z direction.
#
my $N3 = 4;
#
#  The size of the workspace.
#
my $NCF = $N1*$N2*$N3;
my $NWRK = $NCF*($NCF+3);
#
#  Dimension the arrays.
#
my $XDATA = zeroes float, $NDIM, $NDATA;
my $YDATA = zeroes float, $NDATA;
my $KNOTS = zeroes long, $NDIM;
my $WORK = zeroes float, $NWRK;
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID (these values are used by GKS).
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Define arrays for use in plotting the isosurface.
#
my $XO = zeroes float, $NX;
my $YO = zeroes float, $NY;
my $ZO = zeroes float, $NZ;
my $OUTPUT = zeroes float, $NX, $NY, $NZ;
my ( $XMIN, $YMIN, $ZMIN, $XMAX, $YMAX, $ZMAX ) = ( -2., -2., -2., 2.,  2., 2. );
#
#  Define the input data on random coordinates bounded by the
#  above values.
#
for my $I ( 1 .. $NDATA ) {
  set( $XDATA, 0, $I-1, $XMIN+($XMAX-$XMIN)*&DSRND1() );
  set( $XDATA, 1, $I-1, $XMIN+($XMAX-$XMIN)*&DSRND1() );
  set( $XDATA, 2, $I-1, $XMIN+($XMAX-$XMIN)*&DSRND1() );
  set( $YDATA, $I-1, 0.75*at( $XDATA, 0, $I-1 )**2 -
                     1.6 *at( $XDATA, 1, $I-1 )**2 +
                     2.0 *at( $XDATA, 2, $I-1 )**2 );
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
for my $K ( 1 .. $NZ ) {
  set( $ZO, $K-1, $ZMIN+(($K-1)/($NZ-1))*($ZMAX-$ZMIN) );
}
#
#  Specify the numbers of nodes in each coordinate.
#
set( $KNOTS, 0, $N1 );
set( $KNOTS, 1, $N2 );
set( $KNOTS, 2, $N3 );
#
#  Calculate the approximating function.
#
&NCAR::csa3s ($NDATA,$XDATA,$YDATA,$KNOTS,$NX,$NY,$NZ,$XO,$YO,$ZO,$OUTPUT,$NWRK,$WORK,my $IER);
#
#  Plot an isosurface.
#
# Open GKS and define the foreground and background color.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::tdez3d($NX, $NY, $NZ, $XO, $YO, $ZO, $OUTPUT, .7,2.3, -13., 75., 6);
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

rename 'gmeta', 'ncgm/csex06.ncgm';
