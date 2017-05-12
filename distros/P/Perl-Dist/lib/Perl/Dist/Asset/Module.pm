package Perl::Dist::Asset::Module;

use strict;
use Carp         'croak';
use Params::Util qw{ _STRING _HASH };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	name
	type
	force
	extras
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	$self->{force} = $self->force ? 1 : 0; # Needs to be numeric

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Missing or invalid name param");
	}

	return $self;
}





#####################################################################
# Support Methods

sub trace {
	my $self = shift;
	if ( _CODELIKE($self->{trace}) ) {
		$self->{trace}->(@_);
	} else {
		print $_[0];
	}
}

1;
