package BadComponent;

use strict;
use warnings;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# No CSS support.
	# XXX There is a syntax error.
	push @params, 'no_css', 1

	my $self = $class->SUPER::new(@params);

	# Object.
	return $self;
}

1;
