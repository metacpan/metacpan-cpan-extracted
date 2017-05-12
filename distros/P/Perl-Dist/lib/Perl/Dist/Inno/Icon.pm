package Perl::Dist::Inno::Icon;

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
	name
	filename
	working_dir
};





#####################################################################
# Constructors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Missing or invalid name param");
	}
	unless ( _STRING($self->filename) ) {
		croak("Missing or invalid filename param");
	}
	if ( defined $self->working_dir and ! _STRING($self->working_dir) ) {
		croak("Invalid working_dir param");
	}

	return $self;
}





#####################################################################
# Main Methods

sub as_string {
	my $self = shift;
	return join( '; ',
		"Name: \""     . $self->name . "\"",
		"Filename: \"" . $self->filename . "\"",
		defined($self->working_dir)
			? ("WorkingDir: \"" . $self->working_dir . "\"")
			: (),
	);
}

1;
