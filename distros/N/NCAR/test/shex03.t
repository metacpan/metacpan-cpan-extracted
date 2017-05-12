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
#  $Id: shex03.f,v 1.1 1999/08/21 20:20:08 fred Exp $
#
#
#  Create a tube-shaped isosurface.
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
#  The size of the workspace.
#
my ( $NIWK, $NRWK ) = ( 2*$NDATA, 11*$NDATA+6 );
#
#  Dimension the arrays.
#
my $X = zeroes float, $NDATA;
my $Y = zeroes float, $NDATA;
my $Z = zeroes float, $NDATA;
my $F = zeroes float, $NDATA;
my $IWK = zeroes long, $NIWK;
my $RWK = zeroes float, $NRWK;
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
  set( $X, $I-1, my $x = $XMIN+($XMAX-$XMIN)*&DSRND1() );
  set( $Y, $I-1, my $y = $YMIN+($YMAX-$YMIN)*&DSRND1() );
  set( $Z, $I-1, my $z = $ZMIN+($ZMAX-$ZMIN)*&DSRND1() );
  set( $F, $I-1, 0.75*$x**2 - 1.6*$y**2 + 2.0*$z**2. );
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
#  Find the approximating function values on the output grid.
#
&NCAR::shgrid($NDATA,$X,$Y,$Z,$F,$NX,$NY,$NZ,$XO,$YO,$ZO,$OUTPUT,$IWK,$RWK,my $IER);
#
#  Plot an isosurface.
#
#  Open GKS and define the foreground and background color.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
&NCAR::tdez3d($NX, $NY, $NZ, $XO, $YO, $ZO,$OUTPUT, 0.7, 2.3, -13., 75., 6);
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

rename 'gmeta', 'ncgm/shex03.ncgm';
