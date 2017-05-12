#!perl -T

use Test::More tests => 4;

BEGIN {
   package MyObject;
	Test::More::use_ok( 'MooseX::Struct',(
      bar => 'Scalar'
   ));
}

my $object;

ok($object = new MyObject, 'Object creation');

my $val = rand 100;

ok($object->bar($val), 'Attribute assignment');
is($object->bar, $val, 'Attribute value retrieval : ' . $val);

