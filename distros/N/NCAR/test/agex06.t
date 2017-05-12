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

my @gwnd = (
      [ 0.0 , 0.5 , 0.5 , 1.0 ],
      [ 0.5 , 1.0 , 0.5 , 1.0 ],
      [ 0.0 , 0.5 , 0.0 , 0.5 ],
      [ 0.5 , 1.0 , 0.0 , 0.5 ],
);

my @back = (
       '(PERIMETER BACKGROUND)$',
       '(GRID BACKGROUND)$     ',
       '(HALF-AXIS BACKGROUND)$',
       '(NO BACKGROUND)$       ',
);
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my ( @xdra, @ydra );
for my $i ( 1 .. 501 ) {
  my $theta = .031415926535898 * ( $i - 1 );
  push @xdra, 500. + .9 * ( $i - 1 ) * cos( $theta );
  push @ydra, 500. + .9 * ( $i - 1 ) * sin( $theta );
}

&NCAR::agseti( 'FRAME.', 2 );

for my $igrf ( 1 .. 4 ) {
  &NCAR::agsetp( "GRAPH WINDOW.",  float( $gwnd[ $igrf - 1 ] ), 4 );
&NCAR::agseti( 'BACKGROUND TYPE.', $igrf );
  if( $igrf == 4 ) {
&NCAR::agseti( 'LABEL/CONTROL.', 2 );
  }
  my $illx = int( ( $igrf - 1 ) / 2 );
  my $illy =      ( $igrf - 1 ) % 2;
  
&NCAR::agseti( 'X/LOGARITHMIC.', $illx );
&NCAR::agseti( 'Y/LOGARITHMIC.', $illy );
  
  my $glab = sprintf( 'EXAMPLE 6- %d %s', $igrf, $back[ $igrf - 1 ] );
  
  my $xdra = float \@xdra;
  my $ydra = float \@ydra;
  
  &NCAR::ezxy( $xdra, $ydra, 501, $glab );
}

&bndary();
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



sub bndary {
  &NCAR::plotit(     0,     0, 0 );
  &NCAR::plotit( 32767,     0, 1 );
  &NCAR::plotit( 32767, 32767, 1 );
  &NCAR::plotit(     0, 32767, 1 );
  &NCAR::plotit(     0,     0, 1 );
}

rename 'gmeta', 'ncgm/agex06.ncgm';
