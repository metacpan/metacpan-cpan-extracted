use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Method;

{
	package Plain;
	use Moose;

	has some_value => (
		isa => 'Str',
		is  => 'ro',
		default => sub { 'value' },
	);

	__PACKAGE__->meta->make_immutable;
}

{
	package Composite;
	use Moose;
	use MooseX::RemoteHelper;
	with 'MooseX::RemoteHelper::CompositeSerialization';

	has sub_leaf => (
		remote_name => 'SubName',
		isa         => 'Str',
		is          => 'ro',
		default     => sub { 'Bar' },

	);
	__PACKAGE__->meta->make_immutable;
}

{
	package CompositeTop;
	use Moose;
	extends 'Composite';

	has leaf => (
		remote_name => 'Leaf',
		isa         => 'Str',
		is          => 'ro',
	);

	has true => (
		remote_name => 'SpecialBool',
		isa         => 'Bool',
		is          => 'ro',
		serializer  => sub {
			my ( $attr, $instance ) = @_;
			return $attr->get_value( $instance ) ? 'Y' : 'N';
		},
	);

	has composite => (
		remote_name => 'Composite',
		isa         => 'Object',
		is          => 'ro',
		default     => sub { Composite->new },
	);

	has plain => (
		remote_name => 'plain',
		isa     => 'Object',
		is      => 'ro',
		default => sub { Plain->new },
	);

	has not_as_plain => (
		remote_name => 'NotAsPlain',
		isa         => 'Object',
		is          => 'ro',
		default     => sub { Plain->new },
		serializer  => sub {
			my ( $attr, $instance ) = @_;
			return $attr->get_value( $instance )->some_value;
		},
	);

	has no_val => (
		remote_name => 'MyName',
		isa         => 'Str',
		is          => 'ro',
	);

	has undef => (
		remote_name => 'NotValue',
		isa         => 'Undef',
		is          => 'ro',
	);

	__PACKAGE__->meta->make_immutable;
}

my $comp
	= new_ok( 'CompositeTop' => [{
		leaf     => 'foo',
		sub_leaf => 'Baz',
		true     => 1,
		undef    => undef,
	}]);

does_ok $comp, 'MooseX::RemoteHelper::CompositeSerialization';
can_ok  $comp, 'serialize';

my %expected = (
	Leaf        => 'foo',
	SubName     => 'Baz',
	SpecialBool => 'Y',
	NotValue    => undef,
	NotAsPlain  => 'value',
	Composite => {
		SubName => 'Bar',
	},
);

method_ok $comp, serialize => [], \%expected;

done_testing;
