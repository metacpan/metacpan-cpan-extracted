# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 22;

BEGIN { use_ok( 'Net::GPSD3' ); }

#my $string=q({"class":"SKY","tag":"GSV","device":"/dev/ttyUSB0","time":1253336487.996,"reported":9,"satellites":[{"PRN":15,"el":75,"az":77,"ss":38,"used":true},{"PRN":21,"el":50,"az":310,"ss":35,"used":true},{"PRN":29,"el":39,"az":219,"ss":0,"used":false},{"PRN":18,"el":32,"az":276,"ss":0,"used":false},{"PRN":5,"el":28,"az":69,"ss":41,"used":true},{"PRN":10,"el":25,"az":69,"ss":40,"used":true},{"PRN":27,"el":22,"az":144,"ss":0,"used":false},{"PRN":9,"el":12,"az":160,"ss":0,"used":false},{"PRN":8,"el":9,"az":39,"ss":41,"used":true}]});
my $string='{
  "class":"SKY",
  "tag":"0x0120",
  "device":"/dev/cuaU0",
  "xdop":0.58,
  "ydop":0.96,
  "vdop":1.92,
  "tdop":1.14,
  "hdop":1.90,
  "gdop":2.93,
  "pdop":2.70,
  "satellites":[
    {"PRN":17,"el":76,"az":174,"ss":34,"used":true},
    {"PRN":28,"el":57,"az":38,"ss":30,"used":false},
    {"PRN":27,"el":22,"az":314,"ss":18,"used":true},
    {"PRN":7,"el":15,"az":127,"ss":29,"used":true},
    {"PRN":15,"el":31,"az":297,"ss":27,"used":true},
    {"PRN":11,"el":18,"az":54,"ss":28,"used":false},
    {"PRN":24,"el":18,"az":63,"ss":29,"used":false},
    {"PRN":9,"el":4,"az":313,"ss":18,"used":false},
    {"PRN":8,"el":45,"az":117,"ss":33,"used":true},
    {"PRN":26,"el":49,"az":245,"ss":37,"used":true},
    {"PRN":4,"el":5,"az":170,"ss":17,"used":false},
    {"PRN":138,"el":44,"az":157,"ss":40,"used":true}]}';

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::SKY');
isa_ok ($object->parent, 'Net::GPSD3');

is($object->class, 'SKY', 'class');
is($object->string, $string, 'string');

is($object->tag, '0x0120', 'tag');
is($object->device, '/dev/cuaU0', 'device');
is($object->reported, '12', 'reported');
is($object->used, '7', 'reported');

my $s;
my @s;

$s=$object->satellites;
isa_ok($s, 'ARRAY', 'satellites 1');
is(scalar(@$s), '12', 'satellites 2');
isa_ok($s->[0], 'HASH', 'satellites 3');

@s=$object->satellites; 
is(scalar(@s), '12', 'satellites 4');
isa_ok($s[0], 'HASH', 'satellites 5');

$s=$object->Satellites; 
isa_ok($s, 'ARRAY', 'Satellites 6');
is(scalar(@$s), '12', 'Satellites 7');
isa_ok($s->[0], 'Net::GPSD3::Return::Satellite', 'Satellites 8');
isa_ok ($s->[0]->parent, 'Net::GPSD3');

#Current architecture does not keep order...
#is($s->[0]->string, '{"PRN":15,"el":75,"az":77,"ss":38,"used":true}', 'string');

@s=$object->Satellites; 
is(scalar(@s), '12', 'Satellites 9');
isa_ok($s[0], 'Net::GPSD3::Return::Satellite', 'Satellites 10');

my $satellite=$s->[0];
isa_ok($satellite, 'Net::GPSD3::Return::Satellite', 'Satellites 11');

