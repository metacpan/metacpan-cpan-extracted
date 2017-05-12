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

for my $i ( 1 .. 4001 ) {
  my $theta = .0015707963267949 * ( $i - 1 );
  my $rho = sin( 2. * $theta ) + .05 * sin( 64. * $theta );
  push @xdra, $rho * cos( $theta );
  push @ydra, $rho * sin( $theta );
}

&bndary();
&NCAR::ezxy( float( \@xdra ), float( \@ydra ), 4001, 'EXAMPLE 2 (EZXY)$' );


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


rename 'gmeta', 'ncgm/agex02.ncgm';
