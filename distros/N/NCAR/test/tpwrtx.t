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
#	$Id: tpwrtx.f,v 1.4 1995/06/14 14:05:02 haley Exp $
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
&TPWRTX(my $IERR);
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
#
sub TPWRTX {
  my ($IERROR) = @_;
#
# PURPOSE                To provide a demonstration of PWRITX
#                        and to test PWRITX with an example.
#
# USAGE                  CALL TPWRTX (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test is successful,
#                          = 1, otherwise
#
# I/O                    If the test is successful, the message
#
#               PWRITX TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is written on unit 6.
#
#                        In addition, four frames are produced.  The
#                        first three frames contain complete
#                        character plots, and the fourth frame
#                        tests various settings of the function
#                        codes.  To determine if the test is
#                        successful, it is necessary to examine these
#                        plots.
#
# PRECISION              Single
#
# REQUIRED ROUTINES      PWRITX
#
# REQUIRED GKS LEVEL     0A
#
# LANGUAGE               FORTRAN
#
# ALGORITHM              TPWRTX calls the software character drawing
#                        subroutine PWRITX once for twelve different
#                        function codes for 46 separate characters.
#                        This produces a total of 552 characters on
#                        four separate plots.  Each plot contains a
#                        grid of characters with the principle Roman
#                        characters in the first column and their
#                        other representations, produced with different
#                        function codes, across each row.  Each function
#                        code has a mnemonic interpretation (e.g.,
#                        PRU - Principle Roman Upper,  IGL - Indexical
#                        Greek Lower).  In the first four plots, each
#                        column is labelled with its function code.
#                        The fifth plot invokes PWRITX with various
#                        function codes.
#
#
# DAT contains the standard character set
#

  my @DAT = (
     'A',    'B',    'C',    'D',    'E',    'F',    'G',
     'H',    'I',    'J',    'K',    'L',    'M',    'N',
     'O',    'P',    'Q',    'R',    'S',    'T',    'U',
     'V',    'W',    'X',    'Y',    'Z',    '0',    '1',
     '2',    '3',    '4',    '5',    '6',    '7',    '8',
     '9',    '+',    '-',    '*',    '/',    '(',    ')',
     '$',    '=',    ' ',    ',',    '.',    ' ' );
#
# Use normalization transformation 0
#
  &NCAR::gselnt (0);
#
# A separate frame is produced for each iteration through this loop
#
  for my $K ( 1 .. 4 ) {
#
#  Label the column and change the function code
#
    for my $J ( 1 .. 12 ) {
       my $XPOS = ($J*80-39) / 1024.;
       my @C = ( 
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'PRU',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'PRU\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'PRL',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'PRL\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'IRU',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'IRU\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'IRL',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'IRL\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'KRU',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'KRU\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'KRL',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'KRL\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'PGU',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'PGU\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'PGL',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'PGL\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'IGU',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'IGU\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'IGL',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'IGL\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'KGU',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'KGU\'',5,1,0,0);
               },
               sub {
                 &NCAR::pwritx ($XPOS,.9375,'KGL',3,16,0,0);
                 &NCAR::pwritx (1./1024.,1./1024.,'\'KGL\'',5,1,0,0);
               },
      );
      $C[$J-1]->();
#
#           Draw twelve characters with the same function code
#
      for my $I ( 1 .. 12 ) {
        my $YPOS = ( 980-$I*80 ) / 1024.;
        my $IF = $I+($K-1)*12;
        &NCAR::pwritx ($XPOS,$YPOS,$DAT[$IF-1],1,1,0,0);
      }
#
#           Return function to Principle Roman Upper to label column
#
      &NCAR::pwritx (1./1024.,1./1024.,'\'PRU\'',5,1,0,0);
    }
#
#        Label frame
#
    &NCAR::pwritx(.5,1000./1024.,'DEMONSTRATION PLOT FOR PWRITX',29,1,0,0);
    &NCAR::frame();
  }
#
#  Test more function codes.
#
#  Tests:
#    Upper and lower case function codes
#    Sub- and Super-scripting and Normal function codes
#    Down and Across function codes
#    Direct Character access
#    X and Y coordinate control, Carriage control function codes
#    Orientation of string (argument to PWRITX)
#
#
#  Test direct character access and string orientation
#
  &NCAR::pwritx(.5,.5,'\'546\'',5,3,0,0);
  &NCAR::pwritx(.5,.5,'\'H9L\'ANGLE OF \'U\'30',19,18,30,-1);
  &NCAR::pwritx(.5,.5,'\'H-9L\'ANGLE OF \'U\'190',21,18,190,-1);
#
#  Upper and Lower case
#
  &NCAR::pwritx(.65,.25,'2 \'L2\'LOWER, 3 \'U3\'UPPER',24,1,0,0);
#
#  Level definitions (sub and superscripting)
#
  &NCAR::pwritx(.95,.15,'THIS IS \'U1\'S\'S\'UPERSCRIPTING',29,0,0,1);
  &NCAR::pwritx(.95,.1,'\'N\'THIS IS \'L1\'S\'B\'UBSCRIPTING',30,0,0,1);
  &NCAR::pwritx(.95,.05,'\'N\'SHOW \'U1\'U\'S\'SE OF\'NU\'NORMAL', 31,0,0,1);
#
#  Direction definitions
#
  &NCAR::pwritx(.05,.5,'DO\'D\'WNA\'A\'CROSS',16,0,0,-1);
#
#  Coordinate definitions
#
  &NCAR::pwritx(.3,.85,'\'L\'U\'V7\'S\'V7\'E\'V7\' \'V7U1\'V\'V7\' FOR VERTICAL STEPS',49,0,0,0);
  &NCAR::pwritx(.25,.6,'\'U\'SHIFT\'H11\'.\'H11\'.\'H11\'.\'H11\'.RIGHT',37,14,90,-1);
  &NCAR::pwritx(.45,.6,'SHIFT\'H-30\'.\'H-11\'.\'H-11\'.\'H-11\'.LEFT',37,14,90,-1);
  &NCAR::pwritx(.8,.8,'\'L3\'USE C\'CL\'FOR\'C\'CARRIAGE\'C\'RETURNS',37,16,0,0);
  &NCAR::pwritx(.1,.1,'\'UX50Y50\'( X50, Y50 )\'X99Y99\'( X99, Y99 )',41,14,0,-1);
#
#        Label frame
#
  &NCAR::pwritx(.5,1000./1024.,'DEMONSTRATION PLOT FOR PWRITX',29,1,0,0);
  &NCAR::frame();
#
  $IERROR = 0;
  print STDERR "\n PWRITX TEST EXECUTED--SEE PLOTS TO CERTIFY \n";
#
}


rename 'gmeta', 'ncgm/tpwrtx.ncgm';
