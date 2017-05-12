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

unlink( 'gmeta' );

use PDL;
use NCAR::Test;

&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );


#
# Example illustrating polar coordinates using Streamlines
#
my ( @a, @b );
my ( $m, $n ) = ( 20, 36 );
my $WRK = zeroes float, 2 * $m * $n;
#
# Define a GKS color table
#
&dfclrs(1);
#
# Do the SET call, set the mapping mode and data coordinate boundaries
# appropriately for polar coordinate mapping
#
&NCAR::set (0.05,0.95,0.05,0.95,-20.0,20.0,-20.0,20.0,1);
&NCAR::stseti( 'MAP -- Mapping Mode', 2 );
&NCAR::stseti( 'SET -- Do Set Call', 0 );
&NCAR::stsetr( 'XC1 -- Lower X Bound', 1.0 );
&NCAR::stsetr( 'XCM -- Upper X Bound', 20.0 );
&NCAR::stsetr( 'YC1 -- Lower Y Bound', 0.0 );
&NCAR::stsetr( 'YCN -- Upper Y Bound', 360.0 );
#     CALL STSETI('TRT -- Transform Type', 1)
#
# Set up a uniform field parallel to the radius
#
for my $i ( 1 .. $m ) {
  for my $j ( 1 .. $n ) {
    $a[ $i - 1 ][ $j - 1 ] = 1.0;
    $b[ $i - 1 ][ $j - 1 ] = 0.0;
  }
}

my $stumsl = 0;
#
# Render the field using one color
#
&NCAR::gsplci(4);
&NCAR::stinit( float( \@a ), $m, float( \@b ), $m, 
               float( [ 0 ] ), 0, $m , $n , $WRK, 2 * $m * $n );
&NCAR::stream(float( \@a ), float( \@b ), float( [ 0 ] ), long( [ 0 ] ), $stumsl, $WRK ); 
#
# Set up a uniform field perpendicular to the radius
#
for my $i ( 1 .. $m ) {
  for my $j ( 1 .. $n ) {
    $a[ $i - 1 ][ $j - 1 ] = 0.0;
    $b[ $i - 1 ][ $j - 1 ] = 1.0;
  }
}
#
# Change the color and render the next field
#
&NCAR::gsplci(15);
&NCAR::stinit( float( \@a ), $m, float( \@b ), $m, 
               float( [ 0 ] ), 0, $m , $n , $WRK, 2 * $m * $n );
&NCAR::stream(float( \@a ), float( \@b ), float( [ 0 ] ), long( [ 0 ] ), $stumsl, $WRK ); 
#
# ==============================================================
#
sub dfclrs {
  my $iwkid = shift;
#
# Define a set of RGB color triples for colors 0 through 15.
#
  my $nclrs = 16;

#
# Define the RGB color triples needed below.
#
  my @rgbv = (
     [  0.00 , 0.00 , 0.00 ],
     [  1.00 , 1.00 , 1.00 ],
     [  0.70 , 0.70 , 0.70 ],
     [  0.75 , 0.50 , 1.00 ],
     [  1.00 , 0.00 , 1.00 ],
     [  0.00 , 0.00 , 1.00 ],
     [  0.00 , 0.50 , 1.00 ],
     [  0.00 , 1.00 , 1.00 ],
     [  0.00 , 1.00 , 0.60 ],
     [  0.00 , 1.00 , 0.00 ],
     [  0.70 , 1.00 , 0.00 ],
     [  1.00 , 1.00 , 0.00 ],
     [  1.00 , 0.75 , 0.00 ],
     [  1.00 , 0.38 , 0.38 ],
     [  1.00 , 0.00 , 0.38 ],
     [  1.00 , 0.00 , 0.00 ],
  );
#
# Define 16 different color indices, for indices 0 through 15.  The
# color corresponding to index 0 is black and the color corresponding
# to index 1 is white.
#

  for my $i ( 1 .. $nclrs ) {
      &NCAR::gscr ( $iwkid, $i-1, @{ $rgbv[$i-1] } );
  }
}



&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/stex01.ncgm';
