# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Net::GPSD3' ); }

my $string='{"class":"SUBFRAME","device":"/dev/cuaU0","tSV":11,"TOW17":88935,"frame":5,"scaled":false,"ALMANAC":{"ID":12,"Health":0,"e":7742,"toa":15,"deltai":5262,"Omegad":-703,"sqrtA":10554829,"Omega0":11924589,"omega":16078788,"M0":15264683,"af0":2029,"af1":1}}';

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::SUBFRAME');
isa_ok ($object->parent, 'Net::GPSD3');

is($object->class, 'SUBFRAME', 'class');
is($object->string, $string, 'string');

is($object->device, '/dev/cuaU0', 'device');
