# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 18;

BEGIN { use_ok( 'JSON::XS' ); }
BEGIN { use_ok( 'Net::GPSD3' ); }

#my $string=q({"class":"WATCH","enable":false,"raw":0,"scaled":false});
my $string='{"class":"WATCH","enable":true,"json":true,"nmea":false,"raw":0,"scaled":false,"timing":false}';


my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::WATCH');
isa_ok ($object->parent, 'Net::GPSD3');
is($object->string, $string, 'string');

is($object->class, 'WATCH', 'class');

isa_ok($object->enabled, 'JSON::XS::Boolean', 'enabled');
ok($object->enabled, "enabled");

isa_ok($object->enable, 'JSON::XS::Boolean', 'enable');
ok($object->enable, "enable");

is($object->raw, '0', 'raw');

isa_ok($object->nmea, 'JSON::XS::Boolean', 'nmea');
ok(!$object->nmea, 'nmea');

isa_ok($object->scaled, 'JSON::XS::Boolean', 'scaled');
ok(!$object->scaled, 'scaled');

isa_ok($object->timing, 'JSON::XS::Boolean', 'timing');
ok(!$object->timing, 'timing');

