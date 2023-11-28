
use strict;
use warnings;
use Test2::V0;

use Object::Pad;
use Object::PadX::Role::AutoJSON '-toplevel';
use Cpanel::JSON::XS qw//;

my $json = Cpanel::JSON::XS->new()->convert_blessed(1);

class TestObject2 :does(AutoJSON) {
  field $name :param = undef;
}

my $obj = TestObject2->new(name => "ralph");

my $working = $json->encode($obj);

is($working, '{"name":"ralph"}', "basic serialization");

done_testing();
