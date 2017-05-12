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


my ( $M, $N ) = ( 21, 25 );
my $U = zeroes float, $M, $N;
my $V = zeroes float, $M, $N;
my $WRK = zeroes float, 2 * $M * $N;
my $IDM;
#
# IDM is a dummy variable for STINIT and STREAM.
#
# Generate some data
#
&MKDAT($U,$V,$M,$N);
#
# Select normalization transformation 0 (user coordinates are the same
# as NDC coordinates), so that title is drawn at top of plot.
#
&NCAR::gselnt (0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq (.5,.9765,'Example Streamlines Plot',16.,0.,0.);
#
# Define normalization transformation 1, and set up linear scaling.
#
&NCAR::set(0.1, 0.9, 0.1, 0.9,1.0, 21., 1.0, 25.,1);
#
# Tell Streamlines that SET has been called, and
# set spacing of stream lines.
#
&NCAR::stseti('SET -- Set Call Flag', 0);
&NCAR::stsetr('SSP -- Stream Spacing', 0.015);
#
# Initialize Streamlines, and draw streamlines
#
&NCAR::stinit($U,$M,$V,$M,float([0]),$IDM,$M,$N,$WRK,2*$M*$N);
&NCAR::stream($U,$V,float([]),long([]),$IDM,$WRK);

sub MKDAT {
  my ($U,$V,$M,$N) = @_;
#
# Specify horizontal and vertical vector components U and V on
# the rectangular grid. And set up a special value area near the
# center.
#
  my $TPIMX = 2.*3.14/$M;
  my $TPJMX = 2.*3.14/$N;
  for my $J ( 1 .. $N ) {
    for my $I ( 1 .. $M ) {
      set( $U, $I-1, $J-1, sin( $TPIMX * ( $I-1 ) ) );
      set( $V, $I-1, $J-1, sin( $TPJMX * ( $J-1 ) ) );
    }
  }
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fstream.ncgm';
