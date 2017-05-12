package SVG::DOM2::Element::Rect;

use base "SVG::DOM2::Element::Shape";
use base "SVG::DOM2::Element::Shape::Fill";
use base "SVG::DOM2::Element::Shape::Stroke";

use SVG::DOM2::Attribute::Metric;

sub new
{
	my ($proto, %args) = @_;
	return $proto->SUPER::new('rect', %args);
}

sub _attribute_handle
{
	my ($self, $name, %opts) = @_;
	return SVG::DOM2::Attribute::Metric->new(%opts)
		if $name eq 'x' or $name eq 'width'
		or $name eq 'y' or $name eq 'height';
	return $self->SUPER::_attribute_handle($name, %opts);
}

sub attr
{
    my ($self, $name, $set) = @_;
    $self->setAttribute($name, $set) if defined($set);
    return $self->getAttribute($name);
}

sub width  { shift->attr('width',  @_); }
sub height { shift->attr('height', @_); }
sub x      { shift->attr('x',      @_); }
sub y      { shift->attr('y',      @_); }

return 1;
