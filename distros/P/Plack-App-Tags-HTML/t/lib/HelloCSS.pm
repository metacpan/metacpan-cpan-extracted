package HelloCSS;

use base qw(Tags::HTML);
use strict;
use warnings;

sub _process {
	my ($self, $string) = @_;

	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'class', 'foo'],
		['d', $string],
		['e', 'div'],
	);

	return;
}

sub _process_css {
	my ($self, @css_struct) = @_;

	$self->{'css'}->put(
		['s', '.foo'],
		['d', 'border', '1px solid red'],
		['e'],

		@css_struct,
	);

	return;
}

1;
