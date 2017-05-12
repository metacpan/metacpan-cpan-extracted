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

my $NPTS=200;
my $NCURVE=4;
my $YDRA = zeroes float, $NPTS, $NCURVE;
my $XDRA = zeroes float, $NPTS;

for my $I ( 1 .. $NPTS ) {
  my $xdra = $I*0.1;
  set( $XDRA, $I-1, $xdra );
  for my $J ( 1 .. $NCURVE ) {
    set( $YDRA, $I-1, $J-1, sin($xdra+0.2*$J)*exp(-0.01*$xdra*$J*$J) );
  }
}

&DEFCLR();

&NCAR::ezmxy ($XDRA,$YDRA,$NPTS,$NCURVE,$NPTS,'INFO LABEL COLOR$');

sub DEFCLR {
&NCAR::gscr(1, 0, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 1, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.0);
&NCAR::gscr(1, 3, 0.0, 1.0, 0.0);
&NCAR::gscr(1, 4, 0.4, 0.7, 0.9);
&NCAR::gscr(1, 5, 0.7, 0.4, 0.7);
&NCAR::gscr(1, 6, 0.9, 0.7, 0.4);
&NCAR::gscr(1, 7, 0.4, 0.9, 0.7);
}
sub NCAR::agchil {
  my ($IFLG,$LBNM,$LNNO) = @_;
  &NCAR::plotif (0.,0.,2);
  if( $IFLG == 0 ) {
    &NCAR::gstxci( 4 );
  } else {
    &NCAR::gstxci( 1 );
  }
}



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fagilclr.ncgm';
