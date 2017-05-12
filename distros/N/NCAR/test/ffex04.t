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

my ( $m, $n, $npr ) = ( 20, 36, 155 );
my ( @u, @v );
my $W = zeroes float, 2 * $m * $n;

#
&NCAR::stsetr( 'DFM -- Differential Magnitude', 0.01 );
#
&NCAR::stseti( 'MAP -- Mapping Mode', 2 );
&NCAR::stsetr( 'WDL -- Window Left', -20.0 );
&NCAR::stsetr( 'WDR -- Window Right', 20.0 );
&NCAR::stsetr( 'WDB -- Window Bottom', -20.0 );
&NCAR::stsetr( 'WDT -- Window Top', 20.0 );
&NCAR::stsetr( 'XC1 -- Lower X Bound', 1.0 );
&NCAR::stsetr( 'XCM -- Upper X Bound', 20.0 );
&NCAR::stsetr( 'YC1 -- Lower Y Bound', 0.0 );
&NCAR::stsetr( 'YCN -- Upper Y Bound', 360.0 );
#     

my ( $U, $V );

for my $k ( 1, 0, -1 ) {
#
&NCAR::stseti( 'TRT -- Transform Type', $k );
#

for my $i ( 1 .. $m ) {
  for my $j ( 1 .. $n ) {
     $u[ $i - 1 ][ $j - 1 ] = 1.0;
     $v[ $i - 1 ][ $j - 1 ] = 0.0;
  }
}
#

$U = float( \@u );
$V = float( \@v );

&NCAR::stinit( $U, $m, $V, $m, float( [ 0 ] ), $idm, $m, $n, $W, 2 * $m * $n );
&NCAR::stream( $U, $V, float([]), long([]), $idm, $W );

#
for my $i ( 1 .. $m ) {
  for my $j ( 1 .. $n ) {
     $u[ $i - 1 ][ $j - 1 ] = 0.0;
     $v[ $i - 1 ][ $j - 1 ] = 1.0;
  }
}
#


$U = float( \@u );
$V = float( \@v );

&NCAR::stinit( $U, $m, $V, $m, float( [ 0 ] ), $idm, $m, $n, $W, 2 * $m * $n );
&NCAR::stream( $U, $V, float([]), long([]), $idm, $W );

&NCAR::perim(1,0,1,0);
&NCAR::frame();

}

#

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/ffex04.ncgm';
