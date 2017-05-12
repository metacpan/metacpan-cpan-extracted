package PITA::XML::File;

# A PITA::XML class that represents an file resource for a Guest

use 5.006;
use strict;
use Data::Digest        ();
use Params::Util        qw{ _INSTANCE _STRING };
use PITA::XML::Storable ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.52';
	@ISA     = 'PITA::XML::Storable';
}

sub xml_entity { 'file' }






#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# The file name is required
	unless ( _STRING($self->filename) ) {
		Carp::croak('Missing or invalid filename');
	}

	# The resource descriptor is optional
	if ( exists $self->{resource} ) {
		unless ( _STRING($self->{resource}) ) {
			Carp::croak('Cannot provide a null resource type');
		}
	}

	# The digest is optional
	if ( exists $self->{digest} ) {
		eval { $self->{digest} = $self->_DIGEST($self->{digest}) };
		Carp::croak("Missing or invalid digest") if $@;
	}

	$self;
}

sub filename {
	$_[0]->{filename};
}

sub resource {
	$_[0]->{resource};
}

sub digest {
	$_[0]->{digest};
}





#####################################################################
# Main Methods






#####################################################################
# Support Methods

sub _DIGEST {
	_INSTANCE($_[1], 'Data::Digest') ? $_[1] : Data::Digest->new($_[1]);
}

1;
