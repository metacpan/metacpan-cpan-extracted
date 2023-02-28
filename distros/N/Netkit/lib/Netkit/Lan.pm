package Lan;

use strict;
use warnings;

sub new {
	my $class = shift;
	my ($name) = @_;

	my $self = bless {
		name => $name,
	}, $class;

	return $self;
}

1;
