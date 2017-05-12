package SVG::DOM2::Element::Definition::linearGradient::Stop;

use base "SVG::DOM2::Element::Style";

use strict;
use warnings;

sub new
{
    my ($proto, %args) = @_;
    my $self = $proto->SUPER::new('stop', %args);
	return $self;
}

sub stops
{
	my ($self) = @_;
	return $self->getChildren;
}

return 1;
