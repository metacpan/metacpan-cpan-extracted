# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my ( @xdra, @ydra );


for my $i ( 1 .. 201 ) {
  push @xdra, -1. + .02 * ( $i - 1 );
  if( $i > 101 ) {
    $xdra[-1] = 2 - $xdra[-1];
  }
  for my $j ( 1 .. 10 ) {
    push @{ $ydra[ $j - 1 ] },
         $j * sqrt( 1.000000000001 - $xdra[ -1 ] * $xdra[ -1 ] ) / 10;
    if( $i > 101 ) {
      $ydra[ $j - 1 ][ -1 ] = - $ydra[ $j - 1 ][ -1 ];
    }
  }
}

my $xdra = float \@xdra;
my $ydra = float \@ydra;

&bndary();

&NCAR::ezmxy( $xdra, $ydra, 201, 10, 201, 'EXAMPLE 4 (EZMXY)$');

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


sub bndary {
&NCAR::plotit(     0,    0,0 );
&NCAR::plotit( 32767,    0,1 );
&NCAR::plotit( 32767,32767,1 );
&NCAR::plotit(     0,32767,1 );
&NCAR::plotit(     0,    0,1 );
}

rename 'gmeta', 'ncgm/agex04.ncgm';
