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
my ( $M, $N, $LRWK, $LIWK ) = ( 40, 40, 3500, 4000 );      
my $Z = zeroes float, $M, $N;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;

      
&GETDAT ($Z, $M, $M, $N);
# 
# Open GKS, open and activate a workstation.
# 
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::gsclip (0);
#
# Set up label options
#
&NCAR::cpsetc('ILT - INFORMATION LABEL TEXT','Modified Sine Function Contoured from $CMN$ to $CMX$ by $CIU$');
&NCAR::cpsetr('ILX - INFORMATION LABEL X COORDINATE',.5);
&NCAR::cpseti('ILP - INFORMATION LABEL POSITION',0);
#
# Initialize Conpack
#
&NCAR::cprect($Z, $M, $M, $N, $RWRK, $LRWK, $IWRK, $LIWK);
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
&NCAR::frame();
# 
# Deactivate and close workstation, close GKS.
# 
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;
      
sub GETDAT {
  my ($Z, $K, $M, $N) = @_;

  my @t;
  open DAT, "<data/ccpex.dat";
  {
    local $/ = undef;
    my $t = <DAT>;
    $t =~ s/^\s*//o;
    $t =~ s/\s*$//o;
    @t = split /\s+/, $t;
  }
  close DAT;

  my $L=$K;
  for my $I ( 1 .. $L ) {
    for my $J ( 1 .. $N ) {
      set( $Z, $I-1, $J-1, shift( @t ) );
    }
  }
  RETURN:
  return;      
}
   
rename 'gmeta', 'ncgm/ccpilt.ncgm';
