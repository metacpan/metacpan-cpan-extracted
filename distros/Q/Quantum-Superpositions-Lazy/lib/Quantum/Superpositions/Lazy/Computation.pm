package Quantum::Superpositions::Lazy::Computation;

our $VERSION = '1.00';

use v5.24; use warnings;
use Moo;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Quantum::Superpositions::Lazy::Operation::ComputationalOp;
use Quantum::Superpositions::Lazy::ComputedState;
use Quantum::Superpositions::Lazy::Util qw(is_collapsible);
use Types::Common::Numeric qw(PositiveNum);
use Types::Standard qw(ConsumerOf ArrayRef Str);

use namespace::clean;

with "Quantum::Superpositions::Lazy::Role::Collapsible";

has "operation" => (
	is => "ro",
	isa => (ConsumerOf["Quantum::Superpositions::Lazy::Role::Operation"])
		->plus_coercions(Str, q{Quantum::Superpositions::Lazy::Operation::ComputationalOp->new(sign => $_)}),
	coerce => 1,
	required => 1,
);

has "values" => (
	is => "ro",
	isa => ArrayRef->where(q{@$_ > 0}),
	required => 1,
);

sub weight_sum { 1 }

sub collapse($self)
{
	my @members = map {
		(is_collapsible $_) ? $_->collapse : $_
	} $self->values->@*;

	return $self->operation->run(@members);
}

sub is_collapsed($self)
{
	# a single uncollapsed state means that the computation
	# is not fully collapsed
	foreach my $member ($self->values->@*) {
		if (is_collapsible($member) && !$member->is_collapsed) {
			return 0;
		}
	}
	return 1;
}

sub reset($self)
{
	foreach my $member ($self->values->@*) {
		if (is_collapsible $member) {
			$member->reset;
		}
	}
}

sub _cartesian_product($self, $values1, $values2, $sourced)
{
	my %states;
	for my $val1 ($values1->@*) {
		for my $val2 ($values2->@*) {
			my $result = $self->operation->run($val1->[1], $val2->[1]);
			my $probability = $val1->[0] * $val2->[0];

			if (exists $states{$result}) {
				$states{$result}[0] += $probability;
			} else {
				$states{$result} = [
					$probability,
					$result,
				];
			}

			if ($sourced) {
				my $source = [@{ $val1->[2] // [$val1->[1]] }, $val2->[1]];
				push $states{$result}[2]->@*, $source;
			}
		}
	}

	return [values %states];
}

sub _build_complete_states($self)
{
	my $states;
	my $sourced = $Quantum::Superpositions::Lazy::global_sourced_calculations;

	for my $value ($self->values->@*) {
		my $local_states;

		if (is_collapsible $value) {
			my $total = $value->weight_sum;
			$local_states = [map {
				[$_->weight / $total, $_->value]
			} $value->states->@*];
		} else {
			$local_states = [[1, $value]];
		}

		if (defined $states) {
			$states = $self->_cartesian_product($states, $local_states, $sourced);
		} else {
			$states = $local_states;
		}
	}

	if ($sourced) {
		return [map {
			Quantum::Superpositions::Lazy::ComputedState->new(
				weight => $_->[0],
				value => $_->[1],
				source => $_->[2] // $_->[1],
				operation => $self->operation,
			)
		} $states->@*];
	} else {
		return $states;
	}

}

1;

__END__

=head1 NAME

Quantum::Superpositions::Lazy::Computation - a computation result,
superposition-like class

=head1 DESCRIPTION

Computation is a class with the same function as
L<Quantum::Superpositions::Lazy::Superposition> but different source of data. A
computation object spawns as soon as a superposition object is used with an
overloaded operator.

Much like a superposition, the computation object does not act upon its members
immediately but rather waits for a I<collapse> call, which then collapses any
computation member elements that consume the
L<Quantum::Superpositions::Lazy::Role::Collapsible> role. The I<reset> method
also calls itself on any collapsible member, which effectively resets the
entire "system" of members connected with mathematical operations.

Upon building the complete set of possible states, computations perform the
cartesian product of all the complete states of every source superposition.
This is a very costly operation that can produce millions of elements very
quickly.

Computations are almost indistinguishable from regular superpositions, so they
will not be addressed directly in the rest of the documentation. Instead, any
reference to a superposition should be treated as if it also referenced the
computation.

=head1 METHODS

=head2 weight_sum

For computations, this method always returns 1. All of the returned states will
have their weights scaled from the origin to have the same "slice of the pie".

=head2 other methods

Same purpose as in L<Quantum::Superpositions::Lazy::Superposition>.

=head1 OVERLOADING

Same as L<Quantum::Superpositions::Lazy::Superposition>.
