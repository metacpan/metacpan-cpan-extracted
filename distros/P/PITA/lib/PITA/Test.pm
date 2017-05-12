package PITA::Guest;

# A complete abstraction of a Guest

use 5.008;
use strict;
use Process       ();
use Process::YAML ();
use PITA::XML     ();

our $VERSION = '0.60';
our @ISA     = qw{
		Process::YAML
		Process
	};
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->_init;
	$self;
}

sub _init {
	my $self = shift;

	# Load the Guest XML file
	unless ( $self->filename and -f $self->filename ) {
		Carp::croak('Missing or bad guest xml filename');
	}
	if ( _STRING($self->xml) ) {
		$self->{guest} = PITA::XML::Guest->read($self->guest);
	}
	unless ( _INSTANCE($self->guest, 'PITA::XML::Guest') ) {
		Carp::croak('Missing or invalid guest');
	}

	$self;
}

sub guest {
	$_[0]->{guest};
}

sub discovered {
	$_[0]->guest->discovered;	
}

1;
