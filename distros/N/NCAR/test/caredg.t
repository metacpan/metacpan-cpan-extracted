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
#
# Produce a Mercator projection of the Americas, using simplified 
# continental outlines.  See the routine MAPEOD, below.
# And draw a basic contour plot beside it.
#
my ( $M, $N ) =( 40, 40 );
my $Z = zeroes float, $M, $N;
my $RWRK = zeroes float, 2000;
my $IWRK = zeroes long, 2000;

my $PLIM1 = float [  -60., 0. ];
my $PLIM2 = float [ -170., 0. ];
my $PLIM3 = float [   75., 0. ];
my $PLIM4 = float [  -30., 0. ];
#
# Get some data
#
#&NCAR::gendat(Z,M,M,N,1,25,1.0,25.);
my @t;
open DAT, "<data/caredg.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
for my $I ( 1 .. $M ) {
  for my $J ( 1 .. $N ) {
    set( $Z, $I-1, $J-1, shift( @t ) );
  }
}
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Draw the map.
#
&NCAR::mappos (0.0,.53,0.53,1.);
&NCAR::supmap (9,0.,0.,0.,
               $PLIM1,$PLIM2,$PLIM3,$PLIM4,
	       2,0,2,0,my $IERR);
&NCAR::getset (my ( $VPL, $VPR, $VPB, $VPT, $WL, $WR, $WB, $WT, $LOG ) );
&NCAR::gselnt (0);
&NCAR::plchhq (.25,.50,'Geographic Map',.013,0.,0.);
#
# Draw contour plot
#
&NCAR::set (.53, 1.,$VPB,$VPT,1.,$M,1.,$N,$LOG);
&NCAR::cpsetr ('SET',0.);
&NCAR::cpsetr ('LLP',0.);
&NCAR::cprect ($Z, $M, $M, $N, $RWRK, 2000, $IWRK, 2000);
&NCAR::perim (0,0,0,0);
&NCAR::cpcldr ($Z, $RWRK, $IWRK);
&NCAR::gselnt (0);
&NCAR::plchhq (.75,.50,'Contour Map',.013,0.,0.);
#
# Draw Vertical Strips
#
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::line (.2,.05,.8,.05);
&NCAR::line (.2,.45,.8,.45);
&NCAR::line (.2,.05,.2,.45);
&NCAR::line (.3,.05,.3,.45);
&NCAR::line (.4,.05,.4,.45);
&NCAR::line (.5,.05,.5,.45);
&NCAR::line (.6,.05,.6,.45);
&NCAR::line (.7,.05,.7,.45);
&NCAR::line (.8,.05,.8,.45);
&NCAR::gselnt (0);
&NCAR::plchhq (.50,.01,'Vertical Strips',.013,0.,0.);
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
# Done.
#


   
rename 'gmeta', 'ncgm/caredg.ncgm';
