package Quantum::Superpositions::Lazy::Superposition;

our $VERSION = '1.07';

use v5.24;
use warnings;
use Moo;
use Quantum::Superpositions::Lazy::State;
use Quantum::Superpositions::Lazy::Computation;
use Quantum::Superpositions::Lazy::Util qw(get_rand is_collapsible);
use Types::Standard qw(ArrayRef InstanceOf);
use List::Util qw(sum0);

use namespace::clean;

with "Quantum::Superpositions::Lazy::Role::Collapsible";

has "_collapsed_state" => (
	is => "ro",
	lazy => 1,
	builder => "_observe",
	clearer => "_reset",
	predicate => "_is_collapsed",
	init_arg => undef,
);

has "_states" => (
	is => "ro",
	isa => ArrayRef [
		(InstanceOf ["Quantum::Superpositions::Lazy::State"])
		->plus_coercions(
			ArrayRef->where(q{@$_ == 2}),
			q{ Quantum::Superpositions::Lazy::State->new(weight => shift @$_, value => shift @$_) },
			~InstanceOf ["Quantum::Superpositions::Lazy::State"],
			q{ Quantum::Superpositions::Lazy::State->new(value => $_) },
		)
	],
	coerce => 1,
	required => 1,
	init_arg => "states",
);

has "_weight_sum" => (
	is => "ro",
	lazy => 1,
	default => sub {
		sum0 map { $_->weight }
		shift->_states->@*;
	},
	init_arg => undef,
	clearer => 1,
);

sub collapse
{
	my ($self) = @_;

	return $self->_collapsed_state;
}

sub is_collapsed
{
	my ($self) = @_;

	return $self->_is_collapsed;
}

sub weight_sum
{
	my ($self) = @_;

	return $self->_weight_sum;
}

sub reset
{
	my ($self) = @_;

	foreach my $state ($self->_states->@*) {
		$state->reset;
	}
	$self->_reset;

	return $self;
}

sub _observe
{
	my ($self) = @_;

	my @positions = $self->_states->@*;
	my $sum = $self->weight_sum;
	my $prob = get_rand;

	foreach my $state (@positions) {
		$prob -= $state->weight / $sum;
		if ($prob < 0) {
			return is_collapsible($state->value)
				? $state->value->collapse
				: $state->value;
		}
	}

	return undef;
}

sub _build_complete_states
{
	my ($self) = @_;

	my %states;
	for my $state ($self->_states->@*) {
		my @local_states;
		my $coeff = 1;

		my $value = $state->value;
		if (is_collapsible $value) {

			# all values from this state must have their weights multiplied by $coeff
			# this way the weight sum will stay the same
			$coeff = $state->weight / $value->weight_sum;
			@local_states = $value->states->@*;
		}
		else {
			@local_states = $state;
		}

		foreach my $value (@local_states) {
			my $result = $value->value;
			my $copied = $value->clone_with(weight => sub { shift() * $coeff });

			if (exists $states{$result}) {
				$states{$result} = $states{$result}->merge($copied);
			}
			else {
				$states{$result} = $copied;
			}
		}
	}

	return [values %states];
}

1;

__END__

=head1 NAME

Quantum::Superpositions::Lazy::Superposition - a weighted superposition implementation

=head1 DESCRIPTION

This class implements a weighted superposition consisting of a set of
L<Quantum::Superpositions::Lazy::State> states. Each state contains a weight and a value,
and the probability of each state occuring randomly is C<weight /
superposition_weight_sum>. A superposition can be I<collapsed>, so that it will
pick and return one state's value at random. After that, further collapsing
will keep returning that value until the state is I<reset>.

Simple operations only touching superposition creation and collapsing are
optimized - they do not produce the entire list of values that superposition
may contain. For example, creating a superposition which is a mathematical
operation (see L<Quantum::Superpositions::Lazy::Computation>) would normally create a lot
of possible outcomes - one of 100 values plus one of 10 values is one of 1000
values. Normally, picking a random value from such superposition would require
1000 addition operations and one random / select an element operation. In this
implementation however, this only requires one addition and two random numbers
being generated.

This only works this way for the easiest use case. Every time you want to do a
logical operation, get some statistics out of the superposition or even export
to string (the ket notation) a full set of states is generated. Be aware of the
performance implications - producing a million values superposition is not hard
yet very costly.

=head1 METHODS

=head2 new

	# auto weights (all elements have the same probability)
	my $superposition = Quantum::Superpositions::Lazy::Superposition
		->new(states => [1, 2, 3]);

	# custom weights (weight, value)
	my $superposition = Quantum::Superpositions::Lazy::Superposition
		->new(states => [[5, 1], [5, 2], [7, 3]]);

A constructor. The only named argument accepted is the I<states> argument. It
can contain either an array reference of L<Quantum::Superpositions::Lazy::State> objects
(no coercion is applied), an array reference of array references, each having
exactly two elements (coerced into L<Quantum::Superpositions::Lazy::State> objects, the
first element becomes the weight and the second element becomes the value) or
an array referenc of just about anything else (coerced into state objects with
automatic weight).

In most cases it should be easier to use I<superpos> helper function from
L<Quantum::Superpositions::Lazy> rather than the constructor explicitly.

=head2 collapse

	my $random_value = $superposition->collapse;

Collapses a superposition into a single random scalar value. Any further calls
to I<collapse> will keep returning the same value until I<reset> is called.

=head2 is_collapsed

Returns a boolean to tell whether the superposition is currently collapsed.

=head2 reset

Resets the collapsed state of the superposition and any nested superpositions.
The next I<collapse> call will return a newly randomized value.

Returns $self

=head2 states

	my $complete_states = $superposition->states;

Compiles a complete set of possible states for the superposition and returns
it. It will be an array reference consisting of L<Quantum::Superpositions::Lazy::State>
objects or their descendants.

The result of the operation is cached. The operation itself can be costly in
some circumstances (especially when using it on
L<Quantum::Superpositions::Lazy::Computation> of two superpositions).

=head2 stats

	my $mean = $superposition->stats->mean;

Constructs and returns an instance of L<Quantum::Superpositions::Lazy::Statistics>, and
caches it for later use.

=head2 weight_sum

Returns the sum of all states' weights. A possibility for each state occuring
during collapsing can be calculated with a simple division: C<< $state->weight
/ $superposition->weight_sum >>.

=head2 to_ket_notation

	# will return: 0.5|1> + 0.5|2>
	my $ket = superpos(1, 2)->to_ket_notation;

Compiles and returns a string containing the superposition in form of L<ket
notation|https://en.wikipedia.org/wiki/Bra%E2%80%93ket_notation>.

=head2 stringify

An alias to I<collapse> method. Also invoked with overloaded C<"">.

=head2 transform

	# will double every element, same as * 2
	my $transformed1 = $superposition->transform(sub { shift() * 2 });
	my $transformed2 = $superposition->transform(sub { $_ * 2 });

Enables creating a new superposition from an existing one using complex logic
passed as a subroutine reference in the argument. This argument is also passed
as a localized C<$_>.  Works just like the regular computations but with a
custom function.

=head2 compare

	# will perform a custom comparison
	my $boolean = $superposition->compare(sub { shift() =~ /regexp/ });
	my $matches = fetch_matches { $superposition->compare(sub { /regexp/ }) };

Like </transform>, but performs a logical comparison instead of a state mutation.

=head1 OVERLOADING

The package uses overloading to have its objects used in perl expressions
seamlessly. Most operators do the same stuff as they'd do with normal scalars,
but perform them on the superposition states or return a new
L<Quantum::Superpositions::Lazy::Computation> object. The only operator that does
something different is the C<""> stringification, which collapses the
superposition and returns the state.

Operators can be divided into two types:

=over

=item * logical operators, which by default return a standard boolean value

=item * computational operators, which return an instance of
L<Quantum::Superpositions::Lazy::Computation>

=back

Since the behavior of overloaded operators is hard to control, the module
introduces blocks that change how the internal operations will behave when they
are performed in these blocks. These are documented in
L<Quantum::Superpositions::Lazy/FUNCTIONS>.

=head2 The list of overloaded operators considered logical

	! == != > >= < <= eq ne gt ge lt le

=head2 The list of overloaded operators considered computational

	neg + - * ** << >> / % += -= *= **= <<= >>= /= %= . x .=
	x= atan2 cos sin exp log sqrt int abs
