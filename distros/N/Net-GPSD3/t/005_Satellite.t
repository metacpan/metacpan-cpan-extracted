# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 12;

BEGIN { use_ok( 'Net::GPSD3' ); }

#Note "class" here is a Net::GPSD3 pseudo class
#my $string=q({"class":"Satellite","PRN":15,"el":75,"az":77,"ss":38,"used":true});
my $string='{"PRN":17,"el":76,"az":174,"ss":34,"used":true}';

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor(class=>"Satellite", $gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::Satellite');
isa_ok ($object->parent, 'Net::GPSD3');
is($object->string, $string, 'string');

is($object->class, 'Satellite', 'class');
is($object->PRN, '17', 'PRN');
is($object->el, '76', 'el');
is($object->az, '174', 'az');
is($object->ss, '34', 'ss');
ok($object->used, 'used');
isa_ok ($object->used, 'JSON::XS::Boolean');
