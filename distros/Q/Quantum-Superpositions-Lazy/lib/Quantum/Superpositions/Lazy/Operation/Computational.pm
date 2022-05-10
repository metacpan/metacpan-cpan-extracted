package Quantum::Superpositions::Lazy::Operation::Computational;

our $VERSION = '1.11';

use v5.24;
use warnings;
use Moo;

use Types::Standard qw(Enum);

my %types = (
	q{neg} => [1, sub { -$_[0] }],

	q{+} => [2, sub { $_[0] + $_[1] }],
	q{-} => [2, sub { $_[0] - $_[1] }],
	q{*} => [2, sub { $_[0] * $_[1] }],
	q{**} => [2, sub { $_[0]**$_[1] }],
	q{<<} => [2, sub { $_[0] << $_[1] }],
	q{>>} => [2, sub { $_[0] >> $_[1] }],
	q{/} => [2, sub { $_[0] / $_[1] }],
	q{%} => [2, sub { $_[0] % $_[1] }],

	q{+=} => [2, sub { $_[0] + $_[1] }],
	q{-=} => [2, sub { $_[0] - $_[1] }],
	q{*=} => [2, sub { $_[0] * $_[1] }],
	q{**=} => [2, sub { $_[0]**$_[1] }],
	q{<<=} => [2, sub { $_[0] << $_[1] }],
	q{>>=} => [2, sub { $_[0] >> $_[1] }],
	q{/=} => [2, sub { $_[0] / $_[1] }],
	q{%=} => [2, sub { $_[0] % $_[1] }],

	q{.} => [2, sub { $_[0] . $_[1] }],
	q{x} => [2, sub { $_[0] x $_[1] }],

	q{.=} => [2, sub { $_[0] . $_[1] }],
	q{x=} => [2, sub { $_[0] x $_[1] }],

	q{atan2} => [2, sub { atan2 $_[0], $_[1] }],
	q{cos} => [1, sub { cos $_[0] }],
	q{sin} => [1, sub { sin $_[0] }],
	q{exp} => [1, sub { exp $_[0] }],
	q{log} => [1, sub { log $_[0] }],
	q{sqrt} => [1, sub { sqrt $_[0] }],
	q{int} => [1, sub { int $_[0] }],
	q{abs} => [1, sub { abs $_[0] }],

	q{_transform} => [
		[2,],
		sub {
			local $_ = shift;
			my $sub = shift;
			$sub->($_, @_);
		}
	],
);

use namespace::clean;

with "Quantum::Superpositions::Lazy::Role::Operation";

has "+sign" => (
	is => "ro",
	isa => Enum [keys %types],
	required => 1,
);

sub supported_types
{
	my ($self) = @_;

	return keys %types;
}

sub run
{
	my ($self, @parameters) = @_;

	my ($param_num, $code) = $types{$self->sign}->@*;
	$self->_clear_parameters($param_num, @parameters);

	return $code->(@parameters);
}

1;

