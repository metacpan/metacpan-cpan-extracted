#
# GENERATED WITH PDL::PP from prima.pd! Don't modify!
#
package PDL::Drawing::Prima;

our @EXPORT_OK = qw( );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.20';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Drawing::Prima $VERSION;








#line 11 "prima.pd"

use strict;
use warnings;
use PDL;
use PDL::Char;
use Scalar::Util 'blessed';
use Carp 'croak';
use PDL::Drawing::Prima::Utils;
use Prima::noX11;

=head1 NAME

PDL::Drawing::Prima - PDL-aware drawing functions for Prima widgets

=head1 SYNOPSIS

=for podview <img src="PDL/Drawing/Prima/pod/sin.png">

=for html <p><img src="https://raw.githubusercontent.com/dk/PDL-Drawing-Prima/master/pod/sin.png">

Each of the methods comes with a small sample snippet. To see how it
looks, copy this synopsis and replace the code in the
C<Example code goes here> block with the example code.

 use strict;
 use warnings;
 use PDL;
 use PDL::Drawing::Prima;
 use Prima qw(Application);

 my $window = Prima::MainWindow->create(
     text      => 'PDL::Drawing::Prima Test',
     antialias => 1,
     onPaint   => sub {
         my ( $self, $canvas) = @_;

         # wipe the canvas:
         $canvas->clear;

         ### Example code goes here ###

         # Draw a sine curve on the widget:
         my ($width, $height) = $canvas->size;
         my $x = sequence($width);
         my $y = ( sin($x / 20) + 1 ) * $height/2;
         $canvas->pdl_polylines($x, $y, lineWidths => 2);

         ### Example code ends here ###
     },
     backColor => cl::White,
 );

 run Prima;

=head1 DESCRIPTION

This module provides a number of PDL-threaded functions and bindings for use
with the Prima toolkit. Many of the functions are PDL bindings for the
standard Prima drawing functions. Others are useful functions for color
manipulation, or getting data into a form that PDL knows how to handle.
I generally divide the subroutines of this module into two categories:
B<methods> and B<functions>. The methods are subroutines that operate on a
Prima widget; the functions are subroutines that act on or return piddles.

Most of the methods given here are PDLified versions of the Prima drawing API
functions, which are documented under L<Prima::Drawable>. In general, where the
Prima API uses singular nouns, I here use plural nouns. A few of the methods
are only available in this module, mostly added to accomodate the needs of
L<PDL::Graphics::Prima>, the plotting library built on these bindings.

This bindings can be applied to B<any> object whose class is derived from
L<Prima::Drawable>, including displayed widgets and abstract canvases such
as L<Prima::PS::Printer>. If you create your own derived canvas, these
methods should Just Work. (I wish I could take credit for this, but it's
really due to the fact that Prima's internals are very well engineered.)

=head1 COORDINATE ORIGIN

The Prima image coordinate origin is located in lower left corner, which is
where you would expect to find it when creating plots. However, it is different
from the way that many graphics libraries do their coordinates.

=head1 FUNCTIONS

=head2 piddle_of_patterns_for

If you want PDL to thread over line patterns, but you want to use the standard
Prima line patterns, you'll need to convert them line patterns to a piddle.
This works very simply like this:

 my $patterns = piddle_of_patterns_for(lp::Solid, lp::Dash);

This creates a piddle with the two patterns so that you could have PDL thread
over them.

You can also create your own line pattern piddles by hand. I recommend you use
byte array, since otherwise it will be converted to byte arrays for you.
The first element of a row in your byte array
specifies the number of pixels to be "on", the second specifies the number to be
"off", the third specifies the number to be "on" again, the fourth "off", the
fifth "on", etc. If that doesn't make sense, hopefully a couple of examples will
help clarify.

This example creates the equivalent of lp::Dash:

 my $dash_pattern = byte (9, 3);

This example creates a piddle with four line types: lp::Solid, lp::Dash,
lp::ShortDash, and lp::DashDot:

 my $patterns = byte q[ 1; 9 3; 3 3; 9 3 1 3];

and should be identical to

 my $patterns = piddle_of_patterns_for(
     lp::Solid, lp::Dash, lp::ShortDash, lp::DashDot);

When you create a byte piddle, all of the patterns must have the same number of
bytes in their specification. Of course, different patterns have different
lengths, so in that case simply pad the shorter specifications with zeroes.

=cut

# Builds a piddle of patterns with the appropriate sizes, etc.
sub piddle_of_patterns_for {
	# Make sure they're not being stupid:
	croak("You must supply at least one pattern to make a pattern piddle")
		if @_ == 0;

	# First get the longest pattern:
	my $length = 0;
	foreach(@_) {
		$length = length($_) if $length < length($_);
	}

	use PDL::NiceSlice;

	# Create the new byte array with the appropriate dimensions:
	my $to_return = zeroes(byte, $length, scalar(@_));
	$to_return .= $to_return->sequence;
	for (my $i = 0; $i < @_; $i++) {
		# Get a slice and update it:
		my $slice = $to_return(:,$i);
		substr ${$slice->get_dataref}, 0, length($_[$i]), $_[$i];

		# Make sure the modifications propogate back to the original:
		$slice->upd_data;
	}

	no PDL::NiceSlice;

	return $to_return;
}

#line 178 "prima.pd"

=head1 METHODS

The methods described below are a bit unusual for PDL functions. First, they are
not actually PDL functions at all but are methods for C<Prima::Drawable>
objects. Second, their signatures will look a bit funny. Don't worry too much
about that, though, because they will resemble normal signatures close enough
that you should be able to understand them, I hope.

=cut
#line 193 "Prima.pm"


=head1 FUNCTIONS

=cut





#line 1391 "prima.pd"

# This is a list of the number of arguments for each property. It is based on the
# pars_args_for hash which is built in the .pd file associated with this module
my %N_args_for = qw(
	fillModes            1
	backColors           1
	lineJoins            1
	colors               1
	fillPatterns         1
	lineWidths           1
	linePatterns         1
	clipRects            4
	rop2s                1
	rops                 1
	splinePrecisions     1
);

#line 1417 "prima.pd"
sub get_sorted_args_with_defaults {
	my ($self, $arg_names, $given) = @_;

	# Default to an empty list:
	$given = {} unless ref($given) eq 'HASH';

	# Check that they supplied only allowed parameters (allowing both
	# singular and plural forms)
	for my $parameter (keys %$given) {
		croak("Unknown parameter $parameter")
			unless grep {
				# check singular and plural parameter names
				$_ eq $parameter or $_ eq $parameter . 's'
				} @$arg_names
	}

	# Return the sorted list of supplied or default values
	my @to_return = ();
	for my $arg_name (@$arg_names) {
		# If a plural property is not specified, return a default property of
		# a zeroed-out, one-element piddle. Set the value to zero since it is
		# never used.
		if (not exists $given->{$arg_name}) {
			push @to_return, (0) for (1..$N_args_for{$arg_name});
		}
		elsif (ref ($given->{$arg_name}) eq 'ARRAY') {
			# If an array ref, dereference it and make sure the number
			# of arguments agrees with what we expect:
			if (@{$given->{$arg_name}} != $N_args_for{$arg_name}) {
				croak("Expected 1 argument for $arg_name") if $N_args_for{$arg_name} == 1;
				croak("Expected $N_args_for{$arg_name} arguments for $arg_name");
			}
			push @to_return, @{$given->{$arg_name}};
		}
		else {
			# Otherwise, return it outright, if we only expected one
			# argument:
			$N_args_for{$arg_name} == 1
				or croak("Expected $N_args_for{$arg_name} arguments for $arg_name");

			push @to_return, $given->{$arg_name};
		}
	}
	return @to_return;
}
#line 268 "Prima.pm"


=head2 prima_arcs

=for sig

 Signature: (double x(); double y(); double x_diameter(); double y_diameter();
			start_angle(); end_angle(); int colors(); int backColors(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_arcs($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_arcs($y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_arcs

=for sig

  Prima Signature: (widget; x(); y(); x_diameter(); y_diameter();
                     start_angle(); end_angle(); properties)

=for ref

Draws arcs, i.e. incomplete ellipses.

Applicable properties include colors, backColors,
linePatterns, lineWidths, rops, rop2s.

The arcs go from the C<start_angle>s to the C<end_angle>s along the
ellipses centered at the C<x>s and C<y>s, with the specified x- and
y-diameters. The angles are measured in degrees, not radians.
The difference between this command and L</pdl_chords> or L</pdl_sectors> is that
C<pdl_arcs> does not connect the dangling ends.

Here's a simple example:

=for example

 # Draw a bunch of random arcs on $canvas:
 my $N_arcs = 20;
 my ($x_max, $y_max) = $canvas->size;
 my $xs = zeroes($N_arcs)->random * $x_max;
 my $ys = $xs->random * $y_max;
 my $dxs = $xs->random * $x_max / 4;
 my $dys = $xs->random * $y_max / 4;
 my $th_starts = $xs->random * 360;
 my $th_stops = $xs->random * 360;

 # Now that we've generated the data, call the command:
 $canvas->pdl_arcs($xs, $ys, $dxs
                , $dys, $th_starts, $th_stops);

If you put that snippet of code in the C<onPaint> method, as
suggested in the synopsis, a completely new set of arcs will get
redrawn whenever you resize your window.

Compare to the Prima method L<Prima::Drawable/arc>. Closely related
routines include L</pdl_chords> and L</pdl_sectors>. See also
L</pdl_fill_chords>, and L</pdl_fill_sectors>, L</pdl_ellipses>, and
L</pdl_fill_ellipses>.

Spline drawing provides a similar functionality, though more complex and
more powerful. There are no PDL bindings for the spline functions yet.
See L<Prima::Drawable/spline> for more information.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_arcs> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @arcs_props = qw(colors backColors linePatterns lineWidths rops rop2s);
our @arcs_args = qw(x y x_diameter y_diameter start_angle end_angle);
sub Prima::Drawable::pdl_arcs {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_arcs is a widget method that expectes '. scalar(@arcs_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @arcs_args))
		unless (@_ > @arcs_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $x_diameter = shift;
	my $y_diameter = shift;
	my $start_angle = shift;
	my $end_angle = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_arcs expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@arcs_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_arcs_int($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_arcs: $@";
	}
	
}





=head2 prima_bars

=for sig

 Signature: (double x1(); double y1(); double x2(); double y2(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte fillPatterns(oct=8); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_bars($x1, $y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x1->prima_bars($y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_bars

  Prima Signature: (widget; x1(); y1(); x2(); y2(); properties)

=for ref

Draws filled rectangles from corners (x1, y1) to (x2, y2).

Applicable properties include colors, backColors, clipRects,
fillPatterns, rops, rop2s.

=for example

 # Draw 20 random filled rectangles on $canvas:
 my $N_bars = 20;
 my ($x_max, $y_max) = $canvas->size;
 my $x1s = zeroes($N_bars)->random * $x_max;
 my $y1s = $x1s->random * $y_max;
 my $x2s = $x1s + $x1s->random * ($x_max - $x1s);
 my $y2s = $y1s + $x1s->random * ($y_max - $y1s);
 my $colors = $x1s->random * 2**24;

 # Now that we've generated the data, call the command:
 $canvas->pdl_bars($x1s, $y1s, $x2s, $y2s
         , colors => $colors);

If you put that snippet of code in the C<onPaint> method, as
suggested in the synopsis, a completely new set of filled rectangles
will get redrawn whenever you resize your window.

Compare to the Prima method L<Prima::Drawable/bar>. See also
L</pdl_rectangles>, which is the unfilled equivalent, and L</pdl_clears>,
which is sorta the opposite of this.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_bars> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @bars_props = qw(colors backColors clipRects fillPatterns rops rop2s);
our @bars_args = qw(x1 y1 x2 y2);
sub Prima::Drawable::pdl_bars {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_bars is a widget method that expectes '. scalar(@bars_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @bars_args))
		unless (@_ > @bars_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $x2 = shift;
	my $y2 = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_bars expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@bars_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_bars_int($x1, $y1, $x2, $y2, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_bars: $@";
	}
	
}





=head2 prima_chords

=for sig

 Signature: (double x(); double y(); double x_diameter(); double y_diameter();
			double start_angle(); double end_angle(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_chords($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_chords($y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_chords

  Prima Signature: (widget; x(); y(); x_diameter(); y_diameter();
                           start_angle(); end_angle(); properties)

=for ref

Draws arcs (i.e. incomplete ellipses) whose ends are connected by a line.

The chord starts at C<start_angle> and runs to C<end_angle> along the ellipse
centered at C<x>, C<y>, with their specified diameters C<x_diameter>,
C<y_diameter>. Unlike L</pdl_arcs> or L</pdl_sectors>, it connects
the ends of the arc with a straight line. The angles are
measured in degrees, not radians.

Applicable properties include colors, backColors, clipRects,
linePatterns, lineWidths, rops, rop2s.

=for example

 # For this example, you will need:
 use PDL::Char;

 # Draw a bunch of random arcs on $canvas:
 my $N_chords = 20;
 my ($x_max, $y_max) = $canvas->size;
 my $xs = zeroes($N_chords)->random * $x_max;
 my $ys = $xs->random * $y_max;
 my $dxs = $xs->random * $x_max / 4;
 my $dys = $xs->random * $y_max / 4;
 my $th_starts = $xs->random * 360;
 my $th_stops = $xs->random * 360;

 # make a small list of patterns:
 my $patterns_list = PDL::Char->new(
          [lp::Solid, lp::Dash, lp::DashDot]);

 # Randomly select 20 of those patterns:
 my $rand_selections = ($xs->random * 3)->byte;
 use PDL::NiceSlice;
 my $patterns = $patterns_list($rand_selections)->transpose;

 # Now that we've generated the data, call the command:
 $canvas->pdl_chords($xs, $ys, $dxs
                , $dys, $th_starts, $th_stops
                , linePatterns => $patterns);

If you put that snippet of code in the onPaint method, as
suggested in the synopsis, a completely new set of chords
will get redrawn whenever you resize your window.

Compare to the Prima method L<Prima::Drawable/chord>. The filled
equivalent is L</pdl_fill_chords>. Closely related routines are
L</pdl_arcs> and L</pdl_sectors>. See also L</pdl_fill_sectors>,
L</pdl_ellipses>, and L</pdl_fill_ellipses>, as well as
L<Prima::Drawable/spline>.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_chords> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @chords_props = qw(colors backColors clipRects linePatterns lineWidths rops rop2s);
our @chords_args = qw(x y x_diameter y_diameter start_angle end_angle);
sub Prima::Drawable::pdl_chords {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_chords is a widget method that expectes '. scalar(@chords_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @chords_args))
		unless (@_ > @chords_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $x_diameter = shift;
	my $y_diameter = shift;
	my $start_angle = shift;
	my $end_angle = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_chords expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@chords_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_chords_int($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_chords: $@";
	}
	
}





=head2 prima_clears

=for sig

 Signature: (int x1(); int y1(); int x2(); int y2();int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (long)

=for usage

 prima_clears($x1, $y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x1->prima_clears($y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_clears

  Prima Signature: (widget; x1(); y1(); x2(); y2(); properties)

=for ref

Clears the specified rectangle(s).

Applicable properties include backColors, rop2s.

=for example

 my ($width, $height) = $canvas->size;
 # Begin by drawing a filled rectangle:
 $canvas->color(cl::Blue);
 $canvas->bar(0, 0, $width, $height);

 # Now cut random rectangles out of it:
 my $N_chunks = 20;
 my $x1 = random($N_chunks) * $width;
 my $x2 = random($N_chunks) * $width;
 my $y1 = random($N_chunks) * $width;
 my $y2 = random($N_chunks) * $width;
 $canvas->pdl_clears($x1, $y1, $x2, $y2);

Like the other examples, this will give you something new whenever you
resize the window if you put the code in the onPaint method, as the
Synopsis suggests.

Compare to the Prima method L<Prima::Drawable/clear>. In practice I
suppose this might be considered the opposite of L</pdl_bars>, though
technically this is meant for erasing, not drawing.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_clears> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @clears_props = qw(colors backColors clipRects linePatterns lineWidths rops rop2s);
our @clears_args = qw(x1 y1 x2 y2);
sub Prima::Drawable::pdl_clears {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_clears is a widget method that expectes '. scalar(@clears_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @clears_args))
		unless (@_ > @clears_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $x2 = shift;
	my $y2 = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_clears expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@clears_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_clears_int($x1, $y1, $x2, $y2, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_clears: $@";
	}
	
}





=head2 prima_ellipses

=for sig

 Signature: (double x(); double y(); double x_diameter(); double y_diameter();int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (long)

=for usage

 prima_ellipses($x, $y, $x_diameter, $y_diameter, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_ellipses($y, $x_diameter, $y_diameter, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_ellipses

  Prima Signature: (widget; x(); y(); x_diameter();
                          y_diameter(); properties)

=for ref

Draws ellipses centered at C<x>, C<y> with diameters C<x_diameter> and
C<y_diameter>.

Applicable properties include colors, backColors, clipRects,
linePatterns, lineWidths, rops, rop2s.

To draw circles, just use the same x- and y-diameter.

=for example

 # Draw increasingly taller ellipses along the center line
 my $N_ellipses = 10;
 my ($width, $height) = $canvas->size;
 # horizontal positions evenly spaced
 my $x = (sequence($N_ellipses) + 0.5) * $width / $N_ellipses;
 # Vertically, right in the middle of the window
 my $y = $height/2;
 # Use the same x-diameter
 my $x_diameter = 15;
 # Increase the y-diameter
 my $y_diameter = $x->xlinvals(10, $height/1.3);

 # Use the pdl_ellipses method to draw!
 $canvas->pdl_ellipses($x, $y, $x_diameter, $y_diameter, lineWidths => 2);

For this example, if you resize the window, the distance between the ellipses
and the ellipse heights will adjust automatically.

Compare to the Prima method L<Prima::Drawable/ellipse>. The filled
equivalent is L</pdl_fill_ellipses>. See also L</pdl_arcs>, L</pdl_chords>,
and L</pdl_sectors> as well as L</pdl_fill_chords> and
L</pdl_fill_sectors>. You may also be interested in L<Prima::Drawable/spline>,
which does not yet have a PDL interface.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_ellipses> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @ellipses_props = qw(colors backColors clipRects linePatterns lineWidths rops rop2s);
our @ellipses_args = qw(x y x_diameter y_diameter);
sub Prima::Drawable::pdl_ellipses {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_ellipses is a widget method that expectes '. scalar(@ellipses_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @ellipses_args))
		unless (@_ > @ellipses_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $x_diameter = shift;
	my $y_diameter = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_ellipses expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@ellipses_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_ellipses_int($x, $y, $x_diameter, $y_diameter, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_ellipses: $@";
	}
	
}





=head2 prima_fill_chords

=for sig

 Signature: (double x(); double y(); double x_diameter(); double y_diameter();
			start_angle(); end_angle(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte fillPatterns(oct=8); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_fill_chords($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_fill_chords($y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_fill_chords

  Prima Signature: (widget; x(); y(); x_diameter(); y_diameter();
                          start_angle(); end_angle(); properties)

=for ref

Draws filled chords (see L</pdl_chords>).

Applicable properties include colors, backColors, clipRects,
fillPatterns, rops, rop2s.

Chords are partial elipses that run from C<start_angle> to C<end_angle>
along the ellipse centered at C<x>, C<y>, each with their specified diameters.
The ends are connected with a line and the interior is filled. Use this to
draw the open-mouth part of a smiley face.

=for example

 # working here:
 $canvas->pdl_fill_chords($x, $y, $xd, $yd, $ti, $tf);

Compare to the Prima method L<Prima::Drawable/fill_chord>. The unfilled
equivalent is L</pdl_chords>. Closely related to L</pdl_fill_ellipses>
and L</pdl_fill_sectors>. See also L</pdl_arcs>, L</pdl_ellipses>,
and L</pdl_sectors>.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_fill_chords> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @fill_chords_props = qw(colors backColors clipRects fillPatterns rops rop2s);
our @fill_chords_args = qw(x y x_diameter y_diameter start_angle end_angle);
sub Prima::Drawable::pdl_fill_chords {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_fill_chords is a widget method that expectes '. scalar(@fill_chords_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @fill_chords_args))
		unless (@_ > @fill_chords_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $x_diameter = shift;
	my $y_diameter = shift;
	my $start_angle = shift;
	my $end_angle = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_fill_chords expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@fill_chords_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_fill_chords_int($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_fill_chords: $@";
	}
	
}





=head2 prima_fill_ellipses

=for sig

 Signature: (double x(); double y(); double x_diameter(); double y_diameter();int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte fillPatterns(oct=8); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (long)

=for usage

 prima_fill_ellipses($x, $y, $x_diameter, $y_diameter, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_fill_ellipses($y, $x_diameter, $y_diameter, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_fill_ellipses

  Prima Signature: (widget; x(); y(); x_diameter();
                          y_diameter(); properties)

=for ref

Draws filled ellipses (see L</pdl_ellipses>).

Applicable properties include colors, backColors, clipRects,
fillPatterns, rops, rop2s. 

=for example

 # Draw increasingly taller ellipses along the center line
 my $N_ellipses = 10;
 my ($width, $height) = $canvas->size;
 # horizontal positions evenly spaced
 my $x = (sequence($N_ellipses) + 0.5) * $width / $N_ellipses;
 # Vertically, right in the middle of the window
 my $y = $height/2;
 # Use the same x-diameter
 my $x_diameter = 15;
 # Increase the y-diameter
 my $y_diameter = $x->xlinvals(10, $height/1.3);

 # Use the pdl_ellipses method to draw!
 $canvas->pdl_fill_ellipses($x, $y, $x_diameter, $y_diameter);

If you resize the window the distance between the ellipses
and the ellipse heights will adjust automatically.

Compare to the Prima method L<Prima::Drawable/fill_ellipse>. The unfilled
equivalent is L</pdl_ellipses>. Closely related to L</pdl_fill_chords> and
L</pdl_fill_ellipses>, and L</pdl_fill_sectors>.
See also L</pdl_arcs>, L</pdl_ellipses>, and L</pdl_sectors>. Also,
check out L<Prima::Drawable/fill_spline>, which does not yet have
PDL bindings.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_fill_ellipses> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @fill_ellipses_props = qw(colors backColors clipRects fillPatterns rops rop2s);
our @fill_ellipses_args = qw(x y x_diameter y_diameter);
sub Prima::Drawable::pdl_fill_ellipses {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_fill_ellipses is a widget method that expectes '. scalar(@fill_ellipses_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @fill_ellipses_args))
		unless (@_ > @fill_ellipses_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $x_diameter = shift;
	my $y_diameter = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_fill_ellipses expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@fill_ellipses_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_fill_ellipses_int($x, $y, $x_diameter, $y_diameter, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_fill_ellipses: $@";
	}
	
}





=head2 prima_fillpolys

=for sig

 Signature: (x(n); y(n); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte fillPatterns(oct=8); byte fillModes(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_fillpolys($x, $y, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $fillModes, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_fillpolys($y, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $fillModes, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_fillpolys

  Prima Signature: (widget; x(n); y(n); properties)

=for ref

Draws and fills a polygon with (mostly) arbitrary edge vertices.

Applicable properties include colors, backColors, clipRects,
fillPatterns, fillModes, rops, rop2s.

NOTE: there is B<no> underscore between C<fill> and C<poly>, which is
different from the other C<fill> methods!

This is useful for drawing arbitrary filled shapes and for visualizing
integrals. Splines would be the better choice if you want to draw curves, but
a PDL interface to splines is not (yet) implemented.

Unlike most of the other methods, this one actually makes a half-hearted
effort to process bad values. In addition to the IEEE bad values of C<nan>
and C<inf>, PDL has support for bad values. Unlike in C<pdl_polys>,
C<pdl_fillpolys> will simply skip any point that is marked as bad, but drawing
the rest of the polygon. In other words, it reduces the degree of your polygon
by one. If you sent it four points and one of them was bad, you would get a
triangle instead of a quadralaters.

Infinities are also handled, though not perfectly. There are a few
situations where C<pdl_polys> will correctly draw what you mean but
C<pdl_fillpolys> will not.

Because this skips bad data altogether, if you have too much bad data
(i.e. fewer than three good points), the routine will simply not draw
anything. I'm debating if this should croak, or at least give a warning.
(Of course, a warning to STDOUT is rather silly for a GUI toolkit.)

For example:

=for example

 # Create a poorly sampled sine-wave
 my ($width, $height) = $canvas->size;
 my $x = sequence(23)/4;
 my $y = $x->sin;

 # Draw it in such a way that it fits the canvas nicely
 $canvas->pdl_fillpolys($x * $width / $x->max,
     ($y + 1) * $height / 2, fillModes => fm::Winding,
 );

Resizing the window will result in a similar rendering that fits the aspect
ratio of your (resized) window.

Compare to the Prima method L<Prima::Drawable/fillpoly>. See also
L</pdl_bars> and L</pdl_polylines>.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_fillpolys> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @fillpolys_props = qw(colors backColors clipRects fillPatterns fillModes rops rop2s);
our @fillpolys_args = qw(x y);
sub Prima::Drawable::pdl_fillpolys {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_fillpolys is a widget method that expectes '. scalar(@fillpolys_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @fillpolys_args))
		unless (@_ > @fillpolys_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_fillpolys expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@fillpolys_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_fillpolys_int($x, $y, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_fillpolys: $@";
	}
	
}





=head2 prima_fill_sectors

=for sig

 Signature: (double x(); double y(); double x_diameter(); double y_diameter();
			double start_angle(); double end_angle(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte fillPatterns(oct=8); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_fill_sectors($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_fill_sectors($y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_fill_sectors

  Prima Signature: (widget; x(); y(); x_diameter(); y_diameter();
                          start_angle(); end_angle(); properties)

=for ref

Draws filled sectors, i.e. a pie-slices or Pac-Mans.

Applicable properties include colors, backColors, clipRects,
fillPatterns, rops, rop2s.

More specifically, this draws an arc from C<start_angle> to C<end_angle>
along the ellipse centered at C<x>, C<y>, with specified x- and y-diameters.
Like L</pdl_fill_chords>, this command connects the end points of the arc, but
unlike L</pdl_fill_chords>, it does so by drawing two lines, both of which
also connect to the ellipse's center. This results in shapes that look
like pie pieces or pie remnants, depending of whether you're a glass-half-full
or glass-half-empty sort of person.

=for example

 # Draw a bunch of random arcs on $canvas:
 my $N_chords = 20;
 my ($x_max, $y_max) = $canvas->size;
 my $xs = zeroes($N_chords)->random * $x_max;
 my $ys = $xs->random * $y_max;
 my $dxs = $xs->random * $x_max / 4;
 my $dys = $xs->random * $y_max / 4;
 my $th_starts = $xs->random * 360;
 my $th_stops = $xs->random * 360;

 # Now that we've generated the data, call the command:
 $canvas->pdl_fill_sectors($xs, $ys, $dxs
                , $dys, $th_starts, $th_stops);

Compare to the Prima method L<Prima::Drawable/fill_sector>. The unfilled
equivalent is L</pdl_sectors>. This is closely related to C</pdl_fill_chords>
and C</pdl_fill_ellipses>. See also L</pdl_arcs>, L</pdl_chords>, and
L</pdl_ellipses>.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_fill_sectors> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @fill_sectors_props = qw(colors backColors clipRects fillPatterns rops rop2s);
our @fill_sectors_args = qw(x y x_diameter y_diameter start_angle end_angle);
sub Prima::Drawable::pdl_fill_sectors {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_fill_sectors is a widget method that expectes '. scalar(@fill_sectors_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @fill_sectors_args))
		unless (@_ > @fill_sectors_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $x_diameter = shift;
	my $y_diameter = shift;
	my $start_angle = shift;
	my $end_angle = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_fill_sectors expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@fill_sectors_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_fill_sectors_int($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_fill_sectors: $@";
	}
	
}





=head2 prima_flood_fills

=for sig

 Signature: (int x(); int y(); int fill_color(); int singleborder(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte fillPatterns(oct=8); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (long)

=for usage

 prima_flood_fills($x, $y, $fill_color, $singleborder, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_flood_fills($y, $fill_color, $singleborder, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_flood_fills

  Prima Signature: (widget; x(); y(); fill_color();
                   singleborder(); properties)

=for ref

Fill a contiguous region.

NOTE THIS MAY NOT WORK ON MACS! There seems to be a bug in either Prima or
in Mac's X-windows library that prevents this function from doing its job as
described. That means that flood filling is not cross-platform, at least not
at the moment. This notice will be removed from the latest version of this
documentation as soon as the item is addressed, and it may be that your
version of Prima has a work-around for this problem. At any rate, it only
effects Mac users.

Applicable properties include colors, backColors, clipRects,
fillPatterns, rops, rop2s.

Note that C<fill_color> is probably B<not> what you think it is. The
color of the final fill is determined by your C<colors> property. What,
then, does C<fill_color> specify? It indicates how Prima is supposed to
perform the fill. If C<singleborder> is zero, then C<fill_color> is the
color of the B<boundary> to which Prima is to fill. In other words, if you had
a bunch of intersecting lines that were all red and you wanted the interior
of those intersecting lines to be blue, you would say something like

 $widget->pdl_flood_fills($x, $y, cl::Red, 0, colors => cl::Blue);

On the other hand, if C<singleborder> is 1, then the value of C<fill_color>
tells Prima to replace every contiguous pixel B<of color> C<fill_color> with
the new color specified by C<colors> (or the current color, if no C<colors>
piddle is given).

=for example

 # Generate a collection of intersecting
 # circles and triangles
 my ($width, $height) = $canvas->size;
 my $N_items = 20;
 my $x = random($N_items) * $width;
 my $y = random($N_items) * $width;
 $canvas->pdl_ellipses($x, $y, 20, 20, lineWidths => 3);
 $canvas->pdl_symbols($x, $y, 3, 0, 0, 10, 1, lineWidths => 3);

 # Fill the interior of those circle/triangle intersections
 $canvas->pdl_flood_fills($x, $y, cl::Black, 0);

If you put that snippet of code in the example from the synopsis, you should
see a number of narrow rectangles intersecting circles, with the interior of
both shapes filled. Resizing the window will lead to randomly changed
positions for those space-ship looking things.

Compare to the Prima method L<Prima::Drawable/flood_fill>. See also
L</pdl_clears> and the various fill-based drawing methods.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_flood_fills> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @flood_fills_props = qw(colors backColors clipRects fillPatterns rops rop2s);
our @flood_fills_args = qw(x y color singleborder);
sub Prima::Drawable::pdl_flood_fills {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_flood_fills is a widget method that expectes '. scalar(@flood_fills_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @flood_fills_args))
		unless (@_ > @flood_fills_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $color = shift;
	my $singleborder = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_flood_fills expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@flood_fills_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_flood_fills_int($x, $y, $color, $singleborder, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_flood_fills: $@";
	}
	
}





=head2 prima_lines

=for sig

 Signature: (x1(); y1(); x2(); y2(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); int lineJoins(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_lines($x1, $y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $lineJoins, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x1->prima_lines($y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $lineJoins, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_lines

  Prima Signature: (widget; x1(); y1(); x2(); y2(); properties)

=for ref

Draws a line from (x1, y1) to (x2, y2).

Applicable properties include colors, backColors, clipRects,
lineJoins, linePatterns, lineWidths, rops, rop2s.

In contrast to polylines, which are supposed to be connected, these
lines are meant to be independent. Also note that this method does make an
effort to handle bad values, both the IEEE sort (nan, inf) and the official
PDL bad values. See L</pdl_polylines> for a discussion of what might constitute
proper bad value handling.

=for example

 working here

Compare to the Prima methods L<Prima::Drawable/lines> and
L<Prima::Drawable/lines>. See also L</pdl_polylines>.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_lines> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @lines_props = qw(colors backColors clipRects lineJoins linePatterns lineWidths rops rop2s);
our @lines_args = qw(x1 y1 x2 y2);
sub Prima::Drawable::pdl_lines {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_lines is a widget method that expectes '. scalar(@lines_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @lines_args))
		unless (@_ > @lines_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $x2 = shift;
	my $y2 = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_lines expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@lines_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_lines_int($x1, $y1, $x2, $y2, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_lines: $@";
	}
	
}





=head2 prima_polylines

=for sig

 Signature: (x(n); y(n); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); int lineJoins(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_polylines($x, $y, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $lineJoins, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_polylines($y, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $lineJoins, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_polylines

  Prima Signature: (widget; x(n); y(n); properties)

=for ref

Draws a multi-segment line with the given x- and y-coordinates.

Applicable properties include colors, backColors, clipRects,
lineJoins, linePatterns, lineWidths, rops, rop2s.

This method goes to great lengths to Do What You Mean, which is actually
harder than you might have expected. This is the backbone for the Lines
plot type of L<PDL::Graphics::Prima>, so it needs to be able to handle all
manner of strange input. Here is what happens when you specify strange
values:

=over

=item IEEE nan or PDL Bad Value

If either of these values are specified in the middle of a line drawing, the
polyline will completely skip this point and begin drawing a new polyline at
the next point.

=item both x and y are inf and/or -inf

There is no sensible way of interpreting what it means for both x and y to
be infinite, so any such point is skipped, just like nan and Bad.

=item either x or y is inf or -inf

If an x value is infinite (but the paired y value is not), a horizontal line
is drawn from the previous x/y pair out to the edge of a widget; another line
is drawn from the edge to the next x/y pair. The behavior for an infinite y
value is similar, except that the line is drawn vertically.

For example, the three points (0, 1), (1, 1), (2, inf), (3, 1), (4, 1) would
be rendered as a line from (0, 1) to (1, 1), then a vertical line straight
up from (1, 1) to the upper edge of the widget or clipping rectangle, then
a vertical line straight down to (3, 1) from the upper edge of the widget or
clipping rectangle, then a horizontal line from (3, 1) to (4, 1).

=item x and/or y is a large value

If x or y is a large value (say, both x and y are 5e27 when the rest of your
numbers are of the order of 100), it will not be possible to actually show a
renderin of a line to that point. However, it is possible to correctly render
the slope of that point out to the edge of the clipping rectangle. Thus the
slope of the line from within-clip points to large values is faithfully
rendered.

=back

Here's an example of how to plot data using C<pdl_polylines> (though you'd
do better to use L<PDL::Graphics::Prima> to create plots):

=for example

 # Draw a sine curve on the widget:
 my $x = sequence(200);
 my $y = ( sin($x / 20) + 1 ) * 50;
 $canvas->pdl_polylines($x, $y);

Compare to the Prima method L<Prima::Drawable/polyline>. See also L</pdl_lines>
and L</pdl_fillpolys>.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_polylines> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @polylines_props = qw(colors backColors clipRects lineJoins linePatterns lineWidths rops rop2s);
our @polylines_args = qw(x y);
sub Prima::Drawable::pdl_polylines {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_polylines is a widget method that expectes '. scalar(@polylines_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @polylines_args))
		unless (@_ > @polylines_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_polylines expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@polylines_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_polylines_int($x, $y, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_polylines: $@";
	}
	
}





=head2 prima_rectangles

=for sig

 Signature: (int x1(); int y1(); int x2(); int y2(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (long)

=for usage

 prima_rectangles($x1, $y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x1->prima_rectangles($y1, $x2, $y2, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_rectangles

  Prima Signature: (widget; x1(); y1(); x2(); y2(); properties)

=for ref

Draws a rectangle from corner (x1, y1) to corner (x2, y2).

Applicable properties include colors, backColors, clipRects,
linePatterns, lineWidths, rops, rop2s.

=for example

 # Draw 20 random rectangles on $canvas:
 my $N_bars = 20;
 my ($x_max, $y_max) = $canvas->size;
 my $x1s = zeroes($N_bars)->random * $x_max;
 my $y1s = $x1s->random * $y_max;
 my $x2s = $x1s + $x1s->random * ($x_max - $x1s);
 my $y2s = $y1s + $x1s->random * ($y_max - $y1s);
 my $colors = $x1s->random * 2**24;

 # Now that we've generated the data, call the command:
 $canvas->pdl_rectangles($x1s, $y1s, $x2s, $y2s
         , colors => $colors);

If you put that snippet of code in the C<onPaint> method, as
suggested in the synopsis, a completely new set of rectangles
will get redrawn whenever you resize your window.

Compare to the Prima method L<Prima::Drawable/rectangle>. See also
L</pdl_bars>, which is the filled equivalent, and L</pdl_lines>, which
draws a line from (x1, y1) to (x2, y2) instead. Also, there is a Prima
method that does not (yet) have a pdl-based equivalent known as
L<Prima::Drawable/rects3d>, which draws beveled edges around a rectangle.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_rectangles> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @rectangles_props = qw(colors backColors clipRects linePatterns lineWidths rops rop2s);
our @rectangles_args = qw(x1 y1 x2 y2);
sub Prima::Drawable::pdl_rectangles {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_rectangles is a widget method that expectes '. scalar(@rectangles_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @rectangles_args))
		unless (@_ > @rectangles_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $x2 = shift;
	my $y2 = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_rectangles expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@rectangles_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_rectangles_int($x1, $y1, $x2, $y2, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_rectangles: $@";
	}
	
}





=head2 prima_sectors

=for sig

 Signature: (double x(); double y(); double x_diameter(); double y_diameter();
			double start_angle(); double end_angle(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_sectors($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_sectors($y, $x_diameter, $y_diameter, $start_angle, $end_angle, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_sectors

  Prima Signature: (widget; x(); y(); x_diameter(); y_diameter(); start_angle(); end_angle(); properties)

=for ref

Draws the outlines of sectors, i.e. a pie-slices or Pac-Mans.

Applicable properties include colors, backColors, clipRects,
linePatterns, lineWidths, rops, rop2s.

More specifically, this draws an arc from C<start_angle> to C<end_angle>
along the ellipse centered at C<x>, C<y>, with specified x- and y-diameters.
Like L</pdl_fill_chords>, this command connects the end points of the arc, but
unlike L</pdl_fill_chords>, it does so by drawing two lines, both of which
also connect to the ellipse's center. This results in shapes that look
like pie pieces or pie remnants, depending of whether you're a glass-half-full
or glass-half-empty sort of person.

=for example

 # For this example, you will need:
 use PDL::Char;

 # Draw a bunch of random sectors on $canvas:
 my $N_chords = 20;
 my ($x_max, $y_max) = $canvas->size;
 my $xs = zeroes($N_chords)->random * $x_max;
 my $ys = $xs->random * $y_max;
 my $dxs = $xs->random * $x_max / 4;
 my $dys = $xs->random * $y_max / 4;
 my $th_starts = $xs->random * 360;
 my $th_stops = $xs->random * 360;

 # make a small list of patterns:
 my $patterns_list = PDL::Char->new(
          [lp::Solid, lp::Dash, lp::DashDot]);

 # Randomly select 20 of those patterns:
 my $rand_selections = ($xs->random * 3)->byte;
 use PDL::NiceSlice;
 my $patterns = $patterns_list($rand_selections)->transpose;

 # Now that we've generated the data, call the command:
 $canvas->pdl_sectors($xs, $ys, $dxs
                , $dys, $th_starts, $th_stops
                , linePatterns => $patterns);

Compare to the Prima method L<Prima::Drawable/sector>. The filled equivalent
is L</pdl_fill_sectors>. There is a whole slew of arc-based drawing methods
including L</pdl_arcs>, L</pdl_chords>, and L</pdl_ellipses> along with their
filled equivalents. You may also be interested in L<Prima::Drawable/spline>,
which does not yet have a PDL interface.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_sectors> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @sectors_props = qw(colors backColors clipRects linePatterns lineWidths rops rop2s);
our @sectors_args = qw(x y x_diameter y_diameter start_angle end_angle);
sub Prima::Drawable::pdl_sectors {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_sectors is a widget method that expectes '. scalar(@sectors_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @sectors_args))
		unless (@_ > @sectors_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $x_diameter = shift;
	my $y_diameter = shift;
	my $start_angle = shift;
	my $end_angle = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_sectors expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@sectors_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_sectors_int($x, $y, $x_diameter, $y_diameter, $start_angle, $end_angle, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_sectors: $@";
	}
	
}




#line 3119 "prima.pd"

=head2 PDL-ONLY METHODS

These are drawing methods that have no analogous Prima::Drawable function.

=cut
#line 2038 "Prima.pm"


=head2 prima_symbols

=for sig

 Signature: (x(); y(); byte N_points(); orientation(); byte filled(); int size(); byte skip(); int colors(); int backColors(); int clipLeft(); int clipBottom(); int clipRight(); int clipTop(); byte fillPatterns(oct=8); byte fillModes(); byte linePatterns(patlen); int lineWidths(); int rops(); int rop2s(); SV * arg_ref_sv)
 Types: (double)

=for usage

 prima_symbols($x, $y, $N_points, $orientation, $filled, $size, $skip, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $fillModes, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # all arguments given
 $x->prima_symbols($y, $N_points, $orientation, $filled, $size, $skip, $colors, $backColors, $clipLeft, $clipBottom, $clipRight, $clipTop, $fillPatterns, $fillModes, $linePatterns, $lineWidths, $rops, $rop2s, $arg_ref_sv); # method call

=head2 pdl_symbols

  Signature: (widget; x(); y(); N_points(); orientation(); filled(); size(); skip(); properties)

=for ref

Draws a wide variety of symbols centered at (x, y).

Applicable properties include colors, backColors, clipRects, fillPatterns,
fillModes, linePatterns, lineWidths, rops, rop2s.

Through various combinations of C<N_points>, C<filled>, and C<skip>, you can
generate many different regular symbols, including dashes, stars, asterisks,
triangles, and diamonds. You can also specify each symbol's C<size> and
C<orientation>. The size is the radius of a circle that would circumscribe
the shape. The orientation is... well... just keep reading.

The shape drawn depends on C<N_points>. If C<N_points> is:

=over

=item zero or one

This will draw a circle with a radius of the
given size. The circle will be filled or not based on the value passed for
C<filled>, but the C<orientation> and C<skip> parameters are ignored. This
is almost redundant compared with the ellipse functions, except that this
arrangement makes it very easy to thead over filled/not-filled, and you
cannot specify an eccentricity for your points using C<pdl_symbols>.

=item two

This will draw a line centered at (x, y) and with a length of 2*C<size>.
The C<orientation> is measured in degrees, starting from horizontal, with
increasing angles rotating the line counter-clockwise. The value for C<skip>
is ignored.

This is particulary useful for visualizing slope-fields (although calculating
the angles for the slope field is surprisingly tricky).

=item three or more

This will draw a shape related to a regular polygon with the specified
number of sides. Precisely what kind of polygon it draws is based on the
value of C<skip>. For example, a five-sided polygon with a C<skip> of one
would give you a pentagon:

=for podview <img src="PDL/Drawing/Prima/pod/skip1.png" cut=1 title="skip = 1">

=for html <p>
<figure>
<img src="https://raw.githubusercontent.com/dk/PDL-Drawing-Prima/master/pod/skip1.png">
<figcaption>skip = 1</figcaption>
</figure>
<!--

                           second point
                               _
               third   __..--'' \
               point  |          \
                      |           \
                      |            \  first
                      |            /  point
                      |           /
                      |__        /
              fourth     ``--.._/
              point
                           fifth point

                           skip = 1

=for html -->

=for podview </cut>

In contrast, a five-sided polygon with a skip of 2 will give you a star:

=for podview <img src="PDL/Drawing/Prima/pod/skip2.png" cut=1 title="skip = 2">

=for html <p>
<figure>
<img src="https://raw.githubusercontent.com/dk/PDL-Drawing-Prima/master/pod/skip2.png">
<figcaption>skip = 2</figcaption>
</figure>
<!--

                           fourth point

              second          /|                
              point   \`~.._/  |            
                       `\ / `--|.__          
                         X     | __>  first point       
                       ,/ \_,--|'                
              fifth   /_~'' \  |                 
              point           \|

                           third point

                           skip = 2

=for html -->

=for podview </cut>

A skip of three would give visually identical results but the actual order
in which the vertices are drawn is different:

=for podview <img src="PDL/Drawing/Prima/pod/skip3.png" cut=1 title="skip = 3">

=for html <p>
<figure>
<img src="https://raw.githubusercontent.com/dk/PDL-Drawing-Prima/master/pod/skip3.png">
<figcaption>skip = 3</figcaption>
</figure>
<!--

                           third point

              fifth           /|                
              point   \`~.._/  |            
                       `\ / `--|.__          
                         X     | __>  first point       
                       ,/ \_,--|'                
              second  /_~'' \  |                 
              point           \|

                           fourth point

                           skip = 3

=for html -->

=for podview </cut>

A skip of zero is a special case, and means I<draw lines to each point from
the center.> In other words, create an asterisk:

=for podview <img src="PDL/Drawing/Prima/pod/skip0.png" cut=1 title="skip = 0">

=for html <p>
<figure>
<img src="https://raw.githubusercontent.com/dk/PDL-Drawing-Prima/master/pod/skip0.png">
<figcaption>skip = 0</figcaption>
</figure>
<!--

                           second point

               third            /
               point   `.      / 
                         `.   /   
                           `./_______  first
                           .'\         point
                         .'   \
                       .'      \
              fourth            \
              point
                           fifth point

                           skip = 0

=for html -->

=for podview </cut>

In summary, a C<skip> of zero gives you an N-asterisk. A C<skip> of one gives
you a regular polygon. A C<skip> of two gives you a star. And so forth.
Higher values of C<skip> are allowed; they simply add to the winding behavior.

Specifying the orientation changes the position of the first point and,
therefore, all subsequent points. A positive orientation rotates the first
point counter-clockwise by the specified number of degrees. Obviously, due
to the symmetry of the shapes, rotations of 360 / N_points look identical to
not performing any rotation.

For all nonzero values of C<skip>, specifying a fill will end up with
a filled shape instead of a line drawing.

=back

By default, filled stars and other symbols with odd numbers of points have a
hole in their middle. However, Prima provides a means for indicating that you
want such shapes filled; that is the C<fillMode> property. As with almost all
graphical properties, you can specify the C<fillMode> property for each
symbol by specifying the C<fillMode> piddle to one of C<fm::> constants.

This example creates a table of shapes. It uses an argument from the command
line to determine the line width.

=for example

 use PDL::NiceSlice;

 # Generate a table of shapes:
 my @dims = (40, 1, 30);
 my $N_points = xvals(@dims)->clump(2) + 1;
 my $orientation = 0;
 my $filled = yvals(@dims)->clump(2) + 1;
 my $size = 10;
 my $skip = zvals(@dims)->clump(2);
 my $x = $N_points->xvals * 25 + 25;
 my $y = $N_points->yvals * 25 + 25;
 my $lineWidths = $ARGV[0] || 1;

 # Draw them:
 $canvas->pdl_symbols($x, $y, $N_points, 0, $filled, 10, $skip

=for bad

Bad values are handled by C<pdl_symbols>. If any of the values you pass in
are bad, the symbol is not drawn at that x/y coordinate.

=pod

Broadcasts over its inputs.
Can't use POSIX threads.

=for bad

C<prima_symbols> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




our @symbols_props = qw(colors backColors clipRects fillPatterns fillModes linePatterns lineWidths rops rop2s);
our @symbols_args = qw(x y N_points orientation filled size skip);
sub Prima::Drawable::pdl_symbols {
	# Before anything else, make sure they supplied at least the
	# required number of arguments:
	croak('pdl_symbols is a widget method that expectes '. scalar(@symbols_args)
		. ' arguments (besides the widget): ' . join(', ', 'widget', @symbols_args))
		unless (@_ > @symbols_args);

	# unpack the widget and the required arguments for this function:
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $N_points = shift;
	my $orientation = shift;
	my $filled = shift;
	my $size = shift;
	my $skip = shift;

	# Check for an even number of remaining arguments (key-value pairs):
	croak('pdl_symbols expects optional parameters as key => value pairs')
		unless @_ % 2 == 0;

	my %args = @_;

	# Check for piddles as values for singular properties
	for (keys %args) {
		if ($_ !~ /s$/ && eval { $args{$_}->isa('PDL') }) {
			croak "A piddle passed as singular $_ property";
		}
	}

	# Get the a full list of arguments suitable for the internal pp code
	# in the correct order:
	my @args_with_defs
		= get_sorted_args_with_defaults($self, \@symbols_props, \%args);

	# Add the widget to the set of args
	$args{widget} = $self;

	# Call the PP'd internal code. Always put the args hash last.
	eval {
		PDL::_prima_symbols_int($x, $y, $N_points, $orientation, $filled, $size, $skip, @args_with_defs, \%args);
	};

	if ($@) {
		# die $@;
		$@ =~ s/at (.*?) line \d+\.\n$//;
		croak "Issues calling pdl_symbols: $@";
	}
	
}






#line 3474 "prima.pd"

=head1 ERROR MESSAGE

These functions may throw the following exception:

=head2 Your widget must be derived from Prima::Drawable

This means that you tried to draw on something that is not a Prima::Drawable
object, or a class derived from it. I don't know enough about the Prima
internals to know if that has any hope of working, but why do it in the first
place?

=head1 PDL::PP DETAILS

Those well versed in PDL::PP might ask how I manage to produce pdlified methods
that take variable numbers of arguments. That is a long story, and it is told in
the volumes of comments in pdlprima.pd. Give it a read if you want to know what
goes on behind the scenes.

=head1 TODO

These are all the things I wish to do:

=over

=item Full Drawabel API

I would like a PDL function for every drawable function in the API.
Prima Drawable functions that currently do not have an equivalent PDL
implementation include L<Prima::Drawable/draw_text>,
L<Prima::Drawable/fill_spline>, L<Prima::Drawable/put_image>,
L<Prima::Drawable/put_image_indirect>, L<Prima::Drawable/rect3d>,
L<Prima::Drawable/rect_focus>, L<Prima::Drawable/spline>,
L<Prima::Drawable/stretch_image>, and L<Prima::Drawable/text_out>

=item Bad Value Support

Bad values are handled decently in L</pdl_polylines> and L</pdl_fillpolys>, but not for
the other functions. Bad x/y values should be skipped for almost all the drawing
primitives, but what about bad colors for valid coordinates? I could not draw
the primitive, defer to the widget's default color, or use the value associated
with the singular key (i.e. C<color>). But I haven't decided which of these is
best.

=back

=head1 AUTHOR

David Mertens, E<lt>dcmertens.perl@gmail.comE<gt>.

=head1 SEE ALSO

Some useful PDL/Prima functions are defined in L<PDL::Drawing::Prima::Utils>,
especially for converting among simple color formats.

This is built as an extension for the Prima toolkit, http://www.prima.eu.org/, L<Prima>.

This is built using (and targeted at users of) the Perl Data Language, L<PDL>.

This is the bedrock for the plotting package L<PDL::Graphics::Prima>.

Another interface between PDL and Prima is <PDL::PrimaImage>. I am indebted to
Dmitry for that module because it gave me a working template for this module,
including a working Makefile.PL. Thanks Dmitry!

=cut
#line 2405 "Prima.pm"

# Exit with OK status

1;
