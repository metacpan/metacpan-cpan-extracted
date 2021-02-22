package Quantum::Superpositions::Lazy::Role::Collapsible;

our $VERSION = '1.08';

use v5.24;
use warnings;
use Quantum::Superpositions::Lazy::Operation::Computational;
use Quantum::Superpositions::Lazy::Operation::Logical;
use Quantum::Superpositions::Lazy::Computation;
use Quantum::Superpositions::Lazy::State;
use Quantum::Superpositions::Lazy::Statistics;
use Types::Standard qw(ArrayRef InstanceOf);
use List::Util qw(reduce);
use Carp qw(croak);

use Moo::Role;

my %mathematical = map { $_ => 1 }
	Quantum::Superpositions::Lazy::Operation::Computational->supported_types;

my %logical = map { $_ => 1 }
	Quantum::Superpositions::Lazy::Operation::Logical->supported_types;

sub create_computation
{
	my ($type, @args) = @_;

	return Quantum::Superpositions::Lazy::Computation->new(
		operation => $type,
		values => [@args],
	);
}

sub create_logic
{
	my ($type, @args) = @_;

	my $op = Quantum::Superpositions::Lazy::Operation::Logical->new(
		sign => $type,
	);

	if ($Quantum::Superpositions::Lazy::global_compare_bool) {
		return $op->run(@args);
	}
	else {
		return $op->valid_states(@args);
	}
}

sub _operate
{
	my (@args) = @_;

	my $type = pop @args;

	my $self = shift @args;
	return $self->operate($type, @args);
}

use namespace::clean;

requires qw(
	collapse
	is_collapsed
	_build_complete_states
	weight_sum
	reset
);

has "_complete_states" => (
	is => "ro",
	isa => ArrayRef [
		(InstanceOf ["Quantum::Superpositions::Lazy::State"])
		->plus_coercions(
			ArrayRef->where(q{@$_ == 2}),
			q{ Quantum::Superpositions::Lazy::State->new(weight => shift @$_, value => shift @$_) },
		)
	],
	lazy => 1,
	coerce => 1,
	builder => "_build_complete_states",
	clearer => "clear_states",
	init_arg => undef,
);

has "stats" => (
	is => "ro",
	isa => InstanceOf ["Quantum::Superpositions::Lazy::Statistics"],
	lazy => 1,
	default => sub { $Quantum::Superpositions::Lazy::Statistics::implementation->new(parent => shift) },
	init_arg => undef,
	clearer => "_clear_stats",
);

sub states
{
	my ($self) = @_;

	return $self->_complete_states;
}

sub stringify
{
	my ($self) = @_;
	return $self->collapse;
}

sub operate
{
	my ($self, $type, @args) = @_;

	unshift @args, $self;
	my $order = pop @args;
	@args = reverse @args
		if $order;

	if ($mathematical{$type}) {
		return create_computation $type, @args;
	}

	elsif ($logical{$type}) {
		return create_logic $type, @args;
	}

	else {
		croak "quantum operator $type is not supported";
	}
}

sub transform
{
	my ($self, $coderef, @more) = @_;

	return $self->operate("_transform", $coderef, @more, undef);
}

sub compare
{
	my ($self, $coderef, @more) = @_;

	return $self->operate("_compare", $coderef, @more, undef);
}

sub to_ket_notation
{
	my ($self) = @_;

	return join " + ", map {
		($_->weight / $self->weight_sum) . "|" .
			$_->value . ">"
	} $self->states->@*;
}

use overload
	q{nomethod} => \&_operate,
	q{fallback} => 0,

	q{=} => sub { shift },
	q{""} => \&stringify,
	;

1;
