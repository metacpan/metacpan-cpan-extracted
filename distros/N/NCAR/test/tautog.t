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
# PURPOSE                To provide a simple demonstration of
#                        the AUTOGRPH package.
#
# USAGE                  CALL TAUTOG (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test was successful,
#                          = 1, otherwise
#
# I/O                    If the test is successful, the message
#
#               AUTOGRAPH TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is printed on unit 6.  In addition, 4
#                        frames are produced on the machine graphics
#                        device.  In order to determine if the test
#                        was successful, it is necessary to examine
#                        the plots.
#
# PRECISION              Single
#
# LANGUAGE               FORTRAN 77
#
# REQUIRED ROUTINES      AUTOGRPH, DASHCHAR
#
# REQUIRED GKS LEVEL     0A
#
# HISTORY                Originally written in April, 1979.
#                        Converted to FORTRAN 77 and GKS in Feb., 1985.
#
# ALGORITHM              TAUTOG computes data which is plotted in single
#                        calls to each of the entries
#
#                          EZY, EZXY, EZMY, AND EZMXY.
#
#                        On 3 of the plots, routines AGSETF, AGSETI,
#                        and AGSETP are called to specify Y-axis labels
#                        or to introduce log scaling.
#
my $X = zeroes float, 21;
my $Y1D = zeroes float, 21;
my $Y2D = zeroes float, 21, 5;
#
# X contains the abscissae for the plots produced by EZXY and
# EZMXY,  Y1D contains the ordinate values for the plots produced by
# EZXY and EZY,  and Y2D contains the ordinate values for the plots
# produced by EZMY and EZMXY.
#
#
#     Frame 1 -- EZY entry of AUTOGRAPH.
#
# Fill Y1D array for entry EZY.
#
for my $I ( 1 .. 21 ) {
  set( $Y1D, $I-1, exp( -.1 * $I ) * cos( $I * .5 ) );
}
#
# Entry EZY plots Y1D as a function of a set of continuous integers.
#
#       DEMONSTRATING EZY ENTRY OF AUTOGRAPH
#
&NCAR::ezy ($Y1D,21,'DEMONSTRATING EZY ENTRY OF AUTOGRAPH$');
#
#     Frame 2 -- EZXY entry of AUTOGRAPH.
#
# Fill X and Y1D arrays for entry EZXY.
#
for my $I ( 1 .. 21 ) {
  set( $X, $I-1, ( $I-1 )*.314 );
  set( $Y1D, $I-1, at( $X, $I-1 ) + cos( at( $X, $I-1 ) ) * 2 );
}
#
# Set AUTOGRAPH control parameters for Y-axis label   "X+COS(X)*2"
#
&NCAR::agsetc('LABEL/NAME.','L');
&NCAR::agseti('LINE/NUMBER.',100);
&NCAR::agsetc('LINE/TEXT.','X+COS(X)*2$');
#
# Entry EZXY plots contents of X-array vs. Y1D-array.
#
#       DEMONSTRATING EZXY ENTRY OF AUTOGRAPH
#
&NCAR::ezxy ($X,$Y1D,21,'DEMONSTRATING EZXY ENTRY IN AUTOGRAPH$');
#
#     Frame 3 -- EZMY entry of AUTOGRAPH.
#
# Fill Y2D array for entry EZMY.
#
for my $I ( 1 .. 21 ) {
  my $T = .5*($I-1);
  for my $J ( 1 .. 5 ) {
    set( $Y2D, $I-1, $J-1, exp( -.5 * $T ) * cos( $T ) / $J );
  }
}
#
# Set the AUTOGRAPH control parameters for Y-axis label
#         EXP(-X/2)*COS(X)*SCALE
#
&NCAR::agsetc('LABEL/NAME.','L');
&NCAR::agseti('LINE/NUMBER.',100);
&NCAR::agsetc('LINE/TEXT.','EXP(-X/2)*COS(X)*SCALE$');
#
# Use the AUTOGRAPH control parameter for integers to specify the
# alphabetic set of dashed line patterns.
#
&NCAR::agseti('DASH/SELECTOR.',-1);
#
# Use the AUTOGRAPH control parameter for integers to specify the
# graph drawn is to be logarithmic in the X-axis.
#
&NCAR::agseti('X/LOGARITHMIC.',1);
#
# Entry EZMY plots multiple arrays as a function of continuous integers.
#
#       DEMONSTRATING EZMY ENTRY OF AUTOGRAPH
#
&NCAR::ezmy ($Y2D,21,5,10,'DEMONSTRATING EZMY ENTRY OF AUTOGRAPH$');
#
#     Frame 4 -- EZMXY entry of AUTOGRAPH.
#
# Fill Y2D array for EZMXY.
#
sub Pow {
  my ( $x, $a ) = @_;
  return $x ? exp( $a * log( abs( $x ) ) ) : 0;
}

for my $I ( 1 .. 21 ) {
  for my $J ( 1 .. 5 ) {
    set( $Y2D, $I-1, $J-1, &Pow( at( $X, $I-1 ), $J ) + cos( at( $X, $I-1 ) ) );
  }
}
#
# Set the AUTOGRAPH control parameters for Y-axis label
#         X**J+COS(X)
#
&NCAR::agsetc('LABEL/NAME.','L');
&NCAR::agseti('LINE/NUMBER.',100);
&NCAR::agsetc('LINE/TEXT.','X**J+COS(X)$');
#
# Use the AUTOGRAPH control parameter for integers to specify the
# alphabetic set of dashed line patterns.
#
&NCAR::agseti('DASH/SELECTOR.',-1);
#
# Use the AUTOGRAPH control parameter for integers to specify the
# graph have a linear X-axis and a logarithmic Y-axis.
#
&NCAR::agseti('X/LOGARITHMIC.',0);
&NCAR::agseti('Y/LOGARITHMIC.',1);
#
# Entry EZMXY plots multiple Y arrays as a function of a single
# or multiple X arrays.
#
#       DEMONSTRATING EZMXY ENTRY OF AUTOGRAPH
#
&NCAR::ezmxy ($X,$Y2D,21,5,21,'DEMONSTRATING EZMXY ENTRY OF AUTOGRAPH$');
#
# Note that AUTOGRAPH makes its own FRAME advance calls.
#
print STDERR "\n AUTOGRAPH TEST EXECUTED--SEE PLOTS TO CERTIFY\n";
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
 
   
rename 'gmeta', 'ncgm/tautog.ncgm';
