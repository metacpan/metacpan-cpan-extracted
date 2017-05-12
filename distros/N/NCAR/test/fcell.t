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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  Produce an NX x NY  CELL ARRAY based on the Mandelbrot set--color
#  the cells depending upon the speed of convergence or divergence.
#
my ( $NX, $NY, $NITER ) = ( 50, 50, 201 );
my $COLIA = zeroes long, $NX, $NY;
use Math::Complex qw();
#
#  Region of interest.
#
#     DATA XL,XR,YB,YT/-0.1,.5,-0.,1.00/
my ( $XL,$XR,$YB,$YT ) = ( .25,.375,-0.,0.50 );

&NCAR::gswn(1,$XL,$XR,$YB,$YT);
&NCAR::gsvp(1,0.,1.,0.,1.);
&NCAR::gselnt(1);
#
#  Define color indices in a continuous spectrum.
#
for my $K ( 1 .. $NITER ) {
  my $ H = $K/$NITER*360.;
#       CALL HLSRGB(H,50.,100.,RV,GV,BV)
  &NCAR::hlsrgb($H,50.,100., my ( $RV,$GV,$BV ) );
  &NCAR::gscr(1,$K,$RV,$GV,$BV);
}
&NCAR::gscr(1,$NITER+1,1.,0.,0.);
#
#  Set up the cell array and call GFA.
#
my $DX = ($XR-$XL)/$NX;
my $DY = ($YT-$YB)/$NY;
for my $J ( 1 .. $NY ) {
  my $Y = $YB+$DY*($J-1);
  for my $I ( 1 .. $NX ) {
    my $X = $XL+$DX*($I-1);
    my $Z = Math::Complex->make( $X, $Y );
    &CONVG($Z,$NITER,.001,10000.,my $ITER);
    set( $COLIA, $I-1, $J-1, $ITER );
  }
}
&NCAR::gca($XL,$YB,$XR,$YT,$NX,$NY,1,1,$NX,$NY,$COLIA);
&NCAR::frame;

sub CONVG {
  my ($Z,$NUM,$TOLSM,$TOLLG,$ITER) = @_;
#
#  Iterate Z(N+1) = Z(N)**2+Z0 for N=1,...,NUM .  If the complex absolute
#  values get smaller than TOLSM, then set ITER equal to the number of
#  iterations and return.  If the complex absolute value gets larger than
#  TOLLG, set ITER to NUM and return.
#
  my $ZS = $Z;
  my $ZO = $Z;
  for my $I ( 1 .. $NUM ) {
    my $ZN = $ZO*$ZO+$ZS;
    if( abs( $ZN - $ZO ) < $TOLSM ) {
      $ITER = $I;
      $_[4] = $ITER;
      return;
    } elsif( abs( $ZN - $ZO ) > $TOLLG ) {
      $ITER = $I;
      $_[4] = $ITER;
      return;
    }
    $ZO = $ZN;
  }
  $ITER=$NUM;
  $_[4] = $ITER;
}
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fcell.ncgm';
