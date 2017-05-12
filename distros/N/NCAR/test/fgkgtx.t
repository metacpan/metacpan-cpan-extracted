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

my ( $PROJ, $PLAT, $PLON, $ROTA, $OUTLN, $JLIM ) = 
   ( 'CE',-20.,-50.,0.,'PO','CO', );
my ( $PLIM1, $PLIM2, $PLIM3, $PLIM4 ) = (
  float( [  21.3,   0.  ] ),
  float( [ -90. ,  21.3 ] ),
  float( [ -55. , -90.  ] ),
  float( [ -20. , -55.  ] )
);
#
# PURPOSE                To provide a simple demonstration of the
#                        GKS GTX character drawing techniques.
#
# Set up a color table
#
&DFCLRS();
#
# Draw Continental, political outlines 
#
&NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR',$OUTLN);
#
# Set up projection
#
&NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
#
# If it's a satellite projection, choose a satellite distance
#
if( $PROJ eq 'SV' ) { &NCAR::mapstr( 'SA - SATELLITE DISTANCE',5.); }
#
# Set limits of map
#
&NCAR::mapset ($JLIM,$PLIM1,$PLIM2,$PLIM3,$PLIM4);
#
# Turn off Grid lines
#
&NCAR::mapstr ('GR',0.);
#
# Turn off perimeter of map
#
&NCAR::mapsti ('PE', 0);
#
# Turn off map labels
#
&NCAR::mapsti ('LA', 0);
#
# Draw map
#
&NCAR::mapdrw;
#
# Label Brazil
#
# Set text color
#
&NCAR::gstxci(4);
#
#  Set text size
#
&NCAR::gschh(3.);
#
# Set the font
#
&NCAR::gstxfp(-16,2);
#
#  Transform the coordinates
#
my ( $X, $Y );
&NCAR::maptra(-10.,-60.,$X,$Y);
#
#  Draw the text
#
&NCAR::gtx($X,$Y,'Brazil');
#
# Label Argentina
#
# Set text color
#
&NCAR::gstxci(5);
#
#  Set text size
#
&NCAR::gschh(2.);
#
# Set the font
#
&NCAR::gstxfp(-14,2);
#
# Transform the coordinates
#
&NCAR::maptra(-43.,-68.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (-1.,.3);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Argentina');
#
# Label Uruguay
#
# Set text color
#
&NCAR::gstxci(6);
#
# Set text size
#
&NCAR::gschh(1.0);
#
# Set the font
#
&NCAR::gstxfp(-4,2);
#
# Transform the coordinates
#
&NCAR::maptra(-32.5,-58.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (.7,1.);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Uruguay');
#
# Label Paraguay
#
# Set text color
#
&NCAR::gstxci(5);
#
# Set text size
#
&NCAR::gschh(1.0);
#
# Set the font
#
&NCAR::gstxfp(-4,2);
#
# Transform the coordinates
#
&NCAR::maptra(-21.,-61.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (1.,1.);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Paraguay');
#
# Label Bolivia
#
# Set text color
#
&NCAR::gstxci(14);
#
# Set text size
#
&NCAR::gschh(1.6);
#
# Set the font
#
&NCAR::gstxfp(-6,2);
#
# Transform the coordinates
#
&NCAR::maptra(-17.,-68.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (0.,1.);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Bolivia');
#
# Label Chile
#
#  Set text color
#
&NCAR::gstxci(4);
#
# Set text size
#
&NCAR::gschh(1.5);
#
# Set the font
#
&NCAR::gstxfp(-7,2);
#
# Transform the coordinates
#
&NCAR::maptra(-40.,-72.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (-1.,0.03);
#
# Expand the spacing between characters
#
&NCAR::gschsp(2.);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Chile');
#
# Label Peru
#
# Set text color
#
&NCAR::gstxci(14);
#
# Set text size
#
&NCAR::gschh(3.);
#
# Set the font
#
&NCAR::gstxfp(-15,2);
#
# Transform the coordinates
#
&NCAR::maptra(-6.,-79.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (1.,1.);
#
# Reset the spacing between characters
#
&NCAR::gschsp(0.);
#
#  Draw the text
#
&NCAR::gtx($X,$Y,'Peru');
#
# Label Equador
#
# Set text color
#
&NCAR::gstxci(15);
#
#  Set text size
#
&NCAR::gschh(1.5);
#
# Set the font
#
&NCAR::gstxfp(1,2);
#
# Transform the coordinates
#
&NCAR::maptra(0.,-86.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (0.,1.);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Equador');
#
# Label Colombia
#
# Set text color
#
&NCAR::gstxci(1);
#
# Set text size
#
&NCAR::gschh(1.3);
#
#      Set the font
#
&NCAR::gstxfp(-10,2);
#
# Transform the coordinates
#
&NCAR::maptra(7.,-77.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (.8,1.);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Colombia');

#
# Label Venezuela
#
# Set text color
&NCAR::gstxci(3);
#
# Set text size
#
&NCAR::gschh(1.5);
#
#      Set the font
#
&NCAR::gstxfp(-6,2);
#
# Transform the coordinates
#
&NCAR::maptra(7.,-70.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (0.,1.);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Venezuela');

#
# Label Guyana
#
# Set text color
#
&NCAR::gstxci(1);
#
# Set text size
#
&NCAR::gschh(1.0);
#
#      Set the font
#
&NCAR::gstxfp(-4,2);
#
# Transform the coordinates
#
&NCAR::maptra(7.,-59.5,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (1.,0.2);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Guyana');

#
# Label Fr. Guyana
#
# Set text color
&NCAR::gstxci(1);
#
# Set text size
#
&NCAR::gschh(1.2);
#
#      Set the font
#
&NCAR::gstxfp(-4,2);
#
# Transform the coordinates
#
&NCAR::maptra(2.,-53.5,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (-1.,.5);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Fr. Guyana');
#
# Label Suriname
#
# Set text color
#
&NCAR::gstxci(14);
#
# Set text size
#
&NCAR::gschh(1.2);
#
#      Set the font
#
&NCAR::gstxfp(-4,2);
#
# Transform the coordinates
#
&NCAR::maptra(2.5,-56.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (-1.,.2);
#
# Draw the text
#
&NCAR::gtx($X,$Y,'Suriname');

#
# Label the plot
#
# Set text color
#
&NCAR::gstxci(1);
#
# Set text size
#
&NCAR::gschh(4.);
#
#      Set the font
#
&NCAR::gstxfp(-14,2);
#
# Transform the coordinates
#
&NCAR::maptra(15.,-80.,$X,$Y);
#
# Set the angle
#
&NCAR::gschup (0.,1.);
#
# Draw the text
#
&NCAR::gtx ($X,$Y,'South America');
#
# Draw a border around plot
#
# Reset the plot window
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
#
# Set the line color to black
#
&NCAR::gsplci (1);
#
#  Create a background perimeter
#
&NCAR::frstpt( 0.0, 0.0);
&NCAR::vector( 1.0, 0.0);
&NCAR::vector( 1.0, 1.0);
&NCAR::vector( 0.0, 1.0);
&NCAR::vector( 0.0, 0.0);


sub DFCLRS {
#
# Define the RGB color triples needed below.
#
  my @RGBV = (
     [ 0.00 , 0.00 , 0.00 ],
     [ 0.70 , 0.70 , 0.70 ],
     [ 0.75 , 0.50 , 1.00 ],
     [ 0.50 , 0.00 , 1.00 ],
     [ 0.00 , 0.00 , 1.00 ],
     [ 0.00 , 0.50 , 1.00 ],
     [ 0.00 , 1.00 , 1.00 ],
     [ 0.00 , 1.00 , 0.60 ],
     [ 0.00 , 1.00 , 0.00 ],
     [ 0.70 , 1.00 , 0.00 ],
     [ 1.00 , 1.00 , 0.00 ],
     [ 1.00 , 0.75 , 0.00 ],
     [ 1.00 , 0.38 , 0.38 ],
     [ 1.00 , 0.00 , 0.38 ],
     [ 1.00 , 0.00 , 0.00 ],
  );
#
# Define 16 different color indices, for indices 0 through 15.  The
# color corresponding to index 0 is black and the color corresponding
# to index 1 is white.
#
  &NCAR::gscr (1,0,1.,1.,1.);
#
  for my $I ( 1 .. 15 ) {
    &NCAR::gscr (1,$I,@{ $RGBV[$I-1] });
  }
#
# Done.
}
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fgkgtx.ncgm';
