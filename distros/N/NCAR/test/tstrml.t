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
#	$Id: tstrml.f,v 1.4 1995/06/14 14:05:10 haley Exp $
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
&TSTRML(my $IERR);
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#

sub TSTRML {
  my ($IERROR) = @_;
#
# PURPOSE                To provide a simple demonstration of STRMLN.
#
# USAGE                  CALL TSTRML (IERROR)
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
#               STRMLN TEST EXECUTED--SEE PLOT TO CERTIFY
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
# REQUIRED ROUTINES      STRMLN
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              Routine TSTRML calls routine STRMLN to
#                        produce a plot which depicts the flow and
#                        magnitude of a vector field.
#
  my $U = zeroes float, 21, 25;
  my $V = zeroes float, 21, 25;
  my $WRK = zeroes float, 1050;
#
# Specify coordinates for plot titles.  The values TX and TY
# define the center of the title string in a 0. to 1. range.
#
  my ( $TX, $TY ) = ( .5, .9765 );
#
# Set the grid dimensions.
#
  my ( $NH, $NV ) = ( 21, 25 );     
#
# Initialize the error parameter.
#
  $IERROR = 1;
#
# Specify horizontal and vertical vector components U and V on
# the rectangular grid.
#
  my $TPIMX = 2.*3.14/($NH);
  my $TPJMX = 2.*3.14/($NV);
  for my $J ( 1 .. $NV ) {
    for my $I ( 1 .. $NH ) {
      set( $U, $I-1, $J-1, sin($TPIMX*(($I)-1.)) );
      set( $V, $I-1, $J-1, sin($TPJMX*(($J)-1.)) );
    }
  }
#
# Select normalization transformation 0.
#
  &NCAR::gselnt (0);
#
# Call PLCHLQ to write the plot title.
#
  &NCAR::plchlq ($TX,$TY,'DEMONSTRATION PLOT FOR ROUTINE STRMLN',16., 0.,0.);
#
# Define normalization transformation 1, and set up log scaling.
#
  &NCAR::set(0.1, 0.9, 0.1, 0.9,1.0, 21., 1.0, 25.,1);
#
# Draw the plot perimeter.
#
  &NCAR::perim(1,0,1,0);
#
# Call STRMLN for vector field streamlines plot.
#
  &NCAR::strmln ($U,$V,$WRK,$NH,$NH,$NV,1,my $IER);
#
  &NCAR::frame();
#
  $IERROR = 0;
  print STDERR "\n STRMLN TEST EXECUTED--SEE PLOT TO CERTIFY\n";
#
}


rename 'gmeta', 'ncgm/tstrml.ncgm';
