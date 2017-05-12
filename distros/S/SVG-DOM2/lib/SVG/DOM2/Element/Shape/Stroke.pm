package SVG::DOM2::Element::Shape::Stroke;
=head1 NAME

SVG::DOM2::Element::Shape::Stroke

=head1 DESCRIPTION

Extend a shape element with stroke attributes

=cut

use strict;
use warnings;

sub stroke
{
	my ($self, $p) = @_;
	my %result;
	$result{'color'}   = $self->stroke_color($p);
	$result{'opacity'} = $self->stroke_opacity($p);
	$result{'width'}   = $self->stroke_width($p);
	return \%result;
}

sub stroke_color   { shift->_style('stroke-color',   'stroke',       @_); }
sub stroke_width   { shift->_style('stroke-width',   'stroke-width', @_); }
sub stroke_opacity
{
	my ($self) = @_;
	$self->_style('stroke-opacity', 'stroke-opacity', @_);
}

return 1;
