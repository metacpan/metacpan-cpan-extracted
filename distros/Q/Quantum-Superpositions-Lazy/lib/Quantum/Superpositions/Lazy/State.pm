package Quantum::Superpositions::Lazy::State;

our $VERSION = '1.04';

use v5.28;
use warnings;
use Moo;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Quantum::Superpositions::Lazy::Util qw(is_collapsible);
use Types::Common::Numeric qw(PositiveNum);
use Types::Standard qw(Defined);
use Carp qw(croak);

use namespace::clean;

has "weight" => (
	is => "ro",
	isa => PositiveNum,
	default => sub { 1 },
);

# TODO: should this assert for definedness?
has "value" => (
	is => "ro",
	isa => Defined,
	required => 1,
);

sub reset ($self)
{
	if (is_collapsible $self->value) {
		$self->value->reset;
	}
}

sub clone ($self)
{
	return $self->new(
		$self->%{qw(value weight)}
	);
}

sub merge ($self, $with)
{
	croak "cannot merge a state: values mismatch"
		if $self->value ne $with->value;

	return $self->new(
		weight => $self->weight + $with->weight,
		value => $self->value,
	);
}

sub clone_with ($self, %transformers)
{
	my $cloned = $self->clone;
	for my $to_transform (keys %transformers) {
		if ($self->can($to_transform) && exists $cloned->{$to_transform}) {
			$cloned->{$to_transform} = $transformers{$to_transform}->($cloned->{$to_transform});
		}
	}

	return $cloned;
}

1;

=head1 NAME

Quantum::Superpositions::Lazy::State - a weighted state implementation

=head1 DESCRIPTION

This is a simple implementation of a state that contains a weight and a value.
The states are meant to be immutable, so once created you cannot change the
value or weight of a state (without cloning it).

=head1 METHODS

=head2 new

	my $state = Quantum::Superpositions::Lazy::State->new(
		weight => 2,
		value => "on"
	);

A generic Moose constructor. Accepts two arguments: I<weight> of numeric type
(positive), which is optional and 1 by default, and I<value> of any type
(defined), which is required.

=head2 weight

Returns the weight.

=head2 value

Returns the value.

=head2 reset

Resets the state of a superposition inside of the I<value> attribute, if that
value is indeed a superposition.

=head2 clone

Creates a new state with the parameters of the current one.

=head2 clone_with

	# doubles the weight on the cloned state
	$state->clone_with(weight => sub { shift() * 2 });

Clones the objects with I<clone> and then applies some transformators on top of
the object fields.

=head2 merge

Merges two states into one. Only possible for values that are the same
(compared as strings with I<eq>). The weights are added together on the
resulting state.

=head1 SEE ALSO

L<Quantum::Superpositions::Lazy::ComputedState>
