package Perl::Dist::Asset::Launcher;

use strict;
use Carp 'croak';
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	name
	bin
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Did not provide a name");
	}
	unless ( _STRING($self->bin) ) {
		croak("Did not provide a URL");
	}

	return $self;
}

1;
