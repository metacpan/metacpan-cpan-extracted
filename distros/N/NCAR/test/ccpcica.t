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
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $NLON, $NLAT, $LRWK, $LIWK, $ICAM, $ICAN ) = ( 361, 181, 5000, 5000, 512, 512 );
my $ZDAT = zeroes float, $NLON, $NLAT;
my $RWRK = zeroes float, $LRWK;
my $IASF = long [ ( 1 ) x 13 ];
my $IWRK = zeroes long, $LIWK;
my $ICRA = zeroes long, $ICAM, $ICAN;
# 
# Print out a warning about how time consuming this example is
# 
print STDERR "
 WARNING: This example may take 20 minutes or
 more to execute on some machines.
";
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
&NCAR::gsclip (0);
&NCAR::gsasf ($IASF);
# 
# Set up a color table
# 
&COLOR($IWKID);
# 
# Create some data
# 
my @t;
open DAT, "<data/ccpcica.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
  for my $ILAT ( 1 .. $NLAT ) {
for my $ILON ( 1 .. $NLON ) {
    set( $ZDAT, $ILON-1, $ILAT-1, shift( @t ) );
  }
}
# 
# 
# Setup a map
# 
&SETMAP ('SV',40.,-105.);
# 
# Setup contour options
# 
&SETCTR (0,1,-180.,180.,-90.,90.,1.E36);
# 
# Initialize Conpack
# 
&NCAR::cprect ($ZDAT,$NLON,$NLON,$NLAT,$RWRK,$LRWK,$IWRK,$LIWK);
# 
# Set cell array values and map it to user coordinates
# 
&NCAR::cpcica ($ZDAT,$RWRK,$IWRK,$ICRA,$ICAM,$ICAM,$ICAN,0.,0.,1.,1.);
# 
# Draw cell array and flush buffer
# 
&NCAR::gca (&NCAR::cfux(0.),&NCAR::cfuy(0.),
            &NCAR::cfux(1.),&NCAR::cfuy(1.),
            $ICAM,$ICAN,1,1,$ICAM,$ICAN,$ICRA);
&NCAR::sflush();
# 
# Draw contour lines
# 
&NCAR::gsplci (0);
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
&NCAR::sflush;
# 
# Draw Map
# 
&NCAR::gsplci (1);
&NCAR::gslwsc (3.);
&NCAR::maplot;
&NCAR::gslwsc (1.);
&NCAR::mapgrd;
&NCAR::sflush;
# 
# Draw title
# 
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::gsplci (1);
&NCAR::plchhq (.5,.95,'Cell Array in Conpack',.03,0.,0.);
# 
# Close Frame
# 
&NCAR::frame;
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;
      

      
sub SETMAP {
  my ($PTYPE,$PLAT,$PLON) = @_;
# 
# Set up a map projection with desired options, but don't draw it.
# 
      
  &NCAR::mappos (.05,.90,.05,.90);
  &NCAR::maproj ($PTYPE,$PLAT,$PLON,0.);
  &NCAR::mapset ('MA - MAXIMAL AREA',
                 float( [ 0., 0. ] ),
                 float( [ 0., 0. ] ),
                 float( [ 0., 0. ] ),
                 float( [ 0., 0. ] )
		 );
  &NCAR::mapint();

}      

sub SETCTR {
  my ($ISET,$MAPFLG,$XMIN,$XMAX,$YMIN,$YMAX,$SPVAL) = @_;
# 
# Set up Conpack options, but don't do anything
# 
  &NCAR::cpseti ('SET - DO-SET-CALL FLAG',$ISET);
  &NCAR::cpseti ('MAP - MAPPING FLAG',$MAPFLG);
  &NCAR::cpsetr ('XC1 - X COORDINATE AT I=1',$XMIN);
  &NCAR::cpsetr ('XCM - X COORDINATE AT I=M',$XMAX);
  &NCAR::cpsetr ('YC1 - Y COORDINATE AT J=1',$YMIN);
  &NCAR::cpsetr ('YCN - Y COORDINATE AT J=N',$YMAX);
  &NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTOR',1);
  &NCAR::cpsetr ('CMN - CONTOUR LEVEL MINIMUM',0.);
  &NCAR::cpsetr ('CMX - CONTOUR LEVEL MAXIMUM',110.);
  &NCAR::cpsetr ('CIS - CONTOUR INTERVAL SPECIFIER',10.);
  &NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',1.E12);
  &NCAR::cpsetr ('SPV - SPECIAL VALUE',$SPVAL);
  &NCAR::cpseti ('CAF - CELL ARRAY FLAG',2);
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',-1);
  &NCAR::cpseti ('AIA - AREA IDENTIFIER OUTSIDE THE GRID',99);
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',-2);
  &NCAR::cpseti ('AIA - AREA IDENTIFIER - SPECIAL-VALUE AREAS',100);
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',-3);
  &NCAR::cpseti ('AIA - AREA IDENTIFIER - OUT-OF-RANGE AREAS',101);
  &NCAR::cpseti ('LLP - LINE LABEL POSITIONING',0);
  &NCAR::cpsetc ('HLT - HIGH/LOW TEXT',' ');
#     CALL CPSETC ('ILT - INFORMATIONAL LABEL TEXT',' ');
}

sub COLOR {
  my ($IWKID) = @_;
  &NCAR::gscr ($IWKID, 0,0.000,0.000,0.000);
  &NCAR::gscr ($IWKID, 1,1.000,1.000,1.000);
  &NCAR::gscr ($IWKID, 2,0.500,1.000,1.000);
  for my $I ( 3 .. 15 ) {
  &NCAR::gscr ($IWKID,$I,
     &NCAR::Test::max(0.,&NCAR::Test::min(1.,1.-(abs($I- 3)/10.))),
     &NCAR::Test::max(0.,&NCAR::Test::min(1.,1.-(abs($I- 9)/10.))),
     &NCAR::Test::max(0.,&NCAR::Test::min(1.,1.-(abs($I-15)/10.))));
  }
  &NCAR::gscr ($IWKID,16,1.,0.,0.);
  &NCAR::gscr ($IWKID,101,0.,0.,0.) # OUTSIDE THE GRID;
  &NCAR::gscr ($IWKID,102,.5,.5,.5) # SPECIAL VALUE;
  &NCAR::gscr ($IWKID,103,0.,0.,0.) # OUT-OF-RANGE AREA;
} 
   
rename 'gmeta', 'ncgm/ccpcica.ncgm';
