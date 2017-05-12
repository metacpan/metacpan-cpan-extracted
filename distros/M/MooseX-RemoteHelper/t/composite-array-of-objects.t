use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Method;

{
	package Plain;
	use Moose;
	extends 'MooseY::RemoteHelper::MessagePart';
	with 'MooseX::RemoteHelper::CompositeSerialization';

	has some_value => (
		remote_name => 'type',
		isa     => 'Str',
		is      => 'ro',
		default => sub { 'snickers' },
	);

	__PACKAGE__->meta->make_immutable;
}
{
	package NoSerialize;
	use Moose;
	extends 'MooseY::RemoteHelper::MessagePart';

	has some_value => (
		remote_name => 'type',
		isa     => 'Str',
		is      => 'ro',
		default => sub { 'snickers' },
	);

	__PACKAGE__->meta->make_immutable;
}
{
	package OwnSerialize;
	use Moose;
	extends 'MooseY::RemoteHelper::MessagePart';

	sub serialize { $_[0]->some_value }

	has some_value => (
		remote_name => 'type',
		isa     => 'Str',
		is      => 'ro',
		default => sub { 'snickers' },
	);

	__PACKAGE__->meta->make_immutable;
}
{
	package Top;
	use Moose;
	extends 'MooseY::RemoteHelper::MessagePart';
	with 'MooseX::RemoteHelper::CompositeSerialization';

	has array => (
		remote_name => 'candybarz',
		isa     => 'ArrayRef[Plain]',
		is      => 'ro',
		lazy    => 1,
		default => sub { return [
			Plain->new, Plain->new,
		];},
	);

	has no_serialize => (
		remote_name => 'more_candybarz',
		isa     => 'ArrayRef[Object]',
		is      => 'ro',
		lazy    => 1,
		default => sub { return [
			NoSerialize->new, NoSerialize->new,
		];},
	);

	has own_serialize => (
		remote_name => 'feel_better_now',
		isa     => 'ArrayRef[OwnSerialize]',
		is      => 'ro',
		lazy    => 1,
		default => sub { return [
			OwnSerialize->new, OwnSerialize->new,
		];},
	);
	__PACKAGE__->meta->make_immutable;
}

my $top = new_ok 'Top';
my %expected = (
	candybarz       => [{ type => 'snickers'},{ type => 'snickers'}],
	more_candybarz  => [],
	feel_better_now => [qw( snickers snickers )],
);

method_ok $top, serialize => [], \%expected;

done_testing;
