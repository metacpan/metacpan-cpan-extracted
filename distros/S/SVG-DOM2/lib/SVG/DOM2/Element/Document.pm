package SVG::DOM2::Element::Document;

=pod

=head1 NAME

SVG::DOM2::Element::Document - svg document functions

=head1 SUMMARY

Provides the svg document object with the required DOM
interface for document wide element requests.

=head1 METHODS

=cut

use base "XML::DOM2::Element::Document";
use Carp;

sub new
{
	my ($proto, %args) = @_;
	return $proto->SUPER::new(%args);
}

sub _attribute_handle
{
	my ($self, $name, %opts) = @_;
	my $ns = $opts{'namespace'};
	return SVG::DOM2::Attribute::Metric->new(%opts)
        if $name eq 'width'
        or $name eq 'height';
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

=head1 AUTHOR

Martin Owens, doctormo@postmaster.co.uk

=head1 SEE ALSO

perl(1), L<XML::DOM2>, L<XML::DOM2::Element>, L<XML::DOM2::DOM>

L<http://www.w3.org/TR/1998/REC-DOM-Level-1-19981001/level-one-core.html> DOM at the W3C

=cut

return 1;
