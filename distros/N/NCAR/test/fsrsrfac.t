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
# PURPOSE                To provide a simple demonstration of SRFACE.
#
# USAGE                  CALL TSRFAC (IWKID,IERROR)
#
# ARGUMENTS
#
# ON INPUT               IWKID
#                          A workstation id number
#
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test was successful,
#                          = 1, the test was not successful.
#
# I/O                    If the test is successful, the message
#
#               SRFACE TEST EXECUTED--SEE PLOT TO CERTIFY
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
# REQUIRED ROUTINES      SRFACE
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              The function
#
#                          Z(X,Y) = .25*(X + Y + 1./((X-.1)**2+Y**2+.09)
#                                   -1./((X+.1)**2+Y**2+.09)
#
#                        for X = -1. to +1. in increments of .1, and
#                            Y = -1.2 to +1.2 in increments of .1,
#                        is computed.  Then, entry SURFACE
#                        is called to a generate surface plot of Z.
#
# HISTORY                SURFACE was first written in April 1979 and
#                        converted to FORTRAN 77 and GKS in March 1984.
#
# XX contains the X-direction coordinate values for Z(X,Y);  YY contains
# the Y-direction coordinate values for Z(X,Y);  Z contains the function
# values;  S contains values for the line of sight for entry SRFACE;
# WORK is a work array;  ANGH contains the angle in degrees in the X-Y
# plane to the line of sight;  and ANGV contains the angle in degrees
# from the X-Y plane to the line of sight.
#
my $XX = zeroes float, 21;
my $YY = zeroes float, 25;
my $Z  = zeroes float, 21, 25;
my $WORK = zeroes long, 1096;
#
my $S = float [ -8.0, -6.0,  3.0,  0.0,  0.0,  0.0 ];
#
my ( $ANGH, $ANGV ) = ( 45., 15. );
#
# Specify coordinates for plot titles.  The values CX and CY
# define the center of the title string in a 0. to 1. range.
#
my ( $CX, $CY ) = ( .5, .9 );
#
# Set up a the background and foreground colors
#
#     White background
#
&NCAR::gscr (1,0,1.,1.,1.);
#
#     Blue foreground
#
&NCAR::gscr (1,1,0.,0.,1.);
#
# Fill the XX and YY coordinate arrays as well as the Z function array.
#
for my $I ( 1 .. 21 ) {
  my $X = .1*($I-11);
  set( $XX, $I-1, $X );
  for my $J ( 1 .. 25 ) {
    my $Y = .1*($J-13);
    set( $YY, $J-1, $Y );
    set( $Z, $I-1, $J-1, ($X+$Y+1./(($X-.1)*($X-.1)+$Y*$Y+.09)
                        -1./(($X+.1)*($X+.1)+$Y*$Y+.09))*.25 );
  }
}
#
# Select the normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Add the plot title.
#
# Set the text alignment to center the string in horizontal and vertical
#
&NCAR::gstxal(2,3);
#
# Set the character height.
#
&NCAR::gschh(.016);
#
# Write the text.
#
&NCAR::gtx($CX,$CY,'DEMONSTRATION PLOT FOR SRFACE ENTRY OF SRFACE');
#
&NCAR::srface ($XX,$YY,$Z,$WORK,21,15,12,$S,0.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fsrezrf.ncgm';
