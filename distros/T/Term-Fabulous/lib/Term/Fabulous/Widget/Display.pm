package Term::Fabulous::Widget::Display;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Canvas;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Display
	:isa(Term::Fabulous::Widget::Canvas)
	:abstract
{
	use Clay::XS qw(sizing_fixed);
	use Time::HiRes ();
	use Term::Fabulous::Render::Attr qw(cell_color_attr);
	use Term::Fabulous::Theme;
	use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns);

	# Counts mark_changed calls, the changes of the widget's own state; with
	# the rest of the paint key, what the cells were last painted for.
	field $_change_count = 0;
	field $_painted_key;

	# The content size a subclass asks for when the layout gives none.
	method natural_size;

	# Draws the widget into the cleared buffer.
	method paint;

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method mark_changed :override () {
		$_change_count++;
		return $self->SUPER::mark_changed;
	}

	# Paints the cells again when anything paint reads changed since they
	# were last painted.
	method refresh :override () {
		return unless $self->columns > 0 && $self->rows > 0;
		my $key = join "\x{1F}", map { $_ // "\x{0}" } $self->paint_key;
		return if defined $_painted_key && $key eq $_painted_key;
		$_painted_key = $key;
		$self->clear;
		$self->paint;
		return;
	}

	# What paint reads: the size, the widget's own state (every setter
	# calls mark_changed) and the theme. A subclass that paints from the
	# state of other objects adds it.
	method paint_key () {
		return ( $self->columns, $self->rows, $_change_count, Term::Fabulous::Theme::generation() );
	}

	# The termbox2 attribute of a color, undef for none.
	method color_attr ($color) {
		return cell_color_attr( color => $color );
	}

	# Paints a character string from ($x, $y) with termbox2 attributes,
	# stopping before a cluster that would cross column $limit; returns the
	# column after the last painted cluster.
	method paint_text ( $x, $y, $text, $fg, $bg, $limit = $self->columns ) {
		foreach my $cluster ( grapheme_clusters($text) ) {
			my $columns = cluster_columns($cluster);
			last if $x + $columns > $limit;
			$self->put_attrs( $x, $y, $cluster, $fg, $bg );
			$x += $columns;
		}
		return $x;
	}

	method fill_attrs ( $x, $y, $width, $glyph, $fg, $bg ) {
		$self->put_attrs( $_, $y, $glyph, $fg, $bg ) foreach $x .. $x + $width - 1;
		return;
	}

	# ---------------------------------------------------------------------
	# Animation: frames from the application's clock, which a test or the
	# screenshot harness can move; the system clock outside a UI.
	# ---------------------------------------------------------------------

	method now () {
		my $ui = $self->ui;
		return $ui->now if defined $ui && $ui->can('now');
		return Time::HiRes::time();
	}

	# Asks the UI for a frame at a time on the clock; a static page draws
	# once and ignores it.
	method request_frame_at ($time) {
		my $ui = $self->ui;
		$ui->request_frame_at($time) if defined $ui && $ui->can('request_frame_at');
		return $self;
	}

	# The frame of an animation that shows $count frames, $interval seconds
	# each, at the current time, and asks for a frame when the next one is
	# due. Called from paint_key, it keeps the animation going.
	method animation_frame ( $interval, $count ) {
		my $tick = int( $self->now / $interval );
		$self->request_frame_at( ( $tick + 1 ) * $interval );
		return $tick % $count;
	}

	# ---------------------------------------------------------------------
	# Natural size: fills the sizing axes the layout leaves open. Clay::UI
	# runs the contributors in alphabetical order, so this one runs after
	# contribute_layout and contribute_layout_inset and sees the final
	# padding, border included. An axis of the natural size is a number of
	# cells, made a fixed sizing with the padding added, or a sizing hash
	# of Clay::XS, whose limits get the padding added.
	# ---------------------------------------------------------------------

	method contribute_layout_size ($config) {
		my $layout = $config->{layout} // {};
		my $sizing = $layout->{sizing} // {};
		my @open   = grep { !defined $sizing->{$_} } qw(width height);
		return unless @open;

		my $padding = $layout->{padding} // {};
		my ( $columns, $rows ) = $self->natural_size;
		my %natural = ( width => $columns, height => $rows );
		my %inset   = (
			width  => ( $padding->{left} // 0 ) + ( $padding->{right}  // 0 ),
			height => ( $padding->{top}  // 0 ) + ( $padding->{bottom} // 0 ),
		);
		$config->{layout} = { %$layout, sizing => { %$sizing, map { $_ => _with_inset( $natural{$_}, $inset{$_} ) } @open } };
		return;
	}

	# A natural axis as a sizing of the whole widget: a sizing hash with
	# the inset added to its limits (a max of 0 is no limit), or the cells
	# as a fixed sizing.
	sub _with_inset ( $natural, $inset ) {
		return sizing_fixed( $natural + $inset ) unless ref $natural;
		return { %$natural, min => $natural->{min} + $inset, ( $natural->{max} > 0 ? ( max => $natural->{max} + $inset ) : () ) };
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Display - Common base class of the widgets that
paint themselves from their own state

=head1 SYNOPSIS

	use Object::Pad 0.825;
	use Term::Fabulous::Widget::Display;

	class My::Gauge :isa(Term::Fabulous::Widget::Display) :strict(params) {
		field $fraction :param = 0;

		method fraction (@new) {
			return $fraction unless @new;
			$fraction = $new[0];
			$self->mark_changed;    # the next frame paints it
			return $fraction;
		}

		method natural_size () { return ( 20, 1 ) }    # columns, rows

		method paint () {
			my $filled = int( $self->columns * $fraction + 0.5 );
			$self->fill_attrs( 0,       0, $filled,                  "\x{2588}", $self->color_attr('#61afef'), undef );
			$self->fill_attrs( $filled, 0, $self->columns - $filled, "\x{2591}", $self->color_attr('#3a3f4b'), undef );
			return;
		}
	}

	my $gauge = My::Gauge->new( fraction => 0.25 );
	$gauge->fraction(0.5);    # from a timer, a listener, ...

=head1 DESCRIPTION

C<Term::Fabulous::Widget::Display> is the abstract base class of the
widgets that are drawn from their own state whenever a frame needs
them, and of the input widgets, which add the focus, the mouse and the
keyboard to it (L<Term::Fabulous::Widget::Input>):

=over

=item *

L<Term::Fabulous::Widget::Divider> - a line between widgets, with an
optional text

=item *

L<Term::Fabulous::Widget::ProgressBar> - how much of a task is done

=item *

L<Term::Fabulous::Widget::Spinner> - that something is going on

=item *

L<Term::Fabulous::Widget::Chart> and the charts built on it - data as
lines, bars, slices and more

=item *

L<Term::Fabulous::Widget::Scrollbar> - how far a scroll container is
scrolled

=back

You do not create a C<Display> directly (the class is abstract and
C<new> dies); this page describes what these widgets have in common and
how to write one of your own. Every such widget is a
L<Term::Fabulous::Widget::Canvas>, so it takes the parameters of a Box
(C<id>, C<layout>, C<background_color>, the border parameters, ...) and
can be built from a KDL layout file.

=head2 Painting

A widget of this class never paints in its setters: they record the
new value and call C<mark_changed>
(L<Clay::UI::Role::Core::Element/mark_changed>), so a frame becomes
due. When the frame is drawn, the renderer calls the widget's
C<refresh> (L<Term::Fabulous::Widget::Canvas/refresh>), which compares
the widget's I<paint key> (see L</paint_key>) with the one it last
painted for: the size of its buffer, how often it was marked changed,
and what a subclass adds. Only when the key differs does it clear the
buffer and call L</paint>. So the cells always show the state of the
frame they are drawn in, also when the state was changed by a timer or
another widget, and a frame that changes nothing about the widget
paints nothing of it. Anything you draw into such a widget with the
canvas methods (C<put>, C<put_text>, ...) is lost the next time it
paints.

=head2 Size

Every widget of this class has a natural content size, for example one
row and as many columns as its text needs. When the C<layout> gives no
C<sizing> for an axis, the widget is given its natural size on that
axis: a fixed size of the natural cells plus the padding and border
width, or the sizing the widget asks for (a
L<Term::Fabulous::Widget::Divider> grows along its line). A C<sizing> in
the C<layout> always wins:

	# 20 columns wide, one row high:
	Term::Fabulous::Widget::ProgressBar->new;

	# As wide as the parent allows, still one row high:
	Term::Fabulous::Widget::ProgressBar->new( layout => { sizing => { width => sizing_grow() } } );

A fixed natural size takes no part in a C<width_group> or
C<height_group> (L<Term::Fabulous::Widget/new>), which line up C<fit>
and C<grow> sizings only; give the widget a C<fit> sizing with its
natural size as the minimum to line it up with others.

=head1 ANIMATION

A widget that moves by itself, such as a L<Term::Fabulous::Widget::Spinner>
or an indeterminate L<Term::Fabulous::Widget::ProgressBar>, needs no
timer: it reads the time from the application's clock (L</now>) and
asks for a frame when its next frame is due
(L</request_frame_at>). L<Term::Fabulous> draws that frame at the first
tick of its frame timer at or after the time, the widget's C<paint_key>
then differs, and it paints the next frame and asks again. Nothing is
drawn in between, and the widget stops asking as soon as it stops
animating.

Because the time comes from the clock of L<Term::Fabulous/new>, a test
can move an animation on with a clock of its own, and the screenshot
tools run it on a virtual clock. In a L<Term::Fabulous::Static> page the
widget shows the frame of the moment it is rendered.

The helper L</animation_frame> does the arithmetic:

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $running ? $self->animation_frame( 0.1, scalar @frames ) : -1 );
	}

	method paint () {
		my $frame = $running ? $self->animation_frame( 0.1, scalar @frames ) : 0;
		$self->paint_text( 0, 0, $frames[$frame], $self->color_attr($color), undef );
		return;
	}

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Canvas> and
L<Term::Fabulous::Widget>, plus:

=head2 mark_changed

	$widget->mark_changed;

Marks the widget changed: a frame becomes due, and that frame paints the
widget again from its current state and sizes it again. The setters
call it, so you only need it after changing state behind the widget's
back. Returns the widget.

=head1 SUBCLASS INTERFACE

To write a widget that paints itself, subclass
C<Term::Fabulous::Widget::Display> with L<Object::Pad> (see the
L</SYNOPSIS>); for a widget the user edits, subclass
L<Term::Fabulous::Widget::Input> instead, which adds the focus, the
keys and the mouse. You must implement C<natural_size> and C<paint>.
Paint with C<put_attrs> (L<Term::Fabulous::Widget::Canvas/put_attrs>)
and the helpers below, which take termbox2 attributes (the integers
C<color_attr> returns) instead of colors.

Term::Fabulous draws a frame only when something changed, and the frame
paints the widget (see L</Painting>). Whenever your widget changes
state that C<paint> or C<natural_size> uses, call
C<< $self->mark_changed >> and do not paint: the next frame calls
C<paint>. When C<paint> also reads state of other objects that change
without telling your widget, add that state to L</paint_key>. Without
either, the change shows only when something else makes the widget
paint.

=head2 natural_size

	method natural_size () { return ( $columns, $rows ) }
	method natural_size () { return ( sizing_grow(), 1 ) }

Required. The content size the widget wants when the layout does not
size it (see L</Size>): for each axis a number of cells, or a sizing
hash from L<Clay::XS> (C<sizing_grow>, C<sizing_fit>, ...) whose
limits are the content's; the padding and border are added to them.
Called for every frame.

=head2 paint

	method paint () { ... }

Required. Draws the widget into its buffer. It is called while a frame
is drawn, when the L</paint_key> changed, with a cleared buffer that
has at least one cell; use C<< $self->columns >> and C<< $self->rows >>
for its size. Cell writes made here belong to the frame being drawn and
make no further frame due.

=head2 paint_key

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $self->frame_index );
	}

The list of values L</paint> depends on; the widget paints again when
any of them changed since it last painted. The default holds the size
of the buffer and a count of the widget's C<mark_changed> calls. Extend
it with what C<paint> reads from other objects, which do not mark this
widget changed. The values are compared as strings; keep them cheap to
compute, since the key is computed for every frame.

=head2 color_attr

	my $attr = $self->color_attr('#ff0000');

The termbox2 attribute of any color the canvas accepts, C<undef> for
C<undef> or a color with alpha 0 (no color of its own).

=head2 paint_text

	my $next_x = $self->paint_text( $x, $y, $text, $fg, $bg, $limit );

Paints a character string from cell (C<$x>, C<$y>) with the attributes
C<$fg> and C<$bg> (either may be C<undef>). C<$limit> defaults to
C<< $self->columns >>; a grapheme cluster that would reach past it ends
the text. Returns the column after the last cluster painted.

=head2 fill_attrs

	$self->fill_attrs( $x, $y, $width, $glyph, $fg, $bg );

Puts a one-column glyph into C<$width> cells of row C<$y>, starting at
C<$x>.

=head2 now

	my $seconds = $self->now;

The current time in seconds: L<Term::Fabulous/now> when the widget is
part of a L<Term::Fabulous>, otherwise C<Time::HiRes::time>.

=head2 request_frame_at

	$self->request_frame_at( $self->now + 0.25 );

Asks the widget's L<Term::Fabulous> for a frame at a time on the clock
(see L<Term::Fabulous/request_frame_at>); does nothing when the widget
is not part of one, or part of a L<Term::Fabulous::Static>. Returns
the widget.

=head2 animation_frame

	my $index = $self->animation_frame( $interval, $count );

The frame, from 0 to C<$count - 1>, of an animation whose frames last
C<$interval> seconds each, at the current time, counted from the
start of the clock so that every widget with the same interval moves
in step. Also asks for a frame when the next one is due, so call it
from L</paint_key> only while the widget animates (see L</ANIMATION>).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Canvas>, L<Term::Fabulous::Widget::Input>,
L<Term::Fabulous::Manual::CustomWidgets/A widget that draws itself>.

=cut
