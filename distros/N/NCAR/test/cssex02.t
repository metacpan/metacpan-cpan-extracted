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

#
#       $Id: cssex02.f,v 1.10 2000/09/20 06:10:50 fred Exp $
#
# 
#  Define random points and functional values on the globe, 
#  triangulate, interpolate to a uniform grid, then use Ezmap
#  and Conpack to draw a contour plot.
#
#
#  External for CPCLDM that draws the contours.
#
#      EXTERNAL DRAWCL;
#
#  Specify GKS output data.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Dimension the arrays for holding the points for drawing 
#  circular arcs.
#
my $NPARC = 50;
my $ARCLAT = zeroes float, $NPARC;
my $ARCLON = zeroes float, $NPARC;
#
#  Size of the interpolated output grid.
#
my ( $NI, $NJ ) = ( 73, 145 );
#
#  Size of workspaces, etc. for triangulation and interpolation.
#
my $NMAX = 500;
my ( $NTMX, $NT6, $LWK ) = ( 2*$NMAX, 6*$NMAX, 27*$NMAX );
#
#  Array storage for the triangulation, work space, and nodal
#  coordinates.  Note that the real workspace must be double
#  precision.
#
my $RWK = zeroes double, 13, $NMAX;
my $RLAT = zeroes float, $NMAX;
my $RLON = zeroes float, $NMAX;
my $FVAL = zeroes float, $NMAX;
my $PLAT = zeroes float, $NI;
my $PLON = zeroes float, $NJ;
my $FF = zeroes float, $NI, $NJ;
my $ZDAT = zeroes float, $NJ, $NI;
#
#  Storage for the triangulation, work space, and Voronoi vertices.
#
my $LTRI = zeroes long, 3, $NTMX;
my $IWK = zeroes long, $LWK;
my $NV = zeroes long, $NMAX;
#
#  Storage for circumcenters and circumcircle radii.
#
my $RLATO = zeroes float, $NTMX;
my $RLONO = zeroes float, $NTMX;
my $RC = zeroes float, $NTMX;
#
#  Sizes of work arrays for Conpack and Ezmap.
#
my ( $IRWRK, $IIWRK, $IAMASZ ) = ( 1000, 2000, 10000 );
my $RWRK = zeroes float, $IRWRK;
my $IWRK = zeroes long, $IIWRK;
my $IAMA = zeroes long, $IAMASZ;
#
#  Generate a default set of nodes as latitudinal and longitudinal
#  coordinates (latitudes in the range -90. to 90. and longitudes
#  in the range -180. to 180).  The input function is generated
#  using the local subroutines CSGENRS, CSGENI, and CSGENPNT.
#
my $N = $NMAX;
open DAT, "<data/cssex02.dat";
my @t;
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
for my $I ( 1 .. $NMAX ) {
  set( $RLON, $I-1, shift( @t ) );
}
for my $I ( 1 .. $NMAX ) {
  set( $RLAT, $I-1, shift( @t ) );
}
for my $I ( 1 .. $NMAX ) {
  set( $FVAL, $I-1, shift( @t ) );
}
#
#  Create the triangulation.
#
&NCAR::csstri($N,$RLAT,$RLON, my $NT,$LTRI, $IWK,$RWK,my $IER);
#
#  Draw the triangular spherical patches using Ezmap with a
#  satellite view projection.
#
#  Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Color table.
#
&NCAR::gscr($IWKID,0,1.,1.,1.);
&NCAR::gscr($IWKID,1,0.,0.,0.);
&NCAR::gscr($IWKID,2,1.,0.,0.);
&NCAR::gscr($IWKID,3,0.,0.,1.);
#
#  Plot title.
#
&NCAR::plchhq(0.50,0.95,':F26:Triangulation',0.030,0.,0.);
#
#  Define the map projection (satellite view).
#
&NCAR::mapstr ('SA - SATELLITE HEIGHT',4.);
&NCAR::maproj ('SV - SATELLITE-VIEW',40.,-105.,0.);
&NCAR::mapset ('MA - MAXIMAL AREA',
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] )
	      );
&NCAR::mappos (0.06, 0.94, 0.02, 0.90);
#      
#  Draw the triangles.
#
&NCAR::gsplci(2);
for my $NP ( 1 .. $NT ) {
  for my $NS ( 1 .. 3 ) {
#
#  Calculate points along the arc of each side of the triangle.
#
    &NCAR::mapgci(
          at( $RLAT, at( $LTRI, $NS-1, $NP-1 )-1 ), 
          at( $RLON, at( $LTRI, $NS-1, $NP-1 )-1 ),
          at( $RLAT, at( $LTRI, ($NS % 3), $NP-1 )-1 ),
          at( $RLON, at( $LTRI, ($NS % 3), $NP-1 )-1 ),
          $NPARC, $ARCLAT, $ARCLON);
#
#  Draw the arcs.
#
    &NCAR::mapit(
        at( $RLAT, at( $LTRI, $NS-1, $NP-1 )-1 ), 
        at( $RLON, at( $LTRI, $NS-1, $NP-1 )-1 ),
        0);
    for my $I ( 1 .. $NPARC ) {
       &NCAR::mapit( at( $ARCLAT, $I-1 ),at( $ARCLON, $I-1 ),1);
    }
    &NCAR::mapit(
        at( $RLAT, at( $LTRI, ($NS % 3), $NP-1 )-1 ),
        at( $RLON, at( $LTRI, ($NS % 3), $NP-1 )-1 ),
        1);
  }
}
#
#  Mark the original data points (create a circular
#  marker by drawing concentric circles at the data points).
#
&NCAR::gsplci(1);
for my $K ( 1 .. 8 ) {
  for my $I ( 1 .. $N ) {
    &NCAR::nggcog(
       at( $RLAT, $I-1 ),
       at( $RLON, $I-1 ),
       0.1*$K,$ARCLAT,$ARCLON,$NPARC);
    &NCAR::mapit( at( $ARCLAT, 0 ), at( $ARCLON, 0 ),0);
    for my $J ( 2 .. $NPARC-1 ) {
      &NCAR::mapit( at( $ARCLAT, $J-1 ), at( $ARCLON, $J-1 ), 1 );
    }
    &NCAR::mapit( at( $ARCLAT, $NPARC-1 ), at( $ARCLON, $NPARC-1 ), 1 );
    &NCAR::mapiq();
  }
}
#
#  Draw the Voronoi polygons.
#
for my $I ( 1 .. $N ) {
#
#  Get the Voronoi polygon containing the original data point
#  (RLAT(I),RLON(I)).
#
  my $NUMV;
  if( $I == 1 ) {
    &NCAR::csvoro($N,$RLAT,$RLON,$I,1,$IWK,$RWK,$NTMX,$RLATO,$RLONO,$RC,my $NCA,$NUMV,$NV,my $IER);
  } else {
    &NCAR::csvoro($N,$RLAT,$RLON,$I,0,$IWK,$RWK,$NTMX,$RLATO,$RLONO,$RC,my $NCA,$NUMV,$NV,my $IER);
  }
#
#  Draw the polygons.
#
  for my $NN ( 2 .. $NUMV ) {
#
#  Get a polygonal segment.
#
    my $RLAT1 = at( $RLATO, at( $NV, $NN-2)-1 );
    my $RLON1 = at( $RLONO, at( $NV, $NN-2)-1 );
    my $RLAT2 = at( $RLATO, at( $NV, $NN-1)-1 );
    my $RLON2 = at( $RLONO, at( $NV, $NN-1)-1 );
#
#  Plot it.
#
    &NCAR::gsplci(3);
    &NCAR::mapgci($RLAT1,$RLON1,$RLAT2,$RLON2,$NPARC,$ARCLAT,$ARCLON);
    &NCAR::mapit($RLAT1,$RLON1,0);
    for my $J ( 1 .. $NPARC ) {
      &NCAR::mapit( at( $ARCLAT, $J-1 ), at( $ARCLON, $J-1 ),1);
    }
    &NCAR::mapit($RLAT2,$RLON2,1);
    &NCAR::mapiq();
  }
}
#
#  Flush mapping buffer and end the picture.
#
&NCAR::mapiq();
&NCAR::frame();
#
#  Grid the data using NI longitudes and NJ latitudes.
#
for my $I ( 1 .. $NI ) {
  set( $PLAT, $I-1, -90.+($I-1)*2.5 );
}
for my $J ( 1 .. $NJ ) {
  set( $PLON, $J-1, -180.+($J-1)*2.5 );
}
#
#  Do the interpolation to the above uniform grid.  The call
#  to the triangulation routine CSSTRI above is not necessary
#  before calling CSSGRID - it was done in order to illustrate
#  its usage.
#
#     CALL CSSETR('SIG',2.)
#     CALL CSSETI('IGR',0)
&NCAR::cssgrid($N,$RLAT,$RLON,$FVAL,$NI,$NJ,$PLAT,$PLON,$FF,$IWK,$RWK,my $IER);
#
#  Draw a contour map of the gridded data on the globe.
#
&NCAR::mapsti ('PE - PERIMETER',0);
&NCAR::mapsti ('GR - GRID',0);
&NCAR::mapstc ('OU - OUTLINE DATASET','PS');
&NCAR::mapsti ('DO - DOTTING OF OUTLINES',1);
&NCAR::mapdrw();
#
&NCAR::gsplci(3);
&NCAR::gstxci(3);
&NCAR::gstxfp(-13,2);
&NCAR::cpseti ('SET - DO SET-CALL FLAG',0);
&NCAR::cpsetr ('DPS - LINE LABEL SIZE',0.02);
&NCAR::cpsetr ('T2D - TENSION ON THE 2D SPLINES',1.);
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTION FLAG',16);
&NCAR::cpsetc ('HLT - TURN OFF HIGH/LOW LABELS',' ');
&NCAR::cpsetc ('ILT - TURN OFF INFORMATIONAL LABEL',' ');
#
&NCAR::cpsetr ('XC1 - X COORDINATE AT I = 1',-180.);
&NCAR::cpsetr ('XCM - X COORDINATE AT I = M', 180.);
&NCAR::cpsetr ('YC1 - Y COORDINATE AT J = 1', -90.);
&NCAR::cpsetr ('YCN - Y COORDINATE AT J = N',  90.);
&NCAR::cpseti ('MAP - MAPPING FLAG',1);
&NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',1.E12);
#
#  Reverse the indices, since CSSGRID returns FF as a function
#  of latitude and longitude, whereas Conpack wants longitude as
#  the first dimension.
#
for my $I ( 1 .. $NI ) {
  for my $J ( 1 .. $NJ ) {
    set( $ZDAT, $J-1, $I-1, at( $FF, $I-1, $J-1 ) );
  }
}
#
&NCAR::cprect ($ZDAT,$NJ,$NJ,$NI,$RWRK,$IRWRK,$IWRK,$IIWRK);
&NCAR::arinam ($IAMA,$IAMASZ);
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
#
#  Plot picture title.
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq(0.50,0.95,':F26:Contour Plot of Gridded Data',0.025,0.,0.);
#
&NCAR::frame();
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
sub DRAWCL {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
  my $IDR = 1;
  for my $I ( 1 .. $NAI ) {
    if( at( $IAI, $I-1 ) < 0 ) { $IDR = 0; }
  }
  if( $IDR != 0 ) { &NCAR::curved( $XCS,$YCS,$NCS ); }
#
}

rename 'gmeta', 'ncgm/cssex02.ncgm';

