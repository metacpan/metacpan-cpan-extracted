package MongoDBxTestSchema::PersonName;

use MongoDBx::Class::Moose;
use namespace::autoclean;

with 'MongoDBx::Class::EmbeddedDocument';

has 'first_name' => (is => 'ro', isa => 'Str', required => 1, writer => 'set_first_name');

has 'middle_name' => (is => 'ro', isa => 'Str', predicate => 'has_middle_name', writer => 'set_middle_name');

has 'last_name' => (is => 'ro', isa => 'Str', required => 1, writer => 'set_last_name');

sub name {
	my $self = shift;

	my $name = $self->first_name;
	$name .= ' '.$self->middle_name.' ' if $self->has_middle_name;
	$name .= $self->last_name;

	return $name;
}

__PACKAGE__->meta->make_immutable;
