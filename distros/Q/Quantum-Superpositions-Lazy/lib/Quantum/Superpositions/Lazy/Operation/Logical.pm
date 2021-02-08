package Quantum::Superpositions::Lazy::Operation::Logical;

our $VERSION = '1.07';

use v5.24;
use warnings;
use Moo;
use Quantum::Superpositions::Lazy::Superposition;
use Quantum::Superpositions::Lazy::Util qw(is_collapsible is_state);
use Types::Standard qw(Enum);
use List::Util qw(max);

my %types = (

	# type => number of parameters, code, forced reducer type
	q{!} => [1, sub { !$a }, "all"],

	q{==} => [2, sub { $a == $b }],
	q{!=} => [2, sub { $a != $b }],
	q{>} => [2, sub { $a > $b }],
	q{>=} => [2, sub { $a >= $b }],
	q{<} => [2, sub { $a < $b }],
	q{<=} => [2, sub { $a <= $b }],

	q{eq} => [2, sub { $a eq $b }],
	q{ne} => [2, sub { $a ne $b }],
	q{gt} => [2, sub { $a gt $b }],
	q{ge} => [2, sub { $a ge $b }],
	q{lt} => [2, sub { $a lt $b }],
	q{le} => [2, sub { $a le $b }],

	q{_compare} => [2, sub { local $_ = $a; $b->($a) }],
);

# TODO: should "one" reducer run after every iterator pair
# or after an element is compared with the entire superposition?
my %reducer_types = (

	# type => short circuit value, code
	q{all} => [0, sub { ($a // 1) && $b }],
	q{any} => [1, sub { $a || $b }],
	q{one} => [
		undef,
		sub {
			my $val = $a // ($b ? 1 : undef);
			$val -= ($b ? 1 : 0) if defined $a && $val;
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

sub get_iterator
{
	my (@parameters) = @_;

	my @states = map { extract_state($_) } @parameters;
	my @indexes = map { 0 } @parameters;
	my @max_indexes = map { $#$_ } @states;

	# we can't iterate if one of the elements do not exist
	my $finished = scalar grep { $_ < 0 } @max_indexes;
	return sub {
		my ($with_indexes) = @_;
		return if $finished;

		my $i = 0;
		my @ret =
			map { is_state($_) ? $_->value : $_ }
			map { $states[$i++][$_] }
			@indexes;

		if ($with_indexes) {
			@ret = map { $indexes[$_], $ret[$_] } 0 .. max($#indexes, $#ret);
		}

		$i = 0;
		while ($i < @indexes && ++$indexes[$i] > $max_indexes[$i]) {
			$indexes[$i] = 0;
			$i += 1;
		}

		$finished = $i == @indexes;
		return @ret;
	};
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
	my $iterator = get_iterator @parameters;

	local ($a, $b);
	while (($a, $b) = $iterator->()) {

		# $a and $b are set up for type sub
		$b = $code->();
		$a = $carry;

		# $a and $b are set up for reducer sub
		$carry = $reducer->[1]();

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
	my $iterator = get_iterator @parameters;

	local ($a, $b);
	while ((my $key_a, $a, my $key_b, $b) = $iterator->(1)) {
		if (!defined $reducer->[0] || !defined $results{$key_a} || !$results{$key_a} ne !$reducer->[0]) {

			# $a and $b are set up for type sub
			$b = $code->();
			$a = $results{$key_a};

			# $a and $b are set up for reducer sub
			$results{$key_a} = $reducer->[1]();
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
