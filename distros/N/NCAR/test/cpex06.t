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
use NCAR::Test qw( bndary gendat drawcl dfclrs capsap labtop );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

print STDERR "\n";

my $ZDAT = zeroes float, 27, 33;
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 1000;
my $IAMA = zeroes long, 10000;
my $IASF = long [ ( 1 ) x 13 ];
#
# Declare the routine which will draw contour lines, avoiding labels.
#
#       EXTERNAL DRAWCL;
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Define color indices.
#
&dfclrs(1);
#
# Generate an array of test data.
#
&gendat ($ZDAT,27,27,23,25,25,-362.362E11,451.834E11);
#
# Increase the approximate number of contour levels used.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTION', 25 );
#
# Turn on the positioning of labels by the penalty scheme.
#
&NCAR::cpseti( 'LLP - LINE LABEL POSITIONING', 3 );
#
# Label highs and low with just the number, boxed and colored green.
#
&NCAR::cpsetc( 'HLT - HIGH/LOW TEXT', '$ZDV$' );
&NCAR::cpseti( 'HLB - HIGH/LOW LABEL BOX FLAG', 1 );
&NCAR::cpseti( 'HLC - HIGH/LOW LABEL COLOR INDEX', 9 );
#
# Tell CONPACK to delete high/low labels which overlap the informational
# label, another high/low label, or the edge.
#
&NCAR::cpseti( 'HLO - HIGH/LOW LABEL OVERLAP FLAG', 7 );
#
# Turn on the drawing of the grid edge ("contour line number -1"),
# thicken it somewhat, and make it white.
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -1 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
&NCAR::cpsetr( 'CLL - CONTOUR LEVEL LINE WIDTH', 2. );
&NCAR::cpseti( 'CLC - CONTOUR LINE COLOR', 1 );
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,27,27,23,$RWRK,5000,$IWRK,1000);
#
# Force the selection of contour levels by CONPACK.
#
&NCAR::cppkcl ($ZDAT,$RWRK,$IWRK);
#
# Force the color of the negative contours to blue, the color of the
# positive contours to red, and the color of the zero contour to white.
# If a positive or negative contour is labelled, use a darker shade and
# make the color of the label match.
#
&NCAR::cpgeti( 'NCL - NUMBER OF CONTOUR LEVELS', my $NCLV );
#
for my $ICLV ( 1 .. $NCLV ) {

&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', $ICLV );
&NCAR::cpgetr( 'CLV - CONTOUR LEVEL', my $CLEV );
&NCAR::cpgeti( 'CLU - CONTOUR LEVEL USE', my $ICLU );
  if( $CLEV < 0 ) {
    if( $ICLU == 1 ) {
&NCAR::cpseti( 'CLC - CONTOUR LINE COLOR', 7 );
    } else {
&NCAR::cpseti( 'CLC - CONTOUR LINE COLOR', 6 );
&NCAR::cpseti( 'LLC - LINE LABEL COLOR', 6 );
    }
   } elsif( $CLEV == 0 ) {
&NCAR::cpseti( 'CLC - CONTOUR LINE COLOR', 1 );
&NCAR::cpseti( 'LLC - LINE LABEL COLOR', 1 );
   } else {
     if( $ICLU == 1 ) {
&NCAR::cpseti( 'CLC - CONTOUR LINE COLOR', 13 );
     } else {
&NCAR::cpseti( 'CLC - CONTOUR LINE COLOR', 14 );
&NCAR::cpseti( 'LLC - LINE LABEL COLOR', 14 );
     }
   }
}
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,10000);
#
# Put label boxes in the area map.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Draw contour lines, avoiding drawing through label boxes.
#
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&drawcl);
#
# Fill in the labels.
#
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line at the edge of the plotter frame.
#
&capsap ('EXAMPLE 6',$IAMA,10000);
&labtop ('EXAMPLE 6',.017);
&bndary;
#
# Advance the frame.
#





&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/cpex06.ncgm';
