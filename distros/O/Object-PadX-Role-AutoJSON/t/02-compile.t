
use strict;
use warnings;
use Test2::V0;

use Object::Pad;
use Object::PadX::Role::AutoJSON;
use Cpanel::JSON::XS qw//;

my $json = Cpanel::JSON::XS->new()->convert_blessed(1);

class TestObject {
  field $name :param = undef;
}

class TestObject2 :does(Object::PadX::Role::AutoJSON) {
  field $name :param = undef;
}

class TestObject3 :does(Object::PadX::Role::AutoJSON) {
  field $name :param = undef;
  field $social_security_number :param :JSONExclude = undef;
}

class TestObject4 :does(Object::PadX::Role::AutoJSON) {
  field $id :param :JSONStr = undef;
}

class TestObject5 :does(Object::PadX::Role::AutoJSON) {
  field $id :param :JSONNum = undef;
}

class TestObject6 :does(Object::PadX::Role::AutoJSON) {
  field $is_dead :param :JSONBool = undef;
}

class TestObject7 :does(Object::PadX::Role::AutoJSON) {
  field $name :param :JSONNull = undef;
}

class TestObject8 :does(Object::PadX::Role::AutoJSON) {
  field $name :param :JSONKey(first_name) = undef;
}

my $obj = TestObject->new(name => "ralph");
ok(defined $obj, "Non-Object::PadX::Role::AutoJSON object creation");

my $broken = $json->encode($obj);

isnt($broken, '{"name":"ralph"}', "broken serialization by default");

$obj = TestObject2->new(name => "ralph");

my $working = $json->encode($obj);

is($working, '{"name":"ralph"}', "basic serialization");

$obj = TestObject3->new(
  name => "Richard Milhouse Nixon",
  social_security_number => '567-68-0515',
);

my $exclusion = $json->encode($obj);

is($exclusion, '{"name":"Richard Milhouse Nixon"}', "exclusion works");

$obj = TestObject4->new(id => 3.1415926);

my $force_str = $json->encode($obj);

is($force_str, '{"id":"3.1415926"}', "forced stringification");

$obj = TestObject5->new(id => "24601");

my $force_num = $json->encode($obj);

is($force_num, '{"id":24601}', "forced numification");

$obj = TestObject6->new(is_dead => 1);

my $force_bool_true = $json->encode($obj);

is($force_bool_true, '{"is_dead":true}', "forced booleanation, true");

$obj = TestObject6->new(is_dead => 0);

my $force_bool_false = $json->encode($obj);

is($force_bool_false, '{"is_dead":false}', "forced booleanation, false");

$obj = TestObject7->new();

my $allow_null = $json->encode($obj);

is($allow_null, '{"name":null}', "allow nullification");

$obj = TestObject8->new(name => "ralph");

my $new_key = $json->encode($obj);

is($new_key, '{"first_name":"ralph"}', "rename key for serialization");

done_testing();
