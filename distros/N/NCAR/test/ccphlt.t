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

my @t;      
open DAT, "<data/ccphlt.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
for my $J ( 1 .. $N ) {
  for my $I ( 1 .. $M ) {
    set( $Z, $I-1, $J-1, shift( @t ) );
  }
}
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
&NCAR::cpsetc('HLT - HIGH/LOW TEXT','Local High ($ZDV$)\'Local Low ($ZDV$)');
&NCAR::cpseti('HLX - HIGH/LOW SEARCH RADIUS IN X',3);
&NCAR::cpseti('HLY - HIGH/LOW SEARCH RADIUS IN Y',2);
&NCAR::cpsetr('HLL - HIGH/LOW LINE WIDTH',3.0);
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
&NCAR::cpcldr($Z,$RWRK,$IWRK);
&NCAR::cplbdr($Z,$RWRK,$IWRK);
#     
# Close frame and close GKS
#
&NCAR::frame();
# 
# Deactivate and close workstation, close GKS.
# 
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;
      
   
rename 'gmeta', 'ncgm/ccphlt.ncgm';
