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
my ( $NUM, $NX, $NY ) = ( 5000, 21, 21 );
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
my $XI = zeroes float, $NUM;
my $YI = zeroes float, $NUM;
my $ZI = zeroes float, $NUM;
my $XO = zeroes float, $NX;
my $YO = zeroes float, $NY;
my $OUTPUT = zeroes float, $NX, $NY;
my ( $XMININ, $YMININ, $XMAXIN, $YMAXIN ) = (  0.00,  0.00, 1.00, 1.00 );
my ( $XMINOT, $YMINOT, $XMAXOT, $YMAXOT ) = ( -0.21, -0.21, 1.21, 1.21 );
my ( $RHO, $THETA, $PHI ) = ( 3., -70., 40. );
#
#  Create random data in two-space and define a function.
#  To get this to work on your system, you may have to insert
#  the correct random number generator for your compiler.
#
for my $I ( 1 .. $NUM ) {
  my $X = $XMININ+($XMAXIN-$XMININ)*&DSRND5();
  my $Y = $YMININ+($YMAXIN-$YMININ)*&DSRND5();
  set( $XI, $I-1, $X );
  set( $YI, $I-1, $Y );
  set( $ZI, $I-1, ($X-0.25)**2 + ($Y-0.50)**2 );
}
#
#  Create the output grid.
#
for my $I ( 1 .. $NX ) {
  set( $XO, $I-1, $XMINOT+(($I-1)/($NX-1))*($XMAXOT-$XMINOT) );
}
for my $J ( 1 .. $NY ) {
  set( $YO, $J-1, $YMINOT+(($J-1)/($NY-1))*($YMAXOT-$YMINOT) );
}
#
#  Interpolate.
#
&NCAR::dsgrid2s($NUM, $XI, $YI, $ZI, $NX, $NY, $XO, $YO, $OUTPUT, my $IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %3d returned from DSGRID2S\n", $IER );
  exit( 0 );
}
#
#  Plot a surface.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::tdez2d($NX, $NY, $XO, $YO, $OUTPUT, $RHO, $THETA, $PHI, 6);
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
sub DSRND5 {
  return rand();
}

rename 'gmeta', 'ncgm/dsex05.ncgm';
