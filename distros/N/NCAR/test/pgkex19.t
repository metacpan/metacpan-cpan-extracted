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
#
#  Draw three rows and four columns of square boxes.
#
my $NUM = 0;
for my $J ( 1 .. 3 ) {
  my $Y = 0.25*($J-1);
  for my $I ( 1 .. 4 ) {
    $NUM = $NUM+1;
    my $LAB = sprintf( '%3i', $NUM );
    my $X = 0.25*($I-1);
    &BOX($X, $Y, 0.25, $LAB);
  }
}
&NCAR::frame;

sub BOX {
  my ($X,$Y,$SZ,$LAB) = @_;
#
#  Draw box.
#
  my $A = float [ $X, $X+$SZ, $X+$SZ, $X, $X ];
  my $B = float [ $Y, $Y, $Y+$SZ, $Y+$SZ, $Y ];
  &NCAR::gpl(5,$A,$B);
#
#  Write label in box.
#
  &NCAR::gschh(0.25*$SZ);
  &NCAR::gstxal(2,3);
  &NCAR::gtx($X+.5*$SZ, $Y+.5*$SZ, $LAB);
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/pgkex19.ncgm';
