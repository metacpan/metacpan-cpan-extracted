package Mongol::Models::Person;

use Moose;

extends 'Mongol::Model';

with 'Mongol::Roles::Core';
with 'Mongol::Roles::Pagination';
with 'Mongol::Roles::Relations';

has 'first_name' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has 'last_name' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'age' => (
	is => 'rw',
	isa => 'Int',
	required => 1,
);

has 'addresses' => (
	is => 'ro',
	isa => 'ArrayRef[Mongol::Models::Address]',
	default => sub { [] },
	traits => [ qw( Array ) ],
	handles => {
		add_address => 'push',
	}
);

sub setup {
	my $class = shift();

	# Direct access to the undelaying collection object
	$class->collection()
		->indexes()
		->create_one( [ age => 1 ] );
}

sub to_string {
	my $self = shift();

	return sprintf( '%s %s',
		$self->first_name(),
		$self->last_name(),
	);
}

__PACKAGE__->meta()->make_immutable();

1;

__END__
