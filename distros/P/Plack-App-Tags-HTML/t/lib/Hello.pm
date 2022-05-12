package Hello;

use base qw(Tags::HTML);
use strict;
use warnings;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# No CSS support.
	push @params, 'no_css', 1;

	my $self = $class->SUPER::new(@params);

	# Object.
	return $self;
}
	
sub _process {
	my $self = shift;

	$self->{'tags'}->put(
		['d', 'Hello world'],
	);

	return;
}

1;
