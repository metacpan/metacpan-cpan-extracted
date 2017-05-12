# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my ( @xdra, @ydra );


# Compute required constants.

my $pi=3.14159265358979;
my $pid200=$pi/200.;
my $pittwo=2.*$pi;
my $pit2d3=2.*$pi/3.;
my $pit4d3=4.*$pi/3.;
my $radosc=sqrt(3.)/3.;
my $radolc=sqrt(3.)/2.;
my $bsscll=atan(sqrt(12.)/6.);
my $bsscul=atan(sqrt(143.)/7.);
my $bslcll=atan(sqrt(143.)/17.);
my $bslcul=atan(sqrt(2.0));

for my $i ( 1 .. 401 ) {
  my $theta=$pid200*($i-1);
  $xdra[0][$i-1]=   -.5+$radosc*cos($theta);
  $ydra[0][$i-1]=       $radosc*sin($theta);
  if( (abs($theta) >= $bsscll) &&
      (abs($theta) <= $bsscul) ) {
         $xdra[0][$i-1]=1.e36;
  }
  if( (abs($theta-$pittwo) >= $bsscll) &&
      (abs($theta-$pittwo) <= $bsscul) ) {
         $xdra[0][$i-1]=1.e36;
  }
  $xdra[1][$i-1]=.5+$radosc*cos($theta);
  $ydra[1][$i-1]=   $radosc*sin($theta);
  if( (abs($theta-$pit2d3) >= $bsscll) &&
      (abs($theta-$pit2d3) <= $bsscul) ) {
         $xdra[1][$i-1]=1.e36;
  }
  $xdra[2][$i-1]=        $radosc*cos($theta);
  $ydra[2][$i-1]=$radolc+$radosc*sin($theta);
  if( (abs($theta-$pit4d3) >= $bsscll) &&
      (abs($theta-$pit4d3) <= $bsscul) ) {
         $xdra[2][$i-1]=1.e36;
  }
  $xdra[3][$i-1]=   -.5+$radolc*cos($theta);
  $ydra[3][$i-1]=       $radolc*sin($theta);
  if( (abs($theta) >= $bslcll) &&
      (abs($theta) <= $bslcul) ) {
         $xdra[3][$i-1]=1.e36;
  }
  if( (abs($theta-$pittwo) >= $bslcll) &&
      (abs($theta-$pittwo) <= $bslcul) ) {
         $xdra[3][$i-1]=1.e36;
  }
  $xdra[4][$i-1]=    .5+$radolc*cos($theta);
  $ydra[4][$i-1]=       $radolc*sin($theta);
  if( (abs($theta-$pit2d3) >= $bslcll) &&
      (abs($theta-$pit2d3) <= $bslcul) ) {
         $xdra[4][$i-1]=1.e36;
  }
  $xdra[5][$i-1]=        $radolc*cos($theta);
  $ydra[5][$i-1]=$radolc+$radolc*sin($theta);
  if( (abs($theta-$pit4d3) >= $bslcll) &&
      (abs($theta-$pit4d3) <= $bslcul) ) {
         $xdra[5][$i-1]=1.e36;
  }
}



# Specify subscripting of XDRA and YDRA.

&NCAR::agseti( 'ROW.', 2 );

# Set up grid shape to make 1 unit in x = 1 unit in y.

&NCAR::agsetr( 'GRID/SHAPE.', 2. );

# Turn off background, then turn labels back on.

&NCAR::agsetr( 'BACKGROUND.', 4. );
&NCAR::agseti( 'LABEL/CONTROL.', 2 );

# Turn off left label.

&NCAR::agsetc( 'LABEL/NAME.', 'L' );
&NCAR::agseti( 'LABEL/SUPPRESSION FLAG.', 1 );

# Change text of bottom label.

&NCAR::agsetc( 'LABEL/NAME.', 'B' );
&NCAR::agseti( 'LINE/NUMBER.', -100 );
&NCAR::agsetc( 'LINE/TEXT.', 'PURITY, BODY, AND FLAVOR$' );

&bndary();

my $xdra = float \@xdra;
my $ydra = float \@ydra;

&NCAR::ezmxy( $xdra, $ydra, 401, 6, 401, 'EXAMPLE 5 (EZMXY)$' );

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

sub bndary {
&NCAR::plotit(     0,    0,0 );
&NCAR::plotit( 32767,    0,1 );
&NCAR::plotit( 32767,32767,1 );
&NCAR::plotit(     0,32767,1 );
&NCAR::plotit(     0,    0,1 );
}


rename 'gmeta', 'ncgm/agex05.ncgm';
