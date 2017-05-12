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


my ( @xdra, @ydra, @work, @iwrk );

# Fill the data arrays.  First, we define the histogram
# outline.  This will be used in the call to SFWRLD which
# fills in the area under the histogram.

  $xdra[0] = 0.;
  $ydra[0] = 0.;

  for( my $i = 2; $i <= 100; $i += 2 ) {
     $xdra[ $i - 1 ] = $xdra[ $i - 2 ];
     $ydra[ $i - 1 ] = exp( 
                            -16. * ( ( $i / 2. ) / 50. - .51 )  
                                 * ( ( $i / 2. ) / 50. - .51 )
                          )
                            + 0.1 * rand();
     $xdra[ $i ] = $xdra[ $i - 2 ] + 0.02;
     $ydra[ $i ] = $ydra[ $i - 1 ];
  }

  $xdra[ 101 ] = 1.;
  $ydra[ 101 ] = 0.;
 

# Define lines separating vertical boxes from each other.

  my $ndra = 101; 

  for( my $i = 3; $i <= 99; $i += 2 ) {
        $xdra[ $ndra+1 ]=1.E36;
        $ydra[ $ndra+1 ]=1.E36;
        $xdra[ $ndra+2 ]= $xdra[ $i-1 ];
        $ydra[ $ndra+2 ]=0.;
        $xdra[ $ndra+3 ]= $xdra[ $i-1 ];
        $ydra[ $ndra+3 ]= &amin1( $ydra[ $i-1 ], $ydra[ $i ] );
        $ndra=$ndra+3;
  }
  &bndary();

# Suppress the frame advance.

&NCAR::agseti( 'FRAME.', 2 );

# Draw the graph, using EZXY.

  $_ ||= 0 for( @xdra );
  $_ ||= 0 for( @ydra );

  my $xdra = float( \@xdra );
  my $ydra = float( \@ydra );


  &NCAR::ezxy( float( \@xdra ), float( \@ydra ), 249, 'EXAMPLE 12 (HISTOGRAM)$' );

# Use the package SOFTFILL to fill the area defined by the
# data.

&NCAR::sfseti( 'AN', 45 );
&NCAR::sfsetr( 'SP', .004 );
  
  my $work = zeroes float, 204;
  my $iwrk = zeroes long, 204;
  
  &NCAR::sfwrld( float( \@xdra ), float( \@ydra ), 102, $work, 204, $iwrk, 204 );

# Advance the frame.

sub fran {
  return rand();
}

# Routine to draw the plotter-frame edge.


sub bndary {
&NCAR::plotit(     0,    0,0 );
&NCAR::plotit( 32767,    0,1 );
&NCAR::plotit( 32767,32767,1 );
&NCAR::plotit(     0,32767,1 );
&NCAR::plotit(     0,    0,1 );
}

sub amin1 {
return $_[0] <= $_[1] ? $_[0] : $_[1];
}





&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


rename 'gmeta', 'ncgm/agex12.ncgm';
