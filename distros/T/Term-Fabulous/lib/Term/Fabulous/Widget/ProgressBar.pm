package Term::Fabulous::Widget::ProgressBar;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Role::HasRange;
use Term::Fabulous::Widget::Display;

our $VERSION = '0.02';

class Term::Fabulous::Widget::ProgressBar
	:isa(Term::Fabulous::Widget::Display)
	:does(Term::Fabulous::Role::HasRange)
	:strict(params)
{
	use List::Util ();    # max and min are methods here
	use Term::Fabulous::Check qw(boolean cell_color describe number one_of optional positive_integer);
	use Term::Fabulous::Range;
	use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns string_columns);

	use constant FULL_BLOCK => "\x{2588}";

	# How often the stripes move and the indeterminate runner steps.
	use constant STRIPE_SECONDS => 0.15;
	use constant RUNNER_SECONDS => 1 / 15;

	# The left-aligned partial blocks, by eighths: one eighth (U+258F) to
	# seven eighths (U+2589).
	my @EIGHTH_BLOCK = map { chr( 0x2590 - $_ ) } 1 .. 7;

	# The glyphs of the ready-made styles: [ fill, track, stripe ].
	my %GLYPHS_OF_STYLE = (
		block => [ FULL_BLOCK, "\x{2591}", "\x{2593}" ],
		line  => [ "\x{2501}", "\x{2500}", "\x{2505}" ],
		ascii => [ '#',        '-',        '=' ],
	);

	my @VALUE_POSITIONS = qw(left right inside);

	field $indeterminate     :param = 0;
	field $show_value        :param = 1;
	field $value_position    :param = 'right';
	field $preferred_columns :param = 20;
	field $style             :param = 'block';
	field $fill_glyph        :param = undef;
	field $track_glyph       :param = undef;
	field $stripe_glyph      :param = undef;
	field $fractional        :param = 1;
	field $striped           :param = 0;
	field $animated          :param = 0;
	field $separated         :param = 0;

	field $range;    # a Term::Fabulous::Range without steps: min, max and the value
	field @segments;    # { value, color }, or empty for a single value

	ADJUST :params ( :$min = 0, :$max = 100, :$value_format = undef, :$value = undef, :$segments = undef ) {
		die ref($self) . ": give 'value' or 'segments', not both"
			if defined $value && defined $segments;
		$range = Term::Fabulous::Range->new(
			owner          => ref $self,
			min            => $min,
			max            => $max,
			value_format   => $value_format,
			format_percent => 1,
			default_format => sub ( $number, $range ) { sprintf '%.0f%%', 100 * $range->fraction_of($number) },
		);
		$indeterminate     = boolean( $self, indeterminate => $indeterminate );
		$show_value        = boolean( $self, show_value    => $show_value );
		$value_position    = one_of( $self, value_position => $value_position, @VALUE_POSITIONS );
		$preferred_columns = positive_integer( $self, preferred_columns => $preferred_columns );
		$style             = one_of( $self, style => $style, keys %GLYPHS_OF_STYLE );
		$fill_glyph        = $self->_checked_glyph( fill_glyph   => $fill_glyph );
		$track_glyph       = $self->_checked_glyph( track_glyph  => $track_glyph );
		$stripe_glyph      = $self->_checked_glyph( stripe_glyph => $stripe_glyph );
		$fractional        = boolean( $self, fractional => $fractional );
		$striped           = boolean( $self, striped    => $striped );
		$animated          = boolean( $self, animated   => $animated );
		$separated         = boolean( $self, separated  => $separated );
		$self->value($value) if defined $value;
		$self->segments($segments) if defined $segments;
	}

	method _checked_glyph ( $name, $value ) {
		return optional( \&Term::Fabulous::Check::glyph, $self, $name => $value );
	}

	# A segment is { value => ..., color => ... }; the color defaults to
	# the bar's.
	method _checked_segment ($segment) {
		die ref($self) . ": a segment must be a hash reference with 'value' and an optional 'color', got " . describe($segment) unless ref $segment eq 'HASH';
		my @unknown = grep { $_ ne 'value' && $_ ne 'color' } sort keys %$segment;
		die ref($self) . ": a segment takes only 'value' and 'color', got @unknown" if @unknown;
		my $amount = number( $self, 'segment value' => $segment->{value} );
		die ref($self) . ": a segment value must not be negative, got $amount" if $amount < 0;
		return { value => $amount, color => optional( \&cell_color, $self, 'segment color' => $segment->{color} ) };
	}

	# ---------------------------------------------------------------------
	# Value
	# ---------------------------------------------------------------------

	# The value of a bar with segments is their sum, from min on.
	method value (@new) {
		return @segments ? List::Util::min( $range->max, $range->min + List::Util::sum0( map { $_->{value} } @segments ) ) : $range->value unless @new;
		$range->set_value( $new[0] );
		@segments = ();
		$self->mark_changed;
		return $range->value;
	}

	method fraction () {
		return $range->fraction_of( $self->value );
	}

	method percent () {
		return 100 * $self->fraction;
	}

	method segments (@new) {
		return [ map { +{%$_} } @segments ] unless @new;
		my ($list) = @new;
		if ( !defined $list ) {
			@segments = ();
			$self->mark_changed;
			return [];
		}
		die ref($self) . ": segments must be an array reference, got " . describe($list) unless ref $list eq 'ARRAY';
		my @checked = map { $self->_checked_segment($_) } @$list;
		@segments = @checked;
		$range->set_value( $range->min );
		$self->mark_changed;
		return [ map { +{%$_} } @segments ];
	}

	method add_segment ($segment) {
		push @segments, $self->_checked_segment($segment);
		$range->set_value( $range->min );
		$self->mark_changed;
		return $self;
	}

	method set_range (%range) {
		$range->set_range(%range);
		$self->mark_changed;
		return $self;
	}

	method range_properties :common () {
		return qw(min max);
	}

	method min (@new) {
		$self->set_range( min => $new[0] ) if @new;
		return $range->min;
	}

	method max (@new) {
		$self->set_range( max => $new[0] ) if @new;
		return $range->max;
	}

	method format_value ($number) {
		return $range->format_value($number);
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method _set ( $field_ref, $value ) {
		$$field_ref = $value;
		$self->mark_changed;
		return $$field_ref;
	}

	method _set_value_format ($format) {
		$range->set_value_format($format);
		$self->mark_changed;
		return $range->value_format;
	}

	method indeterminate     (@new) { return @new ? $self->_set( \$indeterminate, boolean( $self, indeterminate => $new[0] ) )                    : $indeterminate }
	method show_value        (@new) { return @new ? $self->_set( \$show_value, boolean( $self, show_value => $new[0] ) )                          : $show_value }
	method value_position    (@new) { return @new ? $self->_set( \$value_position, one_of( $self, value_position => $new[0], @VALUE_POSITIONS ) ) : $value_position }
	method value_format      (@new) { return @new ? $self->_set_value_format( $new[0] )                                                           : $range->value_format }
	method preferred_columns (@new) { return @new ? $self->_set( \$preferred_columns, positive_integer( $self, preferred_columns => $new[0] ) )   : $preferred_columns }
	method style             (@new) { return @new ? $self->_set( \$style, one_of( $self, style => $new[0], keys %GLYPHS_OF_STYLE ) )              : $style }
	method fill_glyph        (@new) { return @new ? $self->_set( \$fill_glyph, $self->_checked_glyph( fill_glyph => $new[0] ) )                   : $fill_glyph }
	method track_glyph       (@new) { return @new ? $self->_set( \$track_glyph, $self->_checked_glyph( track_glyph => $new[0] ) )                 : $track_glyph }
	method stripe_glyph      (@new) { return @new ? $self->_set( \$stripe_glyph, $self->_checked_glyph( stripe_glyph => $new[0] ) )               : $stripe_glyph }
	method fractional        (@new) { return @new ? $self->_set( \$fractional, boolean( $self, fractional => $new[0] ) )                          : $fractional }
	method striped           (@new) { return @new ? $self->_set( \$striped, boolean( $self, striped => $new[0] ) )                                : $striped }
	method animated          (@new) { return @new ? $self->_set( \$animated, boolean( $self, animated => $new[0] ) )                              : $animated }
	method separated         (@new) { return @new ? $self->_set( \$separated, boolean( $self, separated => $new[0] ) )                            : $separated }
	method color             (@new) { return @new ? $self->set_look( color => $new[0] )                                                           : $self->look_value('color') }
	method track_color       (@new) { return @new ? $self->set_look( track_color => $new[0] )                                                     : $self->look_value('track_color') }
	method text_color        (@new) { return @new ? $self->set_look( text_color => $new[0] )                                                      : $self->look_value('text_color') }
	method inside_text_color (@new) { return @new ? $self->set_look( inside_text_color => $new[0] )                                               : $self->look_value('inside_text_color') }

	method theme_family :common () {
		return 'progress';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			color             => [ 'color',       'normal', 'cell_color' ],
			track_color       => [ 'track',       'normal', 'cell_color' ],
			text_color        => [ 'text',        'normal', 'cell_color' ],
			inside_text_color => [ 'inside_text', 'normal', 'cell_color' ],
		);
	}

	# The glyphs in use: the style's, unless given one by one.
	method glyphs () {
		my ( $fill, $track, $stripe ) = $GLYPHS_OF_STYLE{$style}->@*;
		return ( $fill_glyph // $fill, $track_glyph // $track, $stripe_glyph // $stripe );
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			( map { $_ => 'scalar' } qw(min max value value_position value_format preferred_columns style fill_glyph track_glyph stripe_glyph) ),
			( map { $_ => 'boolean' } qw(indeterminate show_value fractional striped animated separated) ),
			segment => \&_parse_segment,
		);
	}

	# segment value=30 color="#98c379"
	method _parse_segment ($kid) {
		my $props = $self->kdl_properties( $kid, qw(value color) );
		die ref($self) . ": layout property 'segment' needs value=..." unless exists $props->{value};
		return $self->add_segment($props);
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method _shows_label () {
		return $show_value && !$indeterminate;
	}

	# The columns of the value label: wide enough for any value, so the
	# bar keeps its length while the value changes. A label inside the bar
	# takes no columns of its own.
	method _label_columns () {
		return 0 unless $self->_shows_label && $value_position ne 'inside';
		return List::Util::max map { string_columns( $self->format_value($_) ) } $range->min, $range->max, $self->value;
	}

	# Where the bar starts and how many columns it has.
	method _bar_span () {
		my $label = $self->_label_columns;
		my $bar   = List::Util::max( 1, $self->columns - ( $label ? $label + 1 : 0 ) );
		return ( $value_position eq 'left' && $label ? $label + 1 : 0, $bar );
	}

	method natural_size () {
		my $label = $self->_label_columns;
		return ( $preferred_columns + ( $label ? $label + 1 : 0 ), 1 );
	}

	# The frame of the running animation, if any, which the paint key
	# includes; asking for it keeps the frames coming.
	method _animation_frame () {
		return $self->animation_frame( RUNNER_SECONDS, $self->_runner_frames ) if $indeterminate;
		return $self->animation_frame( STRIPE_SECONDS, 4 ) if $striped && $animated;
		return -1;
	}

	# The indeterminate runner bounces across the bar: as many frames as
	# positions there and back.
	method _runner_width ($bar) {
		return List::Util::max( 1, int( $bar / 4 ) );
	}

	method _runner_frames () {
		my ( undef, $bar ) = $self->_bar_span;
		my $travel = $bar - $self->_runner_width($bar);
		return $travel > 0 ? 2 * $travel : 1;
	}

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $self->_animation_frame );
	}

	# The cells of the bar, left to right, as [ glyph, fg, bg, on_fill ],
	# for the current value: the filled part in the colors of its
	# segments, the rest in the track.
	method _bar_cells ($bar) {
		my ( $fill, $track, $stripe ) = $self->glyphs;
		my $frame  = $self->_animation_frame;
		my $inside = $self->_shows_label && $value_position eq 'inside';
		my @cells  = map { [ $inside ? ' ' : $track, $self->color_attr( $self->track_color ), $inside ? $self->color_attr( $self->track_color ) : undef, 0 ] } 1 .. $bar;

		my @parts = @segments ? @segments : ( { value => $range->value - $range->min, color => undef } );
		my ( $edge, $at ) = ( 0, 0 );
		foreach my $index ( 0 .. $#parts ) {
			my $part  = $parts[$index];
			my $fg    = $self->color_attr( $part->{color} // $self->color );
			my $bg    = $inside ? $fg : undef;
			my $start = $at;
			$edge += $part->{value} / ( $range->max - $range->min ) * $bar;
			$edge = $bar if $edge > $bar;
			my $full = int( $edge + 1e-9 );
			foreach my $x ( $start .. $full - 1 ) {
				my $glyph = $inside ? ' ' : $striped && ( int( ( $x + ( $animated ? $frame : 0 ) ) / 2 ) % 2 ) ? $stripe : $fill;
				$cells[$x] = [ $glyph, $fg, $bg, 1 ];
			}
			$at = $full;
			if ( $separated && $index < $#parts && $at < $bar ) {
				$at++;
				$edge = $at if $edge < $at;
			}
			next if $index < $#parts || $at >= $bar || !$fractional || $fill ne FULL_BLOCK;
			my $eighths = int( ( $edge - $full ) * 8 );
			$cells[$at] = [ $EIGHTH_BLOCK[ $eighths - 1 ], $fg, $inside ? $self->color_attr( $self->track_color ) : undef, 0 ] if $eighths > 0;
		}
		return @cells;
	}

	# The cells of an indeterminate bar: a runner bouncing across the track.
	method _runner_cells ( $bar, $frame ) {
		my ( $fill, $track ) = $self->glyphs;
		my $width  = $self->_runner_width($bar);
		my $travel = $bar - $width;
		my $at     = $travel > 0 ? ( $frame <= $travel ? $frame : 2 * $travel - $frame ) : 0;
		return map { $_ >= $at && $_ < $at + $width ? [ $fill, $self->color_attr( $self->color ), undef, 1 ] : [ $track, $self->color_attr( $self->track_color ), undef, 0 ] } 0 .. $bar - 1;
	}

	method paint () {
		my ( $start, $bar ) = $self->_bar_span;
		my $rows  = $self->rows;
		my @cells = $indeterminate ? $self->_runner_cells( $bar, $self->_animation_frame ) : $self->_bar_cells($bar);
		foreach my $y ( 0 .. $rows - 1 ) {
			$self->put_attrs( $start + $_, $y, @{ $cells[$_] }[ 0 .. 2 ] ) foreach 0 .. $#cells;
		}
		return unless $self->_shows_label;

		my $label = $self->format_value( $self->value );
		my $y     = int( ( $rows - 1 ) / 2 );
		if ( $value_position eq 'inside' ) {
			my $x = List::Util::max( 0, int( ( $bar - string_columns($label) ) / 2 ) );
			foreach my $cluster ( grapheme_clusters($label) ) {
				my $cell = $cells[$x] // last;
				$self->put_attrs( $start + $x, $y, $cluster, $self->color_attr( $cell->[3] ? $self->inside_text_color : $self->text_color ), $cell->[2] );
				$x += cluster_columns($cluster);
			}
			return;
		}
		$self->paint_text( $value_position eq 'left' ? 0 : $self->columns - string_columns($label), $y, $label, $self->color_attr( $self->text_color ), undef );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::ProgressBar - How much of a task is done

=head1 SYNOPSIS

	use Term::Fabulous::Widget::ProgressBar;

	my $progress = Term::Fabulous::Widget::ProgressBar->new(
		id    => 'download',
		max   => $bytes_total,
		value => 0,
	);
	$progress->value($bytes_so_far);    # from a timer, a process, ...

	# Unknown duration: a runner bounces across the bar until you know more.
	my $busy = Term::Fabulous::Widget::ProgressBar->new( indeterminate => 1 );
	$busy->indeterminate(0);
	$busy->value(100);

	# Several parts in one bar:
	my $disk = Term::Fabulous::Widget::ProgressBar->new(
		max      => 500,
		segments => [ { value => 210, color => '#98c379' }, { value => 90, color => '#e5c07b' }, { value => 40, color => '#e06c75' } ],
	);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-progress-bar.svg" alt="Progress bars: a block bar at 42 percent, one with the value inside, a thin line bar, a striped bar, a bar of three colored segments, an indeterminate bar with its runner, and a two-row ASCII bar"></p>

=end html

=head1 DESCRIPTION

The picture shows progress bars in their forms: a block bar with its
percentage, one with the percentage inside the bar, a thin line bar
with a label of its own, a striped bar, a bar of three colored
segments, an indeterminate bar with its runner, and a two-row bar in
the ASCII style. The program is F<examples/widgets/progress-bar.pl>.

A progress bar shows a value between C<min> and C<max> as a bar
filled from the left, and the value as text next to it:

=for highlighter language=text

	████████▌░░░░░░░░░░░ 42%

The bar is drawn in one of three styles: C<block> (the default) fills
cells with blocks and, with C<fractional>, draws the last cell as a
partial block so that the bar moves in eighths of a cell; C<line> is
a thin line like a slider's track; C<ascii> uses C<#> and C<->. Any
glyph can replace the style's. C<striped> alternates two glyphs along
the filled part and C<animated> moves the stripes, which shows that
work is going on. An C<indeterminate> bar, for a task whose extent is
not known, shows no value but a runner bouncing from end to end. The
bar C<segments> can stack several values in their own colors, for
example the parts of a disk, with a cell of track between them when
C<separated>.

The value label is the percentage by default, placed right of the
bar; it can go left of it or inside it, where it is written over the
bar, and C<value_format> formats it as a C<sprintf> string of the
percentage or with code that gets the value.

A progress bar takes no input. It is a L<Term::Fabulous::Widget::Display>,
so it is painted again only when something about it changed, and the
animations run on the application's clock without a timer of their
own (see L<Term::Fabulous::Widget::Display/ANIMATION>). Unless the
C<layout> sizes it, the bar is one row high and C<preferred_columns>
plus the label wide; a taller layout gives a thicker bar.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $progress = Term::Fabulous::Widget::ProgressBar->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters, ...)
and the ones below. All are optional; unknown parameters die.

=over

=item C<min>

A finite number. Default: 0. The value of an empty bar. Must be less
than C<max>, or the constructor dies.

=item C<max>

A finite number. Default: 100. The value of a full bar.

=item C<value>

A finite number in C<min>..C<max>. Default: C<min>. Dies if outside
the range. Give C<value> or C<segments>, not both.

=item C<segments>

An array reference of hash references C<< { value => $n, color => $c } >>,
the parts of a stacked bar from the left, each C<value> a non-negative
number in the units of C<min>..C<max> and C<color> optional (the bar's
C<color>). Default: none, a bar of one value. What goes past C<max> is
cut off.

=item C<indeterminate>

A boolean. Default: 0. True shows the runner instead of a value and
hides the label. Stored as 1 or 0; a reference dies.

=item C<show_value>

A boolean. Default: 1. Whether the value label is shown.

=item C<value_position>

C<right> (the default), C<left> or C<inside>: where the label is
placed. Inside, the bar is drawn with background colors and the label
is centered over it, dark on the filled part and in C<text_color> on
the rest. Anything else dies.

=item C<value_format>

How the value is shown: a C<sprintf> format string that gets the
percentage, such as C<'%.1f%%'>, or a code reference that gets the
value and the fraction (0 to 1) and returns the text. Default:
C<undef>, the percentage without decimals and a percent sign. Anything
other than a string, a code reference or C<undef> dies. The label is as
wide as the widest of the lowest, the highest and the current value, so
the bar keeps its length.

	value_format => sub ( $bytes, $fraction ) { sprintf '%d of %d MB', $bytes / 1e6, $total / 1e6 },

=item C<preferred_columns>

A positive integer. Default: 20. The length of the bar in columns when
the C<layout> gives the widget no width. The label and one space are
added to it.

=item C<style>

C<block> (the default), C<line> or C<ascii>: the glyphs of the fill,
the track and the stripes. C<block>: C<█>, C<░> and C<▓>; C<line>:
C<━>, C<─> and C<┅>; C<ascii>: C<#>, C<-> and C<=>. Anything else
dies.

=item C<fill_glyph>

=item C<track_glyph>

=item C<stripe_glyph>

A single character one column wide, or C<undef>. Default: C<undef>,
the glyph of C<style>. Each replaces one of the style's glyphs.

=item C<fractional>

A boolean. Default: 1. Whether the last filled cell is drawn as a
partial block when the fill glyph is the full block (C<block> style),
so that the bar moves in eighths of a cell. With other glyphs the bar
moves in whole cells.

=item C<striped>

A boolean. Default: 0. Whether the filled part alternates the fill
glyph and the stripe glyph, two cells each.

=item C<animated>

A boolean. Default: 0. Whether the stripes move, a few times per
second, while the bar is C<striped>.

=item C<separated>

A boolean. Default: 0. Whether a cell of track is left between two
segments.

=item C<color>

The color of the filled part, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. Default: the theme's
C<progress.color>, C<[97, 175, 239, 255]> in the dark theme, the blue
of the input widgets' accent.

=item C<track_color>

The color of the empty part. Default: the theme's C<progress.track>,
C<[58, 63, 75, 255]> in the dark theme, a dark
gray.

=item C<text_color>

The color of the value label. Default: the theme's C<progress.text>,
C<[220, 223, 228, 255]> in the dark theme.

=item C<inside_text_color>

The color of the label where it lies over the filled part, with
C<< value_position => 'inside' >>. Default: the theme's
C<progress.inside_text>, C<[16, 18, 22, 255]> in the dark theme, a
near black.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Display> (C<mark_changed>, the
Box and Canvas methods), plus:

=head2 value

	my $number = $progress->value;
	$progress->value(42);

Accessor. Returns the current value: the value set, or, for a bar with
segments, C<min> plus their sum (at most C<max>). Writing sets a single
value, drops any segments, marks the bar changed (so the next frame
paints it) and returns the value. Dies if the new value is not a finite
number in C<min>..C<max>.

=head2 fraction

	my $done = $progress->fraction;    # 0.42

The value as a fraction of the range, from 0 to 1. Read-only.

=head2 percent

	my $done = $progress->percent;     # 42

The value as a percentage of the range. Read-only.

=head2 segments

	my $parts = $progress->segments;
	$progress->segments( [ { value => 30, color => '#98c379' }, { value => 20 } ] );
	$progress->segments(undef);    # back to a single value

Accessor. The reader returns a new array reference of copies of the
segments (empty for a bar of one value). Writing replaces them, checked
as C<new> checks them, resets the single value to C<min> and marks the
bar changed. C<undef> removes them.

=head2 add_segment

	$progress->add_segment( { value => 10, color => '#e06c75' } );

Appends a segment. Returns the bar.

=head2 min

	$progress->min(0);

=head2 max

	$progress->max($total);

Accessors for the ends of the range. Writing moves the value into the
new range if needed, marks the bar changed and returns the new end.
Dies, leaving the range as it was, unless the new C<min> is a finite
number less than C<max> (or the new C<max> greater than C<min>). To
move a range past its other end, use L</set_range>.

=head2 set_range

	$progress->set_range( min => 1000, max => 2000 );

Changes C<min> and C<max> together, so a range can move anywhere in
one call. Moves the value into the new range if needed, marks the bar
changed and returns the bar. Dies, leaving the range as it was, when
C<min> is not less than C<max>, a part is not a finite number, or
another name is given.

=head2 format_value

	my $text = $progress->format_value(42);    # '42%'

A value formatted as the bar shows it (see C<value_format>).

=head2 indeterminate

	$progress->indeterminate(1);

Accessor for the C<indeterminate> parameter. Returns 1 or 0.

=head2 show_value

	$progress->show_value(0);

Accessor for the C<show_value> parameter. Returns 1 or 0.

=head2 value_position

	$progress->value_position('inside');

Accessor for the C<value_position> parameter: C<left>, C<right> or
C<inside>.

=head2 value_format

	$progress->value_format('%.1f%%');

Accessor for the C<value_format> parameter. Anything other than a
string, a code reference or C<undef> dies and leaves the old format.

=head2 preferred_columns

	$progress->preferred_columns(40);

Accessor for the C<preferred_columns> parameter; the new length takes
effect at the next frame.

=head2 style

	$progress->style('line');

Accessor for the C<style> parameter: C<block>, C<line> or C<ascii>.

=head2 fill_glyph

	$progress->fill_glyph("\x{2593}");
	$progress->fill_glyph(undef);    # back to the style's glyph

Accessor for the C<fill_glyph> parameter. A value that is not a single
one-column character or C<undef> dies and leaves the old glyph.

=head2 track_glyph

	$progress->track_glyph(' ');

Accessor for the C<track_glyph> parameter; works like L</fill_glyph>.

=head2 stripe_glyph

	$progress->stripe_glyph('+');

Accessor for the C<stripe_glyph> parameter; works like L</fill_glyph>.

=head2 fractional

	$progress->fractional(0);

Accessor for the C<fractional> parameter. Returns 1 or 0.

=head2 striped

	$progress->striped(1);

Accessor for the C<striped> parameter. Returns 1 or 0.

=head2 animated

	$progress->animated(1);

Accessor for the C<animated> parameter. Returns 1 or 0. The stripes
move only while the bar is also C<striped>.

=head2 separated

	$progress->separated(1);

Accessor for the C<separated> parameter. Returns 1 or 0.

=head2 color

	$progress->color('#98c379');

Accessor for the C<color> parameter. The reader returns
C<[r, g, b, a]>. An invalid color dies and leaves the old one.

=head2 track_color

	$progress->track_color( [ 40, 44, 52 ] );

Accessor for the C<track_color> parameter; works like L</color>.

=head2 text_color

	$progress->text_color('#ffffff');

Accessor for the C<text_color> parameter; works like L</color>.

=head2 inside_text_color

	$progress->inside_text_color('#000000');

Accessor for the C<inside_text_color> parameter; works like L</color>.

Every writer marks the bar changed, so the next frame paints the new
look.

=head2 glyphs

	my ( $fill, $track, $stripe ) = $progress->glyphs;

The three glyphs in use: those given one by one, else those of the
style. Read-only.

=head1 EVENTS

A progress bar fires no events of its own. It paints every cell of its
bar, so it receives C<Mouse> events for clicks on it.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<min>, C<max>, C<value>, C<value_position>, C<value_format> (a format
string only; code references cannot be written in KDL),
C<preferred_columns>, C<style>, C<fill_glyph>, C<track_glyph> and
C<stripe_glyph>; the booleans C<indeterminate>, C<show_value>,
C<fractional>, C<striped>, C<animated> and C<separated> (C<#true> /
C<#false>); the colors C<color>, C<track_color>, C<text_color> and
C<inside_text_color>; and C<segment value=N color="..."> nodes, one
per segment, which add to the segments given before:

=for highlighter language=kdl

	use Term::Fabulous::Widget::ProgressBar as ProgressBar

	ProgressBar "download" {
		max 2048
		value 860
		value_format "%.1f%%"
		sizing width=grow
	}

	ProgressBar "disk" {
		max 500
		segment value=210 color="#98c379"
		segment value=90 color="#e5c07b"
		separated #true
	}

C<min> and C<max> are applied together, through L</set_range>, and
before C<value> and the segments, so they may come in any order.

=head1 EXAMPLES

=head2 A download that reports bytes

=for highlighter language=perl

	my $progress = Term::Fabulous::Widget::ProgressBar->new(
		max          => $total,
		value_format => sub ( $bytes, $fraction ) { sprintf '%.1f of %.1f MB', $bytes / 1e6, $total / 1e6 },
		layout       => { sizing => { width => sizing_grow() } },
	);
	$process->on_read( sub { $progress->value( List::Util::min( $total, $progress->value + length $chunk ) ) } );

=head2 Busy until the first byte arrives

	my $progress = Term::Fabulous::Widget::ProgressBar->new( indeterminate => 1 );
	# When the size becomes known:
	$progress->max($size);
	$progress->indeterminate(0);

=head2 A color that follows the value

	sub show ($done) {
		$progress->value($done);
		$progress->color( $done < 50 ? '#e06c75' : $done < 90 ? '#e5c07b' : '#98c379' );
		return;
	}

=head1 SEE ALSO

L<Term::Fabulous::Widget::Display>, L<Term::Fabulous::Widget::Spinner>,
L<Term::Fabulous::Widget::Slider>,
L<Term::Fabulous::Manual::Feedback/PROGRESS BARS>.

=cut
