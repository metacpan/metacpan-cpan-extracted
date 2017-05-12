# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; };
END {print "not ok 1\n" unless $loaded;};
use NCAR;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use PDL;
use NCAR::Test;

&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  Set up a color table.
#
&NCAR::gscr( 1,0,1.,1.,1.);
&NCAR::gscr( 1,1,0.,0.,0.);
&NCAR::gscr( 1,2,0.,0.,1.);
&NCAR::gscr( 1,3,1.,0.,0.);
#
#  Main title.
#
&NCAR::plchhq(0.5,0.90,":F26:Logos",0.05,0.,0.);
#
#  Change the Plotchar function code control character from
#  its default value of a colon, since we want to produce a colon
#  in calls to PLCHHQ.
#
&NCAR::pcsetc( 'FC', '#' );
#
#  Use Helvetica for the label font.
#
&NCAR::pcsetc( 'FN', 'HELVETICA' );
#
#  Put out examples of the five logo types.
#
#   Type 1 - an NCAR logo that will be full-color for
#            PostScript output and single color otherwise.
#
my $iwkid = 1;
my $psize = 0.04;
my $pxpos = 0.23;
my $xlpos = 0.67;
my $ylpos = 0.75;
my $sizel = 0.10;
my $yinc  = 0.14;
&NCAR::plchhq($pxpos, $ylpos, "Type 1:", $psize, 0.,-1.);
&NCAR::nglogo($iwkid, $xlpos, $ylpos, $sizel, 1, 1, 1);
#
#   Type 2 - the UCAR star logo in red.
#
$ylpos = $ylpos-$yinc;
&NCAR::plchhq($pxpos, $ylpos, "Type 2:", $psize, 0.,-1.);
&NCAR::nglogo($iwkid, $xlpos, $ylpos, $sizel, 2, 3, 1);
#
#   Type 3 - the text string "NCAR" in Bell Gothic font.
#
$ylpos = $ylpos-$yinc;
&NCAR::plchhq($pxpos, $ylpos, "Type 3:", $psize, 0.,-1.);
&NCAR::nglogo($iwkid, $xlpos, $ylpos, 0.6*$sizel, 3, 1, 1);
#
#   Type 4 - the text string "UCAR" in Bell Gothic font.
#
$ylpos = $ylpos-$yinc;
&NCAR::plchhq($pxpos, $ylpos, "Type 4:", $psize, 0.,-1.);
&NCAR::nglogo($iwkid, $xlpos, $ylpos, 0.6*$sizel, 4, 1, 1);
#
#   Type 5 - the UCAR star logo in blue with the text "UCAR" in red.
#
$ylpos = $ylpos-$yinc;
&NCAR::plchhq($pxpos, $ylpos, "Type 5:", $psize, 0.,-1.);
&NCAR::nglogo($iwkid, $xlpos-0.1, $ylpos, $sizel, 5, 2, 3);
#
#  Put an NCAR logo at the lower right using NGEZLOGO.
#
&NCAR::ngezlogo();
      
&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/miex01.ncgm';
