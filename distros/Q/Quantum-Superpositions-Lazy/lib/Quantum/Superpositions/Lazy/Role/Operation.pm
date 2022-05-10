package Quantum::Superpositions::Lazy::Role::Operation;

our $VERSION = '1.11';

use v5.24;
use warnings;
use Carp qw(croak);

use Moo::Role;

requires qw(
	run
	supported_types
);

has "sign" => (
	is => "ro",
);

sub _clear_parameters
{
	my ($self, $param_num, @parameters) = @_;

	my ($params_min, $params_max) = ref $param_num eq 'ARRAY'
		? $param_num->@*
		: ($param_num, undef)
		;

	croak "not enough parameters to " . $self->sign
		if @parameters < $params_min;

	croak "too many parameters to " . $self->sign
		if defined $params_max && @parameters > $params_max;
}

1;

