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
#  Specify the text font and color for Plotchar.
#
&NCAR::pcseti( 'FN', 21 );
&NCAR::pcseti( 'CC', 1 );
#
#  Calculate the initial X start point to center the string.
#
my $STRING = 'NCAR Graphics';
&NCAR::pcseti( 'TE', 1 );
&NCAR::plchhq(0.,.5,$STRING,.1*6./7.,360.,-1.);
&NCAR::pcseti( 'TE', 0 );
&NCAR::pcgetr( 'XE', my $TRIGHT );
my $XSTART = .5*(1.-$TRIGHT);
#
#  Draw the characters and boxes around the character bodies.
#
my $LSTR = length($STRING);
my $XIN  = $XSTART;
my $YPOS = .475;
my ( $BOT, $TOP );
for my $I ( 1 .. $LSTR ) {
  &drwbod($XIN,$YPOS,substr( $STRING, $I - 1, 1 ),.1,my $XOUT,$TOP,$BOT);
  $XIN = $XOUT;
}
my $XEND = $XIN;

for my $I ( 1 .. $LSTR ) {
  &drwbod($XIN,$YPOS,substr( $STRING, $I - 1, 1 ),.1,my $XOUT,$TOP,$BOT);
  $XIN = $XOUT;
}
$XEND = $XIN;
#
#  Label the plot.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::plchhq(.5,.80,'Text Extent Rectangle',.040,0.,0.);
&NCAR::plchhq(.5,.72, 'A concatenation of character bodies',.035,0.,0.);
&NCAR::pcseti( 'FN', 21 );
&NCAR::plchhq(.5,.64, 'The hatched area shades the text extent rectangle',.025,0.,0.);


sub drwbod {
  my ($XIN,$Y,$CHR,$CHGT,$XOUT,$TOP,$BOT) = @_;
#
#  Draw the character in CHR left-centered at (XIN,Y) with character
#  height CHGT.  Draw a box around the character body.  Return the 
#  right of the character body in XOUT and the font top and bottom
#  in TOP and BOTTOM.
#
#
  my $CAP =  $Y+.5*$CHGT;
  my $BASE = $Y-.5*$CHGT;
  my $HALF = .5*($CAP+$BASE);
  $TOP = $HALF+.7*($CAP-$BASE);
  $BOT = $HALF-.8*($CAP-$BASE);
#
#  Convert the character height to width for Plotchar.
#
  my $CWIDTH = (6./7.)*($CAP-$BASE);
#
#  Compute the text extent information.
#
&NCAR::pcseti( 'TE', 1 );
  &NCAR::plchhq($XIN,$HALF,$CHR,$CWIDTH,360.,-1.);
&NCAR::pcseti( 'TE', 0 );
&NCAR::pcgetr( 'XB', my $TLEFT );
&NCAR::pcgetr( 'XE', my $TRIGHT );
#
#  Draw a box around the character body limits and hatch the interior.
#
  my @XB = (
    $TLEFT,
    $TRIGHT,
    $TRIGHT,
    $TLEFT,
    $TLEFT,
  );
  my @YB = (
    $BOT,
    $BOT,
    $TOP,
    $TOP,
    $BOT,
  );
  &NCAR::gslwsc(2.);
  &NCAR::gpl(5,float( \@XB ), float( \@YB ) );
  &NCAR::gsfais(3);
  &NCAR::gsfasi(6);
  &NCAR::gfa(5,float( \@XB ), float( \@YB ) );
  &NCAR::gslwsc(1.);
  &NCAR::gsfais(1);
#
#  Draw the character.
#
  &NCAR::plchhq($XIN,$HALF,$CHR,$CWIDTH,0.,-1.);
#
#  Return the right limit of the character body.
#
   $_[4] = $TRIGHT;
   $_[5] = $TOP;
   $_[6] = $BOT;
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex09.ncgm';
