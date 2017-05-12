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
#       $Id: cssex01.f,v 1.6 2000/01/12 23:50:55 fred Exp $
#
#
#  Example of Delaunay triangulation and Voronoi diagram
#  on the surface of a sphere.
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Input dataset on the globe (latitudes and longitudes in degrees).
#  These data points do not cover the globe, but rather are confined
#  to the nothern hemisphere and are enclosed by a boundary.
#
my $NMAX = 7;
my $RLAT = float [   70.,  70., 70., 85., 60., 60., 65. ];
my $RLON = float [ -160., -70.,  0., 20., 50., 80.,140. ];
#
#  Dimension the arrays for holding the points for drawing 
#  circular arcs.
#
my $NARC = 50;
my $ARCLAT = zeroes float, $NARC;
my $ARCLON = zeroes float, $NARC;
my $ARCUAR = zeroes float, $NARC;
my $ARCVAR = zeroes float, $NARC;
#
#  Storage for the triangulation, work space, and Voronoi vertices.
#
my ( $NTMX, $NT6, $LWK ) = ( 2*$NMAX, 6*$NMAX, 27*$NMAX );
my $LTRI = zeroes long, 3, $NTMX;
my $IWK = zeroes long, $LWK;
my $NV = zeroes long, $NMAX;
#
#  Real workspace.
#
my $RWK = zeroes double, 13*$NMAX;
#
#  Storage for circumcenters and circum radii.
#
my $PLAT = zeroes float, $NTMX;
my $PLON = zeroes float, $NTMX;
my $RC   = zeroes float, $NTMX;
#
my $N = $NMAX;
#
#  Create the triangulation, storing the vertices in LTRI.
#
&NCAR::csstri ($N,$RLAT,$RLON, my $NT,$LTRI, $IWK,$RWK, my $IER);
#
#  Plot the Delaunay triangulation, the circumcircles, and
#  the Voronoi polygons on a sphere.
#
#  Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
#  Color table.
#
&NCAR::gscr($IWKID,0,0.,0.,0.);
&NCAR::gscr($IWKID,1,1.,1.,1.);
&NCAR::gscr($IWKID,2,0.,1.,1.);
&NCAR::gscr($IWKID,3,1.,1.,0.);
&NCAR::gscr($IWKID,4,1.,0.,0.);
&NCAR::gscr($IWKID,5,0.,1.,0.);
&NCAR::gscr($IWKID,6,0.,.8,0.);
#
# Draw a map of the North Atlantic, as seen by a satellite.
#
&NCAR::gsplci(6);
&NCAR::mapstr ('SA',4.);
&NCAR::mappos(0.175, 0.975, 0.025, 0.825);
&NCAR::supmap (7,72.5,127.5,0., 
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               1,-1000,5,0,my $IERR);
#
#  Get the circumcenters of the Delaunay triangles.
#
&NCAR::csvoro($N,$RLAT,$RLON,1,1,$IWK,$RWK,$NTMX,$PLAT,$PLON,$RC, my $NCA, my $NUMV,$NV,$IER);
#
#  Plot the circumcircles whose circumcenters lie in one of
#  the Delaunay triangles composed of original data points
#  (exclude the pseudo points added to complete the
#  triangulation on the whole sphere).
#
&NCAR::gslwsc(2.0);
&NCAR::gsplci(4);
for my $I ( 5 .. 10 ) {
#
  &NCAR::nggcog( at( $PLAT, $I-1 ), at( $PLON, $I-1 ), at( $RC, $I-1 ),$ARCLAT,$ARCLON,$NARC);
  &NCAR::mapit( at( $ARCLAT, 0 ), at( $ARCLON, 0 ), 0 );
  for my $J ( 2 .. $NARC-1 ) {
    &NCAR::mapit( at( $ARCLAT, $J-1 ), at( $ARCLON, $J-1 ), 1 );
  }
  &NCAR::mapit( at( $ARCLAT, $NARC-1 ), at( $ARCLON, $NARC-1 ), 1 );
  &NCAR::mapiq();
}
#
#  Draw the Voronoi polygons.
#
for my $I ( 1 .. $N ) {
#
#  Get the polygon containing the original data point
#  (X(I),Y(I),Z(I)).  
#
  &NCAR::csvoro( 
    $N, $RLAT, $RLON, $I, 0, $IWK, $RWK, $NTMX,
    $PLAT, $PLON, $RC, $NCA, $NUMV, $NV, my $IER 
  );
  
  for my $NN ( 2 .. $NUMV ) {
#
#  Get a polygonal segment.
#
    my $RLAT1 = at( $PLAT, at( $NV, $NN-2 )-1 );
    my $RLON1 = at( $PLON, at( $NV, $NN-2 )-1 );
    my $RLAT2 = at( $PLAT, at( $NV, $NN-1 )-1 );
    my $RLON2 = at( $PLON, at( $NV, $NN-1 )-1 );
#
#  Plot it.
#
  &NCAR::gsplci( 3 );
  &NCAR::mapgci( $RLAT1, $RLON1, $RLAT2, $RLON2, $NARC, $ARCLAT, $ARCLON );
  &NCAR::mapit( $RLAT1, $RLON1, 0 );
  for my $J ( 1 .. $NARC ) {
    &NCAR::mapit( at( $ARCLAT, $J-1 ), at( $ARCLON, $J-1 ), 1 );
  }
  &NCAR::mapit( $RLAT2, $RLON2, 1 );
  &NCAR::mapiq();
  }
}
#
#  Draw the Delaunay triangles.
#
&NCAR::gsplci(2);
for my $NP ( 1 .. $NT ) {
  for my $NS ( 1 .. 3 ) {
    &NCAR::mapgci(
       at( $RLAT, at( $LTRI, $NS-1, $NP-1 )-1 ), 
       at( $RLON, at( $LTRI, $NS-1, $NP-1 )-1 ),
       at( $RLAT, at( $LTRI, ( $NS % 3 ), $NP-1 )-1 ),
       at( $RLON, at( $LTRI, ( $NS % 3 ), $NP-1 )-1 ),
       $NARC, $ARCLAT, $ARCLON 
    );
    &NCAR::mapit(
       at( $RLAT, at( $LTRI, $NS-1, $NP-1 )-1 ),
       at( $RLON, at( $LTRI, $NS-1, $NP-1 )-1 ),
    0);
    for my $I ( 1 .. $NARC ) {
      &NCAR::mapit( at( $ARCLAT, $I-1 ), at( $ARCLON, $I-1 ), 1 );
    }
    &NCAR::mapit(
       at( $RLAT, at( $LTRI, $NS-1, $NP-1 )-1 ),
       at( $RLON, at( $LTRI, $NS-1, $NP-1 )-1 ),
    1);
  }
}
&NCAR::mapiq();
#
#  Mark the original data points.
#
&NCAR::gsfaci(3);
for my $I ( 1 .. $N ) {
  &NCAR::nggcog( at( $RLAT, $I-1 ), at( $RLON, $I-1 ),1.2, $ARCLAT, $ARCLON, $NARC );
  for my $L ( 1 .. $NARC ) {
    &NCAR::maptrn( 
       at( $ARCLAT, $L-1 ), 
       at( $ARCLON, $L-1 ),
       my ( $arcuar, $arcvar ) 
    );
    set( $ARCUAR, $L-1, $arcuar ); 
    set( $ARCVAR, $L-1, $arcvar ); 
  }
  &NCAR::gfa( $NARC, $ARCUAR, $ARCVAR );
}
#
#  Mark the circumcenters.
#
&NCAR::gsfaci(5);
for my $I ( 5 .. 10 ) {
  &NCAR::nggcog( at( $PLAT, $I-1 ), at( $PLON, $I-1 ),0.6, $ARCLAT, $ARCLON, $NARC );
  for my $L ( 1 .. $NARC ) {
    &NCAR::maptrn( 
       at( $ARCLAT, $L-1 ), 
       at( $ARCLON, $L-1 ), 
       my ( $arcuar, $arcvar ) 
    );
    set( $ARCUAR, $L-1, $arcuar ); 
    set( $ARCVAR, $L-1, $arcvar ); 
  }
  &NCAR::gfa($NARC,$ARCUAR,$ARCVAR);
}
#
#  Put out a legend.
#
&NCAR::set(0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1);
#
&CSDRBX(0.02, 0.945, 0.12, 0.955, 2);
&NCAR::pcseti('CC',1);
&NCAR::plchhq(0.14, 0.95, ':F22:Delaunay triangles', 0.025, 0.0, -1.0);
#
&CSDRBX(0.02, 0.895, 0.12, 0.905, 3);
&NCAR::plchhq(0.14, 0.90, ':F22:Voronoi polygons', 0.025, 0.0, -1.0);
#
&CSDRBX(0.02, 0.845, 0.12, 0.855, 4);
&NCAR::plchhq(0.14, 0.85, ':F22:Circumcircles', 0.025, 0.0, -1.0);
#
&NCAR::frame();
#
#  Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
sub CSDRBX {
  my ($XLL,$YLL,$XUR,$YUR,$ICNDX) = @_;
#
#  Draw a filled rectangle with the specified corner points 
#  using color index ICNDX.
#
#
  &NCAR::gqfaci( my ( $IER,$ICOLD ) );
#
  my $X = float [ $XLL, $XUR, $XUR, $XLL, $XLL ];
  my $Y = float [ $YLL, $YLL, $YUR, $YUR, $YLL ];
# 
  &NCAR::gsfaci($ICNDX);
  &NCAR::gfa(5,$X,$Y);
  &NCAR::gsfaci($ICOLD);
#
}

rename 'gmeta', 'ncgm/cssex01.ncgm';
