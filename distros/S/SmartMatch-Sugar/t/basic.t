#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'SmartMatch::Sugar';

foreach my $sub ( @SmartMatch::Sugar::EXPORT ) {
	no strict 'refs';
	ok( defined &$sub, "$sub exported" );
}

foreach my $data (
	# this doesn't work
	#sub () { 1 },
	#sub { 1 },

	[ 1 .. 3 ],
	[ qw(foo bar gorch) ],
	[ ],

	{ },

	{ foo => "bar" },

	1,

	"foo",

	undef,
) {
	my $data_str = defined($data) ? ( ref($data) ? $data : "'$data'" ) : 'undef';

	ok(      $data ~~ any,    "any matches $data_str" );
	ok( not( $data ~~ none ), "none doesn't match $data_str" );

	if ( ref($data) and ref($data) eq 'ARRAY' ) {
		ok( $data ~~ array, "it's an array" );
		ok( not ( $data ~~ hash ), "it's not a hash" );

		ok( $data ~~ non_empty_array, "non empty array" ) if @$data;
		ok( not( $data ~~ array_length_is(5) ), "array_length_is(5) doesn't match $data_str" );
		
		ok( $data ~~ array_length_is( scalar(@$data) ), "matches in smartmatch" );

		ok( not( $data ~~ non_empty_hash ), "doesn't match non empty hash" );
	}

	if ( ref($data) and ref($data) eq 'HASH' ) {
		ok( $data ~~ hash, "it's a hash" );
		ok( not ( $data ~~ array ), "it's not an array" );

		ok( $data ~~ non_empty_hash, "non empty hash" ) if scalar keys %$data;
		ok( not( $data ~~ hash_size_is(5) ), "hash_size_is(5) doesn't match $data_str" );
		ok( $data ~~ hash_size_is( scalar(keys %$data) ), "matches in smartmatch" );

		ok( not( $data ~~ non_empty_array ), "doesn't match non empty array" );
	}

	ok( not ( $data ~~ object ), "not an object" );
}

{
	package Bar;
	sub blah { }

	package Foo;
	use base qw(Bar);

	use overload fallback => 1, '""' => "blah";
}

foreach my $obj ( bless({}, "Foo"), bless([], "Bar") ) {
	ok( $obj ~~ object, "it's an object" );
	ok( $obj ~~ inv_can("isa"), "can 'isa'" );
	ok( $obj ~~ inv_can("blah"), "can 'isa'" );
	ok( ref($obj) ~~ class, "ref is a class" );
	ok( not( $obj ~~ class ), "the object is not a class though" );
	ok( $obj ~~ inv_isa("UNIVERSAL"), "isa universal" );
	ok( $obj ~~ inv_isa("Bar"), "isa Bar" );
	ok( not ( $obj ~~ inv_can("not_a_method") ), "can't nonexistent method" );
	ok( not ( $obj ~~ inv_isa("NotAClass") ), "not isa non existent class" );
}

ok( bless({}, "Foo") ~~ overloaded, "object Foo is overloaded" );
ok( bless({}, "Foo") ~~ stringifies, "it stringifies, too" );
ok( not( "Foo" ~~ overloaded ), "but not the class itself" );

ok( not( bless({}, "Bar") ~~ overloaded ), "object Bar is not overloaded" );

ok( "Foo" ~~ inv_can("blah"), "Class can methods too" );
