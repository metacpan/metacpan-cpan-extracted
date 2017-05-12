# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 27;

BEGIN { use_ok( 'Net::GPSD3' ); }

#my $string=q({"class":"DEVICES","devices":[{"class":"DEVICE","path":"/dev/ttyUSB0","activated":1253333674.67,"flags":1,"driver":"Generic NMEA","native":0,"bps":4800,"parity":"N","stopbits":1,"cycle":1.00}]});
my $string='{
  "class":"DEVICES",
  "devices":[{
    "class":"DEVICE",
    "path":"/dev/cuaU0",
    "activated":1300601059.18,
    "flags":1,
    "driver":"uBlox UBX binary",
    "native":1,
    "bps":9600,
    "parity":"N",
    "stopbits":1,
    "cycle":1.00,
    "mincycle":0.25}]}';

my $gpsd=Net::GPSD3->new;
isa_ok($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok($object, 'Net::GPSD3::Return::DEVICES');
isa_ok($object->parent, 'Net::GPSD3');

is($object->class, 'DEVICES', 'class');
is($object->string, $string, 'string');

my $devices;
my @devices;

$devices=$object->devices; 
isa_ok($devices, 'ARRAY', 'devices');
isa_ok($devices->[0], 'HASH', 'devices');

@devices=$object->devices; 
is(scalar(@devices), '1', 'devices');
isa_ok($devices[0], 'HASH', 'devices');

$devices=$object->Devices; 
isa_ok($devices, 'ARRAY', 'devices');
isa_ok($devices->[0], 'Net::GPSD3::Return::DEVICE', 'Devices');

@devices=$object->Devices; 
is(scalar(@devices), '1', 'Devices');
isa_ok($devices[0], 'Net::GPSD3::Return::DEVICE', 'Devices');

my $device=$devices->[0];
isa_ok($device, 'Net::GPSD3::Return::DEVICE', 'Devices');

is($device->class, 'DEVICE', 'class');
isa_ok ($device->parent, 'Net::GPSD3');
#Current architecture does not keep order...
#is($device->string, '{"class":"DEVICE","path":"/dev/ttyUSB0","activated":1253333674.67,"flags":1,"driver":"Generic NMEA","native":0,"bps":4800,"parity":"N","stopbits":1,"cycle":1.00}', 'string');
is($device->path, '/dev/cuaU0', 'path');
is($device->activated, '1300601059.18', 'activated');
is($device->flags, '1', 'flags');
is($device->driver, 'uBlox UBX binary', 'driver');
is($device->native, '1', 'native');
is($device->bps, '9600', 'bps');
is($device->parity, 'N', 'parity');
is($device->stopbits, '1', 'stopbits');
is($device->cycle, 1, 'cycle');
is($device->mincycle, 0.25, 'cycle');
