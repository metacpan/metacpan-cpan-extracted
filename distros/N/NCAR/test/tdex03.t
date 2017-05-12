# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use NCAR;
$loaded = 1;
print "ok 1\n";

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

unlink( 'gmeta' );

use PDL;
use NCAR::Test qw( bndary gendat drawcl );
use strict;
#
#  Illustrate the use of the simplified entry points for Tdpack, 
#  TDEZ2D and TDEZ3D, by drawing a surface and an isosurface.
#
#  Define the error file, Fortran unit number, workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Declare arrays for the surface.
#
my ( $NSX, $NSY ) = ( 29, 25 );
my $XS = zeroes float, $NSX;
my $YS = zeroes float, $NSY;
my $ZS = zeroes float, $NSX, $NSY;
#
#  Declare arrays for the isosurface.
#
my ( $NIX, $NIY, $NIZ ) = ( 21, 31, 19 );
my $XI = zeroes float, $NIX;
my $YI = zeroes float, $NIY;
my $ZI = zeroes float, $NIZ;
my $UI = zeroes float, $NIX, $NIY, $NIZ;
#
#  Define some constants used in the isosurface creation.
#
my ( $RBIG1,$RBIG2,$RSML1,$RSML2 ) = ( 6.,6.,2.,2. );
#
#  Open GKS, open workstation, activate workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Create the data array for the 2-dimensional surface.
#

sub Pow {
  my ( $x, $y ) = @_;
  return 0 unless( $x );
  return exp( $y * log( $x ) );
}

for my $I ( 1 .. $NSX ) {
  my $NSXH = int($NSX/2);
  my $xs = 0.1*($I-$NSXH-1);
  set( $XS, $I-1, $xs );
  for my $J ( 1 .. $NSY ) {
    my $NSYH = int($NSY/2);
    my $ys = 0.1*($J-$NSYH-1);
    set( $YS, $J-1, $ys );
    my $zs = $xs + $ys;
    my $T1 = 1.0/(
                   &Pow( abs($xs-0.1), 2.75 )
                 + &Pow( abs($ys    ), 2.75 )
                 + 0.09
                 );
    my $T2 = 1.0/(
                   &Pow( abs($xs+0.1), 2.75 )
                 + &Pow( abs($ys    ), 2.75 )
                 + 0.09
                 );
    $zs = 0.3*($zs+$T1-$T2);
    set( $ZS, $I-1, $J-1, $zs );
  }
}
#
#  Draw the surface.
#
&NCAR::tdez2d($NSX,$NSY,$XS,$YS,$ZS,2.5,-154.,80.,6);
&NCAR::frame();
#
#  Create the data array for the isosurface.
#
my $JCENT1 = ($NIY)*.5-$RBIG1*.5;
my $JCENT2 = ($NIY)*.5+$RBIG2*.5;
for my $I ( 1 .. $NIX ) {
  set( $XI, $I-1, $I );
  my $FIMID = $I-$NIX/2;
  for my $J ( 1 .. $NIY ) {
    set( $YI, $J-1, $J );
    my $FJMID1 = $J-$JCENT1;
    my $FJMID2 = $J-$JCENT2;
    for my $K ( 1 .. $NIZ ) {
      set( $ZI, $K-1, $K );
      my $FKMID = $K-$NIZ/2;
      my $F1 = sqrt($RBIG1*$RBIG1/($FJMID1*$FJMID1+$FKMID*$FKMID+.1));
      my $F2 = sqrt($RBIG2*$RBIG2/($FIMID*$FIMID+$FJMID2*$FJMID2+.1));
      my $FIP1 = (1.-$F1)*$FIMID;
      my $FIP2 = (1.-$F2)*$FIMID;
      my $FJP1 = (1.-$F1)*$FJMID1;
      my $FJP2 = (1.-$F2)*$FJMID2;
      my $FKP1 = (1.-$F1)*$FKMID;
      my $FKP2 = (1.-$F2)*$FKMID;
      set( $UI, $I-1, $J-1, $K-1, 
           &NCAR::Test::min(
             $FIMID*$FIMID+$FJP1*$FJP1+$FKP1*$FKP1-$RSML1*$RSML1,
             $FKMID*$FKMID+$FIP2*$FIP2+$FJP2*$FJP2-$RSML2*$RSML2
           )
      );
     }
  }
}
#
#  Draw the isosurface.
#
&NCAR::tdez3d($NIX,$NIY,$NIZ,$XI,$YI,$ZI,$UI,0.,1.8,-45.,58.,-4);
&NCAR::frame();
#
#  Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


rename 'gmeta', 'ncgm/tdex03.ncgm';
