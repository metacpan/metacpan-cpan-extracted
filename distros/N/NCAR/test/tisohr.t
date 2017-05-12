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
#	$Id: tisohr.f,v 1.4 1995/06/14 14:04:57 haley Exp $
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
&NCAR::isoscr();
&TISOHR(my $IERR);
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
#
sub TISOHR {
  my ($IERROR) = @_;
#
# PURPOSE                To provide a simple demonstration of ISOSRFHR.
#
# USAGE                  CALL TISOHR (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test was successful,
#                          = 1, the test was not successful.
#
# I/O                    A scratch file must be assigned to unit IUNIT.
#                        Common block UNITS should be inserted in the
#                        calling program.  Then, set IUNIT in the
#                        calling program.
#
#                        If the test is successful, the message
#
#               ISOSRFHR TEST EXECUTED--SEE PLOT TO CERTIFY
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
# REQUIRED ROUTINES      ISOSRFHR
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              This test program draws a perspective view
#                        of 2 interlocking doughnuts.
#
  my $IS2 = zeroes long, 4, 200;
  my $ST1 = zeroes float, 81, 51, 2;
  my $IOBJS = zeroes long, 81,51;
  use NCAR::COMMON qw( %UNITS );
#
# Specify coordinates for plot titles on a square grid of integer
# coordinates that range from 1 to 1024.  IX and IY define the center
# of the title string.
#
  my ( $IX, $IY ) = ( 448, 990 );
#
#
# Define the eye position.
#
  my $EYE = float [ 200., 250., 250. ];
#
# Define the overall dimensions of the box containing the objects.
#
  my ( $NU, $NV, $NW ) = ( 51, 81, 51 );
#
# Specify the dimensions of the model of the image plane.
#
  my ( $LX, $NX, $NY ) = ( 4, 180, 180 );
#
# Specify the user viewport in a 1 to 1024 range.
#
  my $S = float [ 10.,1010.,10.,1010. ];
  my $MV = 81;
#
# Specify the large and small radii for the individual doughnuts.
#
  my ( $RBIG1, $RBIG2, $RSML1, $RSML2 ) = ( 20., 20., 6., 6. );
#
#
# Call the initialization routine.
#
  &NCAR::init3d ($EYE,$NU,$NV,$NW,$ST1,$LX,$NY,$IS2,$UNITS{IUNIT},$S);
#
# Initialize the error indicator
#
  $IERROR = 1;
#
# Create and plot the interlocking doughnuts.
#
  my $JCENT1 = ($NV)*.5-$RBIG1*.5;
  my $JCENT2 = ($NV)*.5+$RBIG2*.5;
  for my $IBKWDS ( 1 .. $NU ) {
    my $I = $NU+1-$IBKWDS;
#
# Create the i-th cross section in the U direction of the 3-D array
# and store in IOBJS as zeros and ones.
#
     my $FIMID = $I-$NU/2;
     for my $J ( 1 .. $NV ) {
       my $FJMID1 = $J-$JCENT1;
       my $FJMID2 = $J-$JCENT2;
       for my $K ( 1 .. $NW ) {
         my $FKMID = $K-$NW/2;
         my $F1 = sqrt($RBIG1*$RBIG1/($FJMID1*$FJMID1+$FKMID*$FKMID+.1));
         my $F2 = sqrt($RBIG2*$RBIG2/($FIMID*$FIMID+$FJMID2*$FJMID2+.1));
         my $FIP1 = (1.-$F1)*$FIMID;
         my $FIP2 = (1.-$F2)*$FIMID;
         my $FJP1 = (1.-$F1)*$FJMID1;
         my $FJP2 = (1.-$F2)*$FJMID2;
         my $FKP1 = (1.-$F1)*$FKMID;
         my $FKP2 = (1.-$F2)*$FKMID;
         my $TEMP = &NCAR::Test::min(
                       $FIMID**2+$FJP1**2+$FKP1**2-$RSML1**2,
                       $FKMID**2+$FIP2**2+$FJP2**2-$RSML2**2
                    );
         if( $TEMP <= 0 ) { set( $IOBJS, $J-1, $K-1, 1 ); }
         if( $TEMP >  0 ) { set( $IOBJS, $J-1, $K-1, 0 ); }
      }
    }
#
# Set proper words to 1 for drawing axes.
#
    if( $I != 1 ) { goto L50; }
    for my $K ( 1 .. $NW ) {
      set( $IOBJS, 0, $K-1, 1 );
    }
    for my $J ( 1 .. $NV ) {
      set( $IOBJS, $J-1, 0, 1 );
    }
    goto L60;
L50:
    set( $IOBJS, 0, 0, 1 );
L60:
#
# Call the draw and remember routine for this slab.
#
    &NCAR::dandr ($NV,$NW,$ST1,$LX,$NX,$NY,$IS2,$UNITS{IUNIT},$S,$IOBJS,$MV);
  }
#
  &NCAR::gqcntn(my $IER, my $ICN);
#
# Select normalization transformation 0.
#
  &NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
  my $XC = &NCAR::cpux($IX);
  my $YC = &NCAR::cpuy($IY);
  &NCAR::plchlq($XC,$YC,'DEMONSTRATION PLOT FOR ISOSRFHR',16.,0.,0.);
  &NCAR::gselnt($ICN);
#
# Advance the frame.
#
  &NCAR::frame();
#
  $IERROR = 0;
#
  print STDERR " ISOSRFHR TEST EXECUTED--SEE PLOT TO CERTIFY\n";
#
}


rename 'gmeta', 'ncgm/tisohr.ncgm';
