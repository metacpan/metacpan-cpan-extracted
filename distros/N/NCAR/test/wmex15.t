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

#
#  Example of adjusting wind barb directions when drawing
#  station model data.
#
#  City names and locations, station model data.
#
#   NUMC    -  the number of cities.
#   ICITYS  -  city names.
#   CITYUX  -  latitude of city.
#   CITYUY  -  longitude of city.
#   IMDAT   -  station model date for city.
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
my @CITYUX = (
      40.0,   47.6,   37.8,   34.1,   45.8,   31.8,   29.8,
      39.1,   45.0,   41.9,   42.3,   33.8,   25.8,   40.8,
      44.1,   43.6,   40.7,   33.5,   35.1,   46.7,   36.0,
      32.8,   34.7,   38.1,   35.2,   36.8,   44.8
);
#
my @CITYUY = (
    -105.0, -122.3, -122.4, -118.3, -108.5, -106.5, - 95.3,
    - 94.1, - 93.8, - 87.6, - 83.1, - 84.4, - 80.2, - 74.0,
    -123.1, -116.2, -111.9, -112.1, -106.6, -100.8, - 96.0,
    - 96.8, - 92.3, - 84.1, - 80.8, - 76.3, - 68.8
);
#
#  Station model data.  All wind directions have been set to zero, which
#  implies a northerly wind (from the north).
#
my @IMDAT = ( 
     ['11000','00075','11260','21360','30000',
                               '49550','54054','60000','77570','87712' ],
     ['11103','10001','11040','21080','30000',
                               '49590','55050','60051','70430','80369' ],
     ['11206','20003','11020','21040','30000',
                               '49630','56046','60151','70840','81470' ],
     ['11309','30006','10000','21020','30000',
                               '49670','57042','60201','71250','82581' ],
     ['11412','40009','10020','21010','30000',
                               '49710','58038','60251','71660','83592' ],
     ['11515','50012','10040','20000','30000',
                               '49750','50034','60301','72070','84703' ],
     ['11618','60015','10060','20030','30000',
                               '49790','51030','60350','72480','85814' ],
     ['11721','70018','10080','20050','30000',
                               '49830','52026','60400','72890','86925' ],
     ['11824','80021','10090','20070','30000',
                               '49870','53022','60450','73230','87036' ],
     ['11927','90024','10110','20110','30000',
                               '49910','54018','60501','73640','88147' ],
     ['11030','00027','10130','20130','30000',
                               '49950','55014','60551','74050','89258' ],
     ['11133','10030','10150','20170','30000',
                               '49990','56010','60601','74460','80369' ],
     ['11236','20033','10170','20200','30000',
                               '40000','57006','60651','74870','81470' ],
     ['11339','30036','10190','20230','30000',
                               '40040','58002','60701','75280','82581' ],
     ['11442','40039','10210','20250','30000',
                               '40080','50000','60751','75690','83692' ],
     ['11545','50042','10230','20270','30000',
                               '40120','51040','60801','76030','84703' ],
     ['11648','60045','10250','20290','30000',
                               '40170','52008','60851','76440','85814' ],
     ['11751','70048','10270','20310','30000',
                               '40210','53012','60901','76850','86925' ],
     ['11854','80051','10290','20330','30000',
                               '40250','54016','60950','77260','87036' ],
     ['11958','90054','10310','20360','30000',
                               '40290','55018','61000','77670','88147' ],
     ['11060','00057','10330','20380','30000',
                               '40330','56030','61050','78080','89258' ],
     ['11163','10060','10350','20410','30000',
                               '40370','57034','61100','78490','80369' ],
     ['11266','20063','10370','20430','30000',
                               '40410','58043','61150','78830','81470' ],
     ['11369','30066','10390','20470','30000',
                               '40450','50041','61200','79240','82581' ],
     ['11472','40069','10410','20500','30000',
                               '40480','51025','61250','79650','83692' ],
     ['11575','50072','10430','20530','30000',
                               '40510','52022','61350','79960','84703' ],
     ['11678','60075','10480','21580','30000',
                               '40550','53013','61400','73370','85814' ],
);
#
#  Set the foreground and background colors.
#
&NCAR::gscr (1,0,1.,1.,1.);
&NCAR::gscr (1,1,0.,0.,0.);
#
#  Tell EZMAP what part of the frame to use.
#
&NCAR::mappos (.05,.95,.05,.95);
#
#  Draw a satellite view projection.
#

&NCAR::mapstr ('SA',1.3);
&NCAR::maproj ('SV',40.,-97.,35.);
&NCAR::mapset ('MA',
                float( [ 0., 0 ] ),
		float( [ 0., 0 ] ),
		float( [ 0., 0 ] ),
		float( [ 0., 0 ] )
		);
#     CALL MAPSTC ('OU','CO')
&NCAR::mapstc ('OU','US');
#
#  Draw the EZMAP background.
#
&NCAR::mapdrw();
#
#  In the middle of Nebraska, draw a wind barb for a northeasterly wind
#  with a magnitude of 15 knots.
#
&NCAR::maptrn (42.,    -99., my ( $XO, $YO ) );
&NCAR::maptrn (42.+0.1,-99., my ( $XA, $YA ) );
my $UW=($XA-$XO)/sqrt(($XA-$XO)*($XA-$XO)+($YA-$YO)*($YA-$YO));
my $VW=($YA-$YO)/sqrt(($XA-$XO)*($XA-$XO)+($YA-$YO)*($YA-$YO));
&NCAR::wmbarb ($XO,$YO,15.*$UW,15.*$VW);
#
#  Plot station models at selected cities.  Prior to calling WMSTNM, the
#  wind direction in the array IMDAT is modified so that the wind barb
#  will point in the correct direction relative to the map.  This is done
#  by projecting both ends of a tiny wind vector and then computing the
#  angle that the projected wind vector makes with the sides of the map.
#  After the call to WMSTNM, the original wind direction is restored.
#
#  (Note that, because the contents of IMDAT have been defined in DATA
#  statements above so that all winds are northerlies, all wind barbs
#  will point to the north.  Uncommenting one of the other lines setting
#  ANGR will make all of the wind barbs point in some other direction.
#  This is useful for testing purposes.)
#
for my $I ( 1 .. $NUMC ) {
#
#  Find the position of the city on the map.
#
  &NCAR::maptrn ($CITYUX[$I-1],$CITYUY[$I-1],my ( $XO,$YO ) );
#
#  Modify the wind speed before calling WMSTNM.
#
  my $SV2C=substr( $IMDAT[$I-1][1], 1, 2 );
  my $IANG=sprintf( '%2d', $SV2C );
#
#  Modify the direction of the wind barb.
#
  my $ANGR=$DTOR*(10*$IANG);
  &NCAR::maptrn($CITYUX[$I-1]+.1*cos($ANGR),$CITYUY[$I-1]+.1/cos($DTOR*$CITYUX[$I-1])*sin($ANGR),my ( $XA,$YA ) );
  my $ANGD=$RTOD * atan2($XA-$XO,$YA-$YO)+360.;
  $ANGD = $ANGD - 360 * int( $ANGD / 360 );
  my $IANG=&NCAR::Test::max(0,&NCAR::Test::min(35,int($ANGD/10.)));
  $IMDAT[$I-1][1] = sprintf( '%2d', $IANG );
#
#  Call WMSTNM.
#
  &NCAR::wmstnm ($XO,$YO,$IMDAT[$I-1]);
#
#  Restore the original wind speed after calling WMSTNM.
#
  substr( $IMDAT[$I-1][1], 1, 2, $SV2C );
#
}
#

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/wmex15.ncgm';
