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

my ( $M, $N, $LRWK, $LIWK, $LZRG ) = ( 20, 30, 3500, 3500, 2000 );
my $X = zeroes float, $M;
my $Y = zeroes float, $N;
my $Z = zeroes float, $M, $N;
my $ZREG = zeroes float, $LZRG;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;

my $X = float [
           1.,  2.,  3.,  5.,  7., 11., 13., 17., 19., 23.,
          29., 31., 37., 41., 43., 47., 53., 59., 61., 67. ];

&GETDAT ($X, $Y, $Z, $M, $N) ;
#
# Open GKS
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Turn clipping off
#
&NCAR::gsclip(0);
#
# Limit viewport so there's room to mark the data points
#
&NCAR::cpsetr('VPR',.8);
#
# Initialize Conpack
#
&NCAR::cpsps2($X,$Y,$Z,$M,$M,$N,$RWRK,$LRWK,$IWRK,$LIWK,$ZREG,$LZRG);
#
# Draw perimiter
#
&NCAR::cpback($ZREG, $RWRK, $IWRK);
#
# Draw Contours
#
&NCAR::cpcldr($ZREG,$RWRK,$IWRK);
#
# Mark data points
#
&MARK ($X,$Y,$M,$N);
#
# Close frame and close GKS
#
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();

 
sub GETDAT {
  my ($X, $Y, $Z, $M, $N) = @_;
#
# X and Y data locations must be in increasing order.
#
  set( $Y, 0, 1 );
  for my $I ( 2 .. $N ) {
    set( $Y, $I-1, 1.1*at( $Y, $I-2 ) + 1./$I );
  }

  for my $I ( 1 .. $M ) {
    my $x = at( $X, $I-1 );
    for my $J ( 1 .. $N ) {
      my $y = at( $Y, $J-1 );
      set( $Z, $I-1, $J-1, 10.E-5*(-16.*($x**2*$y) + 34*($x*$y**2) - (6*$x) + 93.) );
    }
  }

}

sub MARK {
  my ($X, $Y, $M, $N) = @_;

  &NCAR::gsmksc(.5);

  for my $I ( 1 .. $M ) {
    for my $J ( 1 .. $N ) {
      &NCAR::points (at( $X, $I-1 ), at( $Y, $J-1 ), 1, -4, 0);
    }
  }

}      
   
rename 'gmeta', 'ncgm/ccpsps2.ncgm';
