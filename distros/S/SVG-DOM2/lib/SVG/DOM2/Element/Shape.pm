package SVG::DOM2::Element::Shape;
use base "XML::DOM2::Element";

=head1 NAME

SVG::DOM2::Element::Shape

=head1 DESCRIPTION

Shape module controls all shapes within an svg document.
 * style      - fill and stroke
 * transforms - transform attribute handeling

Also deals with parent group and svg base inheritance via reverse lookup,

=cut

use strict;
use warnings;
use Carp;

use SVG::DOM2::Attribute::Transform;
use SVG::DOM2::Attribute::Style;
use SVG::DOM2::Attribute::Colour;
use SVG::DOM2::Attribute::Metric;
use SVG::DOM2::Attribute::Opacity;

sub new
{
    my ($proto, $shape, %args) = @_;
    my $self = $proto->SUPER::new($shape, %args);
	return $self;
}

sub _attribute_handle
{
	my ($self, $name, %opts) = @_;
	confess "Attribute must have a name $name" if not $opts{'name'};
	return SVG::DOM2::Attribute::Transform->new(%opts) if $name eq 'transform';
	return SVG::DOM2::Attribute::Style->new(%opts) if $name eq 'style';
	return SVG::DOM2::Attribute::Colour->new(%opts)
		if $name eq 'fill' or $name eq 'stroke';
	return SVG::DOM2::Attribute::Metric->new(%opts) if $name eq 'stroke-width';
	return SVG::DOM2::Attribute::Opacity->new(%opts)
		if $name eq 'fill-opacity' or $name eq 'stroke-opacity';
	return $self->SUPER::_attribute_handle($name, %opts);
}

sub _has_attribute
{
    my ($self, $name) = @_;
    return 1 if($name eq 'transform');
	return 1 if($name eq 'style');
    return $self->SUPER::_has_attribute($name);
}

=head1 METHODS

transforms - a list of transforms for this shape

=cut

sub transforms
{
	my ($self) = @_;
	my @tr;
#	warn "Getting transforms for ".$self->name."\n";
	if($self->getAttribute('transform')) {
		push @tr, $self->getAttribute('transform')->transforms;
	}
	return @tr;
}

=head1 METHODS

style - attribute for controling style

=cut

sub style
{
	my ($self) = @_;
	return $self->getAttribute( 'style' );
}

sub _style
{
	my ($self, $name, $attr, %p) = @_;
#	warn "Getting $name / $attr / $default\n";
	# See if the value is stored
	if(not $self->{$name}) {
		# Get the basic style attribute
		my $attribute = $self->getAttribute($attr);
		if(not defined($attribute)) {
			# Check the style attribute for it
			$attribute = $self->style->_style($attr) if $self->style;
#			if(not defined($attribute) and not $p{'noparent'}) {
				# Now we go after the parent nodes, traversal
#				if($self->getParent) {
#					if( $self->getParent->can('_style') ) {
#						my $s = $self->getParent->style;
#						my $p = $s->value if defined($s);
#						$attribute = $self->getParent->_style($name, $attr, %p, nodefault => 1);
#					}
#				}
#			}
		}
		if(not $attribute and not $p{'nodefault'}) {
			$attribute = $self->_attribute_handle( $attr, name => $name, owner => $self );
		}
		# Store the value for later
		$self->{$name} = $attribute;
	}
	return $self->{$name};
}

sub has_font { 0 };

return 1;
