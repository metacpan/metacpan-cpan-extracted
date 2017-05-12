# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 30;

BEGIN { use_ok( 'Net::GPSD3' ); }

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

#my $string=q({"class":"TPV","tag":"RMC","device":"/dev/ttyUSB0","time":1253334480.119,"ept":0.005,"lat":38.949656667,"lon":-77.350946667,"epx":750.000,"epy":750.000,"epv":1150.000,"track":17.0300,"speed":0.211,"mode":3});
my $string='{"class":"TPV","tag":"0x0106","device":"/dev/cuaU0","time":"2011-03-20T06:51:59.12Z","ept":0.005,"lat":37.371427205,"lon":-122.015179890,"alt":25.789,"epx":1.926,"epy":1.808,"epv":6.497,"track":0.0000,"speed":0.000,"climb":0.000,"eps":3.85,"mode":3}';

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok($object, 'Net::GPSD3::Return::TPV');
isa_ok($object->parent, 'Net::GPSD3');
is($object->string, $string, 'string');

is($object->class, 'TPV', 'class');
is($object->tag, "0x0106", "tag");
is($object->device, "/dev/cuaU0", "device");
is($object->time, "1300603919.12", "time");
is($object->timestamp, "2011-03-20T06:51:59.12Z", "time");
isa_ok($object->datetime, "DateTime");
is($object->datetime->iso8601, "2011-03-20T06:51:59", "datetime"); #just to second
is($object->datetime->hires_epoch, "1300603919.12", "datetimei epoch");
is($object->ept, "0.005", "ept");
is($object->lat, "37.371427205", "lat");
is($object->lon, "-122.01517989", "lon");
is($object->epx, "1.926", "epx");
is($object->epy, "1.808", "epy");
is($object->epv, "6.497", "epv");
is($object->eps, "3.85", "epv");
is($object->track, "0", "track");
is($object->speed, "0", "speed");
is($object->climb, "0", "climb");
is($object->mode, "3", "mode");

isa_ok ($object->point, 'GPS::Point');
is($object->point->datetime->iso8601, "2011-03-20T06:51:59", "datetime");
is($object->point->lat, "37.371427205", "lat");
is($object->point->lon, "-122.01517989", "lon");
is($object->point->heading, "0", "track");
is($object->point->speed, "0", "speed");
