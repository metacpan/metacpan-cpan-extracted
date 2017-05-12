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

my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Define an array for the data.
#
my $ZDAT = zeroes float, 40, 40;
#
# Generate dummy data.
#
my @t;
open DAT, "<data/cpex09.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split m/\s+/o, $t;
}
close DAT;
for my $J ( 1 .. 40 ) {
  for my $I ( 1 .. 40 ) {
    set( $ZDAT, $I-1, $J-1, shift( @t ) );
  }
}
#
# Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Turn off clipping by GKS.
#
&NCAR::gsclip (0);
#
# Force the use of medium-quality characters by the package PLOTCHAR.
#
&NCAR::pcseti ('QU - QUALITY OF CHARACTERS',1);
#
# Put a label at the top of the first plot.  (The SET call is not
# needed for CPEZCT, but for the labelling routine.)
#
&NCAR::set (.05,.95,.05,.95,0.,1.,0.,1.,1);
#&NCAR::Test::labtop ('EXAMPLE 9-1',.017);
#
# Put a boundary line at the edge of the plotter frame.
#
&NCAR::Test::bndary();
#
# Contour the data, using the EZCNTR simulator.
#
&NCAR::cpezct ($ZDAT,40,40);
#
# Contour a subset of the data, forcing a contour interval of 20, using
# the CONREC simulator.
#
my $ZDAT1 = $ZDAT->slice( "6:39,8:39" )->copy();
&NCAR::cpcnrc ($ZDAT1,34,32,24,0.,0.,20.,3,0,-682);
#&NCAR::cpcnrc (ZDAT(7,9),40,32,24,0.,0.,20.,3,0,-682);
#
# Put a boundary line at the edge of the plotter frame, label the plot,
# and advance the frame.
#
&NCAR::Test::bndary();
&NCAR::Test::labtop ('EXAMPLE 9-2',.017);
&NCAR::frame();
#
# Switch to the "penalty scheme" for positioning contour-line labels
# and change one of the constants which are used by it.
#
&NCAR::cpseti ('LLP - LINE LABEL POSITIONING',3);
&NCAR::cpsetr ('PC1 - PENALTY SCHEME CONSTANT 1',1.5);
#
# Turn on the smoother, with a relatively high tension.
#
&NCAR::cpseti ('T2D - TENSION ON THE 2D SMOOTHER',4);
#
# Force the labelling of every other contour line.  (This will only
# work when the contour interval is forced, as it will be in the next
# call to CPCNRC.)
#
&NCAR::cpseti ('LIS - LABEL INTERVAL SPECIFIER',2);
#
# Repeat the last plot, forcing a contour interval of 10.
#
&NCAR::cpcnrc ($ZDAT1,34,32,24,0.,0.,10.,3,0,-682);
#&NCAR::cpcnrc (ZDAT(7,9),40,32,24,0.,0.,10.,3,0,-682);
#
# Put a boundary line at the edge of the plotter frame, label the plot,
# and advance the frame.
#
&NCAR::Test::bndary();
&NCAR::Test::labtop ('EXAMPLE 9-3',.017);
&NCAR::frame();
#
# Create an EZMAP background.
#
&NCAR::mapsti ('PE - PERIMETER',0);
&NCAR::mapsti ('GR - GRID',0);
&NCAR::mapstc ('OU - OUTLINE DATASET','PS');
&NCAR::mapsti ('DO - DOTTING OF OUTLINES',1);
&NCAR::mapstr ('SA - SATELLITE HEIGHT',1.13);
&NCAR::maproj ('SV - SATELLITE-VIEW',40.,-95.,0.);
&NCAR::mapset ('MA - MAXIMAL AREA',
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] )
	      );
&NCAR::mapdrw();
#
# Arrange for output from CPCNRC to be placed on the EZMAP background.
#
&NCAR::cpsetr ('XC1 - X COORDINATE AT I = 1',-130.);
&NCAR::cpsetr ('XCM - X COORDINATE AT I = M',-60.);
&NCAR::cpsetr ('YC1 - Y COORDINATE AT J = 1',10.);
&NCAR::cpsetr ('YCN - Y COORDINATE AT J = N',70.);
&NCAR::cpseti ('MAP - MAPPING FLAG',1);
&NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',1.E12);
#
# Define some special values and arrange for the special-value area to
# be outlined.
#
set( $ZDAT, 14, 12, 1.E36 );
set( $ZDAT, 15, 12, 1.E36 );
set( $ZDAT, 14, 13, 1.E36 );
&NCAR::cpsetr ('SPV - OUT-OF-RANGE VALUE',1.E36);
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',-2);
&NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',1);
#
# Specify that high/low labels are to be written at an angle of 30
# degrees, using relatively small characters.  (These parameters will
# really be used for point-value labels.)
#
&NCAR::cpsetr ('HLA - HIGH/LOW LABEL ANGLE',30.);
&NCAR::cpsetr ('HLS - HIGH/LOW LABEL CHARACTER SIZE',.008);
#
# Turn off line labelling.
#
&NCAR::cpseti ('LLP - LINE LABEL POSITIONING',0);
#
# Use the CONREC simulator to plot a subset of the data on the EZMAP
# background, labelling each data point.
#
$ZDAT1 = $ZDAT->slice( "8:39,6:39" )->copy();
&NCAR::cpcnrc ($ZDAT1,32,20,20,0.,0.,10.,4,1,-682);
#&NCAR::cpcnrc (ZDAT(9,7),40,20,20,0.,0.,10.,4,1,-682);
#
# Put a boundary line at the edge of the plotter frame, label the plot,
# and advance the frame.
#
&NCAR::Test::bndary();
&NCAR::Test::labtop ('EXAMPLE 9-4',.017);
&NCAR::frame();
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
# Done.
#

rename 'gmeta', 'ncgm/cpex09.ncgm';
