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
#	$Id: thafto.f,v 1.4 1995/06/14 14:04:55 haley Exp $
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
# PURPOSE                Provides a simple demonstration of HAFTON
#
# USAGE                  CALL THAFTO (IERROR)
#
# ARGUMENTS
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test was successful,
#                          = 1, the test was not successful.
#
# I/O                    If the test is successful, the message
#               HAFTON TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is printed on unit 6.  In addition, 2 half-tone
#                        frames are produced on the machine graphics
#                        device.  In order to determine if the test
#                        was successful, it is necessary to examine
#                        the plots.
#
# PRECISION              Single
#
# LANGUAGE               FORTRAN 77
#
# REQUIRED ROUTINES      HAFTON
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              The function
#                          Z(X,Y) = X + Y + 1./((X-.1)**2+Y**2+.09)
#                                   -1./((X+.1)**2+Y**2+.09)
#                        for X = -1. TO +1. in increments of .1, and
#                            Y = -1.2 TO +1.2 in increments of .1,
#                        is computed.  Then, entries EZHFTN and HAFTON
#                        are called to generate 2 half-tone plots of Z.
#
# Z contains the values to be plotted.
#
my $Z = zeroes float, 21, 25;
#
# Specify coordinates for plot titles.  The values TX and TY
# define the center of the title string in a 0. to 1. range.
#
my ( $TX, $TY ) = ( 0.0762, 0.9769 );
#
# Specify low (FLO) and high (FHI) contour values, and NLEV
# unique contour levels.  NOPT determines how Z maps onto the
# intensities, and the directness of the mapping.
#
my ( $FLO, $FHI, $NLEV, $NOPT ) = ( -4.0, 4.0, 8, -3 );
#
# Initialize the error indicator
#
my $IERROR = 0;
#
# Fill the 2 dimensional array to be plotted
#
for my $I ( 1 .. 21 ) {
  my $X = .1*($I-11);
  for my $J ( 1 .. 25 ) {
    my $Y = .1*($J-13);
    set( $Z, $I-1, $J-1, $X+$Y+1./(($X-.10)**2+$Y**2+.09)-1./(($X+.10)**2+$Y**2+.09) );
  }
}
#
# Select normalization trans 0 for plotting title.
#
&NCAR::gselnt (0);
#
#
#     Frame 1 -- The EZHFTN entry with default parameters.
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq ($TX,$TY,'DEMONSTRATION PLOT FOR ENTRY EZHFTN OF HAFTON',16.,0.,-1.);
#
# Entry EZHFTN requires only the array and its dimensions.
#
&NCAR::ezhftn ($Z,21,25);
#
#
#     Frame 2 -- The HAFTON entry with user selectable parameters.
#
#   Add a plot title.
#
&NCAR::plchlq ($TX,$TY,'DEMONSTRATION PLOT FOR ENTRY HAFTON OF HAFTON',16.,0.,-1.);
#
# Entry HAFTON allows user specification of plot parameters.
#
&NCAR::hafton ($Z,21,21,25,$FLO,$FHI,$NLEV,$NOPT,0,0,0.);
&NCAR::frame();
print STDERR "\n HAFTON TEST EXECUTED--SEE PLOTS TO CERTIFY\n";
#


&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
   
rename 'gmeta', 'ncgm/thafto.ncgm';
