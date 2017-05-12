#!/usr/bin/perl

use 5.008005;
use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 6;

# Create the equivalent test classes
SCOPE: {
	package Bar;

	use MooseX::Atom [
		has => [ qw{ foo is ro isa Str } ],
	];

	package Foo;

	use Moose;

	has qw{ foo is ro isa Str };

	no Moose;

	__PACKAGE__->meta->make_immutable;
}

# The two classes should behave identically
test( 'Foo' );
test( 'Bar' );

sub test {
	my $class = shift;

	# Test the class
	ok( ! $class->meta->is_mutable, "$class: ->is_mutable is false" );

	# Test an object
	my $object = $class->new( foo => 'bar' );
	isa_ok( $object, $class, "$class: Object created ok" );
	is( $object->foo, 'bar', "$class: ->foo ok" );
}
