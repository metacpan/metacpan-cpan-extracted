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
#       $Id: tezmap.f,v 1.5 1995/06/14 14:04:51 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# OPEN GKS, OPEN WORKSTATION OF TYPE 1, ACTIVATE WORKSTATION
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# PURPOSE                To provide a simple demonstration of
#                        the mapping utility, EZMAP.
#
# USAGE                  CALL TEZMAP (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#                          An integer variable
#                          = 0, if the test was successful,
#                          = 1, the test was not successful.
#
# I/O                    The map dataset must be connected to a
#                        FORTRAN unit.  See the open statement in
#                        this test deck.
#
#                        If the test is successful, the message
#
#              EZMAP TEST EXECUTED--SEE PLOTS TO CERTIFY
#
#                        is printed on unit 6.  In addition, 10
#                        frames are produced on the machine graphics
#                        device.  In order to determine if the test
#                        was successful, it is necessary to examine
#                        the plots.
#
# PRECISION              Single
#
# LANGUAGE               FORTRAN 77
#
# REQUIRED ROUTINES      EZMAP, GRIDAL
#
# REQUIRED GKS LEVEL     0A
#
# ALGORITHM              TEZMAP calls routine MAPROJ once for each of
#                        the 10 types of projections:
#                          stereographic,
#                          orthographic,
#                          Lambert conformal conic with 2 standard
#                            parallels,
#                          Lambert equal area,
#                          gnomonic,
#                          azimuthal equidistant,
#                          cylindrical equidistant,
#                          Mercator,
#                          Mollweide type, and
#                          satellite view.
#
# HISTORY                Written October, 1976, main entry SUPMAP.
#                        Updated September, 1985, main entry EZMAP.
#
my ( $IFRAME, $IERRR );
#
my $PLM1 = float [ 0, 0 ];
my $PLM2 = float [ 0, 0 ];
my $PLM3 = float [ 0, 0 ];
my $PLM4 = float [ 0, 0 ];
#
# Define the center of a plot title string on a square grid of size
# 0. to 1.
#
my ( $TX, $TY ) = ( 0.5, 0.9765 );
#
# Initialize the error parameter.
#
$IERRR = 0;
#
# Turn on the error recovery mode.
#
&NCAR::entsr(my $IDUM,1);
#
#
#     Frame 1 -- The stereographic projection.
#
$IFRAME = 1;
#
# Set the projection-type parameter.
#
&NCAR::maproj('ST',80.0,-160.0,0.0);
#
# Set the limit parameters.
#
&NCAR::mapset('MA',$PLM1,$PLM2,$PLM3,$PLM4);
#
# Set the outline-dataset parameter.
#
&NCAR::mapstc('OU','PS');
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
my $IERR;
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION:  STEREOGRAPHIC PROJECTION',16.,0.,0.);
&NCAR::frame();
L10:
#
#
#     Frame 2 -- The orthographic projection.
#
$IFRAME = 2;
#
#
# Set the projection-type parameter.
#
&NCAR::maproj('OR',60.0,-120.0,0.0);
#
# Draw the map.
#
&NCAR::mapdrw();
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Write the title.
#
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION:  ORTHOGRAPHIC PROJECTION',16.,0.,0.);
&NCAR::frame;
L20:
#
#
#     Frame 3 -- The Lambert conformal conic projection.
#
$IFRAME = 3;
#
#
# Set the projection-type, limits, and outline-dataset parameters.
#
&NCAR::maproj('LC',45.0,-100.0,45.0);
&NCAR::mapset('CO',
              float( [   50.0, 0 ] ),
	      float( [ -130.0, 0 ] ),
	      float( [   20.0, 0 ] ),
	      float( [  -75.0, 0 ] ),
	      );
&NCAR::mapstc('OU','US');
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION: LAMBERT CONFORMAL CONIC PROJECTION',16.,0.,0.);
&NCAR::frame;
 L30:
#
#
#     Frame 4 -- The Lambert equal area projection.
#
$IFRAME = 4;
#
# Set the projection-type, limits, and outline-dataset parameters.
#
&NCAR::maproj('LE',20.0,-40.0,0.0);
&NCAR::mapset('MA',$PLM1,$PLM2,$PLM3,$PLM4);
&NCAR::mapstc('OU','CO');
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION:  LAMBERT EQUAL AREA PROJECTION',16.,0.,0.);
&NCAR::frame;
L40:
#
#
#     Frame 5 -- The gnomonic projection.
#
$IFRAME = 5;
#
# Set the projection-type parameter.
#
&NCAR::maproj('GN',0.0,0.0,0.0);
#
# Draw the map.
#
&NCAR::mapdrw();
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION:  GNOMONIC PROJECTION',16.,0.,0.);
&NCAR::frame;
L50:
#
#
#     Frame 6 -- The azimuthal equidistant projection.
#
$IFRAME = 6;
#
# Set the projection-type parameter.
#
&NCAR::maproj('AE',-20.0,40.0,0.0);
#
# Set the grid spacing.
#
&NCAR::mapstr('GR',5.0);
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION:  AZIMUTHAL EQUIDISTANT PROJECTION',16.,0.,0.);
&NCAR::frame();
L60:
#
#
#     Frame 7 -- The cylindrical equidistant projection.
#
$IFRAME = 7;
#
# Set the map projection type parameter.
#
&NCAR::maproj('CE',-40.0,80.0,0.0);
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION:  CYLINDRICAL EQUIDISTANT PROJECTION',16.,0.,0.);
&NCAR::frame;
L70:
#
#
#     Frame 8 -- The mercator projection.
#
$IFRAME = 8;
#
# Set the map projection type parameter.
#
&NCAR::maproj('ME',-60.0,120.0,0.0);
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION: MERCATOR PROJECTION',16.,0.,0.);
&NCAR::frame();
L80:
#
#
#     Frame 9 -- The Mollyweide-type projection.
#
$IFRAME = 9;
#
# Set the map projection type parameter.
#
&NCAR::maproj('MO',-80.0,160.0,0.0);
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION:  MOLLWEIDE-TYPE PROJECTION',16.,0.,0.);
&NCAR::frame;
L90:
#
#
#     Frame 10 -- The satellite view projection.
#
$IFRAME = 10;
#
# Set the map projection type parameter.
#
&NCAR::maproj('SV',0.0,-135.0,0.0);
#
# Set the satellite distance and supress grid lines.
#
&NCAR::mapstr('SA',6.631);
&NCAR::mapsti('GR',0);
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Report any errors encountered.
#
if( &NCAR::nerro( $IERR ) != 0 ) { &RPTERR(); }
#
# Select normalization transformation 0.
#
&NCAR::gselnt(0);
#
# Call PLCHLQ to write the plot title.
#
&NCAR::plchlq($TX,$TY,'EZMAP DEMONSTRATION: SATELLITE VIEW PROJECTION',16.,0.,0.);
&NCAR::frame();
L100:
#
if( $IERRR == 0 ) { print STDERR " EZMAP TEST EXECUTED--SEE PLOTS TO CERTIFY\n"; }
if( $IERRR == 1 ) { print STDERR " EZMAP TEST UNSUCCESSFUL\n"; }
#



sub RPTERR {
#
# ROUTINE TO REPORT ERROR MESSEGES
#
#
  printf( STDERR " ERROR IN FRAME %2d ERROR MESSAGE FOLLOWS:\n", $IFRAME );
  &NCAR::eprin();
  print STDERR " ******\n";
  &NCAR::errof();
  $IERRR = 1;
  return;
#
}
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
 
   
rename 'gmeta', 'ncgm/tezmap.ncgm';
