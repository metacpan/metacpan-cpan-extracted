package SVG::DOM2::Attribute::Colour;

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
	my $result = $self->{'colour'};
	return $result;
}

sub deserialise
{
	my ($self, $colour) = @_;
	$self->{'colour'} = $colour;
	return $self;
}

return 1;
