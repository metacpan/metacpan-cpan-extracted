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
      
&GETDAT ($Z, $K, my $M, $N) ;
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Set up color table
#
&COLOR($IWKID);
#     
# Call conpack normally
#
&NCAR::cprect($Z,$K,$M,$N,$RWRK,$LRWK,$IWRK,$LIWK);
&NCAR::cppkcl($Z, $RWRK, $IWRK);
#
# Set line color to red if it's negative, green if it's zero, 
# and blue if it's positive.
#
&NCAR::cpgeti('NCL - NUMBER OF CONTOUR LEVELS',my $NCON);
for my $I ( 1 .. $NCON ) {
  &NCAR::cpseti('PAI - PARAMETER ARRAY INDEX',$I);
  &NCAR::cpgetr('CLV - CONTOUR LEVEL VALUES',my $CVAL);
  if( $CVAL < 0 ) {
    &NCAR::cpseti('CLC - CONTOUR LINE COLOR INDEX',1);
  } elsif( $CVAL == 0 ) {
    &NCAR::cpseti('CLC - CONTOUR LINE COLOR INDEX',2);
  } else {
    &NCAR::cpseti('CLC - CONTOUR LINE COLOR INDEX',3);
  }
}
      
&NCAR::cpback($Z, $RWRK, $IWRK);
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
      
  $M=$K;
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      set( $Z, $I-1, $J-1, 10.E-5*(-16.*($I*$I*$J) +  34*($I*$J*$J) - (6*$I) + 93.) );
    }
  }
  RETURN:
  $_[2] = $M;
  return;      
}      

sub COLOR {
  my ($IWKID) = @_;
      
  &NCAR::gscr ($IWKID,0,1.,1.,1.);
  &NCAR::gscr ($IWKID,1,1.,0.,0.);
  &NCAR::gscr ($IWKID,2,0.,1.,0.);
  &NCAR::gscr ($IWKID,3,0.,0.,1.);
      
}
   
rename 'gmeta', 'ncgm/ccpclc.ncgm';
