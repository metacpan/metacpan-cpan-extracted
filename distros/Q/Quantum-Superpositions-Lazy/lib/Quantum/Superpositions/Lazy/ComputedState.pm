package Quantum::Superpositions::Lazy::ComputedState;

our $VERSION = '1.00';

use v5.24; use warnings;
use Moo;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Quantum::Superpositions::Lazy::Role::Operation;
use Types::Standard qw(ConsumerOf ArrayRef);
use Carp qw(croak);

use namespace::clean;

extends "Quantum::Superpositions::Lazy::State";

has "source" => (
	is => "ro",
	isa => ArrayRef,
	required => 1,
);

has "operation" => (
	is => "ro",
	isa => ConsumerOf["Quantum::Superpositions::Lazy::Role::Operation"],
	required => 1,
);

sub clone($self)
{
	return $self->new(
		$self->%{qw(value weight source operation)}
	);
}

# TODO: allow merging with regular states
sub merge($self, $with)
{
	croak "cannot merge a state: values mismatch"
		if $self->value ne $with->value;
	croak "cannot merge a state: operation mismatch"
		if $self->operation->sign ne $with->operation->sign;

	return $self->new(
		weight => $self->weight + $with->weight,
		operation => $self->operation,
		value => $self->value,
		source => [$self->source->@*, $with->source->@*],
	);
}

1;

=head1 NAME

Quantum::Superpositions::Lazy::ComputedState - a weighted state implementation
with the source of the computation

=head1 DESCRIPTION

This is a subclass of L<Quantum::Superpositions::Lazy::State> with extra fields
that allow tracking of the computation sources that produced the state. Objects
of this class are produced inside the
L<with_sources|Quantum::Superpositions::Lazy/with_sources> block.

=head1 METHODS

All of the methods available in L<Quantum::Superpositions::Lazy::State>, plus:

=head2 operation

Instance of a class consuming the
L<Quantum::Superpositions::Lazy::Role::Operation> role. This can be helpful to
determine what kind of operation was performed to obtain the state.

=head2 source

An array reference of state values that were used in the operation (in order).
The number of elements in the arrayref will depend of the operation type.
