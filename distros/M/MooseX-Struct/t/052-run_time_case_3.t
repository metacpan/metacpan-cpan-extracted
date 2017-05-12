#!perl -T

use Test::More tests => 3;

package MyObject;

use MooseX::Struct;

struct {
   bar => 'Scalar',
};

my $object;

Test::More::ok($object = new MyObject, 'Object creation');

my $val = rand 100;

Test::More::ok($object->bar($val), 'Attribute assignment');
Test::More::is($object->bar, $val, 'Attribute value retrieval : ' . $val);

