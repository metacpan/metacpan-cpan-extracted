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
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $K, $N, $LRWK, $LIWK ) = ( 40, 40, 1000, 1000 );
my $Z = zeroes float, $K, $N;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;
      
my @CIT = ( 1.,2.,3.,4.,5.,6.,7.,8.,9.,0. );
my @LIT = ( 2, 2, 2, 2, 2, 2, 2, 2, 2, 0 );
      
&GETDAT ($Z, $K, my $M, $N) ;
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Change nice values to be steps of 1/3. (1/3, 2/3, 3/3...)
#     Draw labels at every 5th contour level no matter which contour
# level interval is chosen.
#
for my $I ( 1 .. 10 ) {
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$I);
&NCAR::cpsetr ('CIT - CONTOUR INTERVAL TABLE',$CIT[$I-1]);
&NCAR::cpseti ('LIT - LABEL INTERVAL TABLE',$LIT[$I-1]);
}
#
# Initialize Conpack
#
&NCAR::cprect($Z,$K,$M,$N,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Draw perimeter
#
&NCAR::cpback($Z, $RWRK, $IWRK);
#
# Draw Contours
#
&NCAR::cpcldr($Z,$RWRK,$IWRK);
#
# Close frame
#
&NCAR::frame();
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      
      
sub GETDAT {
  my ($Z, $K, $M, $N) = @_;
      
  my $M=$K;
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      set( $Z, $I-1, $J-1, 10.E-5*(-16.*($I*$I*$J) + 34*($I*$J*$J) - (6*$I) + 93.) );
    }
  }
  RETURN:
  $_[2] = $M;
  return;     
}   
rename 'gmeta', 'ncgm/ccpcit.ncgm';
