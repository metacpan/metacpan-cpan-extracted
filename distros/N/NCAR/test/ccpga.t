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

my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $K, $N, $LRWK, $LIWK ) = ( 30, 30, 1000, 1000 );      
my $Z = zeroes float, $K, $N;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;
      
&GETDAT ($Z, $K, my $M, $N) ;
# 
# Open GKS, open and activate a workstation.
# 
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Turn clipping off
#
&NCAR::gsclip (0);
#
# Set X and Y min and max values
#
&NCAR::cpsetr ('XC1 - X COORDINATE AT INDEX 1',2.0);
&NCAR::cpsetr ('XCM - X COORDINATE AT INDEX M',20.0);
&NCAR::cpsetr ('YC1 - Y COORDINATE AT INDEX 1',0.0);
&NCAR::cpsetr ('YCN - Y COORDINATE AT INDEX N',.01);
#     
# Make viewport slightly smaller so that labels will fit
#
&NCAR::cpsetr ('VPL - VIEWPORT LEFT',0.10);
&NCAR::cpsetr ('VPB - VIEWPORT BOTTOM',0.10);
#     
# Initialize Conpack
#
&NCAR::cprect($Z,$K,$M,$N,$RWRK,$LRWK,$IWRK,$LIWK);
#     
# Draw and label perimeter
#
&NCAR::labmod('(E7.2)','(E7.2)',0,0,10,10,0,0,1);
&NCAR::gridal($K-1,0,$N-1,0,1,1,5,0.,0.);
      
# Draw Contours
&NCAR::cpcldr($Z,$RWRK,$IWRK);
      
# Close frame and close GKS
#
&NCAR::frame();
# 
# Deactivate and close workstation, close GKS.
# 
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      
      
sub GETDAT {
  my ($Z, $K, $M, $N) = @_;;
      
  $M=$K;
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      set( $Z, $I-1, $J-1, 10.E-5*(-16.*($I*$I*$J) + 34*($I*$J*$J) - (6*$I) + 93.) );
    }
  }
  RETURN:
  $_[2] = $M;
  return;     
}
   
rename 'gmeta', 'ncgm/ccpga.ncgm';
