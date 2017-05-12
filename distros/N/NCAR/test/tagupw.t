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
   
#
#	$Id: tagupw.f,v 1.4 1995/06/14 14:04:39 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# OPEN GKS, OPEN WORKSTATION OF TYPE 1, ACTIVATE WORKSTATION
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#
# PURPOSE                To provide a simple demonstration of the use
#                        of AGUPWRTX with AUTOGRAPH.
#
# USAGE                  CALL TAGUPW (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#
#                          an error parameter
#                          = 0, if the test is successful,
#                          = 1, otherwise
#
# I/O                    If the test is successful, the message
#
#                          AGUPWRTX TEST SUCCESSFUL  . . .  SEE PLOTS
#                          TO VERIFY PERFORMANCE
#
#                        is written on unit 6.
#
#                        In addition, four (4) labelled frames
#                        containing the two-dimensional plots are
#                        produced on the machine graphics device.
#                        To determine if the test was successful,
#                        it is necessary to examine these plots.
#
# PRECISION              Single.
#
# REQUIRED LIBRARY       AUTOGRAPH, AGUPWRTX, PWRITX, SPPS
# FILES
#
# REQUIRED GKS LEVEL     0A
#
# LANGUAGE               FORTRAN
#
# HISTORY                Adapted from TAUTOG, in June, 1987.
#
# ALGORITHM              TAGUPW computes data for AUTOGRAPH subroutines
#
#                          EZY, EZXY, EZMY, and EZMXY,
#
#                        and calls each of these routines to produce
#                        one plot each.
#
#                        On three of the plots, TAGUPW uses the
#                        AUTOGRAPH control parameter routines
#                        AGSETF, AGSETI, and AGSETP to specify
#                        Y-axis labels or introduce log scaling.
#
#                        Loading AGUPWRTX with AUTOGRAPH caused the
#                        labels to be written by PWRITX.
#
# PORTABILITY            FORTRAN 77
#
#
#
# Declare the data arrays X, Y1D, and Y2D.  X contains abscissae for
# the plots produced by EZXY and EZMXY,  Y1D contains ordinates for
# the plots produced by EZXY and EZY,  and Y2D contains ordinates for
# the plots produced by EZMY and EZMXY.
#
my $X = zeroes float, 21;
my $Y1D = zeroes float, 21;
my $Y2D = zeroes float, 21, 5;
#
#
#
# Fill the array Y1D for the call to EZY.
#
for my $I ( 1 .. 21 ) {
  set( $Y1D, $I-1, exp(-.1*$I)*cos($I*.5) );
}
#
# Plot the contents of Y1D as a function of the integers.
#
&NCAR::ezy ($Y1D,21,'DEMONSTRATING EZY ENTRY OF AUTOGRAPH$');
#
#
#
# Fill the arrays X and Y1D for the call to EZXY.
#
for my $I ( 1 .. 21 ) {
  set( $X, $I-1, ( $I-1 ) * .314 );
  set( $Y1D, $I-1, at( $X, $I-1 ) + cos( at( $X, $I-1 ) ) * 2.0 );
}
#
# Redefine the Y-axis label.
#
&NCAR::agsetc('LABEL/NAME.','L');
&NCAR::agseti('LINE/NUMBER.',100);
&NCAR::agsetc('LINE/TEXT.','X+COS(X)*2$');
#
# Plot the array Y1D as a function of the array X.
#
&NCAR::ezxy ($X,$Y1D,21,'DEMONSTRATING EZXY ENTRY IN AUTOGRAPH$');
#
#
#
# Fill the array Y2D for the call to EZMY.
#
for my $I ( 1 .. 21 ) {
  my $T = .5*($I-1);
  for my $J ( 1 .. 5 ) { 
    set( $Y2D, $I-1, $J-1, exp(-.5*$T)*cos($T)/$J );
  }
}
#
# Redefine the Y-axis label.
#
&NCAR::agsetc('LABEL/NAME.','L');
&NCAR::agseti('LINE/NUMBER.',100);
&NCAR::agsetc('LINE/TEXT.','EXP(-X/2)*COS(X)*SCALE$');
#
# Specify that the alphabetic set of dashed line patterns is to be used.
#
&NCAR::agseti('DASH/SELECTOR.',-1);
#
# Specify that the graph drawn is to be logarithmic in X.
#
&NCAR::agseti('X/LOGARITHMIC.',1);
#
# Plot the five curves defined by Y2D as functions of the integers.
#
&NCAR::ezmy ($Y2D,21,5,10,'DEMONSTRATING EZMY ENTRY OF AUTOGRAPH$');
#
#
#
# Fill the array Y2D for the call to EZMXY.
#
sub Pow {
  my ( $x, $a ) = @_;
  return $x ? exp( $a * log( $x ) ) : 0;
}

for my $I ( 1 .. 21 ) {
  for my $J ( 1 .. 5 ) {
    set( $Y2D, $I-1, $J-1, &Pow( at( $X, $I-1 ), $J ) + cos( at( $X, $I-1 ) ) );
  }
}
#
# Redefine the Y-axis label.
#
&NCAR::agsetc('LABEL/NAME.','L');
&NCAR::agseti('LINE/NUMBER.',100);
&NCAR::agsetc('LINE/TEXT.','X**J+COS(X)$');
#
# Specify that the graph is to be linear in X and logarithmic in Y.
#
&NCAR::agseti('X/LOGARITHMIC.',0);
&NCAR::agseti('Y/LOGARITHMIC.',1);
#
# Plot the five curves defined by Y2D as functions of X.
#
&NCAR::ezmxy ($X,$Y2D,21,5,21,'DEMONSTRATING EZMXY ENTRY OF AUTOGRAPH$');
#
#
#
# Done.
#
print STDERR "\n  AGUPWRTX TEST SUCCESSFUL SEE PLOTS TO VERIFY PERFORMANCE\n";
#

#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
 
   
rename 'gmeta', 'ncgm/tagupw.ncgm';
