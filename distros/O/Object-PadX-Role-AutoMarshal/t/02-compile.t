
use strict;
use warnings;
use Test::More;

use Object::Pad;
use Object::PadX::Role::AutoMarshal;
use Cpanel::JSON::XS qw//;

my $json = Cpanel::JSON::XS->new()->convert_blessed(1);

class TestObject {
  field $name :param;
  field $other_data :param;
}

class TestObject2 :does(Object::PadX::Role::AutoMarshal) {
  field $name :param;
  field $siblings :param :MarshalTo([TestObject2]) = [];
}

my $obj = TestObject->new(name => "ralph", other_data => {foo => 1});
ok(defined $obj, "Non-Object::PadX::Role::AutoMarshal object creation");

my $mocked = bless(['ralph', {foo => 1}], 'TestObject');

is_deeply($obj, $mocked, "IsDeeply check on normal object");

my $obj2 = TestObject2->new(name => "wiggum", siblings => [{name => "ralph"}]);

my $mocked2 = bless(['wiggum', [bless(['ralph', []], 'TestObject2')]], 'TestObject2');

use Data::Dumper;

print Dumper($obj2, $mocked2);

is_deeply($obj2, $mocked2, "IsDeeply check on marshaled object");

done_testing();
