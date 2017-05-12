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
#	$Id: tgrida.f,v 1.4 1995/06/14 14:04:54 haley Exp $
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
&TGRIDA(my $IERR);
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
#
sub TGRIDA {
  my ($IER) = @_;
#
# PURPOSE                To provide a simple demonstration of
#                        all of the entry points of the GRIDAL
#                        package.  Eight plots are produced.
#
# USAGE                  CALL TGRIDA (IERROR)
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
#              GRIDAL TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is printed on unit 6.  In addition, 8
#                        frames are produced on the machine graphics
#                        device.  In order to determine if the test
#                        was successful, it is necessary to examine
#                        these plots.
#
# PRECISION              Single
#
# LANGUAGE               FORTRAN 77
#
# ALGORITHM              All of the entries of the GRIDAL package
#                        are invoked (GRID, GRIDL, PERIM, PERIML,
#                        HALFAX, TICK4, LABMOD, and GRIDAL) to
#                        produce plots.  The GRIDAL entry is called
#                        ten times.  The first call is to demonstate
#                        a full frame grid.  The next nine calls
#                        create a single frame that contains the
#                        nine legal IGPH grid options to show how
#                        up to nine plots can be placed on a single
#                        frame.
#
#
# Define normalization transformation 1.
#
  &NCAR::gswn(1,0.,1.,0.,1.);
  &NCAR::gsvp(1,.2,.8,.2,.8);
#
# GRID
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR GRID',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::grid(5,2,6,3);
  &NCAR::frame();
#
# GRIDL
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR GRIDL',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::gridl(5,2,6,3);
  &NCAR::frame();
#
# PERIM
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR PERIM',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::perim(5,2,6,3);
  &NCAR::frame();
#
# PERIML
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR PERIML',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::periml(5,2,6,3);
  &NCAR::frame();
#
# HALFAX
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR HALFAX',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::halfax(5,2,6,3,.3,.5,0,0);
  &NCAR::frame();
#
# TICK4
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR TICK4',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::tick4(150,50,150,50);
  &NCAR::perim(5,2,6,3);
  &NCAR::frame();
  &NCAR::tick4(12,8,12,8);
#
# LABMOD
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR LABMOD',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::labmod('(E10.2)','(F4.2)',10,4,15,15,0,0,0);
  &NCAR::halfax(2,1,10,1,0.,0.,1,1);
  &NCAR::frame();
#
# Use LABMOD to reduce the number of digits in the grid scales
#
#
  &NCAR::labmod('(F4.2)','(F4.2)',4,4,0,0,0,0,0);
#
# GRIDAL  -  A single grid on a frame.
#
  my $IGPH = 0;
  my $BUFF = sprintf( "%2.2d", $IGPH );
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.85,'IGPH = ',16.,0.,1.);
  &NCAR::plchlq(.5,.85,$BUFF,16.,0.,-1.);
  &NCAR::plchlq(.5,.9,'DEMONSTRATION PLOT FOR GRIDAL',16.,0.,0.);
  &NCAR::gselnt(1);
  &NCAR::gridal(5,2,6,3,1,1,$IGPH,.3,.13);
  &NCAR::frame();
#
# GRIDAL  -  All 9 legal grids on a single frame.
#
  &NCAR::gselnt(0);
  &NCAR::plchlq(.5,.98,'TEST IGPH OPTIONS OF GRIDAL',16.,0.,0.);
  my $KNT = 0;
  for my $I ( 0 .. 10 ) {
    if( ( $I == 3 ) || ( $I == 7 ) ) { goto L100; }
    $IGPH = $I;
    $BUFF = sprintf( "%2.2d", $IGPH );
    $KNT = $KNT + 1;
#
# Compute the X and Y grid boundaries for the 9 plots.
#
    my $Y1 = .42;
    if( $KNT < 4 ) { $Y1 = .74; }
    if( $KNT > 6 ) { $Y1 = .10; }
    my $X1 = .10;
    if( ( $KNT == 2 ) || ( $KNT == 5 ) || ( $KNT == 8 ) ) { $X1 = .42; }
    if( ( $KNT == 3 ) || ( $KNT == 6 ) || ( $KNT == 9 ) ) { $X1 = .74; }
    my $X2 = $X1 + .18;
    my $Y2 = $Y1 + .18;
#
# Specify some user coordinates.
#
    my $H1 = $X1*10.;
    my $H2 = $X2*10.;
    my $V1 = $Y1*10.;
    my $V2 = $Y2*10.;
#
# Locate the IGPH legend above the grid.
#
    my $XG = $X1 + .13;
    my $YG = $Y2 + .03;
    &NCAR::gselnt(0);
    &NCAR::plchlq($XG,$YG,'IGPH = ',16.,0.,1.);
    &NCAR::plchlq($XG,$YG,$BUFF,16.,0.,-1.);
    &NCAR::gselnt(1);
    &NCAR::set($X1,$X2,$Y1,$Y2,$H1,$H2,$V1,$V2,1);
    &NCAR::gridal(3,3,4,2,1,1,$IGPH,$H1,$V1);
    L100:
  }
#
# Advance the frame.
#
      &NCAR::frame();
#
  print STDERR "\nGRIDAL TEST EXECUTED--SEE PLOTS TO CERTIFY\n";
}

rename 'gmeta', 'ncgm/tgrida.ncgm';

