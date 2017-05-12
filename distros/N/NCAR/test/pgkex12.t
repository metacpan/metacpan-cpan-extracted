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
my $LABEL  = 'NCAR Graphics, Release 4.0';
#
#  Define colors.
#
&NCAR::gscr(1,0, 1.0, 1.0, 1.0);
&NCAR::gscr(1,1, 0.0, 0.0, 0.0);
&NCAR::gscr(1,2, 0.4, 0.0, 0.4);
#
#  Set up character attributes.
#
&NCAR::gschh(.022);
&NCAR::gstxal(2,3);
&NCAR::gstxci(1);
#
#  Loop through the Hershey fonts.
#
my $X = .5;
for my $I ( 1 .. 20 ) {
  my $Y = .02+.043*(20-$I);
&NCAR::pcseti( 'FN', $I );
  ( $I == 18 ) &&  ( $NCAR::PLOTCHAR{'r:AS'} = .25 );
  ( $I == 19 ) &&  ( $NCAR::PLOTCHAR{'r:AS'} = .5  );
  ( $I == 20 ) &&  ( $NCAR::PLOTCHAR{'r:AS'} = .25 );
  &NCAR::plchhq($X,$Y,$LABEL,.02,0.,0.);
}
#
#  Label the plot using Plotchar.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::pcsetr( 'AS', 0. );
&NCAR::plchhq(.5,.98,'Same string',.032,0.,0.);
&NCAR::plchhq(.5,.92,'using various fonts',.032,0.,0.);

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex12.ncgm';
