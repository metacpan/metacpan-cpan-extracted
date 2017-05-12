package SVG::DOM2::Element::Line;

use base "SVG::DOM2::Element::Shape";
use base "SVG::DOM2::Element::Shape::Fill";
use base "SVG::DOM2::Element::Shape::Stroke";

sub new
{
	my ($proto, %args) = @_;
	return $proto->SUPER::new('line', %args);
}

sub attr
{
	my ($self, $name, $set) = @_;
	$self->setAttribute($name, $set) if defined($set);
    return $self->getAttribute($name);
}

sub x1 { shift->attr('x1', @_); }
sub y1 { shift->attr('y1', @_); }
sub x2 { shift->attr('x2', @_); }
sub y2 { shift->attr('y2', @_); }

return 1;
