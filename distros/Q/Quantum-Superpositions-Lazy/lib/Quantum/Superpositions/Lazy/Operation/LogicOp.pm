package Quantum::Superpositions::Lazy::Operation::LogicOp;

our $VERSION = '1.01';

use v5.24; use warnings;
use Moo;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Quantum::Superpositions::Lazy::Superposition;
use Quantum::Superpositions::Lazy::Util qw(is_collapsible is_state);
use Types::Standard qw(Enum);
use List::MoreUtils qw(zip);

my %types = (
	# type => number of parameters, code, forced reducer type
	q{!} => [1, sub { !$a }, "all"],

	q{==} => [2, sub { $a == $b }],
	q{!=} => [2, sub { $a != $b }],
	q{>}  => [2, sub { $a > $b }],
	q{>=} => [2, sub { $a >= $b }],
	q{<}  => [2, sub { $a < $b }],
	q{<=} => [2, sub { $a <= $b }],

	q{eq} => [2, sub { $a eq $b }],
	q{ne} => [2, sub { $a ne $b }],
	q{gt} => [2, sub { $a gt $b }],
	q{ge} => [2, sub { $a ge $b }],
	q{lt} => [2, sub { $a lt $b }],
	q{le} => [2, sub { $a le $b }],
);

# TODO: should "one" reducer run after every iterator pair
# or after an element is compared with the entire superposition?
my %reducer_types = (
	# type => short circuit value, code
	q{all} => [0, sub { ($a // 1) && $b }],
	q{any} => [1, sub { $a || $b }],
	q{one} => [undef, sub {
		my $val = $a // ($b ? 1 : undef);
		$val -= 0+ $b if defined $a && $val;
		return $val;
	}],
);

sub extract_state($ref, $index = undef)
{
	my $values = is_collapsible($ref) ? $ref->states : [$ref];

	return $values unless defined $index;
	return $values->[$index];
}

sub get_iterator(@parameters)
{
	my @states = map { extract_state($_) } @parameters;
	my @indexes = map { 0 } @parameters;
	my @max_indexes = map { $#$_ } @states;

	# we can't iterate if one of the elements do not exist
	my $finished = scalar grep { $_ < 0 } @max_indexes;
	return sub ($with_indexes = 0) {
		return if $finished;

		my $i = 0;
		my @ret =
			map { is_state($_) ? $_->value : $_ }
			map { $states[$i++][$_] }
			@indexes;

		if ($with_indexes) {
			@ret = zip @indexes, @ret;
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
	isa => Enum[keys %types],
	required => 1,
);

has "reducer" => (
	is => "ro",
	isa => Enum[keys %reducer_types],
	writer => "set_reducer",
	default => sub { $Quantum::Superpositions::Lazy::global_reducer_type },
);

sub supported_types($self)
{
	return keys %types;
}

sub run($self, @parameters)
{
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
		return $carry if defined $reducer->[0] && !!$carry eq !!$reducer->[0];
	}

	return !!$carry;
}

sub valid_states($self, @parameters)
{
	my ($param_num, $code) = $types{$self->sign}->@*;
	@parameters = $self->_clear_parameters($param_num, @parameters);

	my @carry;
	my $iterator = get_iterator @parameters;

	local ($a, $b);
	my ($key_a, $key_b);
	while (($key_a, $a, $key_b, $b) = $iterator->(1)) {
		# $a and $b are set up for type sub
		my $result = $code->();

		if ($result) {
			push @carry, extract_state($parameters[0], $key_a);
		}
	}

	return Quantum::Superpositions::Lazy::Superposition->new(
		states => [@carry]
	);
}

1;
