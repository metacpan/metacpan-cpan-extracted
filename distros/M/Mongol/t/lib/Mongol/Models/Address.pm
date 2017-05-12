package Mongol::Models::Address;

use Moose;

extends 'Mongol::Model';

has 'street' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has 'number' => (
	is => 'ro',
	isa => 'Int',
	required => 1,
);

__PACKAGE__->meta()->make_immutable();

1;

__END__
