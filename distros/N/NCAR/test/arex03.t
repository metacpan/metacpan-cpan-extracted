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
# Define the length of the area map array.
#
my $LAMA=50000;
#
# Declare the area map array for ARSCAM.
#
my $IAMA = zeroes long, $LAMA;
#
# Declare arrays in which to define edge segments for AREDAM.
#
my $XEDG = zeroes float, 11;
my $YEDG = zeroes float, 11;
#
# Declare an array in which to put area identifiers for each of the
# ten edges of each of the five decagons in each row of decagons on
# each of two frames.
#
my $IAID = long [
      -1 , -1 , -2 , -3 , -4 , -5 , -6 , -7 , -8 , -9 ,
       0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,
       1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,
       2 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,
       1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  2 ,
       1 ,  1 ,  1 ,  1 ,  1 ,  2 ,  2 ,  2 ,  2 ,  2 ,
      -1 ,  1 ,  1 ,  1 ,  1 ,  2 ,  2 ,  2 ,  2 ,  2 ,
       0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  1 ,
       0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  0 ,  2 ,  2 ,  1 ,
       0 ,  0 ,  0 ,  0 , -3 , -2 , -1 ,  2 ,  2 ,  1 ,
];
reshape( $IAID, 10, 5, 2 );
#
# Declare external the user routine to process a subarea, so the
# compiler won't mistake its name for that of a variable.
#
#       EXTERNAL URTPSA;
#
# Declare scratch arrays for ARSCAM to use in calls to URTPSA.
#
my $XCRA = zeroes float, 1000;
my $YCRA = zeroes float, 1000;
my $IAAI = zeroes long, 9;
my $IAGI = zeroes long, 9;
#
# Declare a character temporary to use in writing area ids.
#
my $CTMP;
#
# Declare a character variable in which to put the main title.
#
my $TITL;
#
# Define the area identifiers to be used for each of the ten edges
# of each of the five decagons in each row of decagons.
#
#
# Define the title with an "n" to be replaced by a frame number.
#
$TITL = 'USING VARIOUS VALUES OF \'RC\' - FRAME n';
#
# Turn off clipping by GKS.
#
&NCAR::gsclip (0);
#
# Set up a convenient mapping from the user coordinate system to the
# fractional coordinate system.
#
&NCAR::set (.15,.95,.02,.82,.5,5.5,.5,5.5,1);
#
# Tell PLOTCHAR to use font number 25 and to put outlines on all filled
# characters.
#
&NCAR::pcseti( 'FN - FONT NUMBER', 25 );
&NCAR::pcseti( 'OF - OUTLINE FLAG', 1 );
#
# Set up an outer loop on frame number.
#
for my $IFRA ( 1 .. 2 ) {
#
# Put some labels at the top of the plot.

  substr( $TITL, 37, 1, chr( $IFRA ) );
  &NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.954),$TITL,.02,0.,0.);
#
  &NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.918), 
                 'The specified element of \'RC\' is used for '
               . 'each decagon in a particular horizontal row.',
                 .012,0.,0.);
#
  &NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.894), 
               'The same set of area identifiers is used for '
             . 'each decagon in a particular vertical column.',
               .012,0.,0.);
#
  &NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.870),
               'Each of the small numbers in a'
             . ' decagon is an area identifier for one edge of the decagon.',
               .012,0.,0.);
#
  &NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.846),
               '(The larger the character size used '
             . 'for the number, the more recently it was seen by AREAS.)',
               .012,0.,0.);
#
  &NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.822),
               'The largest number (in the center of the decagon) '
             . 'is a reconciled area identifier for the decagon.',
               .012,0.,0.);

#
# Set the values of the elements of the 'RC' parameter array so that
# each reconciliation method will be used for exactly one edge group.
#
&NCAR::arseti( 'RC(1) - RECONCILIATION METHOD FOR GROUP 1', -2 );
&NCAR::arseti( 'RC(2) - RECONCILIATION METHOD FOR GROUP 2', -1 );
&NCAR::arseti( 'RC(3) - RECONCILIATION METHOD FOR GROUP 3', 0 );
&NCAR::arseti( 'RC(4) - RECONCILIATION METHOD FOR GROUP 4', 1 );
&NCAR::arseti( 'RC(5) - RECONCILIATION METHOD FOR GROUP 5', 2 );
#
# Change the function-code signal character for PLOTCHAR so we can
# use colons in some labels.
#
&NCAR::pcsetc( 'FC - FUNCTION-CODE CHARACTER', '|' );
#
# Put labels on each of the rows of decagons.
#


&NCAR::plchhq (&NCAR::cfux(.05),4.75,'RC(1): -2',.015,0.,-1.);
&NCAR::plchhq (&NCAR::cfux(.05),3.75,'RC(2): -1',.015,0.,-1.);
&NCAR::plchhq (&NCAR::cfux(.05),2.75,'RC(3):  0',.015,0.,-1.);
&NCAR::plchhq (&NCAR::cfux(.05),1.75,'RC(4): +1',.015,0.,-1.);
&NCAR::plchhq (&NCAR::cfux(.05),0.75,'RC(5): +2',.015,0.,-1.);
#


&NCAR::plchhq (&NCAR::cfux(.05),4.5,
               'Method: If any are negative, use -1 else, '
             . 'use most-frequently-occurring value, possibly zero.',
               .012,0.,-1.);
#
&NCAR::plchhq (&NCAR::cfux(.05),3.5,
               'Method: If any are negative, use -1 if all are zero,'
             . ' use zero; else, use most-frequently-occurring no n-zero.',
               .012,0.,-1.);
#
&NCAR::plchhq (&NCAR::cfux(.05),2.5,
               'Method: If any are negative, use -1 if all are zero, '
             . 'use zero; else, use most-recently-seen non-zero.',
               .012,0.,-1.);
#
&NCAR::plchhq (&NCAR::cfux(.05),1.5,
               'Method: Ignore zeroes; treat negatives as -1s; '
             . 'use most-frequently-occurring value in resulting set.',
               .012,0.,-1.);
#
&NCAR::plchhq (&NCAR::cfux(.05),0.5, 
               'Method: Do not ignore zeroes; treat negatives as -1s; '
             . 'use most-frequently-occurring value in resulting set.',
               .012,0.,-1.);
#
# Change the function-code signal character for PLOTCHAR back to the
# default.
#
&NCAR::pcsetc( 'FC - FUNCTION-CODE CHARACTER', ':' );

#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,$LAMA);
#
# Put a collection of decagons into the area map.  Each horizontal row
# of decagons is identified with a particular edge group and therefore
# with a particular element of 'RC'.
#
for my $IGID ( 1 .. 5 ) {
  my $YCEN=6-$IGID;
  for my $IDEC ( 1 .. 5 ) {
    my $XCEN=$IDEC;
    for my $IANG ( 1 .. 10 ) {
      my $ANG1=.017453292519943*((36*$IANG-36) % 360);
      my $ANG2=.017453292519943*((36*$IANG-18) % 360);
      set( $XEDG, $IANG - 1, $XCEN+.4*cos($ANG1) );
      set( $YEDG, $IANG - 1, $YCEN+.4*sin($ANG1) );
      $CTMP = sprintf( "%2d", at( $IAID, $IANG - 1, $IDEC - 1, $IFRA - 1 ) );
      &NCAR::plchhq ($XCEN+.27*cos($ANG2),$YCEN+.27*sin($ANG2),$CTMP,
                     .006+.0009*$IANG,0.,0.);
    }
    set( $XEDG, 10, at( $XEDG, 0 ) );
    set( $YEDG, 10, at( $YEDG, 0 ) );
    &NCAR::gslwsc (2.);
    &NCAR::gpl    (11,$XEDG,$YEDG);
    &NCAR::gslwsc (1.);
    for my $IANG ( 1 .. 10 ) {
      &NCAR::aredam ( $IAMA, 
                      at( $XEDG, $IANG - 1 ),
                      at( $YEDG, $IANG - 1 ),
                      2,$IGID,  
                      at( $IAID, $IANG - 1, $IDEC - 1, $IFRA - 1 ), 
                      0 );
    }
  }
}
#
# Scan the area map, extracting all subareas and delivering each to
# a processing routine that will just draw the edge of the area and
# write its area identifier, relative to the group IGID, in its
# center.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IAAI,$IAGI,9,\&urtpsa);
#
&NCAR::frame();
}

sub urtpsa {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS) = @_;
#
#
# Declare a character temporary to use in writing area identifiers.
#
  my $CTMP;
#
# If the number of groups reported is not equal to five, log an error
# and return.
#
  if( $NGPS != 5 ) {
    print STDERR "IN URTPSA, NGPS NOT EQUAL TO 5\n";
    return;
  }
#
# Otherwise, if the number of coordinates is eleven, it's one of the
# decagons, so plot the appropriate area identifier in the middle of it.
#
  if( $NCRA == 11 ) {
    my $XCEN=0.;
    my $YCEN=0.;
    for my $I ( 1 .. $NCRA - 1 ) {
       $XCEN=$XCEN+at( $XCRA, $I - 1 );
       $YCEN=$YCEN+at( $YCRA, $I - 1 );
    }
    $XCEN=$XCEN/($NCRA-1);
    $YCEN=$YCEN/($NCRA-1);
    my $IGID=max(1,min(5,1+int((.82-$YCEN)/.16)));
    my $IAID=-2;
    for my $I ( 1 .. $NGPS ) {
      if( at( $IAGI, $I - 1 ) == $IGID ) {
        $IAID = at( $IAAI, $I - 1 );
      }
    }
    if( $IAID != -2 ) {
      my $CTMP = sprintf( "%2i", $IAID );
      &NCAR::plchhq ($XCEN,$YCEN,$CTMP,.02,0.,0.);
    } else {
      print STDERR "IN URTPSA, DESIRED AREA IDENTIFIER NOT FOUND\n";
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



rename 'gmeta', 'ncgm/arex03.ncgm';
