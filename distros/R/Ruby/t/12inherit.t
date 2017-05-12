#!perl

use warnings;
use strict;

use Test::More tests => 16;

BEGIN{ use_ok('Ruby') }

my $destroyed;

BEGIN{
	package MyObject;
	use Ruby 'lambda(&)';
	use Ruby -base => 'Object';

	__CLASS__->attr_accessor('foo');

	my $bar = 'bar';

	sub mymethod{ 'mymethod' }

	sub set_foo{
		$_[0]->instance_variable_set('@foo', $_[1]);
	}
	sub get_foo{
		$_[0]->instance_variable_get('@foo');
	}

	sub bar_getter{
		lambda{ $bar };
	}
	

	sub DESTROY{
		$_[0]->SUPER::DESTROY();

		$destroyed = 1;
	}
}

{
	my $o = MyObject->new;

	isa_ok($o, 'MyObject');


	ok($o->object_id, "call std method");
	ok($o->kind_of('MyObject'), "kind of MyObject");
	ok($o->kind_of('Object'), "kind of Object");

	is($o->mymethod, "mymethod", "call my method");

	for (1, "str", undef, true){

		$o->set_foo($_);

		is($o->get_foo, $_, "call my attr accessor");
	}

	is($o->get_foo, true);

	$o->set_foo(0xBeef);
	is($o->foo, 0xBeef, "call std attr accessor");
	is($o->get_foo, 0xBeef);
}

is(MyObject->bar_getter->(), 'bar', 'my in lambda');

is(MyObject::__CLASS__, MyObject->new->class, '__CLASS__');

END{
	ok $destroyed, "test end";
}