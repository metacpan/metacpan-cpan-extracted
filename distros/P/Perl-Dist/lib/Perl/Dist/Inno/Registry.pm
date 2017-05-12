package Perl::Dist::Inno::Registry;

use 5.006;
use strict;
use warnings;
use Carp         qw{ croak               };
use Params::Util qw{ _IDENTIFIER _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	root
	subkey
	value_type
	value_name
	value_data
};





#####################################################################
# Constructors

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	unless ( defined $self->root ) {
		$self->{root} = 'HKLM';
	}
	unless ( defined $self->value_type ) {
		$self->{value_type} = 'expandsz';
	}

	# Check params
	unless ( _IDENTIFIER($self->root) ) {
		croak("Missing or invalid root param");
	}
	unless ( _STRING($self->subkey) ) {
		croak("Missing or invalid subkey param");
	}
	unless ( _IDENTIFIER($self->value_type) ) {
		croak("Missing or invalid value_type param");
	}
	unless ( _IDENTIFIER($self->value_name) ) {
		croak("Missing or invalid value_name param");
	}
	unless ( _STRING($self->value_data) ) {
		croak("Missing or invalid value_data param");
	}

	return $self;
}

# Shortcut constructor for an environment variable
sub env {
	return $_[0]->new(
		subkey     => 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
		value_name => $_[1],
		value_data => $_[2],
	);
}





#####################################################################
# Main Methods

sub as_string {
	my $self = shift;
	return join( '; ',
		"Root: "      . $self->root,
		"Subkey: "    . $self->subkey,
		"ValueType: " . $self->value_type,
		"ValueName: " . $self->value_name,
		"ValueData: " . '"' . $self->value_data . '"',
	);
}

1;
