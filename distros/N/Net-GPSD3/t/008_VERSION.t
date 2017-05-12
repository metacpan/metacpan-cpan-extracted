# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 13;

BEGIN { use_ok( 'Net::GPSD3' ); }

#my $string=q({"class":"VERSION","release":"2.40dev","rev":"$Id: gpsd.c 5957 2009-08-23 15:45:54Z esr $","proto_major":3,"proto_minor":1});
my $string='{"class":"VERSION","release":"2.96~dev","rev":"2011-03-17T02:51:23","proto_major":3,"proto_minor":4}';

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::VERSION');
isa_ok ($object->parent, 'Net::GPSD3');
is($object->string, $string, 'string');

is($object->class, 'VERSION', 'class');
is($object->release, '2.96~dev', 'release');
is($object->rev, '2011-03-17T02:51:23', 'rev');
is($object->revision, '2011-03-17T02:51:23', 'revision');
is($object->proto_major, '3', 'proto_major');
is($object->proto_minor, '4', 'proto_minor');
is($object->proto, '3.4', 'proto');
is($object->protocol, '3.4', 'protocol');
