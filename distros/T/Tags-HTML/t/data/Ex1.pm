package Ex1;

use parent qw(Tags::HTML);
use strict;
use warnings;

sub _process {
	my ($self, @params) = @_;

	$self->{'tags'}->put(
		['b', 'div'],
		['d', 'Hello'],
		['e', 'div'],
	);

	return;
}

1;
