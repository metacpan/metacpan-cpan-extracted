#!perl -T

use Test::More tests => 5;

use MooseX::Struct 'MyObject' => {
      bar => 'Scalar'
};

package MyObject;

has 'baz' => ( is => 'rw', isa => 'ArrayRef' );

my $object;

Test::More::ok($object = new MyObject, 'Object creation');

my $val = rand 100;

Test::More::ok($object->bar($val), 'Attribute assignment');
Test::More::is($object->bar, $val, 'Attribute value retrieval : ' . $val);

Test::More::ok($object->baz([$val]), 'Extended attribute assignment');
Test::More::is($object->baz->[0], $val, 'Extended Attribute value retrieval');

