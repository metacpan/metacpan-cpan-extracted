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
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  Set up color table.
#
&NCAR::gscr(1, 0, 0.87, 0.87, 1.00);
&NCAR::gscr(1, 1, 0.00, 0.00, 0.00);
&NCAR::gscr(1, 2, 0.00, 0.00, 1.00);
&NCAR::gscr(1, 3, 1.00, 1.00, 1.00);
&NCAR::gscr(1, 4, 1.00, 1.00, 0.00);
&NCAR::gscr(1, 5, 1.00, 0.65, 0.00);
#
#  Sun.
#
&NCAR::wmseti( 'SC1 - color of the center', 4 );
&NCAR::wmseti( 'SC2 - color of the star points', 5 );
&NCAR::wmseti( 'SC3 - color of the outlines', 1 );
&NCAR::wmseti( 'SC4 - shadow color', 1 );
&NCAR::wmsetr( 'SHT - size of sun', .0375 );
&NCAR::wmlabs(0.27, 0.65, 'SU');
#
#  Cloud.
#
&NCAR::wmseti( 'CC1 - primary color', 3 );
&NCAR::wmseti( 'CC2 - outline color', 1 );
&NCAR::wmseti( 'CC3 - shadow color', 1 );
&NCAR::wmsetr( 'SHT - size of cloud', 0.047 );
&NCAR::wmlabs(0.55, 0.33, 'C');
#
#  Title.
#
&NCAR::plchhq(.52,.78,':F26:NCAR',.076,0.,-1.);
&NCAR::plchhq(.52,.67,':F26:Graphics',.0555,0.,-1.);
#
#  Waves.
#
my $WAVSIZ = .15;
&NCAR::pcseti( 'CC', 2 );
&NCAR::pcseti( 'TE', 1 );
&NCAR::plchhq(.5,.2,':F37:n',$WAVSIZ,360.,0.);
&NCAR::pcseti( 'TE', 0 );
&NCAR::pcgetr( 'DL', my $XL );
&NCAR::pcgetr( 'DR', my $XR );
my $XWID = $XL+$XR;
#
my $XB = .2;
&NCAR::gslwsc(6.0);

for my $i ( 1 .. 4 ) {
  &NCAR::plchhq ($XB,.15,':F37:n',$WAVSIZ,0.,0.);
  $XB = $XB+$XWID;
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex08.ncgm';
