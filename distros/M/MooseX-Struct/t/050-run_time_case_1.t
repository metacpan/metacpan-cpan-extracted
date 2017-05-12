#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'MooseX::Struct');
}

struct 'MyObject' => {
   bar => 'Scalar',
};

ok($object = new MyObject, 'Object creation');

my $val = rand 100;

ok($object->bar($val), 'Attribute assignment');
is($object->bar, $val, 'Attribute value retrieval : ' . $val);

