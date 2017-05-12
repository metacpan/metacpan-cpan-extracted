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
my ( $NUM, $NX, $NY, $NZ ) = ( 1000, 21, 21, 21 );
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
my $XI = zeroes float, $NUM;
my $YI = zeroes float, $NUM;
my $ZI = zeroes float, $NUM;
my $U = zeroes float, $NUM;

my $XO = zeroes float, $NX;
my $YO = zeroes float, $NY;
my $ZO = zeroes float, $NZ;
my $OUTPUT = zeroes float, $NX, $NY , $NZ;
my ( $XMIN,$YMIN,$ZMIN,$XMAX,$YMAX,$ZMAX ) = ( -2., -2., -2., 2., 2., 2. );
#
for my $I ( 1 .. $NUM ) {
  my $X = $XMIN+($XMAX-$XMIN)*&DSRND1();
  my $Y = $YMIN+($YMAX-$YMIN)*&DSRND1();
  my $Z = $ZMIN+($ZMAX-$ZMIN)*&DSRND1();
  set( $XI, $I-1, $X );
  set( $YI, $I-1, $Y );
  set( $ZI, $I-1, $Z );
  set( $U, $I-1, $X*$X + $Y*$Y + $Z*$Z );
}
#
#  Create the output grid.
#
for my $I ( 1 .. $NX ) {
  set( $XO, $I-1, $XMIN+(($I-1)/($NX-1))*($XMAX-$XMIN) );
}
#
for my $J ( 1 .. $NY ) {
  set( $YO, $J-1, $YMIN+(($J-1)/($NY-1))*($YMAX-$YMIN) );
}
#
for my $K ( 1 .. $NZ ) {
  set( $ZO, $K-1, $ZMIN+(($K-1)/($NZ-1))*($ZMAX-$ZMIN) );
}
#
#  Interpolate.
#
&NCAR::dsgrid3s($NUM,$XI,$YI,$ZI,$U,$NX,$NY,$NZ,$XO,$YO,$ZO,$OUTPUT,my $IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %s returned from DSGRID3S\n", $IER );
  exit( 0 );
}
#
#  Plot an isosurface.
#
#
# Open GKS and define the foreground and background color.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
&NCAR::tdez3d($NX, $NY, $NZ, $XO, $YO, $ZO, $OUTPUT, 3.0, 2., -35., 65., 6);
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

rename 'gmeta', 'ncgm/dsex01.ncgm';
