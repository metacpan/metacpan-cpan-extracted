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
use NCAR::Test;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );
#
#  Data for picture two illustrating slope control at end points.
#
my $NV=5;
my @XV = ( 0.10, 0.30, 0.50, 0.70, 0.90 );
my @YV = ( 1.00, 1.08, 1.00, 0.95, 0.94 );
#
#  Define a color table.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.0);
&NCAR::gscr(1, 3, 0.0, 0.0, 1.0);
#
&NCAR::pcseti( 'CC', 1 );
&NCAR::plchhq(0.50,0.96,':F26:Slope control at endpoints',0.03,0.,0.);
#
#  Set some parameter values.
#
&NCAR::wmseti( 'NMS - number of symbols on front line', 6 );
&NCAR::wmsetr( 'SL1 - slope at start of front line if SLF=0 or 1', 0. );
&NCAR::wmsetr( 'SL2 - slope at end of front line if SLF=0 or 1', -15. );
&NCAR::wmseti( 'WFC - color for warm fronts', 1 );
&NCAR::wmsetr( 'LIN - line widths of front lines', 3. );
&NCAR::wmseti( 'REV - line widths of front lines', 1 );
&NCAR::wmseti( 'WFC - color for warm fronts', 2 );
&NCAR::pcseti( 'CC', 3 );

for my $i ( 3, 2, 1, 0 ) {
&NCAR::wmseti( 'SLF - flags whether slopes are from SL1 and SL2', $i );
  for my $j ( 1 .. $NV ) {
    $YV[ $j - 1 ] = $YV[ $j - 1 ] - 0.22;
  }
  &NCAR::wmdrft( $NV, float( \@XV ), float( \@YV ) );
  my $LABEL = sprintf( ':F22:SLF=%1d, SL1=0., SL2=-15.', $i );
  &NCAR::plchhq(.7, $YV[0]+.08,$LABEL,.024,0.,0.);
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex03.ncgm';
