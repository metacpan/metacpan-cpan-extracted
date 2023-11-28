use strict;
use warnings;
use Test2::V0;

use Object::Pad;
use Object::PadX::Role::AutoJSON '-toplevel';
use Cpanel::JSON::XS qw//;

my $json = Cpanel::JSON::XS->new()->convert_blessed(1);

class TestObject2 :does(AutoJSON) {
  field $vector :JSONList(JSONNum) :param = undef;
}

my $obj = TestObject2->new(vector => ["1",2,"3.0e2",4]);

my $working = $json->encode($obj);

is($working, '{"vector":[1,2,300,4]}', "basic serialization");

done_testing();