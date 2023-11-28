
use strict;
use warnings;
use Test::More;

use Object::Pad;
use Object::PadX::Role::AutoMarshal '-toplevel';

class MetaMetaMeta {
  field $ssn :param;
  field $phone :param;
  field $id :param;
}

class TestObject2 :does(AutoMarshal) {
  field $name :param;
  field $meta :param :MarshalTo(MetaMetaMeta);
}

my $obj = TestObject2->new(name => "ralph", meta => {ssn => "123-45-6789", phone => "867-5309", id => "none"});

my $mocked = bless( [
                 'ralph',
                 bless( [
                          "123-45-6789",
                          "867-5309",
                          "none"
                        ], 'MetaMetaMeta' )
               ], 'TestObject2' );

is_deeply($obj, $mocked, "Object created correctly");

done_testing();
