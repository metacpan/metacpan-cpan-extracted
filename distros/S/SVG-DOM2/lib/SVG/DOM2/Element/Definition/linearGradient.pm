package SVG::DOM2::Element::Definition::linearGradient;

use base "SVG::DOM2::Element::Definition";

use strict;
use warnings;

sub new
{
    my ($proto, %args) = @_;
    my $self = $proto->SUPER::new('linearGradient', %args);
	return $self;
}

sub stops
{
	my ($self) = @_;
	return $self->getChildren;
}

return 1;
