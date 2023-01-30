use strict;
use warnings;
use PDL::Drawing::Prima::Utils;
use PDL::Graphics::Prima::SizeSpec;

# For further reading: http://cadik.posvete.cz/color_to_gray_evaluation/

=head1 NAME

PDL::Graphics::Prima::Palette - a set of palettes for the Prima graph widget

=head1 DESCRIPTION

=for podview <img src="PDL/Graphics/Prima/pod/palette.png">

=for html <p><img src="https://raw.githubusercontent.com/PDLPorters/PDL-Graphics-Prima/master/lib/PDL/Graphics/Prima/pod/palette.png">

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
         return floor((($data - $min) / ($max - $min)) * 255) * 0x10000;
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

 my $x = sequence(100)/10 + 0.1;
 my $y = $x->sin + $x->grandom / 10;
 plot(
     -data => ds::Grid( $y,
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

our $VERSION = 0.18;   # update with update-version.pl

=head2 new

Accepts key/value pairs. The only required key is the C<apply> key, which
should have a coderef that accepts a data piddle and performs the
data-to-color conversion, returning a piddle of Prima colors. Note that when
using the HSVRange palette described below, the apply key is NOT mandatory.

If this palette is being rendered as the plot-wide color map, there is a wide
variety of properties that let you tweak how it is drawn. The C<label> indicates
a string that will be drawn above the color bar. You can specify a boolean value
for C<boxed> which indicates whether or not to enclose the color bar in a box.
There are then a large collection of L<SizeSpec|PDL::Graphics::Prima::SizeSpec/>s
that control the exact positioning and sizes of the color bar, its tick marks,
and the tick mark labels. These include:

=over

=item C<outer_margin>

the space between the edge of the plot and the edge of the widest tick label

=item C<tick_label_padding>

the space between the labels and the end of the tick mark

=item C<tick_size>

the length of the tick mark

=item C<tick_padding>

the space between the color bar and the end of the tick mark

=item C<bar_width>

the width of the color bar

=item C<inner_margin>

the space between the color bar and the outer edge of the plotting space

=item C<top_margin>

the space between either the figure title or the top of the figure and the
top of the color bar or (if there is a label) the color map's label

=item C<label_padding>

the space between the bottom of the label and the top of the color bar, if the
label is present (this is ignored if there is no label text)

=item C<bottom_margin>

the space between the bottom edge of the figure and the bottom of the color bar

=back

Finally, there are three additional keys that are not usable by this basic
palette, but are usable by derived palette classes. The C<min> and C<max>
properties can be used to explicitly set the minimum and maximum values to be
used in the scaling. This is useful when multiple datasets are using the same
palette and you want consistency in the color scaling. If you do not set these
you will get automatic scaling, but if you want to change them from a fixed
number back to autoscaling, you can use the C<lm::Auto> value that is also used
to tell the x- and y-axes to resume autoscaling. The last key of interest is the
C<badval_color> key, which provides a Prima color to use when the system
encounters bad data. The default value is C<cl::Brown>.

Note that any colors that fall outside of explicitly specified minimum and
maximum values have no guarantees about their rendering. Eventually it would be
good to provide keys C<toohigh_color> and C<toolow_color>, just like
C<badval_color>. However, the exact rendering of those on the visualization
still needs to be worked out

=cut

sub defaults {
	return (
		label              => '',       # displayed over the palette box

		# Horizontal placement
		outer_margin       => '1em',    # between outer edge and palette box
		tick_label_padding => '0.5em',  # space between labels and tick marks
		tick_size          => '0.5em',  # length of tick marks
		tick_padding       => 0,        # distance between tick marks and bar
		bar_width          => '1.5em',  # width of the drawn palette box
		inner_margin       => 0,        # space between bar and left edge of plot,
		                                #    in addition to the plot's margin
		# TODO:
		# * make both labeling fonts configurable
		# * make it possible to put the tick marks and labels on the left
		#   instead of the right (inner vs outer placement)
		# * make it possible to draw the palette on the left, bottom, or top
		#   of the plot
		# * make it possible to put the color bar *inside* the plot window,
		#   in which case it will need to be enclosed with a box
		# * come up with a convenient means for dictating alignment of
		#   top/bottom of bar with top/bottom of plot
		# * make it possible to label the palette on the side instead of on the
		#   top

		# Vertical placement
		top_margin    => '1em',    # between figure's top edge and top of label
		                           #   text or top of color bar
		# label height will be dictated by the font
		label_padding => '0.5em',    # between bottom of label and top of bar,
		                           #   only applied if label is non-empty
		bottom_margin => '1.5em',  # between bottom of color bar figure's bottom
		                           #   edge

		# min and max set to autoscale
		min  => lm::Auto,
		max  => lm::Auto,
		# Color to represent bad values; this should be revised when better
		# color spaces are eventually worked into PDL::Graphics::Prima
		badval_color => cl::Brown,
		# whether or not to draw a box around the color map
		boxed => 0,
	)
}

sub width_property_names { ( qw(outer_margin bar_width tick_padding tick_size
			tick_label_padding inner_margin) ) }
sub height_property_names { ( qw(top_margin label_padding bottom_margin) ) }

use Scalar::Util ();
sub new {
	my $class = shift;
	croak("${class}::new expects arguments in key=>value pairs")
		unless @_ % 2 == 0;

	my $self = {
		$class->defaults,
		@_,
	};
	if ($class eq __PACKAGE__) {
		croak("${class}::new requires that you supply an 'apply' key with a subroutine reference")
			unless exists $self->{apply} and ref($self->{apply})
				and ref($self->{apply}) eq 'CODE';
	}

	# Create the palette object
	bless $self, $class;

	# Avoid memory leaks and cache the default size specs
	if ($self->{widget}) {
		Scalar::Util::weaken($self->{widget});
		$self->{default_size_specs} = $self->generate_size_specs_for_canvas($self->{widget});
	}

	return $self;
}

# Getter/setter for the widget. If we change the widget, then regenerate all of
# the size specs.
sub widget {
	my $self = shift;
	return $self->{widget} unless @_;
	my $new_widget = shift;
	# delete widget?
	return delete $self->{widget} unless $new_widget;
	# Setting widget to same thing?
	return if $self->{widget} && $new_widget && $self->{widget} == $new_widget;
	# new widget. Add the ref, avoid memory leaks, and update the size specs
	$self->{widget} = $new_widget;
	Scalar::Util::weaken($self->{widget});
	$self->{default_size_specs} = $self->generate_size_specs_for_canvas($new_widget);
}

=head2 generate_size_specs_for_canvas

This method takes a single canvas as an argument and generates a hashref
containing SizeSpec objects for all of the size specs for the Palette. But if
you need access to those size specs, you probably don't want to use this. Use
C<size_specs_for_canvas> instead, which should be a little faster than this
because it caches for the common case of SizeSpecs for the palette's plot widget.

=cut

# Function that always generates the size specs hashref. Y
sub generate_size_specs_for_canvas {
	my ($self, $canvas) = @_;

	# Build a typical size-spec parser
	my $parser = PDL::Graphics::Prima::SizeSpec::Parser->new($canvas);

	# Construct the various size specs, stashing them in the hash
	my %size_specs;
	for my $length ($self->width_property_names, $self->height_property_names) {
		$size_specs{$length} = $parser->parse($self->{$length});
	}
	return \%size_specs;
}

=head2 size_specs_for_canvas

This method takes a single canvas as an argument and returns a hashref
containing SizeSpec objects for all of the size specs for the Palette. Unlike
C<generate_size_specs_for_canvas>, this uses cached SizeSpecs for the plot
widget and so is usually faster.

=cut

# Initializes all size specs, if the palette has an associated widget
sub size_specs_for_canvas {
	my ($self, $canvas) = @_;
	# If we're working with our widget then return the pre-computed specs
	return $self->{default_size_specs} if $canvas == $self->{widget};
	# Otherwise generate new specs on the fly
	return $self->generate_size_specs_for_canvas($canvas);
}

=head2 scaling

Every palette knows its scaling. At the time of writing that's either linear
or logarithmic. The default scaling is linear.

=cut

sub scaling { return shift->{scaling} || sc::Linear }

=head2 apply

Every palette knows how to apply itself to its data. The apply function
returns a piddle of Prima color values given a piddle of scalar values.
After calling the pallete's C<apply> subref, all points that were previously
C<bad> in the given data are marked with the C<badval_color>.

=cut

# A basic palette knows how to apply itself to a set of data. The basic
# palette invokes the subroutine reference supplied in the apply key:
sub apply {
	my ($self, $data) = @_;
	my $colors_to_return = $self->{apply}->($data);
	$colors_to_return->where($data->isbad) .= $self->{badval_color};
	$colors_to_return->badflag(0);
	return $colors_to_return;
}

=head2 boxed

Getter/setter for the boxed property. If this is a color map, setting this will
trigger a redraw of the plot. If this is not a color map, then setting this has
no effect on anything.

=cut

sub boxed {
	my $self = shift;
	return $self->{boxed} if @_ == 0;
	my $new_boxed =!! shift;
	if ($self->{boxed} != $new_boxed) {
		$self->{boxed} = $new_boxed;
		if ($self->{widget}) {
			$self->widget->notify('Paint');
			# If running in the PDL shell, clear the event queue so this hits
			# immediately
			$::application->yield if defined $PERLDL::TERM;
		}
	}
}

=head2 draw

Draws the palette on the associated widget.

=cut

sub draw {
	my ($self, $canvas, $clip_left, $clip_bottom, $clip_right, $clip_top
		, $ratio) = @_;

	# Get the size specs
	my $sizes = $self->size_specs_for_canvas($canvas);

	# Get an em height, which we use to specifying the draw_text command
	my $em_points = $canvas->get_text_box('M');
	my $em_height = $em_points->[1] - $em_points->[3];

	# We'll work our way in from the right, starting with the labels and
	# finishing with the color bar. For pretty much all of this, we'll need
	# the height of the color bar
	my $bottom = 0 + $sizes->{bottom_margin};
	my $top = $canvas->height - $sizes->{top_margin};
	# Move top down even more if there is a label
	$top -= $canvas->font->height + $sizes->{label_padding} if $self->{label};
	my $bar_height = $top - $bottom;

	# We also need the palette's min/max. Note that our minmax method handles
	# degeneracy for us, thankfully.
	my ($min, $max) = $self->minmax;

	### Draw the ticks and labels
	# Figure out the x-position at which we will draw the labels, as well as
	# the horizontal start and stop points for the tick marks.
	my $tick_label_width = $self->get_tick_label_width($canvas);
	my $label_left = $canvas->width - $sizes->{outer_margin} - $tick_label_width;
	my $tick_right = $label_left - $sizes->{tick_label_padding};
	my $tick_left = $tick_right - $sizes->{tick_size};

	# use the scaling to get the actual ticks
	for my $Tick ($self->get_label_Ticks->list) {
		# Render each tick. To get there, perform the inverse transform on the
		# tick value, multiply by the height, and add the pixel height of the
		# bottom of the color bar
		my $y = $self->scaling->transform($min, $max, $Tick) * $bar_height
			+ $bottom;
		# the tick mark
		$canvas->line($tick_left, $y, $tick_right, $y);
		# the tick label
		$canvas->draw_text($Tick, $label_left, $y - $em_height,
			$label_left + $tick_label_width, $y + $em_height,
			dt::Left | dt::VCenter | dt::NoWordWrap | dt::UseExternalLeading);
	}

	### Draw the color bar.
	# It's position is a known width away from the clip right.
	my $bar_right = $tick_left - $sizes->{tick_padding};
	my $bar_left = $bar_right - $sizes->{bar_width};
	# for a smooth gradient, we need to draw rectangles from the bottom to the
	# top, one per pixel. Use the scaling to generate the associated values,
	# then run those values through the palette's apply method.
	my $N_gradient_boxes = $top - $bottom;
	my $rect_bottoms = PDL->sequence($N_gradient_boxes) + $bottom;
	my $gradient_values = $self->scaling->sample_evenly($self->minmax,
		$N_gradient_boxes);
	my $gradient_colors = $self->apply($gradient_values);
	# draw the color bar!
	$canvas->pdl_bars($bar_left, $rect_bottoms, $bar_right, $rect_bottoms + 0.99,
		colors => $gradient_colors);
	$canvas->rectangle($bar_left, $bottom, $bar_right, $top)
		if $self->boxed;

	if ($self->{label}) {
		### Finish with the color map label at the top, if it exists
		# Compute a few of the label positions
		my $label_bottom = $top + $sizes->{label_padding};
		my $label_right = $canvas->width - $sizes->{outer_margin};
		# Draw the label
		$canvas->draw_text($self->{label}, $bar_left, $label_bottom, $label_right,
			$label_bottom + 2 * $em_height,
			dt::Center | dt::Bottom | dt::NoWordWrap | dt::UseExternalLeading);
	}
}

=head2 set_autoscaling_minmax

Sets or clears the values to be used as the minimum and maximum when they are
set to C<lm::Auto>.

=cut

sub set_autoscaling_minmax {
	my ($self, $min, $max) = @_;
	if (defined $max) {
		$self->{autoscaling_minmax} = [$min, $max];
	}
	else {
		delete $self->{autoscaling_minmax};
	}
}

=head2 minmax

Returns the minimum and maximum values that will be used by the palette. This
optionally takes a single argument, the data to be transformed. If either of the
explicit min or max values are set to C<lm::Auto>, this checks to see if an
autoscaling minmax pair has been set and uses those in place of C<lm::Auto>. If
there is no autoscaling minmax pair, then this queries the data for its min
and/or max and uses those. If the method gets this far but you did not pass data
to be transformed, it croaks saying

  Requested palette minmax but none specified,
  autoscaling minmax not set, and no data given

=cut

sub minmax {
	my ($self, $data) = @_;
	# First get what we think our min and max should be
	my ($min, $max) = ($self->{min}, $self->{max});
	# Does either ask for auto-scaling?
	if ($min == lm::Auto or $max == lm::Auto) {
		# Must get the extrema. If our extrema field is set, use that. Otherwise
		# use the data's minmax, if data was given. If not, croak.
		my @minmax = @{$self->{autoscaling_minmax} || []};
		@minmax = $data->minmax if @minmax == 0 and defined $data;
		croak("Requested palette minmax but none specified, autoscaling minmax not set, and no data given")
			if @minmax == 0;

		$min = $minmax[0] if $min == lm::Auto;
		$max = $minmax[1] if $max == lm::Auto;
	}
	# Handle degeneracy
	($min, $max) = $self->scaling->min_max_for_degenerate($min)
		if $min == $max;
	return ($min, $max);
}

=head2 get_tick_label_width

Computes the width needed to draw all the palette tick labels. This dynamically
generates the list of labels and computes the width of the widest one. Takes an
optional argument for the canvas upon which to draw, but defaults to the current
widget if none is given.

Because this needs to compute text widths, this can only be called on a palette
that has been attached to a widget.

=cut

sub get_label_Ticks {
	my $self = shift;
	# use the scaling to get the Ticks, but drop the ticks
	my ($Ticks) = $self->scaling->compute_ticks($self->minmax);
	return $Ticks;
}

sub get_tick_label_width {
	my $self = shift;
	my $canvas = shift || $self->widget
		or croak("palette must be tied to a plot or given a Drawable to compute its width");

	# determine the text width of the ticks
	my $width = 0;
	for my $Tick ($self->get_label_Ticks->list) {
		my $points = $canvas->get_text_box($Tick);
		$width = $points->[4] if $points->[4] > $width;
	}

	return $width;
}

=head2 get_width

Computes the total width of the given palette. This can only be called on a
palette that has been attached to a widget and for which the minimum and maximum
data values have been articulated.

=cut

sub get_width {
	my $self = shift;
	my $canvas = shift || $self->widget;

	# First get the label width
	my $width = $self->get_tick_label_width($canvas);

	# Add up all the size specs for width
	my $size_specs = $self->size_specs_for_canvas($canvas);

	# Add this to all the other widths
	for my $width_property_name ($self->width_property_names) {
		$width += $size_specs->{$width_property_name};
	}
	return $width;
}


package PDL::Graphics::Prima::Palette::HSVrange;
our @ISA = qw(PDL::Graphics::Prima::Palette);
use Carp;

sub new {
	my $class = shift;
	croak("${class}::new expects key=>value pairs")
		unless @_ % 2 == 0;

	# Default to a rainbow spectrum:
	my $self = $class->SUPER::new(
		h_start => 0,
		h_stop  => 360,
		s_start => 1,
		s_stop  => 1,
		v_start => 1,
		v_stop  => 1,
		gamma   => 1,
		@_
	);
	croak("${class}::new expects positive gamma values") if $self->{gamma} <= 0;

	return $self;
}

sub apply {
	my ($self, $data) = @_;

	# Figure out the min and max.
	my ($min, $max) = $self->minmax($data);

	# Scale the data from zero to one
	my $scaled_data = $self->scaling->transform($min, $max, $data);
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
	my $colors = PDL->pdl($h, $s, $v)->mv(-1,0)->hsv_to_rgb->rgb_to_color;
	# handle bad value coloring
	$colors->where($data->isbad) .= $self->{badval_color};
	$colors->badflag(0);
	# All set!
	return $colors;
}

=head1 Special Palettes

This module provides many ready-made palettes with short-name constructors
in the C<pal> namespace.

=over

=item pal::Rainbow

Runs from red->orange->yellow->green->blue->purple in ascending order.

=cut

sub pal::Rainbow {
	return pal::RainbowSV(1, 1, @_);
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
	my ($saturation, $value, @other_args) = @_;
	croak("You must supply a saturation and a value")
		if not defined $saturation or not defined $value;
	return pal::HSVrange([0, $saturation, $value] => [300, $saturation, $value],
		@other_args);
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
and final hue, saturation and value. You can also specify data min and max. Any data
that falls below the min or above the max will be represented with the closest min
or max color. This is particularly helpful when you need to coordinate the min and
max of multiple palettes.

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

=item L<PDL::Graphics::Prima::SizeSpec|PDL::Graphics::Prima::SizeSpec/>

Compute pixel distances from meaningful units

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
