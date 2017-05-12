package SVG::DOM2::Element::Text;

use base "SVG::DOM2::Element::Shape";
use base "SVG::DOM2::Element::Shape::Font";
use base "SVG::DOM2::Element::Shape::Fill";
use base "SVG::DOM2::Element::Shape::Stroke";
use strict;
use warnings;

use SVG::DOM2::Attribute::Metric;

sub new
{
    my ($proto, %args) = @_;
    my $self = $proto->SUPER::new('text', %args);
	return $self;
}

sub _attribute_handle
{
	my ($self, $name, %opts) = @_;
	return SVG::DOM2::Attribute::Metric->new(%opts) if $name eq 'x' or $name eq 'y';
	return $self->SUPER::_attribute_handle($name, %opts);
}

sub _has_attribute
{
	my ($self, $name) = @_;
	return $self->SUPER::_has_attribute($name);
}

sub attr
{
    my ($self, $name, $set) = @_;
    $self->setAttribute($name, $set) if defined($set);
    return $self->getAttribute($name);
}

sub x { shift->attr('x', @_); }
sub y { shift->attr('y', @_); } 

sub has_font { 1 }

return 1;
