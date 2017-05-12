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
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $K, $N, $LRWK, $LIWK ) = ( 400, 400, 2000, 2000 );
my $Z = zeroes float, $K, $N;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;


&GETDAT ($Z, $K, my $M, $N) ;
#
# Open GKS
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Initialize Conpack
#
&NCAR::cprect($Z,$K,$M,$N,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Draw perimeter
#
&NCAR::cpback($Z, $RWRK, $IWRK);
#
# Turn on line labels for every line
#
&NCAR::cppkcl($Z, $RWRK, $IWRK);
&NCAR::cpgeti('NCL - NUMBER OF CONTOUR LEVELS', my $NCL);
for my $I ( 1 .. $NCL ) {
  &NCAR::cpseti('PAI - PARAMETER ARRAY INDEX',$I);
  &NCAR::cpseti('CLU - CONTOUR LEVEL USE FLAG',3);
}
#
# Set RWC so that labels come out on some lines
#
&NCAR::cpseti('RWC - REAL WORKSPACE FOR CONTOURS',125);
#
# Draw Contours
#
&NCAR::cpcldr($Z,$RWRK,$IWRK);
#
# Close frame and close GKS
#
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;


sub GETDAT {
  my ($Z, $K, $M, $N) = @_;

  $M=$K;
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      set( $Z, $I-1, $J-1, 10.E-8*(-16.*($I**2*$J) + 34*($I*$J**2) - (6*$I) + 93.) );
    }
  }
  RETURN:
  $_[2] = $M;
  return;
}


rename 'gmeta', 'ncgm/ccprwc.ncgm';
