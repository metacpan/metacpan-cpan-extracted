package SVG::DOM2::Element::Shape::Fill;
=head1 NAME

SVG::DOM2::Element::Shape::Fill

=head1 DESCRIPTION

Extend a shape element with fill attributes

=cut

use strict;
use warnings;

=head1 METHODS

fill - fill style, has color and opacity output

=cut
sub fill
{
	my ($self) = @_;
	my %result;
	$result{'color'}   = $self->fill_color;
	$result{'opacity'} = $self->fill_opacity;
	return \%result;
}

sub fill_color     { shift->_style('fill-color','fill', @_); }
sub fill_opacity
{
    my $self = shift;
    $self->_style('fill-opacity','fill-opacity', @_);
}

return 1;
