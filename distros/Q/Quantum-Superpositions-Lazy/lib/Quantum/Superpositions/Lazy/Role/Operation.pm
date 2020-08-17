package Quantum::Superpositions::Lazy::Role::Operation;

our $VERSION = '1.01';

use v5.24; use warnings;
use Moo::Role;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Carp qw(croak);

requires qw(
	run
	supported_types
);

has "sign" => (
	is => "ro",
);

sub _clear_parameters :prototype($$@) ($self, $param_num, @parameters)
{
	@parameters = grep defined, @parameters;
	croak "invalid number of parameters to " . $self->sign
		unless @parameters == $param_num;

	return @parameters;
}

1;
