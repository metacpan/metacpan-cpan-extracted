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
my ( $M, $N, $LWRK, $LIWK ) = ( 40, 40, 3500, 4000 );
my $Z = zeroes float, $M, $N;
my $RWRK = zeroes float, $LWRK;
my $IWRK = zeroes long, $LIWK;
      
&GETDAT ($Z, $M, $N);
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::gsclip (0);
#
# Initialize Conpack
#
&NCAR::cpsetr('CFX - CONSTANT FIELD LABEL X',0.);
&NCAR::cpsetr('CFY - CONSTANT FIELD LABEL Y',1.);
&NCAR::cpseti('CFP - CONSTANT FIELD POSITION FLAG',2);
&NCAR::cprect($Z, $M, $M, $N, $RWRK, $LWRK, $IWRK, $LIWK);
#
# Draw Perimeter
#
&NCAR::cpback($Z, $RWRK, $IWRK);
#
# Draw Contours
#
&NCAR::cplbdr($Z,$RWRK,$IWRK);
&NCAR::cpcldr($Z,$RWRK,$IWRK);
#
# Close frame
#
&NCAR::frame;
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      

sub GETDAT {
  my ($Z, $M, $N) = @_;
   
  for my $I ( 1 .. $M ) {   
    for my $J ( 1 .. $N ) { 
      set( $Z, $I-1, $J-1, 13 );  
    }
  }
      
}
   
rename 'gmeta', 'ncgm/ccpcfx.ncgm';
