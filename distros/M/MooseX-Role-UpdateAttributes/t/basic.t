#!/usr/bin/env perl

package Test::Model {
	use Moose;

	with 'MooseX::Role::UpdateAttributes';

	has 'name' => (
		is => 'ro',
		isa => 'Str',
		required => 1,
	);

	has 'age' => (
		is => 'rw',
		isa => 'Int',
		required => 1,
	);

	has 'address' => (
		is => 'rw',
		isa => 'Str',
		required => 1,
	);

	__PACKAGE__->meta()->make_immutable();
}

package main {
	use strict;
	use warnings;

	use Test::More;
	use Test::Moose;

	my $instance = Test::Model->new(
		{
			name => 'Bruce Wayne',
			age => 30,
			address => 'Wayne Mannor',
		}
	);

	does_ok( $instance, 'MooseX::Role::UpdateAttributes' );
	can_ok( $instance, qw( set_attributes ) );

	my $data = {
		name => 'Wally West',
		age => 31,
		address => 'Main St.',
		email => 'wally.west@heroes.com',
	};

	$instance->set_attributes( %{ $data } );

	is( $instance->name(), 'Bruce Wayne', 'Read-only value ok' );
	is( $instance->age(), 31, 'Age: Value changed' );
	is( $instance->address(), 'Main St.', 'Addess: Value changed' );

	done_testing();
}
