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

my ( @ydra1, @ydra2 );

# Fill the data array.

for my $i ( 1 .. 100 ) {
  $ydra1[ $i - 1 ] = cos( 3.14159265358979 * $i / 25. ) * $i * $i;
  $ydra2[ $i - 1 ] = cos( 3.14159265358979 * $i / 25. ) 
                   * exp( 0.04 * $i * log( 10 ) );

}

my $ydra = float( [ \@ydra1, \@ydra2 ] );

# Draw a boundary around the edge of the plotter frame.

&bndary();

# Draw the graph, using EZMY.

&NCAR::ezmy( $ydra, 100, 2, 100, 'EXAMPLE 3 (EZMY)$' );


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


rename 'gmeta', 'ncgm/agex03.ncgm';
