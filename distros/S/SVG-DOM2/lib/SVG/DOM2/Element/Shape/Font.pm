package SVG::DOM2::Element::Shape::Font;
=head1 NAME

SVG::DOM2::Element::Shape::Font

=head1 DESCRIPTION

Extend a shape element with font attributes

=cut

use strict;
use warnings;

sub stroke
{
	my ($self, $p) = @_;
	my %result;
	$result{'family'} = $self->font_family($p);
	$result{'size'}   = $self->font_size($p);
	return \%result;
}

sub font_family { shift->_style('font-family', 'font-family', @_); }
sub font_size   { shift->_style('font-size',   'font-size',   @_); }
sub font_weight { shift->_style('font-weight', 'font-weight', @_); }
sub font_style  { shift->_style('font-style',  'font-style',  @_); }

sub text_align  { shift->_style('text-align',  'text-align',  @_); }

return 1;
