package Quantum::Superpositions::Lazy::Operation::ComputationalOp;

our $VERSION = '1.02';

use v5.28; use warnings;
use Moo;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Types::Standard qw(Enum);

my %types = (
	q{neg} => [1, sub { -$a }],

	q{+} => [2, sub { $a + $b }],
	q{-} => [2, sub { $a - $b }],
	q{*} => [2, sub { $a * $b }],
	q{**} => [2, sub { $a**$b }],
	q{<<} => [2, sub { $a << $b }],
	q{>>} => [2, sub { $a >> $b }],
	q{/} => [2, sub { $a / $b }],
	q{%} => [2, sub { $a % $b }],

	q{+=} => [2, sub { $a + $b }],
	q{-=} => [2, sub { $a - $b }],
	q{*=} => [2, sub { $a * $b }],
	q{**=} => [2, sub { $a**$b }],
	q{<<=} => [2, sub { $a << $b }],
	q{>>=} => [2, sub { $a >> $b }],
	q{/=} => [2, sub { $a / $b }],
	q{%=} => [2, sub { $a % $b }],

	q{.} => [2, sub { $a . $b }],
	q{x} => [2, sub { $a x $b }],

	q{.=} => [2, sub { $a . $b }],
	q{x=} => [2, sub { $a x $b }],

	q{atan2} => [2, sub { atan2 $a, $b }],
	q{cos} => [1, sub { cos $a }],
	q{sin} => [1, sub { sin $a }],
	q{exp} => [1, sub { exp $a }],
	q{log} => [1, sub { log $a }],
	q{sqrt} => [1, sub { sqrt $a }],
	q{int} => [1, sub { int $a }],
	q{abs} => [1, sub { abs $a }],

	q{_transform} => [2, sub { $b->($a) }],
);

use namespace::clean;

with "Quantum::Superpositions::Lazy::Role::Operation";

has "+sign" => (
	is => "ro",
	isa => Enum [keys %types],
	required => 1,
);

sub supported_types($self)
{
	return keys %types;
}

sub run ($self, @parameters)
{
	my ($param_num, $code) = $types{$self->sign}->@*;
	@parameters = $self->_clear_parameters($param_num, @parameters);

	local ($a, $b) = @parameters;
	return $code->();
}

1;
