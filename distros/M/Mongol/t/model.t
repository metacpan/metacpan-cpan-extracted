#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Moose;

use MongoDB;

# --- Address
require_ok( 'Mongol::Models::Address' );
my $address = Mongol::Models::Address->new(
	{
		street => 'Main St.',
		number => 123
	}
);

isa_ok( $address, 'Mongol::Models::Address' );
has_attribute_ok( $address, 'street' );
has_attribute_ok( $address, 'number' );

isa_ok( $address, 'Mongol::Model' );
can_ok( $address, qw( pack unpack serialize ) );

# --- Person
require_ok( 'Mongol::Models::Person' );
my $person = Mongol::Models::Person->new(
	{
		first_name => 'Peter',
		last_name => 'Parker',
		age => 25,
	}
);

isa_ok( $person, 'Mongol::Models::Person' );
has_attribute_ok( $person, 'first_name' );
has_attribute_ok( $person, 'last_name' );
has_attribute_ok( $person, 'age' );
has_attribute_ok( $person, 'addresses' );
can_ok( $person, qw( add_address to_string ) );

isa_ok( $person, 'Mongol::Model' );
can_ok( $person, qw( pack unpack serialize ) );

$person->add_address( $address );

my $data = {
	id => undef,
	first_name => 'Peter',
	last_name => 'Parker',
	age => 25,
	addresses => [
		{
			street => 'Main St.',
			number => 123,
		}
	]
};
is_deeply( $person->pack( no_class => 1 ), $data , 'Object serialized correctly (pack)' );
is_deeply( $person->serialize(), $data , 'Object serialized correctly (serialize)' );

is( $person->to_string(), 'Peter Parker', 'Instance methods work correctly' );

done_testing();
