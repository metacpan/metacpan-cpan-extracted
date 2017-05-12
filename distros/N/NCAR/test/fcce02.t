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
# PURPOSE                To provide a demonstration of the routines in
#                        the package COLCONV and to test them.
#
# I/O                    If the test is successful, the message
#
#                        COLCONV TEST SUCCESSFUL
#
#                        is written on unit 6.
#
#                        Otherwise, the message
#
#                        COLCONV TEST UNSUCCESSFUL
#
#                        is written on unit 6.
#
# REQUIRED PACKAGES      COLCONV
#
# ALGORITHM              TCOLCV executes six calls to test each of
#                        the color conversions:
#
#                              HLS to RGB
#                              RGB to HLS
#                              HSV to RGB
#                              RGB to HSV
#                              YIQ to RGB
#                              RGB to YIQ
#
# ---------------------------------------------------------------------
#
#  Initialize the error flag.
#
my $IERR = 0;
#
#  Set tolerance limit for HLS and HSV tests.
#
my $EPS = 0.00001;
#
#  HLS to RGB.
#
my ( $HUE, $RLIGHT, $SATR, $RED, $BLUE, $GREEN, $Y, $RI, $Q, $VALUE );
$HUE    = 120.;
$RLIGHT =  50.;
$SATR   = 100.;
&NCAR::hlsrgb($HUE,$RLIGHT,$SATR,$RED,$GREEN,$BLUE);
if ( (abs($RED-1.) > $EPS) || (abs($GREEN) > $EPS) || (abs($BLUE) > $EPS) ) 
{ $IERR = 1; }
#
#  RGB to HLS.
#
$RED   = 1.;
$GREEN = 0.;
$BLUE  = 0.;
&NCAR::rgbhls($RED,$GREEN,$BLUE,$HUE,$RLIGHT,$SATR);
if ( (abs($HUE-120.) > $EPS) || (abs($RLIGHT-50.) > $EPS) || (abs($SATR-100.) > $EPS) ) 
{ $IERR = 1; }
#
#  HSV to RGB.
#
$HUE   = 120.;
$SATR  = 1.;
$VALUE = 1.;
&NCAR::hsvrgb($HUE,$SATR,$VALUE,$RED,$GREEN,$BLUE);
if ( (abs($RED-0.) > $EPS) || (abs($GREEN-1.) > $EPS) || (abs($BLUE-0.) > $EPS) ) 
{ $IERR = 1; }
#
#  RGB to HSV.
#
$RED   = 0.;
$GREEN = 0.;
$BLUE  = 1.;
&NCAR::rgbhsv($RED,$GREEN,$BLUE,$HUE,$SATR,$VALUE);
if ( (abs($HUE-240.) > $EPS) || (abs($SATR-1.) > $EPS) || (abs($VALUE-1.) > $EPS) ) 
{ $IERR = 1; }
#
#  Set tolerance limit for YIQ tests.
#
$EPS = 0.01;
#
#  YIQ to RGB.
#
$Y = 0.59;
$RI = -.28;
$Q = -.52;
&NCAR::yiqrgb($Y,$RI,$Q,$RED,$GREEN,$BLUE);
if ( (abs($RED-0.) > $EPS) || (abs($GREEN-1.) > $EPS) || (abs($BLUE-0.) > $EPS) ) 
{ $IERR = 1; }
#
#  RGB to YIQ.
#
$RED   = 1.0;
$GREEN = 1.0;
$BLUE  = 1.0;
&NCAR::rgbyiq($RED,$GREEN,$BLUE,$Y,$RI,$Q);
if ( (abs($Y-1.) > $EPS) || (abs($RI) > $EPS) || (abs($Q) > $EPS) ) 
{ $IERR = 1; }
#
if ($IERR == 0) {
  print( STDERR "\nCOLCONV TEST SUCCESSFUL\n" );
} else {
  print( STDERR "\nCOLCONV TEST UNSUCCESSFUL\n" );
}
#
#
