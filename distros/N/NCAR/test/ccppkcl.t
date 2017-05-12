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

my ( $K, $N, $LRWK, $LIWK ) = ( 40, 40, 1000, 1000 );      
my $ZREG = zeroes float, $K, $N;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;
      
&GETDAT ($ZREG, $K, my $M, $N) ;
#     
# Open GKS
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
      
&NCAR::cpseti('CLS - CONTOUR LEVEL SELECTION FLAG',-20);
&NCAR::cprect($ZREG,$K,$M,$N,$RWRK,$LRWK,$IWRK,$LIWK);
#     
# Force contour lines to be chosen
#
&NCAR::cppkcl ($ZREG, $RWRK, $IWRK);
#
# Get the number of contour levels chosen
#
&NCAR::cpgeti ('NCL - NUMBER OF CONTOUR LEVELS',my $NOCL);
&NCAR::cpseti ('NCL - NUMBER OF CONTOUR LEVELS',$NOCL+1);
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$NOCL+1);
&NCAR::cpsetr ('CLV - CONTOUR LEVEL VALUE',0.0);
      
&NCAR::cpback($ZREG, $RWRK, $IWRK);
&NCAR::cpcldr($ZREG,$RWRK,$IWRK);
#     
# Close frame and close GKS
#
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      
sub GETDAT {
  my ($ZREG, $K, $M, $N) = @_;
      
  $M=$K;
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      set( $ZREG, $I-1, $J-1, 10.E-5*(-16.*($I*$I*$J) + 34*($I*$J*$J) - (6*$I) + 93.) );
    }
  }
  RETURN:
  $_[2] = $M;
  return;     
}      
   
rename 'gmeta', 'ncgm/ccppkcl.ncgm';
