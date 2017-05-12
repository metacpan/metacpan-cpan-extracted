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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# PURPOSE                To provide a simple demonstration of
#                        entry PWRZS with the SRFACE utility.
#
# USAGE                  CALL TPWRZS (IWKID,IERROR)
#
# ARGUMENTS
#
# ON INPUT               IWKID
#                          A workstation id number
#
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test was successful,
#                          = 1, otherwise
#
# I/O                    If the test is successful, the message
#
#               PWRZS TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is printed on unit 6.  In addition, 1
#                        frame is produced on the machine graphics
#                        device.  In order to determine if the test
#                        was successful, it is necessary to examine
#                        the plot.
#
# PRECISION              Single
#
# REQUIRED ROUTINES      PWRZS, SRFACE
#
# REQUIRED GKS LEVEL     0A
#
# LANGUAGE               FORTRAN 77
#
# ALGORITHM              A function of 2 variables is defined and the
#                        values of the function on a 2-D rectangular
#                        grid are stored in an array.  This routine
#                        calls SRFACE to draw a surface representation
#                        of the array values.  PWRZS is then called 3
#                        times to label the front, side, and back of
#                        the picture.
#
my $Z = zeroes float, 20, 30;
my $X = zeroes float, 20;
my $Y = zeroes float, 30;
my $MM = zeroes long, 20, 30, 2;
#
# Load the SRFACE common block needed to supress a NEWFM call.
#
#     COMMON /SRFIP1/ IFR        ,ISTP       ,IROTS      ,IDRX       ,;
#    1                IDRY       ,IDRZ       ,IUPPER     ,ISKIRT     ,;
#    2                NCLA       ,THETA      ,HSKIRT     ,CHI        ,;
#    3                CLO        ,CINC       ,ISPVAL;
#
# Define the center of a plot title string on a square grid of size
# 0. to 1.
#
use NCAR::COMMON qw( %SRFIP1 );

my ( $TX, $TY ) = ( 0.4375, 0.9667 );
#
# Specify grid loop indices and a line of sight.
#
my ( $M, $N ) = ( 20, 30 );
my $S = float [ 4.,5.,3.,0.,0.,0. ];
#
# Initial the error parameter.
#
my $IERROR = 1;
#
# Set up a color table
#
# White background
#
&NCAR::gscr (1,0,1.,1.,1.);
#
# Black foreground
#
&NCAR::gscr (1,1,0.,0.,0.);
#
# Red
#
&NCAR::gscr (1,2,1.,0.,0.);
#
# Green
#
&NCAR::gscr (1,3,0.,1.,0.);
#
# Blue
#
&NCAR::gscr (1,4,0.,0.,1.);
#
# Define the function values and store them in the Z array.
#
for my $I ( 1 .. $M ) {
  set( $X, $I-1, -1 + ( $I - 1 ) / ( $M - 1 ) * 2 );
}
for my $J ( 1 .. $N ) {
  set( $Y, $J-1, -1 + ( $J - 1 ) / ( $N - 1 ) * 2 );
}
for my $J ( 1 .. $N ) {
  for my $I ( 1 .. $M ) {
    my $x = at( $X, $I-1 );
    my $y = at( $Y, $J-1 );
    set( $Z, $I-1, $J-1, exp( -2 * sqrt( $x*$x+$y*$y ) ) );
  }
}
#
# Set SRFACE parameters to supress the FRAME call and draw contours.
#
$SRFIP1{IFR} = 0;
$SRFIP1{IDRZ} = 1;
#
# Select normalization trans number 0.
#
&NCAR::gselnt (0);
#
# Label the plot.
#
&NCAR::plchlq ($TX,$TY,'DEMONSTRATION PLOT FOR PWRZS',16.,0.,0.);
#
# Draw the surface plot.
#
&NCAR::srface ($X,$Y,$Z,$MM,$M,$M,$N,$S,0.);
#
# Put the PWRZS labels on the picture.
#
#     Set the label color
&NCAR::gsplci(2);
my $ISIZE = 35;
&NCAR::pwrzs (0.,1.1,0.,'FRONT',5,$ISIZE,-1,3,0);
&NCAR::pwrzs (1.1,0.,0.,'SIDE',4,$ISIZE,2,-1,0);
&NCAR::pwrzs (0.,-1.1,.2,' BACK BACK BACK BACK BACK',25,$ISIZE,-1, 3,0);
#
$IERROR = 0;
print STDERR "\n PWRZS TEST EXECUTED--SEE PLOT TO CERTIFY\n";
#
# Restore the SRFACE parameters to their default values.
#
$SRFIP1{IFR} = 1;
$SRFIP1{IDRZ} = 0;
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fsrpwrzs.ncgm';
