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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# Define a data array.
#
my $XYCD = zeroes float, 224;
#
# Define the centers and the expansion/shrinkage factors for
# various copies of the curve to be drawn.
#
#
my @FLOC = ( -38.1, -37.9, -38.0, -38.0 );
my @FLAC = (  32.0,  32.0,  31.9,  32.1 );
my @FMUL = (   1.7,   1.7,   1.7,   1.7 );
#
# Fill the data array.
#
open DAT, "<data/mpexfi.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/\s+/ /gmois;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  my @t = split /\s+/, $t;
  my $I = 1;
  while( @t ) {
    set( $XYCD, $I-1, shift( @t ) );
    $I++;
  }
}
close DAT;
#
# Define the altitude of the satellite.
#
&NCAR::mapstr ('SA',2.);
#
# Draw a map of the North Atlantic, as seen by a satellite.
#
&NCAR::supmap (7,32.,-38.,20.,
               float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       1,-1000,5,0,my $IERR);
#
# Force MAPIT to draw dotted lines.
#
&NCAR::mapsti ('DL',1);
&NCAR::mapsti ('DD',24);
#
# Draw some curves.
#
for my $I ( 1 .. 4 ) {
#
  my $IFST=0;
#
  for my $J ( 1 .. 112 ) {
    if( at( $XYCD, 2 * $J - 2 ) == 0 ) {
      $IFST=0;
    } else {
      my $FLON=$FLOC[$I-1]+$FMUL[$I-1]*(at( $XYCD, 2*$J-2)-15.);
      my $FLAT=$FLAC[$I-1]+$FMUL[$I-1]*(at( $XYCD, 2*$J-1)-15.);
      &NCAR::mapit ($FLAT,$FLON,$IFST);
      $IFST=1;
    }
  }
#
}
#
# Dump MAPIT's buffers.
#
&NCAR::mapiq();
#
# Draw a boundary around the edge of the plotter frame.
#
&NCAR::Test::bndary();
#

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpexfi.ncgm';
