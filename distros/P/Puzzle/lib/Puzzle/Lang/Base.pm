package Puzzle::Lang::Base;

our $VERSION = '0.02';

use strict;
use warnings;

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;
	return bless {}, $class;
}

sub s { my $self= shift; return 'Skel string. Define your own subclass of Puzzle::Lang for every language supported'};

1;
