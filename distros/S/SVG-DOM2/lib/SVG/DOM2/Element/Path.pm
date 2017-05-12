package SVG::DOM2::Element::Path;

use base "SVG::DOM2::Element::Shape";
use base "SVG::DOM2::Element::Shape::Fill";
use base "SVG::DOM2::Element::Shape::Stroke";
use strict;
use warnings;

use SVG::DOM2::Attribute::Path;

sub new
{
    my ($proto, %args) = @_;
    my $self = $proto->SUPER::new('path', %args);
	return $self;
}

sub _attribute_handle
{
	my ($self, $name, %opts) = @_;
	if($name eq 'd') {
		return SVG::DOM2::Attribute::Path->new(%opts);
	}
	return $self->SUPER::_attribute_handle($name, %opts);
}

sub _has_attribute
{
	my ($self, $name) = @_;
	return 1 if($name eq 'd');
	return $self->SUPER::_has_attribute($name);
}

sub instructions
{
	my ($self) = @_;
	if($self->hasAttribute('d')) {
		return $self->getAttribute('d')->instructions;
	}
}

return 1;
