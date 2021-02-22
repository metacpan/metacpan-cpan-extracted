package Quantum::Superpositions::Lazy::Operation::Logical;

our $VERSION = '1.08';

use v5.24;
use warnings;
use Moo;
use Quantum::Superpositions::Lazy::Superposition;
use Quantum::Superpositions::Lazy::Util qw(is_collapsible get_iterator);
use Types::Standard qw(Enum);

my %types = (

	# type => number of parameters, code, forced reducer type
	q{!} => [1, sub { !$_[0] }, "all"],

	q{==} => [2, sub { $_[0] == $_[1] }],
	q{!=} => [2, sub { $_[0] != $_[1] }],
	q{>} => [2, sub { $_[0] > $_[1] }],
	q{>=} => [2, sub { $_[0] >= $_[1] }],
	q{<} => [2, sub { $_[0] < $_[1] }],
	q{<=} => [2, sub { $_[0] <= $_[1] }],

	q{eq} => [2, sub { $_[0] eq $_[1] }],
	q{ne} => [2, sub { $_[0] ne $_[1] }],
	q{gt} => [2, sub { $_[0] gt $_[1] }],
	q{ge} => [2, sub { $_[0] ge $_[1] }],
	q{lt} => [2, sub { $_[0] lt $_[1] }],
	q{le} => [2, sub { $_[0] le $_[1] }],

	q{_compare} => [
		[2,],
		sub {
			local $_ = shift;
			my $sub = shift;
			$sub->($_, @_);
		}
	],
);

# TODO: should "one" reducer run after every iterator pair
# or after an element is compared with the entire superposition?
my %reducer_types = (

	# type => short circuit value, code
	q{all} => [0, sub { ($_[0] // 1) && $_[1] }],
	q{any} => [1, sub { $_[0] || $_[1] }],
	q{one} => [
		undef,
		sub {
			my $val = $_[0] // ($_[1] ? 1 : undef);
			$val -= ($_[1] ? 1 : 0) if defined $_[0] && $val;
			return $val;
		}
	],
);

sub extract_state
{
	my ($ref, $index) = @_;

	my $values = is_collapsible($ref) ? $ref->states : [$ref];

	return $values unless defined $index;
	return $values->[$index];
}

use namespace::clean;

with "Quantum::Superpositions::Lazy::Role::Operation";

has "+sign" => (
	is => "ro",
	isa => Enum [keys %types],
	required => 1,
);

has "reducer" => (
	is => "ro",
	isa => Enum [keys %reducer_types],
	writer => "set_reducer",
	default => sub { $Quantum::Superpositions::Lazy::global_reducer_type },
);

sub supported_types
{
	my ($self) = @_;
	return keys %types;
}

sub run
{
	my ($self, @parameters) = @_;

	my ($param_num, $code, $forced_reducer) = $types{$self->sign}->@*;
	@parameters = $self->_clear_parameters($param_num, @parameters);

	my $carry;
	my $reducer = $reducer_types{$forced_reducer // $self->reducer};
	my $iterator = get_iterator map { extract_state $_ } @parameters;

	while (my @params = $iterator->()) {

		@params = ($code->(@params));
		unshift @params, $carry;

		$carry = $reducer->[1](@params);

		# short circuit if possible
		return $carry if defined $reducer->[0] && !$carry eq !$reducer->[0];
	}

	return !!$carry;
}

sub valid_states
{
	my ($self, @parameters) = @_;

	my ($param_num, $code, $forced_reducer) = $types{$self->sign}->@*;
	@parameters = $self->_clear_parameters($param_num, @parameters);

	my %results;
	my $reducer = $reducer_types{$forced_reducer // $self->reducer};
	my $iterator = get_iterator map { extract_state $_ } @parameters;

	while (my ($key_a, $val_a, @params) = $iterator->(1)) {
		if (!defined $reducer->[0] || !defined $results{$key_a} || !$results{$key_a} ne !$reducer->[0]) {

			@params = map { $params[$_] } grep { $_ % 2 == 1 } keys @params;
			@params = ($code->($val_a, @params));
			unshift @params, $results{$key_a};

			$results{$key_a} = $reducer->[1](@params);
		}
	}

	my @carry;
	for my $key_a (keys %results) {
		if ($results{$key_a}) {
			push @carry, extract_state($parameters[0], $key_a);
		}
	}

	return Quantum::Superpositions::Lazy::Superposition->new(
		states => [@carry]
	);
}

1;
