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
my ( $M, $N, $LRWK, $LIWK, $LZDT ) = ( 30, 30, 3500, 3500, 2000 );
my ( $THETMN, $THETMX, $RHOMN, $RHOMX ) = ( 25, 124, 0.5, 5 );
my $Z = zeroes float, $M, $N;
my $RWRK = zeroes float, $LRWK;      
my $IWRK = zeroes long, $LIWK;
# 
# Generate some data to contour
# 
my @t;
open DAT, "<data/ccpcir.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
  for my $J ( 1 .. $N ) {
for my $I ( 1 .. $M ) {
    set( $Z, $I-1, $J-1, shift( @t ) );
  }
}
close DAT;
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
# 
# Turn off clipping.
# 
&NCAR::gsclip (0);
# 
# 
# Tell CONPACK that the SET call has been done, force it to generate X
# coordinates that are longitudes and Y coordinates that are latitudes,
# turn on mapping to an EZMAP background. Define the out-of-range value
# (returned by MAPTRN for an unprojectable point).
# 
&NCAR::set (0.05,0.95,0.05,0.95,-$RHOMX,$RHOMX,-$RHOMX,$RHOMX,1);
&NCAR::cpseti ('SET - DO SET-CALL FLAG',0);
&NCAR::cpsetr ('XC1 - X COORDINATE AT INDEX 1',$RHOMN);
&NCAR::cpsetr ('XCM - X COORDINATE AT INDEX M',$RHOMX);
&NCAR::cpsetr ('YC1 - Y COORDINATE AT INDEX 1',$THETMN);
&NCAR::cpsetr ('YCN - Y COORDINATE AT INDEX N',$THETMX);
&NCAR::cpseti ('MAP - MAPPING FLAG',2);
# 
# Initialize the drawing of the first contour plot.
# 
&NCAR::cprect ($Z,$M,$M,$N,$RWRK,$LRWK,$IWRK,$LIWK);
# 
# Draw Contours
# 
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
      

   
rename 'gmeta', 'ncgm/ccpcir.ncgm';
