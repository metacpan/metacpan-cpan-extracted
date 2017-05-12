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
#       $Id: ftex06.f,v 1.2 1998/06/24 23:40:20 fred Exp $
#
#
#  Example of SURF1/SURF2.
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
my ( $NXI, $NYI, $NXO, $NYO ) = ( 11, 17, 31, 21 );
my $IDTEMP = 2*$NYI+$NXI;
#
my $X = zeroes float, $NXI;
my $Y = zeroes float, $NYI;
my $Z = zeroes float, $NXI, $NYI;
my $ZX1 = zeroes float, $NYI;
my $ZXM = zeroes float, $NYI;
my $ZY1 = zeroes float, $NXI;
my $ZYN = zeroes float, $NXI;
my $ZP = zeroes float, $NXI, $NYI, 3;
my $TEMP = zeroes float, $IDTEMP;
my $XO = zeroes float, $NXO;
my $YO = zeroes float, $NYO;
my $ZO = zeroes float, $NXO, $NYO;
#
# Declare a function ZF(U,V) that defines a surface.
#
sub ZF {
  my ( $U, $V ) = @_;
  return .5+.25*sin(-7.*$U)+.25*cos(5.*$V);
}
#
# Define the surface to be drawn.
#
for my $I ( 1 .. $NXI ) {
  set( $X, $I-1, ($I-1)/($NXI-1) );
  for my $J ( 1 .. $NYI ) {
    set( $Y, $J-1, ($J-1)/($NYI-1) );
    set( $Z, $I-1, $J-1, &ZF( at( $X, $I-1 ), at( $Y, $J-1 ) ) );
  }
}
#
#  Do SURF1 set up.
#
my $SIGMA = 1.;
my $ISF   = 255;
&NCAR::surf1($NXI,$NYI,$X,$Y,$Z,$NXI,$ZX1,$ZXM,$ZY1,$ZYN,
           my ( $ZXY11,$ZXYM1,$ZXY1N,$ZXYMN ),$ISF,$ZP,$TEMP,$SIGMA,my $IERR);
if( $IERR != 0 ) {
  print STDERR "Error return from SURF =$IERR\n";
  exit( 0 );
}
#
#  Get interpolated points using SURF2.
#
my $TINCX = 1.0/($NXO-1);
my $TINCY = 1.0/($NYO-1);
for my $I ( 1 .. $NXO ) {
  my $xo = ($I-1)*$TINCX;
  set( $XO, $I-1, $xo );
  for my $J ( 1 .. $NYO ) {
    my $yo = ($J-1)*$TINCY;
    set( $YO, $J-1, $yo );
    set( $ZO, $I-1, $J-1, &NCAR::surf2($xo,$yo,$NXI,$NYI,$X,$Y,$Z,$NXI,$ZP,$SIGMA) );
  }
}

#
#  Plot a surface.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::tdez2d($NXO, $NYO, $XO, $YO, $ZO, 3., 36., 67., -6);
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#

rename 'gmeta', 'ncgm/ftex06.ncgm';

