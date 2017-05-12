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
#	$Id: tvelvc.f,v 1.4 1995/06/14 14:05:12 haley Exp $
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
&TVELVC(my $IERR);
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
#
sub TVELVC {
  my ($IERROR) = @_;
#
# PURPOSE                To provide a simple demonstration of VELVCT.
#
# USAGE                  CALL TVELVC (IERROR)
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
#               VELVCT TEST EXECUTED--SEE PLOTS TO CERTIFY
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
# REQUIRED ROUTINES      VELVCT
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              This test program calls entries EZVEC and
#                        VELVCT.  Each call produces a plot of a
#                        vector field obtained from the function
#
#                          Z(X,Y) = X + Y + 1./((X-.1)**2+Y**2+.09)
#                                   -1./((X+.1)**2+Y**2+.09),
#
#                        by using the direction of the Z gradient
#                        vectors and the logarithm of the absolute
#                        value of the components.
#
# HISTORY                Originally written in November 1976.
#                        Converted to FORTRAN 77 and GKS in July 1984.
#
#
  my $U = zeroes float, 21, 25;
  my $V = zeroes float, 21, 25;
#
# Specify coordinates for a plot title.
#
  my ( $IX, $IY ) = ( 94, 1000 );
#
# Specify VELVCT arguments.
#
  my ( $FLO, $HI, $NSET, $LENGTH, $ISPV, $SPV ) = ( 0, 0, 0, 0, 0, float([0,0]) );
#
# Initialize the error parameter.
#
  $IERROR = 1;
#
# Specify velocity field functions U and V.
#
  my $M = 21;
  my $N = 25;
  for my $I ( 1 .. $M ) {
    my $X = .1*($I-11);
    for my $J ( 1 .. $N ) {
      my $Y = .1*($J-13);
      my $DZDX = 1.-2.*($X-.10)/(($X-.10)**2+$Y**2+.09)**2+2.*($X+.10)/(($X+.10)**2+$Y**2+.09)**2;
      my $DZDY = 1.-2.*$Y/(($X-.10)**2+$Y**2+.09)**2+2.*$Y/(($X+.10)**2+$Y**2+.09)**2;
      my $UVMAG = log(sqrt($DZDX*$DZDX+$DZDY*$DZDY));
      my $UVDIR = atan2($DZDY,$DZDX);
      set( $U, $I-1, $J-1, $UVMAG*cos($UVDIR) );
      set( $V, $I-1, $J-1, $UVMAG*sin($UVDIR) );
    }
  }
#
  &NCAR::gqcntn(my $IERR, my $ICN);
#
# Select normalization transformation 0.
#
  &NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
  my $X = &NCAR::cpux($IX);
  my $Y = &NCAR::cpuy($IY);
  &NCAR::plchlq ($X,$Y,'DEMONSTRATION PLOT FOR ENTRY EZVEC OF VELVCT',16.,0.,-1.);
  &NCAR::gselnt($ICN);
#
# Call EZVEC for a default velocity field plot.
#
  &NCAR::ezvec ($U,$V,$M,$N);
#
# Call VELVCT to generate the user tuned velocity field plot.
#
  &NCAR::velvct ($U,$M,$V,$M,$M,$N,$FLO,$HI,$NSET,$LENGTH,$ISPV,$SPV);
  &NCAR::gqcntn($IERR,$ICN);
#
# Select normalization transformation 0.
#
  &NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
  $X = &NCAR::cpux($IX);
  $Y = &NCAR::cpuy($IY);
  &NCAR::plchlq ($X,$Y,'DEMONSTRATION PLOT FOR ENTRY VELVCT OF VELVCT',16.,0.,-1.);
  &NCAR::gselnt($ICN);
  &NCAR::frame();
#
  $IERROR = 0;
  print STDERR "\n VELVCT TEST EXECUTED--SEE PLOTS TO CERTIFY\n";
#
}


rename 'gmeta', 'ncgm/tvelvc.ncgm';
