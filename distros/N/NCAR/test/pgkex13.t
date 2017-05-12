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

my @XP = ( .5,2. );
#
#  Define colors.
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,1.);
&NCAR::gscr(1,2,.4,.0,.4);
#
#  Alignment = [center, center]
#
&NCAR::gstxal(2,3);
#
#  Character spacings.
#
my $Y = .95;
for my $I ( 0 .. 2 ) {

  my $SPACNG = 0.5*$I;
  my $LABEL = sprintf( ' Spacing = %4.1f ', $SPACNG );
#
#  Attributes for the label for the demo text string.
#
  &NCAR::gstxfp(-12,2);
  &NCAR::gschh(.033);
  &NCAR::gstxci(2);
  &NCAR::gschsp(0.);
  &NCAR::gtx(.5,$Y,$LABEL);
  $Y = $Y-.08;
#
#  Attributes for the demo string.
#
  &NCAR::gschh(.04);
  &NCAR::gschsp($SPACNG);
  &NCAR::gstxfp(-13,2);
  &NCAR::gstxci(1);
  &NCAR::gtx(.5,$Y,'NCAR Graphics');
  $Y = $Y-.12;
}
#
#  Character expansion factors.
#
for my $I ( 1 .. 2 ) {
  my $CEXP = $XP[$I-1];
  my $LABEL = sprintf( 'Expansion = %4.1f', $CEXP );
#
#  Attributes for the label for the demo text string.
#
  &NCAR::gstxfp(-12,2);
  &NCAR::gschh(.033);
  &NCAR::gstxci(2);
  &NCAR::gschsp(0.);
  &NCAR::gschxp(1.);
  &NCAR::gtx(.5,$Y,$LABEL);
  $Y = $Y-.08;
#
#  Attributes for the demo string.
#
  &NCAR::gschh(.04);
  &NCAR::gschxp($CEXP);
  &NCAR::gstxfp(-13,2);
  &NCAR::gstxci(1);
  &NCAR::gtx(.5,$Y,'NCAR Graphics');
  $Y = $Y-.12;
}



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex13.ncgm';
