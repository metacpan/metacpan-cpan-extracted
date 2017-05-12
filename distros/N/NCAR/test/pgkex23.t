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
#  Illustrate changing spacing between hatch pattern lines.
#
my @XL = ( 0.05, 0.55, 0.05, 0.55 );
my @XR = ( 0.45, 0.95, 0.45, 0.95 );
my @YT = ( 0.90, 0.90, 0.40, 0.40 );
my @YB = ( 0.50, 0.50, 0.00, 0.00 );
my @IHATCH = ( 1, 1, 3, 6 );
my @RSPACE = ( 0.01, 0.02, 0.03, 0.05 );
#
#  Set up color table.
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,0.);
&NCAR::gscr(1,2,0.,0.,1.);
#
&NCAR::gsfais(3);
&NCAR::ngseti( 'Workstation ID', 1 );
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 1 );
for my $I ( 1 .. 4 ) {
&NCAR::gsfais(3);
&NCAR::gsfasi($IHATCH[$I-1]);
&NCAR::ngsetr( 'Hatch spacing', $RSPACE[$I-1] );
&ZIGZAG($XL[$I-1],$XR[$I-1],$YB[$I-1],$YT[$I-1]);
&NCAR::gsfais(1);
my $LAB = sprintf( 'Style index = %1i', $IHATCH[$I-1] );
&NCAR::plchhq($XL[$I-1]+0.21,$YT[$I-1]-0.02,$LAB,0.022,0.,0.);
$LAB = sprintf( 'Spacing = %4.2f ', $RSPACE[$I-1] );
&NCAR::plchhq($XL[$I-1]+0.32,$YT[$I-1]-0.09,$LAB,0.022,0.,0.);
}
#
&NCAR::plchhq(.5,.98,'Hatch line spacings',0.035,0.,0.);
#

sub ZIGZAG {
  my ($XLEFT,$XRIGHT,$YBOT,$YTOP) = @_;
#
#  Draw a zigzag figure within the specified limits for a rectangle.
#
  my $IDIM=10;
#
  my $DX = ($XRIGHT-$XLEFT)/8.;
  my $DY = ($YTOP-$YBOT)/10.;
#
  my $X = zeroes float, $IDIM;
  for my $I ( 1 .. $IDIM-1 ) {
    set( $X, $I-1, $XLEFT+($I-1)*$DX );
  }
  set( $X, $IDIM-1, at( $X, 0 ) );
#
  my $Y = float [
     $YTOP-2.*$DY,
     $YTOP,
     $YBOT,
     $YTOP-2.0*$DY,
     $YBOT,
     $YTOP-4.0*$DY,
     $YBOT,
     $YTOP-6.0*$DY,
     $YTOP-8.5*$DY,
     $YTOP-2.*$DY
  ];
#
  &NCAR::gsfaci(2);
  &NCAR::gfa($IDIM,$X,$Y);
  &NCAR::gsplci(1);
  &NCAR::gpl($IDIM,$X,$Y);
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/pgkex23.ncgm';
