# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; };
END {print "not ok 1\n" unless $loaded;};
use NCAR;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use PDL;
use NCAR::Test;


&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my $pi = 3.14159; ;
my $msize = 21;
my $nsize = 25; 
my $iwsize = 2* $msize * $nsize;

my ( @u, @v );

#
# Set the grid dimensions.
#
my $m = $msize;
my $n = $nsize;
 
#
# Specify horizontal and vertical vector components U and V on
# the rectangular grid.
#

my $gisize = 2. * $pi / $m;
my $gjsize = 2. * $pi / $n;

for my $j ( 1 .. $n ) {
  for my $i ( 1 .. $m ) {
     $u[ $j - 1 ][ $i - 1 ] = cos( $gisize * ( $i - 1 ) );
     $v[ $j - 1 ][ $i - 1 ] = cos( $gjsize * ( $j - 1 ) );
  }
}
#
# Draw the field with streamlines overlaid on vectors
#

my $idm = 0;
my $rdm = 0;

my $U = float( \@u );
my $V = float( \@v );
my $W = zeroes float, 10000;


&NCAR::vvinit( $U, $m, $V, $m, float( [ 0 ] ), $idm, $m, $n, float( [ 0 ] ), $idm);
&NCAR::vvectr( $U, $V, float([]), long([]), $idm, float([]) );
&NCAR::stinit( $U, $m, $V, $m, float( [ 0 ] ), $idm, $m, $n, $W, $iwsize );
&NCAR::stream( $U, $V, float( [ 0 ] ), long([]), $idm, $W );
&NCAR::perim(1,0,1,0);
&NCAR::frame;
#
# Draw just the vectors
# 
#


 $idm = 0;
 $rdm = 0;

&NCAR::vvinit( $U, $m, $V, $m, float( [ 0 ] ), $idm, $m, $n, float( [ 0 ] ), $idm);
&NCAR::vvectr( $U, $V, float([]), long([]), $idm, float([]) );
&NCAR::perim(1,0,1,0);
&NCAR::frame;
#
# Draw just the streamlines
#


 $idm = 0;
 $rdm = 0;

&NCAR::stinit( $U, $m, $V, $m, float( [ 0 ] ), $idm, $m, $n, $W, $iwsize);
&NCAR::stream( $U, $V, float([]), long([]), $idm, $W );
&NCAR::perim(1,0,1,0);
&NCAR::frame;


&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


rename 'gmeta', 'ncgm/ffex01.ncgm';
