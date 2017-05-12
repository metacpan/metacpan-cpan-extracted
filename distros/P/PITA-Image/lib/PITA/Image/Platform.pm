package PITA::Image::Platform;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.60';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->_init;
	$self;
}

sub _init {
	my $self = shift;

	1;
}

sub scheme {
	$_[0]->{scheme};
}

sub path {
	$_[0]->{path};
}

1;
