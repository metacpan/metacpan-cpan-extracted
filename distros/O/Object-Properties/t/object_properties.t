use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Test::Fatal 'exception';
use Test::Lives;
use Object::Properties ();

use lib 't/lib';

require_ok 'SomeClass';

for my $obj ( SomeClass->new ) {
	isa_ok $obj, 'SomeClass';
	isa_ok $obj, 'Object::Properties::Base';
	can_ok $obj, 'PROPINIT';
	is 0+keys %$obj, 0, 'It is an empty hash';
}

for my $obj ( SomeClass->new( rw => 1, ro => 2, xx => 3 ) ) {
	isa_ok $obj, 'SomeClass';
	isa_ok $obj, 'Object::Properties::Base';
	is 0+keys %$obj, 3, 'It has the right number of keys';
	is $obj->{'rw'}, 1, '... with correct value for "rw"';
	is $obj->{'ro'}, 2, '... and "ro"';
	is $obj->{'xx'}, 3, '... and "xx"';

	lives_and { is $obj->rw, 1, $_ } 'Accessors exist and give the expected answers';
	lives_and { is $obj->ro, 2, $_ } '... for declared fields';
	like exception { $obj->xx }, qr/locate object method/, '... but not for other keys';

	lives_and { $obj->rw = 42; is $obj->rw, 42, $_ } 'Read-write accessors can be written to';
	like exception { $obj->ro = 42 }, qr/non-lvalue/, '... but not read-only ones';
}

like exception { package Foo; Object::Properties->import( 'bad identifier' ) },
	qr/Invalid accessor name/, 'Bad identifiers are rejected';

like exception { SomeClass->new->rw_die = 'hello!' }, qr/hello!/,
	'Checks are called on write ...';

like exception { SomeClass->new( rw_die => 'hello!' ) }, qr/hello!/,
	'... and during instantiation';

like exception { SomeClass->new( ro_die => 'hello!' ) }, qr/hello!/,
	'... even on read-only fields';

for my $obj ( SomeClass->new( ro_munged => 'AAA', rw_munged => 'AAA', bitbucket => 'AAA' ) ) {
	is $obj->ro_munged, 'aaa', 'Munging read-only fields works in instantiation...';
	is $obj->rw_munged, 'aaa', '... and for read-write fields too';
	is $obj->bitbucket, undef, '... including rejection';
	$obj->rw_munged = 'EEE';
	is $obj->rw_munged, 'eee', '... as well as during writing';
	$obj->bitbucket = 'EEE';
	is $obj->bitbucket, undef, '... including rejection';
}

require_ok 'SubClass';

for my $obj ( SubClass->new( foo => 1, bar => 2, baz => 3 ) ) {
	isa_ok $obj, 'SubClass';
	isa_ok $obj, 'PlainClass';
	is $obj->isa( 'Object::Properties::Base' ), !1, '@ISA is only touched if non-empty';
	ok !$obj->can( 'PROPINIT' ), '... and PROPINIT is not added unless necessary';
	is 0+keys %$obj, 3, '... but constructor inheritance should still work';
	is $obj->{'foo'}, 1, '... with correct value for "foo"';
	is $obj->{'bar'}, 2, '... and "bar"';
	is $obj->{'baz'}, 3, '... and "baz"';
	lives_and { is $obj->foo, 1, $_ } 'Accessors exist and give the expected answers';
	lives_and { is $obj->bar, 2, $_ } '... for declared fields';
	like exception { $obj->baz }, qr/locate object method/, '... but not for other keys';
}

done_testing;
