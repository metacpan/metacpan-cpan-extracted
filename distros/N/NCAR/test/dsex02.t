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
my ( $NUM, $NX, $NY ) = ( 6, 61, 61 );
my $IWDIM = 2*$NX*$NY;
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
my $ZI = zeroes float, $NUM;
my $XO = zeroes float, $NX;
my $YO = zeroes float, $NY;
my $OUTPUT = zeroes float, $NY, $NY;
#
#  Input data points and values.
#
my $XI = float [ 0.00, 1.00, 0.00, 1.00, 0.40, 0.75 ];
my $YI = float [ 0.00, 0.00, 1.00, 1.00, 0.20, 0.65 ];
my $ZI = float [ 0.00, 0.00, 0.00, 0.00, 1.25, 0.80 ];
my ( $RHO, $THETA, $PHI ) = ( 3.0, -45., 55. );
#
#  Specify the output grid.
#
my $XINC = 1./ ($NX-1);
my $YINC = 1./ ($NY-1);
for my $I ( 1 .. $NX ) {
  set( $XO, $I-1, ($I-1)*$XINC );
  for my $J ( 1 .. $NY ) {
    set( $YO, $J-1, ($J-1)*$YINC );
  }
}
#
#  Exponent equals 0.5
#
&NCAR::dssetr('EXP',0.5);
&NCAR::dsgrid2s($NUM, $XI, $YI, $ZI, $NX, $NY, $XO, $YO, $OUTPUT, my $IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %3d returned from DSGRID2S\n", $IER );
  exit( 0 );
}
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::tdez2d($NX, $NY, $XO, $YO, $OUTPUT, $RHO, $THETA, $PHI, 6);
&NCAR::frame();
#
#  Exponent equals 1.0
#
&NCAR::dssetr('EXP',1.0);
&NCAR::dsgrid2s($NUM, $XI, $YI, $ZI, $NX, $NY, $XO, $YO, $OUTPUT, $IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %3d returned from DSGRID2S\n", $IER );
  exit( 0 );
}
&NCAR::tdez2d($NX, $NY, $XO, $YO, $OUTPUT, $RHO, $THETA, $PHI, 6);
&NCAR::frame();
#
#  Exponent equals 10.0
#
&NCAR::dssetr('EXP',5.0);
&NCAR::dsgrid2s($NUM, $XI, $YI, $ZI, $NX, $NY, $XO, $YO, $OUTPUT, $IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %3d returned from DSGRID2S\n", $IER );
  exit( 0 );
}
#
&NCAR::tdez2d($NX, $NY, $XO, $YO, $OUTPUT, $RHO, $THETA, $PHI, 6);
&NCAR::frame();
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#


rename 'gmeta', 'ncgm/dsex02.ncgm';
