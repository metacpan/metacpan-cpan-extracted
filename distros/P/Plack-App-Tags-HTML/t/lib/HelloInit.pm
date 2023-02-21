package HelloInit;

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

sub _cleanup {
	my $self = shift;

	delete $self->{'_string'};

	return;
}

sub _init {
	my ($self, @string) = @_;

	$self->{'_string'} = \@string;

	return;
}
	
sub _process {
	my $self = shift;

	$self->{'tags'}->put(
		map { ['d', $_] } @{$self->{'_string'}},
	);

	return;
}

1;
