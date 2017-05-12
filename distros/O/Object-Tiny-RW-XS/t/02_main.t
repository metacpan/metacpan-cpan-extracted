#!/usr/bin/perl

# Simple tests for a simple module
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;

# Define a class
SCOPE: {
	eval "
	package Foo;

	use Object::Tiny::RW::XS qw{ foo bar };
	";
	ok( ! $@, 'Created package without error' );
}

# Create a trivial object
SCOPE: {
	my $empty = Foo->new;
	isa_ok( $empty, 'Foo' );
	isa_ok( $empty, 'Object::Tiny::RW::XS' );
	is( scalar( keys %$empty ), 0, 'Empty object is empty' );
}

# Create a real object
SCOPE: {
	my $object = Foo->new( foo => 1, bar => 2, baz => 3 );
	isa_ok( $object, 'Foo' );
	isa_ok( $object, 'Object::Tiny::RW::XS' );
	is( scalar( keys %$object ), 3, 'Object contains expect elements' );
	is( $object->foo, 1, '->foo ok' );
	is( $object->bar, 2, '->bar ok' );
	eval {
		$object->baz;
	};
	ok( $@, '->baz returns an error' );
	is( $object->{baz}, 3, '->{baz} does contain value' );
        $object->foo(42);
	is( $object->foo, 42, '->foo(new_value) ok' );
	$object->bar(undef);
	is( $object->bar, undef, '->bar(new_value) ok' );
}

# Trigger the constructor exception
SCOPE: {
	eval "package Bar; use Object::Tiny::RW::XS 'bad thing';";
	ok( $@ =~ /Invalid accessor name/, 'Got expected error' );
}
