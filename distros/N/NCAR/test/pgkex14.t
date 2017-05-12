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

my $DTR = .017453292519943;
#
#  Define colors.
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,1.);
&NCAR::gscr(1,2,.4,.0,.4);
#
&NCAR::gstxfp(-4,2);
#
#  Alignment = [center, center]
#
&NCAR::gstxal(2,3);
#
#  Loop through angles from 1 degree to 135 degrees on a circular arc
#  in increments proportional to character heights.  Position text
#  strings centered on a circular arc with up vectors being tangents
#  to the arc.
#
my $IANG = 1;

while( 1 ) {
my $ANG=$DTR*$IANG;
my $XOFF = .3;
my $YOFF = .2;
#
#  Calculate an (X,Y) coordinate on the arc.
#
my $XCD=$XOFF+.4*cos($ANG);
my $YCD=$YOFF+.4*sin($ANG);
#
#  The up vector is tangent to the circular arc.
#
my $CHUX = -($YCD-$YOFF);
my $CHUY =   $XCD-$XOFF;
&NCAR::gschup($CHUX,$CHUY);
#
#  Scale the character heights depending on the angle and plot the text.
#
my $CHH = .0004*(136-$IANG);
&NCAR::gschh($CHH);
&NCAR::gtx($XCD,$YCD,'NCAR');
#
#  Increment the angle by an amount proportional to the character heights.
#
$IANG = $IANG+max(210.*$CHH,1.);

last unless( $IANG <= 135 );
}
#
#  Plot a character string with the up vector being down.
#
&NCAR::gschup(0.,-1.);
&NCAR::gschh(.03);
&NCAR::gtx(.25,.34,'NCAR');
&NCAR::gschup(0.,1.);
&NCAR::gstxci(2);
&NCAR::gschh(.025);
&NCAR::gtx(.25,.40,'Vect.=(0.,-1.)');
#
#  Plot a character string with up vector at an angle to the right.
#
&NCAR::gschup(1.6,2.);
&NCAR::gschh(.03);
&NCAR::gstxci(1);
&NCAR::gtx(.65,.65,'NCAR');
&NCAR::gschup(0.,1.);
&NCAR::gstxci(2);
&NCAR::gschh(.025);
&NCAR::gtx(.8,.7,'Vect.=(1.6,2.)');
#
#  Label the plot using Plotchar.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 2 );
&NCAR::plchhq(.1,.89,'Character heights &',.035,0.,-1.);
&NCAR::plchhq(.1,.82,'Character up vectors',.035,0.,-1.);

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex14.ncgm';
