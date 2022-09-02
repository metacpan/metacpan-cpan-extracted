use strict; use warnings;

use Test::More tests => 26;
use Test::Lives;

use lib 't/lib';

require_ok 'SomeClass';

for my $obj ( SomeClass->new ) {
	isa_ok $obj, 'SomeClass';
	isa_ok $obj, 'Object::Tiny::Lvalue';
	is 0+keys %$obj, 0, 'Empty object is empty';
}

for my $obj ( SomeClass->new( foo => 1, bar => 2, baz => 3 ) ) {
	isa_ok $obj, 'SomeClass';
	isa_ok $obj, 'Object::Tiny::Lvalue';
	is 0+keys %$obj, 3, 'It has the right number of keys';
	is $obj->{'foo'}, 1, '... with correct value for "foo"';
	is $obj->{'bar'}, 2, '... and "bar"';
	is $obj->{'baz'}, 3, '... and "baz"';

	lives_and { is $obj->foo, 1, $_ } 'Accessors exist and give the expected answers';
	lives_and { is $obj->bar, 2, $_ } '... for declared fields';
	lives_and { eval { $obj->baz; 1 } ? die : like $@, qr/locate object method/, $_ } '... but not for other keys';

	lives_and { $obj->foo = 42; is $obj->foo, 42, $_ } 'Read-write accessors can be written to';
}

lives_and {
	eval { package Foo; Object::Tiny::Lvalue->import( 'bad identifier' ); 1 } && die;
	like $@, qr/Invalid accessor name/, $_;
}
	'Bad identifiers are rejected';

require_ok 'SubClass';

for my $obj ( SubClass->new( foo => 1, bar => 2, baz => 3 ) ) {
	isa_ok $obj, 'SubClass';
	isa_ok $obj, 'PlainClass';
	is $obj->isa( 'Object::Tiny::Lvalue' ), !1, '@ISA is only touched if non-empty';
	is 0+keys %$obj, 3, 'It has the right number of keys';
	is $obj->{'foo'}, 1, '... with correct value for "foo"';
	is $obj->{'bar'}, 2, '... and "bar"';
	is $obj->{'baz'}, 3, '... and "baz"';
	lives_and { is $obj->foo, 1, $_ } 'Accessors exist and give the expected answers';
	lives_and { is $obj->bar, 2, $_ } '... for declared fields';
	lives_and { eval { $obj->baz; 1 } ? die : like $@, qr/locate object method/, $_ } '... but not for other keys';
}
