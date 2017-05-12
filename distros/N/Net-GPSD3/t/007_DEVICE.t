# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 17;

BEGIN { use_ok( 'Net::GPSD3' ); }

#my $string=q({"class":"DEVICE","path":"/dev/ttyUSB0","activated":1253333674.67,"flags":1,"driver":"Generic NMEA","native":0,"bps":4800,"parity":"N","stopbits":1,"cycle":1.00});

my $string='{
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
    "mincycle":0.25}';

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::DEVICE');
isa_ok ($object->parent, 'Net::GPSD3');

is($object->class, 'DEVICE', 'class');
is($object->string, $string, 'string');

is($object->class, 'DEVICE', 'class');
is($object->path, '/dev/cuaU0', 'path');
is($object->activated, '1300601059.18', 'activated');
is($object->flags, '1', 'flags');
is($object->driver, 'uBlox UBX binary', 'driver');
is($object->native, '1', 'native');
is($object->bps, '9600', 'bps');
is($object->parity, 'N', 'parity');
is($object->stopbits, '1', 'stopbits');
is($object->cycle, 1, 'cycle');
is($object->mincycle, 0.25, 'cycle');

