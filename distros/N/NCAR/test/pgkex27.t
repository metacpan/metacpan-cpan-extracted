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

#
#  This program illustrates apeending to metafiles, both to
#  metafiles that have been suspended in the middle of a picture
#  as well as to previously created full metafiles.  The logic
#  of the code is:
#
#         o  Open and activate an initial metafile and establish
#            values for the primitive attributes for that file.
#         o  Draw a line and a filled area in the first metafile
#            and suspend output.
#         o  Open a second metafile, establish values for the
#            primitive attributes in that metafile.
#         o  Draw a picture in the second metafile and deactivate
#            it and close it.
#         o  Reopen the first metafile and complete drawing the
#            first picture.
#         o  Close the first metafile.
#         o  Reopen the second metafile and draw another picture.
#         o  Close the second metafile.
#
#  Two metafiles are created.  The first, gmeta1, has one picture;
#  the second, gmeta2, has two pictures.
#
#
#  Number of colors in the color tables.
#
my $NCOLS=5;
#
#  Arrays for storing the attribute settings, and the color tables. 
#
my $IC1 = zeroes long, 14;
my $IC2 = zeroes long, 14;
my $RC1 = zeroes float, 7;
my $RC2 = zeroes float, 7;
#
#  Dafine the color tables for the two metafiles.
#
my @CTAB1 = (
   [ 1., 1., 1. ],
   [ 0., 0., 0. ],
   [ 1., 0., 0. ],
   [ 0., 1., 0. ],
   [ 0., 0., 1. ],
);
my @CTAB2 = (
   [ 0., 0., 0. ],
   [ 1., 1., 1. ],
   [ 0., 1., 1. ],
   [ 1., 0., 1. ],
   [ 1., 1., 0. ],
);
#
#  Open GKS.
#
&NCAR::gopks(6,0);
#
#  Open a metafile named "gmeta1" and begin a picture, using
#  the color table in CTAB1.
#
&NCAR::ngsetc('ME','gmeta1');
&NCAR::gopwk(1,2,1);
&NCAR::gacwk(1);
for my $I ( 1 .. $NCOLS ) {
  &NCAR::gscr(1,$I-1,@{ $CTAB1[$I-1] });
}
#
#  Establish values for the GKS attributes for gmeta1.
#
&NCAR::gsln(1);
&NCAR::gsplci(1);
&NCAR::gslwsc(5.);
&NCAR::gsfais(1);
&NCAR::gsfaci(4);
&NCAR::gsmk(2);
&NCAR::gspmci(2);
&NCAR::gsmksc(5.);
&NCAR::gstxci(3);
&NCAR::gschh(0.05);
&NCAR::gstxfp(12,2);
&NCAR::gstxal(2,3);
#
#  Draw a line and a filled area.
#
&DRPRIM(' ', 0 );
#
#  Save the current attribute settings and suspend drawing in gmeta1.
#
&NCAR::ngsrat(2,$IC1,$RC1);
&NCAR::gdawk(1);
&NCAR::ngmftc(1);
#
#  Open and activate a metafile named gmeta2.
#
&NCAR::ngsetc('ME','gmeta2');
&NCAR::gopwk(1,2,1);
&NCAR::gacwk(1);
for my $I ( 1 .. $NCOLS ) {
&NCAR::gscr(1,$I-1,@{ $CTAB2[$I-1] });
}
#
#  Draw a picture and close the workstation.
#
&NCAR::gsln(2);
&NCAR::gsplci(4);
&NCAR::gslwsc(1.);
&NCAR::gsfais(3);
&NCAR::gsfasi(5);
&NCAR::gsfaci(1);
&NCAR::gsmk(4);
&NCAR::gspmci(2);
&NCAR::gsmksc(10.);
&NCAR::gstxci(3);
&NCAR::gschh(0.03);
&NCAR::gstxfp(13,2);
&NCAR::gstxal(2,3);
&DRPRIM(' ',0);
&DRPRIM('gmeta2 - picture 1',1);
&NCAR::frame;
#
#  Save the attriburtes of the second metafile.
#
&NCAR::ngsrat(2,$IC2,$RC2);
#
#  Close the workstation for gmeta2.
#
&NCAR::gdawk(1);
&NCAR::gclwk(1);
#
#  Reopen gmeta1 and add to the first picture.
#
&NCAR::ngreop(1, 2, 1, 'gmeta1', 2, $IC1, $RC1, $NCOLS, 0, float(\@CTAB1) );
&NCAR::gacwk(1);
#
&DRPRIM('gmeta1',1);
&NCAR::frame;
#
#  Deactivate and close the first metafile.
#
&NCAR::gdawk(1);
&NCAR::gclwk(1);
#
#  Reopen and add a second picture to gmeta2.
#
&NCAR::ngreop(1, 2, 1, 'gmeta2', 2, $IC2, $RC2, $NCOLS, 0, float(\@CTAB2) );
&NCAR::gacwk(1);
&DRPRIM(' ',0);
&DRPRIM('gmeta2 - picture 2',1);
&NCAR::frame;
#
#  Close things down.
#
&NCAR::gdawk(1);
&NCAR::gclwk(1);
&NCAR::gclks;
#
sub DRPRIM {
  my ( $STR, $IOPT) = @_;
#
#  Draws output primitives.
#
#   GPL and GFA if IOPT=0;
#   GPM and GTX if IOPT=1.
#
  my $XX = float [ 0.15, 0.45 ];
  my $YY = float [  0.7,  0.7 ];
  my $BX = float [ 0.6, 0.8, 0.8, 0.6, 0.6 ];
  my $BY = float [ 0.4, 0.4, 0.8, 0.8, 0.4 ];
  my $TX = 0.30;
  my $TY = 0.50;
  my $TMX = float [ 0.2, 0.4, 0.6, 0.8 ];
  my $TMY = float [ 0.2, 0.2, 0.2, 0.2 ];
#
  if( $IOPT == 0 ) {
    &NCAR::gpl(2,$XX,$YY);
    &NCAR::gfa(5,$BX,$BY);
  } elsif( $IOPT == 1 ) {
    &NCAR::gpm(4,$TMX,$TMY);
    &NCAR::gtx($TX,$TY,$STR);
    &NCAR::ngdots(float([$TX]),float([$TY]),1,0.01,1);
  }
}

rename 'gmeta1', 'ncgm/pgkex27.gmeta1.ncgm';
rename 'gmeta2', 'ncgm/pgkex27.gmeta2.ncgm';
