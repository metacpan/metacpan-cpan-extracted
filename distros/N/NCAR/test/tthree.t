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
use NCAR::Test;
use strict;
   
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# OPEN GKS, OPEN WORKSTATION OF TYPE 1, ACTIVATE WORKSTATION
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# PURPOSE                To provide a simple demonstration of THREED.
#
# USAGE                  CALL TTHREE (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test was successful,
#                          = 1, the test was not successful.
#
# I/O                    If the test is successful, the message
#
#               THREED TEST EXECUTED--SEE PLOT TO CERTIFY
#
#                        is printed on unit 6.  In addition, 1
#                        frame is produced on the machine graphics
#                        device.  In order to determine if the test
#                        was successful, it is necessary to examine
#                        the plot.
#
# PRECISION              Single
#
# LANGUAGE               FORTRAN 77
#
# REQUIRED ROUTINES      THREED
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              Routine TTHREE calls SET3 to establish a
#                        mapping between the plotter addresses and
#                        the user's volume, and to indicate the
#                        coordinates of the eye position from which
#                        the lines to be drawn are viewed.  Next,
#                        the volume perimeters and associated tick
#                        marks are drawn by calls to PERIM3.  The
#                        selected latitude and longitude lines of
#                        a sphere are then drawn.
#
# HISTORY                THREED was originally written in November
#                        1976 and converted to FORTRAN 77 and GKS
#                        in July 1984.
#
my $X = zeroes float, 31;
my $Y = zeroes float, 31;
my $Z = zeroes float, 31;
#
# Specify the arguments to be used by routine SET3 on a plot
# grid in the address range of 0. to 1.  In each coordinate direction,
# the values  RXA, RXB, RYA, and RYB define the portion of the address
# space to be used in making the plot.  UC, UD, VC, VD, WC, and WD
# define a volume in user coordinates which is to be mapped onto the
# portion of the viewing surface as specified by RXA, RXB, RYA, and RYB.
#
my ( $RXA, $RXB, $RYA, $RYB ) = ( 0.097656, 0.90236, 0.097656, 0.90236 );
my ( $UC, $UD, $VC, $VD, $WC, $WD ) = ( -1, 1, -1, 1, -1, 1 );
my $EYE = float [ 10.,6.,3. ];
my ( $TX, $TY ) = ( 0.4374, 0.9570 );
my $PI = 3.1415926535898;
#
# Select normalization transformation 0.
#
&NCAR::gselnt (0);
#
# Call SET3 to establish a mapping between the plotter addresses
# and the user's volume, and to indicate the coordinates of the
# eye position from which the lines to be drawn are viewed.
#
&NCAR::set3($RXA,$RXB,$RYA,$RYB,$UC,$UD,$VC,$VD,$WC,$WD,$EYE);
#
# Call PERIM3 to draw perimeter lines and tick marks.
#
&NCAR::perim3(2,5,1,10,1,-1.);
&NCAR::perim3(4,2,1,1,2,-1.);
&NCAR::perim3(2,10,4,5,3,-1.);
#
# Define and draw latitudinal lines on the sphere of radius one
# having its center at (0.,0.,0.)
#
for my $J ( 1 .. 18 ) {
  my $THETA = ($J)*$PI/9.;
  my $CT = cos($THETA);
  my $ST = sin($THETA);
  for my $K ( 1 .. 31 ) {
    my $PHI = ($K-16)*$PI/30.;
    set( $Z, $K-1, sin( $PHI ) );
    my $CP = cos( $PHI );
    set( $X, $K-1, $CT*$CP );
    set( $Y, $K-1, $ST*$CP );
  }
  &NCAR::curve3($X,$Y,$Z,31);
}
#
# Define and draw longitudinal lines on the sphere of radius one
# having its center at (0.,0.,0.)
#
for my $K ( 1 .. 5 ) {
  my $PHI = ($K-3)*$PI/6.;
  my $SP = sin($PHI);
  my $CP = cos($PHI);
  for my $J ( 1 .. 31 ) {
    my $TUETA = ($J-1)*$PI/15.;
    set( $X, $J-1, cos($TUETA)*$CP );
    set( $Y, $J-1, sin($TUETA)*$CP );
    set( $Z, $J-1, $SP );
  }
  &NCAR::curve3($X,$Y,$Z,31);
}
#
# Add a plot title.
#
&NCAR::plchlq($TX,$TY,'DEMONSTRATION PLOT FOR ROUTINE THREED',16.,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();
#
print STDERR "\n THREED TEST EXECUTED--SEE PLOT TO CERTIFY\n";

#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
 
   
rename 'gmeta', 'ncgm/tthree.ncgm';
