# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Net::GPSD3' ); }

my $string=q({"class":"ERROR","message":"Unrecognized request 'FOO'"});

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::ERROR');
isa_ok ($object->parent, 'Net::GPSD3');
is($object->string, $string, 'string');

is($object->class, 'ERROR', 'class');
is($object->message, "Unrecognized request 'FOO'", 'message');
