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

sub bndary {
&NCAR::plotit(     0,     0, 0 );
&NCAR::plotit( 32767,     0, 1 );
&NCAR::plotit( 32767, 32767, 1 );
&NCAR::plotit(     0, 32767, 1 );
&NCAR::plotit(     0,     0, 1 );
}

sub fran {

  return rand( );

}


   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my ( @xdra, @ydra );

for my $i ( 1..500 ) {
  my $x = ( 2. * ( &fran() - .5 ) );
  my $y = ( 2. * ( &fran() - .5 ) );
  push @xdra, .5 + $x * $x * $x * $x * $x;
  push @ydra, .5 + $y * $y * $y * $y * $y;
}

&bndary();

&NCAR::agseti( 'FRAME.', 2 );
&NCAR::agseti( 'SET.', -1 );
&NCAR::ezxy( float( \@xdra ), float( \@ydra ), 500, 'EXAMPLE 11 (SCATTERGRAM)$' );

&NCAR::points( float( \@xdra ), float( \@ydra ), 500, -2, 0 );


&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


rename 'gmeta', 'ncgm/agex11.ncgm';
