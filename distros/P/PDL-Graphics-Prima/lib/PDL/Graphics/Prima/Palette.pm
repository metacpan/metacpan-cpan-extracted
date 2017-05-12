use strict;
use warnings;
use PDL::Drawing::Prima::Utils;

=head1 NAME

PDL::Graphics::Prima::Palette - a set of palettes for the Prima graph widget

=head1 DESCRIPTION

Suppose you want to use color to convey some meaningful value. For example,
you want the color to represent the topography of a landscape, darker is
lower, lighter is higher. In that case, you need a mapping from a height to
a color, i.e. from a scalar value to a color. This is what palettes provide.

If all you need is basic palette, you can use one of the
L<palette builders provided below|/"Special Palettes">. That said, creating
custom color palettes, when you have some idea of what you're doing and a
simple means for doing so, is a lot of fun. This, for example, creates a
palette that runs from black to red. You could just use
L<pal::BlackToHSV|/pal::BlackToHSV>, but what's the fun in that?

 my $palette = PDL::Graphics::Prima::Palette->new(
     apply => sub {
         my $data = shift;
         my ($min, $max) = $data->minmax;
         
         # Build the rgb piddle
         my $rgb = zeroes(3, $data->dims);
         $rgb->slice("0") .= (($data->double - $min) / ($max - $min)) * 255;
         
         # Convert to Prima colors
         return $rgb->rgb_to_color;
     }
 );

Applying the palette to some data simply calls the subref that your provided
earlier:

 my $colors = $palette->apply($some_data);

Using this with a standard palette builder is pretty easy, too:

 my $colors = pal::Rainbow->apply($some_data);

And, you can provide the palette to customize how
L<pgrid::Matrix|PDL::Graphics::Prima::PlotType/pgrid::Matrix>
colorizes its data:

 plot(
     -data => ds::Grid( $matrix,
         plotType => pgrid::Matrix(palette => $palette),
         bounds => [0, 0, 1, 1],
     )
 );

=for future
All Palette classes know how to make new copies of themselves... ?

=cut

# At this point, I am debating just how closely I want Palettes to interact
# with Axes. I know I want to provide both linear and logarithmic scaling
# options. I would like to provide for auto-scaling as well as a means for
# explicitly stating the min and max of the color scale. I want to provide a
# means for easy display of the palette, with tick marks and labels. Then
# again, I could simply have the Palette hold its own scaling and create a
# special widget to draw the Palette (and possibly another widget to draw
# legends, but now I'm getting ahead of myself) 
#
# Let's start with the basics: the Palette knows how to scale data and
# convert scaled values to color values.

package PDL::Graphics::Prima::Palette;
use Carp;

our $VERSION = 0.17;   # update with update-version.pl

=head2 new

Accepts key/value pairs. The only required key is the C<apply> key, which
should have a coderef that accepts a data piddle and performs the
data-to-color conversion, returning a piddle of Prima colors.

=cut

sub new {
	my $class = shift;
	croak("${class}::new expects arguments in key=>value pairs")
		unless @_ % 2 == 0;
	
	my $self = {@_};
	croak("${class}::new requires that you supply an 'apply' key with a subroutine reference")
		unless exists $self->{apply} and ref($self->{apply})
			and ref($self->{apply}) eq 'CODE';
	
	return bless $self, $class;
}

=head2 apply

Every palette knows how to apply itself to its data. The apply function
returns a piddle of Prima color values given a piddle of scalar values.

=cut

# A basic palette knows how to apply itself to a set of data. The basic
# palette invokes the subroutine reference supplied in the apply key:
sub apply {
	my ($self, $data) = @_;
	return $self->{apply}->($data);
}

=head2 plotType

Every Palette knows the specific data and plot type to which it belongs.
The first time that a Palette is used in a drawing operation, it will become
associated with that specific plotType object, which is in turn associated
with that specific dataSet and widget. Thereafter, you can retrieve the
plotType object using this accessor, but you cannot change it.
If you want to use the same Palette with a different plotType, you can
create a copy of your palette using the L</copy> method.

=cut

sub plotType {
	my $self = shift;
	
	# See if they're requesting the plotType, return it if we have one, and
	# croak if we don't:
	if (@_ == 0) {
		return $self->{plotType} if exists $self->{plotType};
		croak("Requested palette's plot type, but it does not have one");
	}
	
	# If they are setting the plotType, croak if it has already been set,
	# since this is a write-once property
	if (exists $self->{plotType}) {
		croak("You can only set a palette's plot type once");
	}
	
	# Otherwise, they're setting the plotType. Set it and weaken the
	# reference so we don't have a memory leak
	$self->{plotType} = $_[0];
	use Scalar::Util;
	Scalar::Util::weaken($self->{plotType});
}

=head2 copy

You can make a copy of a Palette that is identical to your current pallete
except that it does not have an associated plotType. This way, if you put a
lot of effort into making a palette, you can easily reuse that palette with
minimal effort.

Note that this mechanism does not perform a deep copy, and any nested data
structures will be copied by reference to the new palette object.

=cut

sub copy {
	my $self = shift;
	my $new_guy = { %$self };
	delete $new_guy->{plotType};
	return $new_guy;
}

package PDL::Graphics::Prima::Palette::HSVrange;
our @ISA = qw(PDL::Graphics::Prima::Palette);
use Carp;

sub new {
	my $class = shift;
	croak("${class}::new expects key=>value pairs")
		unless @_ % 2 == 0;
	
	# Default to a rainbow spectrum:
	my $self = {
		h_start => 0,
		h_stop  => 360,
		s_start => 1,
		s_stop  => 1,
		v_start => 1,
		v_stop  => 1,
		gamma   => 1,
		@_
	};
	croak("${class}::new expects positive gamma values")
		if $self->{gamma} <= 0;
	return bless $self, $class;
}

sub apply {
	my ($self, $data) = @_;
	
	# Get the data and scale it from zero to one, taking care to correctly
	# handle collections of identical values:
	my ($min, $max) = $data->minmax;
	my $scaled_data = $min == $max ? $data->zeroes
						: (($data->double - $min) / ($max - $min));
	$scaled_data **= $self->{gamma};
	
	# Compute the associated hue, saturation, and vaue:
	my $h = $scaled_data * ($self->{h_stop} - $self->{h_start})
		+ $self->{h_start};
	my $s = $scaled_data * ($self->{s_stop} - $self->{s_start})
		+ $self->{s_start};
	my $v = $scaled_data * ($self->{v_stop} - $self->{v_start})
		+ $self->{v_start};
	
	# changed $h->cat($s, $v) to PDL->pdl($h, $s, $v) because it's robust
	# against empty piddles.
	return PDL->pdl($h, $s, $v)->mv(-1,0)->hsv_to_rgb->rgb_to_color;
}

=head1 Special Palettes

This module provides many ready-made palettes with short-name constructors
in the C<pal> namespace.

=over

=item pal::Rainbow

Runs from red->orange->yellow->green->blue->purple in ascending order.

=cut

sub pal::Rainbow {
	return pal::RainbowSV(1, 1);
}

=item pal::RainbowSV

Runs from red->orange->yellow->green->blue->purple in ascending order. The two
arguments it accepts are the saturation and value, which it holds uniformly.
This makes it much easier to create palettes that can be easily seen against a
white background. For example, the yellow from this palette is much eaiser to
see against a white background than the yellow from pal::Rainbow:

 pal::RainbowSV(1, 0.8)

=cut

sub pal::RainbowSV {
	croak("You must supply a saturation and a value") unless @_ == 2;
	return pal::HSVrange([0, @_] => [300, @_]);
}

=item pal::BlackToWhite

Larger values are white, smaller values are black. The optional argument is
the gamma exponent correction value, which should be positive. Typically,
gamma exponents are near 0.5.

=cut

sub pal::BlackToWhite {
	my $gamma = shift || 1/2.2;
	return PDL::Graphics::Prima::Palette::HSVrange->new(
		h_start => 0,
		h_stop  => 0,
		s_start => 0,
		s_stop  => 0,
		v_start => 0,
		v_stop  => 1,
		gamma   => $gamma,
	);
}

=item pal::WhiteToBlack

Larger values are black, smaller values are white. The optional argument is
the gamma exponent correction value, which should be positive. Typically,
gamma exponents are near 0.5.

=cut

sub pal::WhiteToBlack {
	my $gamma = shift || 1/2.2;
	return PDL::Graphics::Prima::Palette::HSVrange->new(
		h_start => 0,
		h_stop  => 0,
		s_start => 0,
		s_stop  => 0,
		v_start => 1,
		v_stop  => 0,
		gamma   => $gamma,
	);
}

=item pal::WhiteToHSV

Smaller values are closer to white, larger values are closer to the color
indicated by the HSV values that you specify, which are supplied to the
function as three different scalars. The first three arguments are hue,
saturation, and value. The optional fourth value is a gamma correction
exponent.

For example:

 my $white_to_red = pal::WhiteToHSV(0, 1, 1);
 my $gamma_white_to_red = pal::WhiteToHSV(0, 1, 1, 0.8);

=cut

sub pal::WhiteToHSV {
	my @gamma;
	@gamma = (gamma => pop) if @_ == 4;
	return PDL::Graphics::Prima::Palette::HSVrange->new(
		h_start => 0,
		s_start => 0,
		v_start => 1,
		h_stop  => $_[0],
		s_stop  => $_[1],
		v_stop  => $_[2],
		@gamma,
	);
}

=item pal::BlackToHSV

Like WhiteToHSV, but smaller values are closer to black instead of white.

=cut

sub pal::BlackToHSV {
	my @gamma;
	@gamma = (gamma => pop) if @_ == 4;
	return PDL::Graphics::Prima::Palette::HSVrange->new(
		h_start => 0,
		s_start => 0,
		v_start => 0,
		h_stop  => $_[0],
		s_stop  => $_[1],
		v_stop  => $_[2],
		@gamma,
	);
}

=item pal::HSVrange

Maps data in ascending order from the start to the stop values in hue, saturation,
and value. You can specify the initial and final hue, saturation, and value
in one of two ways: (1) a pair of three-element arrayrefs/piddles with the
initial and final hsv values, or (3) a set of key/value pairs describing the initial
and final hue, saturation and value.

For example, this creates a palette that runs from red (H=360) to blue
(H=240):

 my $blue_to_red = pal::HSVrange([360, 1, 1] => [240, 1, 1]);

If you know the L<Prima name of your color|Prima::Const/cl>, you can use the
conversion functions provided by
L<PDL::Drawing::Prima::Utils|PDL::Drawing::Prima::Utils/> to build an HSV
range. This example produces a palette from blue to red:

 my $blue_hsv = pdl(cl::LightBlue)->color_to_rgb->rgb_to_hsv;
 my $red_hsv = pdl(cl::LightRed)->color_to_rgb->rgb_to_hsv;
 my $blue_to_red = pal::HSVrange($blue_hsv, $red_hsv);

The final means for specifying a range in HSV space is to provide key/value
pairs that describe your initial and final points in HSV space. You can
also specify a non-unitary gamma correction exponent. For example,
to go from blue to red with a gamma of 0.8, you could say:

 my $blue_to_red = pal::HSVrange(
       h_start => 240,
       s_start => 1,
       v_start => 1,
       h_stop  => 360,
       s_stop  => 1,
       v_stop  => 1,
       gamma   => 0.8,
   );

However, you do not need to provide all of these values. Any key that you do
not supply will use a default value:

 Key       Default
 -----------------
 h_start   0
 s_start   1
 v_start   1
 h_stop    360
 s_stop    1
 v_stop    1
 gamma     1

So the blue-to-red palette, without a gamma correction, could be specified
as:

 my $blue_to_red = pal::HSVrange(
     h_start => 240, h_stop => 360,
 );

=cut

use Scalar::Util qw(blessed);
sub pal::HSVrange {
	croak("pal::HSVrange called with odd number of arguments")
		if @_ % 2 == 1;
	
	# replace piddles in either of the fist two args with arrayrefs
	$_[0] = [$_[0]->dog] if blessed($_[0]) and $_[0]->isa('PDL');
	$_[1] = [$_[1]->dog] if blessed($_[1]) and $_[1]->isa('PDL');
	
	# Did they provide two array refs?
	if (ref($_[0]) and ref($_[0]) eq ref([])) {
		my $from = shift;
		my $to = shift;
		
		# Check that $to is also an array ref, and that the dims are correct
		ref($to) and ref($to) eq ref([])
			or croak('If the first argument to pal::HSVrange is an array ref'
				. ' or piddle, the second should be an array ref or piddle, too');
		@$from == 3 and @$to == 3
			or croak('If called with to/from array refs or piddles, pal::HSVrange'
				. ' expects three-elements in said array refs or piddles');
		# Pad the argument list in preparation for the call to new
		unshift @_,
			h_start => $from->[0],
			s_start => $from->[1],
			v_start => $from->[2],
			h_stop  => $to->[0],
			s_stop  => $to->[1],
			v_stop  => $to->[2],
	}
	
	return PDL::Graphics::Prima::Palette::HSVrange->new(@_);
}

## Basic histogram equalization implementation, worth considering:
## See http://www.generation5.org/content/2004/histogramEqualization.asp
#
## Let's try histogram equalization on this
#my $xs = $m51->flat->qsort;
## Find the bottom 10% and top 10% and clip by them
#$m51->flat .= $m51->flat->vsearch($xs);
#my $ys = $xs->xlinvals(0, 1);
#line_plot($xs, $ys);
#
## Interesting clipping idea:
#my $min = $xs->at($xs->nelem/10);
#my $max = $xs->at($xs->nelem*0.9);
#$m51->clip($min, $max);

1;

=back

=head1 AUTHOR

David Mertens (dcmertens.perl@gmail.com)

=head1 ADDITIONAL MODULES

Here is the full list of modules in this distribution:

=over

=item L<PDL::Graphics::Prima|PDL::Graphics::Prima/>

Defines the Plot widget for use in Prima applications

=item L<PDL::Graphics::Prima::Axis|PDL::Graphics::Prima::Axis/>

Specifies the behavior of axes (but not the scaling)

=item L<PDL::Graphics::Prima::DataSet|PDL::Graphics::Prima::DataSet/>

Specifies the behavior of DataSets

=item L<PDL::Graphics::Prima::Limits|PDL::Graphics::Prima::Limits/>

Defines the lm:: namespace

=item L<PDL::Graphics::Prima::Palette|PDL::Graphics::Prima::Palette/>

Specifies a collection of different color palettes

=item L<PDL::Graphics::Prima::PlotType|PDL::Graphics::Prima::PlotType/>

Defines the different ways to visualize your data

=item L<PDL::Graphics::Prima::ReadLine|PDL::Graphics::Prima::ReadLine/>

Encapsulates all interaction with the L<Term::ReadLine> family of
modules.

=item L<PDL::Graphics::Prima::Scaling|PDL::Graphics::Prima::Scaling/>

Specifies different kinds of scaling, including linear and logarithmic

=item L<PDL::Graphics::Prima::Simple|PDL::Graphics::Prima::Simple/>

Defines a number of useful functions for generating simple and not-so-simple
plots

=back

=head1 LICENSE AND COPYRIGHT

Unless otherwise stated, all contributions in code and documentation are
copyright (c) their respective authors, all rights reserved.

Portions of this module's code are copyright (c) 2011 The Board of
Trustees at the University of Illinois.

Portions of this module's code are copyright (c) 2011-2013 Northwestern
University.

Portions of this module's code are copyright (c) 2013-2014 Dickinson
College.

This module's documentation is copyright (c) 2011-2014 David Mertens.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
