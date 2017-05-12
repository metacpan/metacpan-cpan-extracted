package SVG::DOM2::Attribute::Style;

use base "XML::DOM2::Attribute";

use strict;
use warnings;
use Carp;

use SVG::DOM2::Attribute::Colour;
use SVG::DOM2::Attribute::Metric;
use SVG::DOM2::Attribute::Opacity;

# Each element in a style attribute is really another attribute
# condensed, to make this a simpler api we are going to load
# up the apropriate attribute class for each element.

my %style_part = (
	'fill'              => sub { SVG::DOM2::Attribute::Colour->new(@_) },
	'fill-opacity'      => sub { SVG::DOM2::Attribute::Opacity->new(@_) },
	'stroke'            => sub { SVG::DOM2::Attribute::Colour->new(@_) },
	'stroke-width'      => sub { SVG::DOM2::Attribute::Metric->new(@_) },
	'stroke-opacity'    => sub { SVG::DOM2::Attribute::Opacity->new(@_) },
);

sub new
{
	my ($proto, %opts) = @_;
	return bless \%opts, $proto;
}

sub serialise
{
	my ($self) = @_;
	my $result = '';
	my $style = $self->style;
	foreach my $name (keys(%{$style})) {
		my $value = $self->_style($name)->value;
		$result .= ';' if $result;
		$result .= $name.':'.$value;
	}
	return $result;
}

sub deserialise
{
	my ($self, $attr) = @_;
	my %result;
	foreach my $style (split(/;/, $attr)) {
		my ($name, $value) = split(/:/, $style);
		$self->_style($name, $value);
	}
	return $self;
}

sub style
{
	my ($self) = @_;
	return $self->{'style'};
}

sub fill
{
	my ($self, $set) = @_;
	my %result;
	$result{'color'}   = $self->fill_color($set);
	$result{'opacity'} = $self->fill_opacity($set);
	return \%result;
}

sub stroke
{
	my ($self, $set) = @_;
	my %result;
	$result{'color'}   = $self->stroke_color($set);
	$result{'opacity'} = $self->stroke_opacity($set);
	$result{'width'}   = $self->stroke_width($set);
	return \%result;
}

sub fill_color        { shift->_style('fill',              @_); }
sub fill_opacity      { shift->_style('fill-opacity',      @_); }
sub stroke_color      { shift->_style('stroke',            @_); }
sub stroke_width      { shift->_style('stroke-width',      @_); }
sub stroke_opacity    { shift->_style('stroke-opacity',    @_); }
sub stroke_linecap    { shift->_style('stroke-linecap',    @_); }
sub stroke_linejoin   { shift->_style('stroke-linejoin',   @_); }
sub stroke_miterlimit { shift->_style('stroke-miterlimit', @_); }
sub stroke_dasharray  { shift->_style('stroke-dasharray',  @_); }

sub _style
{
	my ($self, $attr, $set) = @_;
	if($set and defined($style_part{$attr})) {
		$self->{'style'}->{$attr} = $style_part{$attr}->( value => $set, owner => $self, name => $attr );
	} elsif($set) {
		$self->{'style'}->{$attr} = XML::DOM2::Attribute->new( value => $set, owner => $self, name => $attr );
	}
	return $self->{'style'}->{$attr};
}

return 1;
