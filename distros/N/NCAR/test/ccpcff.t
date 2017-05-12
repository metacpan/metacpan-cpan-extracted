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
my ( $M, $N, $LRWK, $LIWK ) = ( 40, 40, 3500, 4000 );
my $Z = zeroes float, $M, $N;
my $RWRK = zeroes float, $LRWK;
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
&NCAR::cprect($Z, $M, $M, $N, $RWRK, $LRWK, $IWRK, $LIWK);
&NCAR::cpgeti('CFF - CONSTANT FIELD FOUND FLAG',my $ICFF);
if( $ICFF != 0 ) { goto L101; }
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
# Close frame and close GKS
#
&NCAR::frame();
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();

      
L101:
print STDERR "
The field is constant.
This program does not create a valid CGM file.
";

sub GETDAT {
  my ($Z, $M, $N) = @_;   
      
  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      set( $Z, $I-1, $J-1, 13 );
    }
  }
      
}
   
rename 'gmeta', 'ncgm/ccpcff.ncgm';
