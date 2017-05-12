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

my ( $IDTF, $IDBD ) = ( 0, 0 );
#
# Produce a Mercator projection of the whole globe, using a
# version of MAPUSR which dots the grid lines and dashes the
# continental outlines.
#
#
# Define the label for the top of the map.
#
my $PLBL = 'ILLUSTRATING THE USE OF MAPUSR';
#
# Weird up the projection a little.
#
&NCAR::supmap (9,0.,0.,90.,
               float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       1,15,2,0,my $IERR);
#
# Put the label at the top of the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pwrit (.5,.975,$PLBL,30,2,0,0);
#
# Draw a boundary around the edge of the plotter frame.
#
&NCAR::Test::bndary();

sub NCAR::mapusr {
  my ( $IPRT ) = @_;
#
# This version of MAPUSR forces the grid lines to be dotted and
# the outlines to be dashed.
#
# Certain local parameters must be saved from call to call.
#
#     SAVE IDTF,IDBD;
#
# If IPRT is positive, a part is about to be drawn.  Save the
# dotted/solid flag and/or the distance between dots and then
# reset them and/or the dash pattern.
#
  if( $IPRT > 0 ) {
    if( $IPRT == 2 ) {
      &NCAR::mapgti ('DL',$IDTF);
      &NCAR::mapgti ('DD',$IDBD);
      &NCAR::mapsti ('DL',1);
      &NCAR::mapsti ('DD',24);
    } elsif( $IPRT == 5 ) {
      &NCAR::mapgti ('DL',$IDTF);
      &NCAR::mapsti ('DL',0);
      &NCAR::dashdb (21845);
    }
#
  } else {
#
# Otherwise, a part has just been drawn.  Restore saved settings
# and/or select a solid dash pattern.
#
    if( $IPRT == -2 ) {
      &NCAR::mapsti ('DL',$IDTF);
      &NCAR::mapsti ('DD',$IDBD);
    } elsif( $IPRT == -5 ) { 
      &NCAR::mapsti ('DL',$IDTF);
      &NCAR::dashdb (65535);
    }
#
  }
#
# Done.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex08.ncgm';
