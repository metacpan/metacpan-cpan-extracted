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
# The object of this EZMAP example is to show off some capabilities of
# new code in EZMAPB (created in April, 1998).  Three different parts of
# the earth are shown at various "levels"; level 1 includes just land
# and water, level 2 includes continents, level 3 includes countries,
# level 4 includes states within the US, and level 5 includes counties
# within the states.
#
# LAMA is the length of an area map A for geographical boundaries;
# in general, this value needs to be a bit larger than would have been
# required for the old 'CO', 'PO', 'PS', and 'US' datasets.  The
# geographical boundaries go into edge group 1, but we also put into
# area map A a set of lines carving up the frame into vertical strips
# and some circles carving up the frame into areas within each of which
# we wish to display geographic information differently; the vertical
# strips go into edge group 2 and the circles into edge group 5.
#
my $LAMA=2000000;
#
# LAMB is the length of an area map B into which will be put just the
# circles mentioned above.  This area map will be used to determine
# characteristics of the lines drawn by the call to MPLNDM.
#
my $LAMB=  80000;
#
# MCRA is the required length of the scratch arrays to be used by
# ARSCAM for X/Y coordinates.
#
my $MCRA=  40000;
#
# Declare the area map arrays.
#
my $IAMA = zeroes long, $LAMA;
my $IAMB = zeroes long, $LAMB;
#
# Declare the X/Y scratch arrays and area-identifier-information arrays
# to be used by ARSCAM.
#
my $XCRA = zeroes float, $MCRA;
my $YCRA = zeroes float, $MCRA;
my $IAAI = zeroes long, 5;
my $IAGI = zeroes long, 5;
#
# Declare the names of some area- and line-processing routines EXTERNAL
# to keep the compiler from interpreting them as REAL variables.
#
#       EXTERNAL COLORA,COLORL,COLORS
#
# Declare some arrays in which to put values defining some portions of
# the globe to be looked at.
#
#
# Define the portions of the globe to be looked at.
#
my @CLON = (  -90. ,  10. , 55. , 110. );
#
my @SLAT = (   -9. ,  34. , 20. , -16. );
my @SLON = ( -145. , -10. , 20. ,  80. );
my @BLAT = (   70. ,  65. , 60. ,  40. );
my @BLON = (  -45. ,  40. , 90. , 140. );
#
my @LABL = (
     +       'North America (Custer County, Nebraska, in Pink)',
     +       'Northern Europe (Slovakia in Pink)              ',
     +       'Eurasia (Uzbekistan in Pink)'                    ,
     +       'Southeast Asia (Cambodia in Pink)'               
);
#
# Turn off clipping by GKS.
#
&NCAR::gsclip (0);
#
# Set the GKS "fill area interior style" to "solid".
#
&NCAR::gsfais (1);
#
# Define some color indices.  (DFCLRS is part of this example; it is
# not an NCAR Graphics library routine.)
#
&DFCLRS();
#
# Select PLOTCHAR font number 25, turn on the outlining of filled fonts,
# and turn off the setting of the outline color.
#
&NCAR::pcseti ('FN - FONT NUMBER',25);
&NCAR::pcseti ('OF - OUTLINE FLAG',1);
&NCAR::pcsetr ('OC - OUTLINE LINE COLOR',-1.);
#
# Turn on "vertical stripping" by EZMAP.  What this means is that a call
# to MPLNAM will put into an area map not only the geographical boundary
# lines (in edge group 1), but also lines (in edge group 2) defining
# some vertical strips (4, in this case).  This helps to break up the
# areas defined by the geographical boundaries in such a way as to
# reduce the total number of points required for any particular area.
#
&NCAR::mpseti ('VS',4);
#
# Loop to depict three different portions of the globe.
#
for my $IVEW ( 1 .. 4 ) {
#
# Tell EZMAP to use a Mercator projection.  CLON(IVEW) is the center
# longitude.
#
  &NCAR::maproj ('ME',0.,$CLON[$IVEW-1],0.);
#
# Tell EZMAP to set up the map limits in such a way as to include all
# of a region from some smallest latitude and longitude to some biggest
# latitude and longitude.
#
  &NCAR::mapset ('GR',
                  float( [ $SLAT[$IVEW-1], 0 ] ),
		  float( [ $SLON[$IVEW-1], 0 ] ),
		  float( [ $BLAT[$IVEW-1], 0 ] ),
		  float( [ $BLON[$IVEW-1], 0 ] )
		  );
#
# Initialize EZMAP.
#
  &NCAR::mapint;
#
# Find out what SET call was done by EZMAP, reset the map limits in
# such a way as to make the map square, and then reinitialize.
#
  &NCAR::getset (my ($XVPL,$XVPR,$YVPB,$YVPT,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG));
  my $XCEN=.5*($XWDL+$XWDR);
  my $YCEN=.5*($YWDB+$YWDT);
  my $HWTH=.5*&NCAR::Test::max($XWDR-$XWDL,$YWDT-$YWDB);
  &NCAR::mapset ('LI',
                 float( [ $XCEN-$HWTH, 0 ] ),
		 float( [ $XCEN+$HWTH, 0 ] ),
		 float( [ $YCEN-$HWTH, 0 ] ),
		 float( [ $YCEN+$HWTH, 0 ] )
		 );
  &NCAR::mapint();
#
# Initialize both of area maps A and B.
#
  &NCAR::arinam ($IAMA,$LAMA);
  &NCAR::arinam ($IAMB,$LAMB);
#
# Put four concentric circles into both of area maps A and B (in edge
# group 5).  The interior of the smallest circle has area identifier 5,
# the ring around it has area identifier 4, the ring around that has
# area identifier 3, the ring around that has area identifier 2, and
# the remainder has area identifier 1.  These area identifiers will be
# used to determine the "level" at which the geographical information
# is to be displayed; level 5 means "counties", level 4 means "states",
# level 3 means "countries", level 2 means "continents", and level 1
# means just "land/water".
#
  for my $ICIR ( 1 ... 4 ) {
    for my $IANG ( 1 .. 361 ) {
      my $ANGL=.017453292519943*(($IANG-1) % 360);
      set( $XCRA, $IANG-1, &NCAR::cfux(.5+(.05+.13*($ICIR-1))*cos($ANGL)) );
      set( $YCRA, $IANG-1, &NCAR::cfuy(.5+(.05+.13*($ICIR-1))*sin($ANGL)) );
    }
    &NCAR::aredam ($IAMA,$XCRA,$YCRA,361,5,6-$ICIR,5-$ICIR);
    &NCAR::aredam ($IAMB,$XCRA,$YCRA,361,5,6-$ICIR,5-$ICIR);
  }
#
# Put all the EZMAP boundary lines from the named dataset (down to
# level 5) into area map A.
#
  &NCAR::mplnam ('Earth..2',5,$IAMA);
#
# Color the map as implied by the contents of area map A.  See the
# "user callback" routine COLORA (elsewhere in this file) to see how
# the area identifiers from groups 1 (geographic), 2 (vertical strips),
# and 5 (circles) are all used to produce the desired effect.
#
  &NCAR::arscam ($IAMA,$XCRA,$YCRA,$MCRA,$IAAI,$IAGI,5,\&COLORA);
#
# Print some numbers reflecting the amount of space actually used in
# the area map arrays.
#
  printf( STDERR "

          Length of area map A: %d
          Length of area map B: %d
", $LAMA-at($IAMA,5)+at($IAMA,4)+1 ,$LAMB-at($IAMB,5)+at($IAMB,4)+1 );

#
# Draw the EZMAP boundary lines masked by area map B; the lines are
# drawn differently inside each of the areas created by the concentric
# circles.
#
  &NCAR::mplndm ('Earth..2',5,$IAMB,$XCRA,$YCRA,$MCRA,$IAAI,$IAGI,5,\&COLORL);
#
# Draw the concentric circles themselves.
#
  &NCAR::gslwsc (2.);
  &NCAR::gsplci (2);
#
  for my $ICIR ( 1 .. 4 ) {
    for my $IANG ( 1 .. 361 ) {
      my $ANGL=.017453292519943*(($IANG-1) % 360);
      set( $XCRA, $IANG-1, &NCAR::cfux(.5+(.05+.13*($ICIR-1))*cos($ANGL)) );
      set( $YCRA, $IANG-1, &NCAR::cfuy(.5+(.05+.13*($ICIR-1))*sin($ANGL)) );
    }
    &NCAR::curve ($XCRA,$YCRA,361);
  }
#
# Put some labels on the plot.
#
  &NCAR::gslwsc (1.);
  &NCAR::gsplci (2);
  &NCAR::gsfaci (2);
#
  &NCAR::plchhq (&NCAR::cfux(.500),&NCAR::cfuy(.975),
  'The Database "Earth..2" at Various Levels',.018,0.,0.);
#
  &NCAR::plchhq (&NCAR::cfux(.500),&NCAR::cfuy(.025),
  substr( $LABL[$IVEW-1], 0, &NCAR::mpilnb( $LABL[$IVEW-1] ) ),.018,0.,0.);
#
  &NCAR::plchhq (&NCAR::cfux(.142911),&NCAR::cfuy(.142911),'1',.02,0.,0.);
  &NCAR::plchhq (&NCAR::cfux(.234835),&NCAR::cfuy(.234835),'2',.02,0.,0.);
  &NCAR::plchhq (&NCAR::cfux(.326759),&NCAR::cfuy(.326759),'3',.02,0.,0.);
  &NCAR::plchhq (&NCAR::cfux(.418683),&NCAR::cfuy(.418683),'4',.02,0.,0.);
  &NCAR::plchhq (&NCAR::cfux(.500000),&NCAR::cfuy(.500000),'5',.02,0.,0.);
#
  &NCAR::gsplci (1);
  &NCAR::gsfaci (1);
#
# Advance the frame.
#
&NCAR::frame();
#
# End of view loop.
#
}


sub DFCLRS {
#
# Define some color indices for use in the example "mpex13".
#
  &NCAR::gscr (1,  0,0.,0.,0.); #  black   - the background;
  &NCAR::gscr (1,  1,1.,1.,1.); #  white   - the foreground;
  &NCAR::gscr (1,  2,1.,1.,0.); #  yellow  - some labelling;
  &NCAR::gscr (1, 11,1.,1.,1.); #  white   - water/land edges;
  &NCAR::gscr (1, 12,1.,1.,1.); #  gray    - continent edges;
  &NCAR::gscr (1, 13,1.,1.,1.); #  gray    - country edges;
  &NCAR::gscr (1, 14,1.,1.,1.); #  gray    - state edges;
  &NCAR::gscr (1, 15,.1,.1,.1); #  gray    - county edges;
  &NCAR::gscr (1, 16,1.,.6,.6); #  pink    - highlighted area;
  &NCAR::gscr (1,101,.2,.2,.8); #  area color 1;
  &NCAR::gscr (1,102,.2,.4,.6); #  area color 2;
  &NCAR::gscr (1,103,.2,.6,.4); #  area color 3;
  &NCAR::gscr (1,104,.2,.8,.2); #  area color 4  !  area fills;
  &NCAR::gscr (1,105,.4,.6,.2); #  area color 5;
  &NCAR::gscr (1,106,.6,.4,.2); #  area color 6;
  &NCAR::gscr (1,107,.6,.6,.6); #  area color 7;
#
}

sub NCAR::mpchln {
  my ($IFLG,$ILTY,$IOAL,$IOAR,$NPTS,$PNTS) = @_;
#
# This version of the "user callback" routine MPCHLN determines some
# characteristics of lines of different types drawn by calls to MPLNDM
# and MPLNDR, as follows:
#
#     Level 1 (land/water boundaries): double thickness, color 11
#     Level 2 (continental boundaries): double thickness, color 12
#     Level 3 (country boundaries): double thickness, color 13
#     Level 4 (state boundaries): single thickness, color 14
#     Level 5 (county boundaries): single thickness, color 15
#
# Flush SPPS pen-move buffers.
#
  &NCAR::plotif (0.,0.,2);
#
# If IFLG is greater than one, a line of type ILTY is about to be
# drawn; set up the desired characteristics.
#
  if( $IFLG > 1 ) {
#
    if( $ILTY == 1 ) {
      &NCAR::gslwsc (2.);
      &NCAR::gsplci (11);
    } elsif( $ILTY == 2 ) {
      &NCAR::gslwsc (2.);
      &NCAR::gsplci (12);
    } elsif( $ILTY == 3 ) {
      &NCAR::gslwsc (2.);
      &NCAR::gsplci (13);
    } elsif( $ILTY == 4 ) {
      &NCAR::gslwsc (1.);
      &NCAR::gsplci (14);
    } elsif( $ILTY == 5 ) {
      &NCAR::gslwsc (1.);
      &NCAR::gsplci (15);
    }
#
# If, on the other hand, IFLG is less than minus one, a line was just
# drawn; reset line characteristics to default values.
#
  } elsif( $IFLG < -1 ) {
#
    &NCAR::gslwsc (1.);
    &NCAR::gsplci (1);
#
  }
#
# Done.
#
}

sub COLORA {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS) = @_;
#
# In the example "mpex13", the routine COLORA is called by the AREAS
# routine ARSCAM to fill the areas created by area map A.
#
#
# Extract the area identifiers of the area relative to groups 1
# (geographic), 2 (vertical stripping), and 5 (concentric circles).
#
  my $IAI1=-1;
  my $IAI2=-1;
  my $IAI5=-1;
#
  for my $I ( 1 .. $NGPS ) {
    if( at( $IAGI, $I-1 ) == 1 ) { $IAI1 = at( $IAAI, $I-1 ); }
    if( at( $IAGI, $I-1 ) == 2 ) { $IAI2 = at( $IAAI, $I-1 ); }
    if( at( $IAGI, $I-1 ) == 5 ) { $IAI5 = at( $IAAI, $I-1 ); }
  }
#
# If all the area identifiers have valid values, choose a color for the
# area and fill it.  If the full name of it is "Nebraska - Custer",
# "Slovakia", "Uzbekistan", or "Cambodia", it is filled using color 16
# (pink); otherwise, we use the suggested color for the area at the
# level implied by the group-5 area identifier.
#
  if( $IAI1 >= 1 ) {
    if( $IAI2 >= 0 ) {
      if( $IAI5 >= 1 ) {
        my $MPFNME = &NCAR::mpfnme( $IAI1, 4 );
        if( 
            ( $MPFNME =~ m/Nebraska - Custer/io ) ||
            ( $MPFNME =~ m/Slovakia/io          ) ||
            ( $MPFNME =~ m/Uzbekistan/io        ) ||
            ( $MPFNME =~ m/Cambodia/io          ) ) {
          &NCAR::gsfaci (16);
        } else {
          &NCAR::gsfaci (100+&NCAR::mpisci(&NCAR::mpiosa($IAI1,$IAI5)));
        }
        &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
      }
    }
  }
#
# Done.
#
}



sub COLORL {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS) = @_;
#
# In the example "mpex13", the routine COLORL is called by the EZMAPB
# routine MPLNDM to draw lines masked by the contents of area map B.
#
# Get the value of the line type for the line being drawn.
#
  &NCAR::mpglty (my $ILTY);
#
# Find the area identifier relative to group 5 (the circles).
#
  my $IAI5=-1;
#
  for my $I ( 1 .. $NGPS ) {
    if( at( $IAGI, $I-1 ) == 5 ) { $IAI5 = at( $IAAI, $I-1 ); }
  }
#
# If the group-5 area identifier is valid, draw the line if and only
# if its type is less than or equal to the group-5 area identifier.
# What this means is that all boundary lines (down to the county level)
# are drawn in the inner circle, county lines are omitted in the ring
# surrounding that, state lines are omitted in the ring surrounding
# that, country lines are omitted in the ring surrounding that, and
# continental boundary lines are omitted elsewhere.
#
  if( $IAI5 >= 1 ) {
    if( $ILTY <= $IAI5 ) {
      &NCAR::gpl ($NCRA,$XCRA,$YCRA);
    }
  }
#
# Done.
#
}
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex11.ncgm';
