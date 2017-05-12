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
#  This subroutine provides a simple example of STITLE usage.
#  It is assumed that GKS has been opened prior to calling
#  this suboutine.
#
#
#  First, set up the CARDS array to specify the text strings, the
#  text sizes, horizontal centering, and vertical coordinate
#  information.  This information is supplied for each line of text.
#  In this example, all the X-coordinates are set to 512, and the
#  horizontal centering is always set to 1, so each line of text will
#  be centered horizontally.  All character sizes will be 1.5 times
#  the default PLOTCHAR character size except the equation supplied
#  in CARD(8) that will be 3.5 times the default PLOTCHAR character
#  size.  Notice that each line has a Y-coordinate specified for it;
#  these coordinates range from 1500 at the top to 200 at the bottom
#  of the scroll.
#
my $NCARDS = 12;
my @CARDS = (
  '  512 1500    1  1.5The PLOTCHAR',
  '  512 1400    1  1.5utility',
  '  512 1300    1  1.5can be',
  '  512 1200    1  1.5used to',
  '  512 1100    1  1.5write',
  '  512 1000    1  1.5an equation',
  '  512  900    1  1.5like',
  '  512  700    1  3.5C:S:2:N:=A:S:2:N:+B:S:2:N:',
  '  512  500    1  1.5in a',
  '  512  400    1  1.5movie title',
  '  512  300    1  1.5created by',
  '  512  200    1  1.5STITLE',
);
#
#  Define the remaining inputs for STITLE.
#
#  NYST specifies the Y-coordinate that will be at the vertical center
#  of the frame when scrolling begins.  The value specified (1300)
#  means that the line "can be" will be centered vetically on the
#  first frame and scrolling will proceed from there.
#
my $NYST  = 1300;
#
#  NYFIN specifies the Y-coordinate that will be at the vertical center
#  of the frame when scrolling is terminated.  The value specified (400)
#  means that the line "movie title" will be centered vertically on
#  the frame when scrolling terminates.
#
my $NYFIN = 400;
#
#  TST specifies how many seconds  the first frame will remain
#  stationary before scrolling begins.
#
my $TST   = 1.0;
#
#  Specify the scroll time.  This is the time in seconds that the
#  text will be scrolled from position NYST to NYFIN.
#
my $TMV   = 10.0;
#
#  Specify how many seconds  the final frame will remain stationary
#  after scrolling stops.
#
my $TFIN  =  0.5;
#
#  Indicate that this will be a practice run, and not a production
#  run.
#
my $MOVIE = 1;
#
#  Call SLSETR to indicate that the first frame should be faded
#  in for 2.5 seconds.
#
&NCAR::slsetr('FIN',2.5);
#
#  Call SLSETR to indicate that the last frame should be faded
#  out for 2.0 seconds.
#
&NCAR::slsetr('FOU',2.0);
#
#  Call STITLE.
#
&NCAR::stitle (\@CARDS,$NCARDS,$NYST,$NYFIN,$TST,$TMV,$TFIN,$MOVIE);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/slex01.ncgm';
