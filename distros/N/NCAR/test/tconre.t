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
#	$Id: tconre.f,v 1.4 1995/06/14 14:04:46 haley Exp $
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
# INVOKE DEMO DRIVER
#
&TCONRE(my $IERR);
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
#
sub TCONRE {
  my ($IERROR) = @_;
#
# PURPOSE                To provide a simple demonstration of standard
#                        contouring of regularly spaced data using
#                        the CONREC package.
#
# USAGE                  CALL TCONRE (IERROR)
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
#               CONREC TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is printed on unit 6.  In addition, 2
#                        frames are produced on the machine graphics
#                        device.  In order to determine if the test
#                        was successful, it is necessary to examine
#                        the plots.
#
# PRECISION              Single
#
# LANGUAGE               FORTRAN 77
#
# REQUIRED ROUTINES      CONREC, DASHCHAR
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              The function
#
#                          Z(X,Y) = X + Y + 1./((X-.1)**2+Y**2+.09)
#                                   -1./((X+.1)**2+Y**2+.09)
#
#                        for X = -1. to +1. in increments of .1, and
#                            Y = -1.2 to +1.2 in increments of .1,
#                        is computed.  Then, entries EZCNTR and CONREC
#                        are called to generate contour plots of Z.
#
#                        This is the standard version of the CONREC
#                        family of utilities.
#
# Z contains the values to be plotted.
#
  my $Z = zeroes float, 21, 25;
#
# Define the position of the plot title.
#
  my ( $TX, $TY ) = ( .3955, .9765 );
#
# Initialize the error parameter.
#
  my $IERROR = 0;
#
# Fill the 2-D array to be plotted.
#
  for my $I ( 1 .. 21 ) {
    my $X = .1*($I-11);
    for my $J ( 1 .. 25 ) {
      my $Y = .1*($J-13);
      set( 
           $Z, $I-1, $J-1,
           $X+$Y+1./(($X-.10)**2+$Y**2+.09)-1./(($X+.10)**2+$Y**2+.09) 
         );
    }
  }
#
# Select normalization transformation number 0.
#
  &NCAR::gselnt ( 0 );
#
#
#     Frame 1 -- EZCNTR entry of CONREC.
#
# Entry EZCNTR requires only the array name and dimensions.
#
  &NCAR::plchlq ($TX, $TY,'DEMONSTRATION PLOT FOR EZCNTR ENTRY OF CONREC',16.,0.,0.);
  &NCAR::ezcntr ($Z,21,25);
#
#
#     Frame 2 -- CONREC entry of CONREC.
#
# Entry CONREC allows user definition of various plot parameters.
#
# In this example, the lowest contour level (-4.5), the highest contour
# level (4.5), and the increment between contour levels (0.3) are set.
#
  &NCAR::plchlq ($TX,$TY,'DEMONSTRATION PLOT FOR CONREC ENTRY OF CONREC',16.,0.,0. );
  &NCAR::conrec ($Z,21,21,25,-4.5,4.5,.3,0,0,0);
  &NCAR::frame();
#
  print STDERR "\n CONREC TEST EXECUTED--SEE PLOTS TO CERTIFY\n";
#
}

rename 'gmeta', 'ncgm/tconre.ncgm';
