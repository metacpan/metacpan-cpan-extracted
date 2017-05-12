#!perl -T

use Test::More tests => 6;

BEGIN {
	use_ok( 'MooseX::Struct','MyObject' => (
      [qw( bar baz )] => 'Scalar',
   ));
}

my $object;

ok($object = new MyObject, 'Object creation');

my $val = rand 100;

ok($object->bar($val), 'Attribute assignment');
is($object->bar, $val, 'Attribute value retrieval');

$val = rand 100;

ok($object->baz($val), 'Second attribute assignment');
is($object->baz, $val, 'Second attribute assignment');


