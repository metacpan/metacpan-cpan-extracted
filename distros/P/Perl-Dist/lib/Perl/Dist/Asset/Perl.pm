package Perl::Dist::Asset::Perl;

# Perl::Dist asset for the Perl source code itself

use strict;
use Carp              ();
use Params::Util      ();
use Perl::Dist::Asset ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.16';
	@ISA     = 'Perl::Dist::Asset';
}

use Object::Tiny qw{
	name
	force
	license
	unpack_to
	install_to
	patch
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	$self->{unpack_to} = '' unless defined $self->unpack_to;

	# Check params
	unless ( Params::Util::_STRING($self->name) ) {
		Carp::croak("Missing or invalid name param");
	}
	unless ( Params::Util::_HASH($self->license) ) {
		Carp::croak("Missing or invalid license param");
	}
	unless ( defined $self->unpack_to and ! ref $self->unpack_to ) {
		Carp::croak("Missing or invalid unpack_to param");
	}
	unless ( Params::Util::_STRING($self->install_to) ) {
		Carp::croak("Missing or invalid install_to param");
	}
	if ( $self->patch and ! Params::Util::_ARRAY($self->patch) ) {
		Carp::croak("Invalid patch param");
	}
	$self->{force} = !! $self->force;

	return $self;
}

1;
