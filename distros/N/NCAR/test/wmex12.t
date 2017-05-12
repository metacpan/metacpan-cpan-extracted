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
use Math::Trig qw();
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  City names and locations, Station model data.
#
#   NUMC    -  the number of cities.
#   ICITYS  -  City names.
#   CITYUX  -  latitude of city.
#   CITYUY  -  longitude of city.
#   IMDAT   -  station model data for city.
#   SV2C    -  variable in which to save two characters.
#
my $NUMC=27;
#
#  Constants used to convert from degrees to radians and from radians
#  to degrees.
#
my $DTOR = .017453292519943;
my $RTOD = 57.2957795130823;
#
#  City names.
#
my @ICITYS = (
                'NCAR',       'Seattle', 'San Francisco',               
         'Los Angeles',      'Billings',       'El Paso',
             'Houston',   'Kansas City',   'Minneapolis',
             'Chicago',       'Detroit',       'Atlanta',
               'Miami',      'New York',        'Eugene',
               'Boise',     'Salt Lake',       'Phoenix',
         'Albuquerque',      'Bismarck',         'Tulsa',
              'Dallas',   'Little Rock',     'Lexington',
           'Charlotte',       'Norfolk',        'Bangor'
);
#
#  City locations.
#
my $CITYUX = float [
        40.0,   47.6,   37.8,   34.1,   45.8,   31.8,   29.8, 
        39.1,   45.0,   41.9,   42.3,   33.8,   25.8,   40.8,
        44.1,   43.6,   40.7,   33.5,   35.1,   46.7,   36.0,
        32.8,   34.7,   38.1,   35.2,   36.8,   44.8
];
my $CITYUY = float [
     +  -105.0, -122.3, -122.4, -118.3, -108.5, -106.5, - 95.3, 
     +  - 94.1, - 93.8, - 87.6, - 83.1, - 84.4, - 80.2, - 74.0,
     +  -123.1, -116.2, -111.9, -112.1, -106.6, -100.8, - 96.0,
     +  - 96.8, - 92.3, - 84.1, - 80.8, -076.3, - 68.8
];
#
#  Station model data.
#
my @IMDAT;
$IMDAT[0] = [ '11000','00000','11260','21360','30000',       
                               '49550','54054','60000','77570','87712' ];
$IMDAT[1] = [ '11103','11101','11040','21080','30000',
                               '49590','55050','60051','70430','80369' ];
$IMDAT[2] = [ '11206','21003','11020','21040','30000',
                               '49630','56046','60151','70840','81470' ];
$IMDAT[3] = [ '11309','31106','10000','21020','30000',
                               '49670','57042','60201','71250','82581' ];
$IMDAT[4] = [ '11412','41209','10020','21010','30000',
                               '49710','58038','60251','71660','83592' ];
$IMDAT[5] = [ '11515','51312','10040','20000','30000',
                               '49750','50034','60301','72070','84703' ];
$IMDAT[6] = [ '11618','61415','10060','20030','30000',
                               '49790','51030','60350','72480','85814' ];
$IMDAT[7] = ['11721','71518','10080','20050','30000',
                               '49830','52026','60400','72890','86925' ];
$IMDAT[8] = ['11824','81621','10090','20070','30000',
                               '49870','53022','60450','73230','87036' ];
$IMDAT[9] = ['11927','91724','10110','20110','30000',
                               '49910','54018','60501','73640','88147' ];
$IMDAT[10] = ['11030','01827','10130','20130','30000',
                               '49950','55014','60551','74050','89258' ];
$IMDAT[11] = ['11133','11930','10150','20170','30000',
                               '49990','56010','60601','74460','80369' ];
$IMDAT[12] = ['11236','22033','10170','20200','30000',
                               '40000','57006','60651','74870','81470' ];
$IMDAT[13] = ['11339','32136','10190','20230','30000',
                               '40040','58002','60701','75280','82581' ];
$IMDAT[14] = ['11442','42239','10210','20250','30000',
                               '40080','50000','60751','75690','83692' ];
$IMDAT[15] = ['11545','52342','10230','20270','30000',
                               '40120','51040','60801','76030','84703' ];
$IMDAT[16] = ['11648','62445','10250','20290','30000',
                               '40170','52008','60851','76440','85814' ];
$IMDAT[17] = ['11751','70048','10270','20310','30000',
                               '40210','53012','60901','76850','86925' ];
$IMDAT[18] = ['11854','82651','10290','20330','30000',
                               '40250','54016','60950','77260','87036' ];
$IMDAT[19] = ['11958','92754','10310','20360','30000',
                               '40290','55018','61000','77670','88147' ];
$IMDAT[20] = ['11060','02857','10330','20380','30000',
                               '40330','56030','61050','78080','89258' ];
$IMDAT[21] = ['11163','12960','10350','20410','30000',
                               '40370','57034','61100','78490','80369' ];
$IMDAT[22] = ['11266','23063','10370','20430','30000',
                               '40410','58043','61150','78830','81470' ];
$IMDAT[23] = ['11369','33166','10390','20470','30000',
                               '40450','50041','61200','79240','82581' ];
$IMDAT[24] = ['11472','43269','10410','20500','30000',
                               '40480','51025','61250','79650','83692' ];
$IMDAT[25] = ['11575','51172','10430','20530','30000',
                               '40510','52022','61350','79960','84703' ];
$IMDAT[26] = ['11678','60075','10480','21580','30000',
                               '40550','53013','61400','73370','85814' ];
#
#  Calls to position the output (applicable only to PostScript output).
#
&NCAR::ngseti( 'LX', -90 );
&NCAR::ngseti( 'UX', 710 );
&NCAR::ngseti( 'LY', -15 );
&NCAR::ngseti( 'UY', 785 );
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,0.);
#
&NCAR::pcseti( 'CC', 1 );
&NCAR::plchhq(0.5,0.82,':F21:Sample Plotted Station Model Data', 0.02,0.,0.);
&NCAR::plchhq(0.5,0.77,':F21:(Data are not from actual readings)',0.02,0.,0.);
#
#  Set up the parameters for drawing the U.S. state outlines.
#
#   Position the plot.
&NCAR::mappos(0.05, 0.95, 0.00, 0.90);
#
#   Choose Lambert conformal projection with two standard parallels.
&NCAR::maproj('LC',30.,-100.,45.);
#
#   Specify U.S. state outlines.
&NCAR::mapstc('OU','US');
#
#   Specify the corner points of the plot as lat/lon pairs.
&NCAR::mapset('CO',
               float( [  22.6, 0 ] ),
	       float( [ -120., 0 ] ),
	       float( [  46.9, 0 ] ),
	       float( [ -64.2, 0 ] )
	       );
#
#   Draw the U.S. map.
&NCAR::mapdrw();
#  
#  Plot station models at selected cities.
#
#  Prior to calling WMSTNM, the wind direction in the array IMDAT is 
#  modified so that the wind barb will point in the correct direction 
#  relative to the map.  This is done by projecting both ends of a tiny 
#  wind vector and then computing the angle that the projected wind 
#  vector makes with the sides of the map.  After the call to WMSTNM, 
#  the original wind direction is restored.
#
#  In particular, the wind barbs for San Francisco, California
#  and Bangor, Maine indicate a northerly wind.  Note how they
#  align align with the longitude lines.
#
#  To get the correct wind barb directions relative to the map, the
#  wind speeds are converted into a rate of change of longitude.
#  That is to say, if a particle is at a given RLAT and RLON and it's 
#  moving with eastward component VE and northward component VN, then 
#  its position a bit later is given roughly by RLAT+Q*VN and 
#  RLON+Q*VE/COS(RLAT), where Q is some small quantity (the smaller 
#  the value of Q, the more accurate the position estimate).  By
#  projecting both (RLAT,RLON) and (RLAT+C*VN,RLON+Q*VE/COS(RLAT)), you
#  get points (XO,YO) and (XA,YA) on the map, defining the end points 
#  of a tiny vector pointing in the direction the particle is moving.  
#  As you get near the pole, there's a problem with this: COS(RLAT) 
#  becomes zero, so you're dividing by zero.  This reflects the fact that 
#  the concept "eastward" is undefined at the pole.
#
for my $I ( 1 .. $NUMC ) {
&NCAR::wmsetr( 'WBS - Wind barb size', 0.035 );
  if( ( $I == 10 ) || ( $I == 21 ) || ( $I == 22 ) || ( $I == 23 ) || ( $I == 25 ) ) {
&NCAR::wmsetr( 'WBS - Wind barb size', 0.028 );
  }
#
#  Find the position of the city on the map.
#
  &NCAR::maptrn( at( $CITYUX, $I-1 ),at( $CITYUY, $I-1 ), my $XO, my $YO );
#
#  Modify the wind direction before calling WMSTNM (note that the wind
#  directions, being represented as integers between 0 and 35, are 
#  accurate only to within 10 degrees).
#
  
  my $SV2C = substr( $IMDAT[$I-1][1], 1, 2 );
  my $IANG = sprintf( '%2d', $SV2C );
  my $ANGR = $DTOR*(10*$IANG);
  &NCAR::maptrn(at( $CITYUX, $I-1 )+.1* cos($ANGR),
                at( $CITYUY, $I-1 )+.1/cos($DTOR*at( $CITYUX, $I-1))*sin($ANGR), my ( $XA, $YA ) );
  my $ANGD = $RTOD*atan2($XA-$XO,$YA-$YO)+360.; 
  $ANGD = $ANGD - 360 * int( $ANGD / 360 );
  $IANG = &NCAR::Test::max(0,&NCAR::Test::min(35,int($ANGD/10.)));
  ( $I == 18 ) && ( $IANG = 1 );
  substr( $IMDAT[$I-1][1], 1, 2, sprintf( '%2d', $IANG ) );
#
#  Plot the station model data.
# 
  &NCAR::wmstnm($XO,$YO,$IMDAT[$I-1]); 
#
#  Restore original wind speed.
#
  substr( $IMDAT[$I-1][1], 1, 2, $SV2C );
#
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/wmex12.ncgm';
