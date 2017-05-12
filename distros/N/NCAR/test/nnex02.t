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
#  Simple example of natural neighbor linear regridding.
#
my ( $ISLIM, $NUMXOUT, $NUMYOUT ) = ( 6, 21, 21 );
#
#  Dimension for the work space for the NCAR Graphics call to
#  SRFACE to plot the interpolated grid.
#

my $IDIM = 2*$NUMXOUT*$NUMYOUT;
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Output grid arrays.
#
my $XI = zeroes float, $NUMXOUT;
my $YI = zeroes float, $NUMYOUT;
my $ZI = zeroes float, $NUMXOUT, $NUMYOUT;
#
#  Define the input data arrays.
#
my $X = float [ 0.00, 1.00, 0.00, 1.00, 0.40, 0.75 ];
my $Y = float [ 0.00, 0.00, 1.00, 1.00, 0.20, 0.65 ];
my $Z = float [ 0.00, 0.00, 0.00, 0.00, 1.25, 0.80 ];
#
my $IWORK = zeroes long, $IDIM;
#
#  Define the output grid.
#
my $XMIN = 0.;
my $XMAX = 1.;
my $XINC = ($XMAX-$XMIN)/($NUMXOUT-1.) ;
for my $I ( 1 .. $NUMXOUT ) {
  set( $XI, $I-1, $XMIN + ( $I-1 ) * $XINC );
}
#
my $YMAX =  1.;
my $YMIN =  0.;
my $YINC = ($YMAX-$YMIN)/($NUMYOUT-1.);
for my $J ( 1 .. $NUMYOUT ) {
  set( $YI, $J-1, $YMIN + ( $J-1 ) * $YINC );
}
#
#  Set the flag for using estimated gradients.
#
&NCAR::nnseti('IGR',1);
#
#  Do the regridding.
#
&NCAR::natgrids($ISLIM,$X,$Y,$Z,$NUMXOUT,$NUMYOUT,$XI,$YI,$ZI,my $IER);
if( $IER != 0 ) {
  printf( STDERR "Error return from NATGRIDS = %3d\n", $IER );
}
#
#  Draw a plot of the interpolated surface.
#
#
# Open GKS and define the foreground and background color.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
&NCAR::gscr($IWKID, 0, 1.00, 1.00, 1.00);
&NCAR::gscr($IWKID, 1, 0.00, 0.00, 0.00);
#
&DRWSRF($NUMXOUT,$NUMYOUT,$XI,$YI,$ZI,15.,-25.,90.,$IWORK);
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
# 

sub DRWSRF {
  my ($NX,$NY,$X,$Y,$Z,$S1,$S2,$S3,$IWK) = @_;
#
#  Procedure DRWSRF uses the NCAR Graphics function SRFACE to
#  draw a surface plot of the data values in Z.
# 
#  The point of observation is calculated from the 3D coordinate
#  (S1, S2, S3); the point looked at is the center of the surface.
# 
#   NX     -  Dimension of the X-axis variable X.
#   NY     -  Dimension of the Y-axis variable Y.
#   X      -  An array of X-axis values.
#   Y      -  An array of Y-axis values.
#   Z      -  An array dimensioned for NX x NY containing data
#             values for each (X,Y) coordinate.
#   S1     -  X value for the eye position.
#   S2     -  Y value for the eye position.
#   S3     -  Z value for the eye position.
#   IWK    -  Work space dimensioned for at least 2*NX*NY.
# 
#  
#
  my ( $IERRF, $LUNIT, $IWKID, $IWTYPE ) = ( 6, 2, 1, 8 );
#
#  Open GKS, open and activate a workstation.
#
  my $JTYPE = $IWTYPE;
  &NCAR::gqops(my $ISTATE);
  if( $ISTATE ==  0 ) {
    &NCAR::gopks ($IERRF, my $ISZDM);
    if( $JTYPE == 1 ) {
      &NCAR::ngsetc('ME','srf.ncgm');
    } elsif( ( $JTYPE >= 20 ) && ( $JTYPE <= 31 ) ) {
      &NCAR::ngsetc('ME','srf.ps');
    }
    &NCAR::gopwk ($IWKID, $LUNIT, $JTYPE);
    &NCAR::gscr($IWKID,0,1.,1.,1.);
    &NCAR::gscr($IWKID,1,0.,0.,0.);
    &NCAR::gacwk ($IWKID);
  }
#
#  Find the extreme values.
#
  my $XMN = at( $X, 0 );
  my $XMX = at( $X, 0 );
  my $YMN = at( $Y, 0 );
  my $YMX = at( $Y, 0 );
  my $ZMN = at( $Z, 0, 0 );
  my $ZMX = at( $Z, 0, 0 );
#
  for my $I ( 2 .. $NX ) {
    $XMN = &NCAR::Test::min($XMN,at( $X, $I-1 ));
    $XMX = &NCAR::Test::max($XMX,at( $X, $I-1 ));
  }
#
  for my $I ( 1 .. $NY ) {
    $YMN = &NCAR::Test::min($YMN,at( $Y, $I-1 ));
    $YMX = &NCAR::Test::max($YMX,at( $Y, $I-1 ));
  }
#
  for my $I ( 1 .. $NX ) {
    for my $J ( 1 .. $NY ) {
      $ZMN = &NCAR::Test::min($ZMN, at( $Z, $I-1, $J-1));
      $ZMX = &NCAR::Test::max($ZMX, at( $Z, $I-1, $J-1));
    }
  }
#
  my ( $ST1, $ST2, $ST3 );
  if( ( $S1 == 0 ) && ( $S2 == 0 ) && ( $S3 == 0 ) ) {
    $ST1 = -3.;
    $ST2 = -1.5;
    $ST3 = 0.75;
  } else {
    $ST1 = $S1;
    $ST2 = $S2;
    $ST3 = $S3;
  }
  my $S = float [
            5.*$ST1*($XMX-$XMN), 5.*$ST2*($YMX-$YMN), 5.*$ST3*($ZMX-$ZMN), 
            0.5*($XMX-$XMN),     0.5*($YMX-$YMN),     0.5*($ZMX-$ZMN) 
  ];
#
  &NCAR::srface ($X,$Y,$Z,$IWK,$NX,$NX,$NY,$S,0.);
#
#  Close down GKS.
#
  if( $ISTATE == 0 ) {
    &NCAR::gdawk ($IWKID);
    &NCAR::gclwk ($IWKID);
    &NCAR::gclks();
  }
#
}


rename 'gmeta', 'ncgm/nnex02.ncgm';

