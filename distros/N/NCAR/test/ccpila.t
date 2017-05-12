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
# Initialize Conpack
# 
&NCAR::cpsetr('HLA - HIGH/LOW LABEL ANGLE',30.);
&NCAR::cpsetr('ILA - INFORMATION LABEL ANGLE',90.);
&NCAR::cpsetr('ILX - INFORMATION LABEL X COORD',-0.02);
&NCAR::cpsetr('ILY - INFORMATION LABEL Y COORD',0.25);
&NCAR::cpseti('ILP - INFORMATION LABEL POSITION', 0);
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
  my ($Z, $K, $M, $N) = @_;
      
  my $L=$K;
  my @t;
  open DAT, "<data/ccpila.dat";
  {
    local $/ = undef;
    my $t = <DAT>;
    $t =~ s/^\s*//o;
    $t =~ s/\s*$//o;
    @t = split /\s+/, $t;
  }
  close DAT;
  for my $I ( 1 .. $L ) {
    for my $J ( 1 .. $N ) {
       set( $Z, $I-1, $J-1, shift( @t ) );
    }
  }
      
}
   
rename 'gmeta', 'ncgm/ccpila.ncgm';
