package SVG::DOM2::Attribute::Opacity;

use base "XML::DOM2::Attribute";

use strict;
use warnings;
use Carp;

sub new
{
	my ($proto, %opts) = @_;
	return $proto->SUPER::new(%opts);
}

sub serialise
{
	my ($self) = @_;
	my $result = $self->{'value'};
	return $result;
}

sub deserialise
{
	my ($self, $path) = @_;
	return $self->{'value'};
}

return 1;
