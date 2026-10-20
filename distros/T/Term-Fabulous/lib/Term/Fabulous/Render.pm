package Term::Fabulous::Render;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

# Loaded first: dies with a clear message when termbox2 lacks truecolor,
# before the TB_OUTPUT_TRUECOLOR import below could fail obscurely.
use Term::Fabulous::Render::Attr ();

use Term::Fabulous::Render::Rectangle;
use Term::Fabulous::Render::Border;
use Term::Fabulous::Render::Text;
use Term::Fabulous::Render::Canvas;

role Term::Fabulous::Render
	:does(Term::Fabulous::Render::Rectangle)
	:does(Term::Fabulous::Render::Border)
	:does(Term::Fabulous::Render::Text)
	:does(Term::Fabulous::Render::Canvas)
{
	use Clay::XS qw(
		CLAY_RENDER_COMMAND_TYPE_RECTANGLE
		CLAY_RENDER_COMMAND_TYPE_BORDER
		CLAY_RENDER_COMMAND_TYPE_TEXT
		CLAY_RENDER_COMMAND_TYPE_CUSTOM
	);
	use Clay::UI::Revision qw(bump_revision);
	use Clay::UI::Role::Layout::HasParent qw(is_widget);
	use Feature::Compat::Try;
	use Scalar::Util qw(blessed looks_like_number refaddr weaken);
	use Term::Fabulous::Check qw(describe positive_integer string);
	use Term::Fabulous::Termbox qw(TB_OUTPUT_TRUECOLOR TB_DEFAULT);
	use Term::Fabulous::Render::Attr qw(color_attr);
	use Term::Fabulous::Render::Frame;
	use Term::Fabulous::Role::Themed;
	use Term::Fabulous::Theme;
	use Term::Fabulous::Unicode qw(string_columns);

	# Scissors paint nothing: the Frame has turned them into clip rects.
	my %handler_by_command_type = (
		CLAY_RENDER_COMMAND_TYPE_RECTANGLE() => 'render_rectangle',
		CLAY_RENDER_COMMAND_TYPE_BORDER()    => 'render_border',
		CLAY_RENDER_COMMAND_TYPE_TEXT()      => 'render_text',
		CLAY_RENDER_COMMAND_TYPE_CUSTOM()    => 'render_custom',
	);

	# Clay_UpdateScrollContainers moves a scroll container by ten layout
	# units, here cells, per unit of scroll delta.
	use constant CELLS_PER_CLAY_SCROLL_UNIT => 10;

	field $output_mode :param :reader = TB_OUTPUT_TRUECOLOR;

	# The theme the widgets draw with (Term::Fabulous::Theme), set at
	# construction and through the theme accessor.
	field $theme :param = undef;

	# Background attribute of every cell painted this frame, indexed [y][x].
	field $buffer = [];

	# The attribute of the screen background the frame being painted lies
	# on, TB_DEFAULT when the terminal's own background shows.
	field $_screen_background_attr = TB_DEFAULT;
	field $_last_frame;

	# The paint-order index of the command being painted, undef between
	# commands.
	field $_painting_index;

	# The work to do after frames, in the order it was registered (see
	# after_draw and each_draw): { code, owner, bound, key, repeat,
	# frames, calls, done }. An owner is held weakly.
	field @_frame_work;

	my %FRAME_WORK_OPTIONS = ( after_draw => [qw(owner)], each_draw => [qw(owner name frames)] );

	# Provided by Clay::UI.
	method render;
	method widget_for;
	method measure_text;
	method owns;

	# Provided by the consumer: undef, or { x, y, down } of the pointer.
	method pointer_state;

	# Provided by the consumer: the Term::Fabulous::Color the screen is
	# painted in before the widgets, or undef to leave the terminal's own
	# background (see SCREEN BACKGROUND).
	method screen_background;

	# Provided by the consumer: the cell target the frames are painted
	# into (see CELL TARGET).
	method cell_target;

	ADJUST {
		die "Term::Fabulous::Render: output_mode must be TB_OUTPUT_TRUECOLOR (" . TB_OUTPUT_TRUECOLOR . "), got '$output_mode'"
			unless looks_like_number($output_mode) && $output_mode == TB_OUTPUT_TRUECOLOR;

		$theme = _checked_theme( $theme // 'dark' );
		Term::Fabulous::Theme::bump_generation();    # widgets built before this UI look their looks up again
		Term::Fabulous::Role::Themed::forget_tree_looks( $self->root );
		$self->measure_text( \&_measure_text );
	}

	# A Term::Fabulous::Theme, or one of the built-in themes by name.
	sub _checked_theme ($value) {
		return $value if blessed $value && $value->isa('Term::Fabulous::Theme');
		my $builtin = defined $value && !ref $value ? Term::Fabulous::Theme->builtin($value) : undef;
		die "Term::Fabulous::Render: theme must be a Term::Fabulous::Theme or the name of a built-in theme (" . join( ', ', Term::Fabulous::Theme::builtin_names() ) . "), got " . describe($value)
			unless defined $builtin;
		return $builtin;
	}

	# Setting a theme makes every widget look its looks up again, tells
	# the widgets that copy looks into their parts (a Table), and draws a
	# frame.
	method theme (@new) {
		return $theme unless @new;
		$theme = _checked_theme( $new[0] );
		$self->refresh_looks;
		return $theme;
	}

	# The theme a widget of the tree draws with (Term::Fabulous::Role::Themed
	# asks): the UI's. A subclass may give parts of its tree another theme;
	# it calls refresh_looks when what it returns changes.
	method theme_for ($widget) {
		return $theme;
	}

	# Every widget looks its looks up again in the next frame.
	method refresh_looks () {
		Term::Fabulous::Theme::bump_generation();
		Term::Fabulous::Role::Themed::forget_tree_looks( $self->root );
		bump_revision();
		return $self;
	}

	# Clay measures single words and single lines, so the height is one cell.
	sub _measure_text ( $text, $config, $userdata ) {
		return { width => string_columns($text), height => 1 };
	}

	method last_frame () {
		return $_last_frame // Term::Fabulous::Render::Frame->new( commands => [], width => $self->width, height => $self->height );
	}

	method clip_rect () {
		die "Term::Fabulous::Render: clip_rect is only known while a render command is painted" unless defined $_painting_index;
		return $_last_frame->clip_rect($_painting_index);
	}

	sub _clay_scroll_delta ($scroll_cells) {
		die "Term::Fabulous::Render: scroll_cells must be [columns, rows] of numbers"
			unless ref $scroll_cells eq 'ARRAY' && @$scroll_cells == 2 && !grep { !looks_like_number($_) } @$scroll_cells;
		my ( $columns, $rows ) = @$scroll_cells;
		return { x => $columns / CELLS_PER_CLAY_SCROLL_UNIT, y => $rows / CELLS_PER_CLAY_SCROLL_UNIT };
	}

	# Clay counts the right and bottom edges of a box as inside it, so a
	# cell's corner would also lie in the boxes left of and above it; its
	# center lies in the box of the cell only.
	sub _clay_pointer ($pointer) {
		return { %$pointer, x => $pointer->{x} + 0.5, y => $pointer->{y} + 0.5 };
	}

	# clip_rect answers for the command being painted, and for no other
	# time, even when a handler dies.
	method _paint_commands ($frame) {
		my @commands = $frame->commands;
		try {
			foreach my $index ( 0 .. $#commands ) {
				my $command = $commands[$index];
				my $handler = $handler_by_command_type{ $command->{commandType} } // next;
				$_painting_index = $index;
				$self->$handler( $command, $self->widget_for( $command->{userData} ), $buffer );
			}
		}
		catch ($error) {
			$_painting_index = undef;
			die $error;
		}
		$_painting_index = undef;
		return;
	}

	method draw (%args) {
		my @unknown = grep { $_ ne 'scroll_cells' } sort keys %args;
		die "Term::Fabulous::Render: draw got unknown argument(s): @unknown" if @unknown;

		my $pointer  = $self->pointer_state;
		my $commands = $self->render(
			( defined $pointer            ? ( pointer_state => _clay_pointer($pointer) )                   : () ),
			( defined $args{scroll_cells} ? ( scroll_delta  => _clay_scroll_delta( $args{scroll_cells} ) ) : () ),
		);

		# Complete before painting starts, so hit-testing sees the whole
		# frame even when painting dies partway.
		$_last_frame = Term::Fabulous::Render::Frame->new( commands => $commands, width => $self->width, height => $self->height );

		my $screen_background = $self->screen_background;
		$_screen_background_attr = defined $screen_background ? color_attr($screen_background) : TB_DEFAULT;

		my $target = $self->cell_target;
		$target->begin_frame( $self->plan_canvases($_last_frame) );
		$buffer = [];
		$self->_paint_screen_background($target) if defined $screen_background;
		$self->_paint_commands($_last_frame);
		$target->show_sixels( $self->sixel_placements( $_last_frame, $target ) ) if $target->DOES('Term::Fabulous::Render::Target::Sixel');
		$target->end_frame;
		$self->finish_canvases;

		$self->_run_frame_work;
		return;
	}

	# Runs the work that was registered when the frame was drawn; work
	# registered meanwhile (a callback may queue more) waits for the next
	# frame. Every due callback runs even if an earlier one dies, a dying
	# one ends, and the first error is rethrown afterwards.
	method _run_frame_work () {
		my $first_error;
		my @due = grep { !$_->{done} } @_frame_work;    # copies: callbacks change the list
		foreach my $entry (@due) {
			next if $entry->{done};    # replaced by a callback that ran before it
			try { $self->_run_frame_entry($entry) }
			catch ($error) {
				$entry->{done} = 1;
				$first_error //= $error;
			}
		}
		@_frame_work = grep { !$_->{done} } @_frame_work;
		die $first_error if defined $first_error;
		return;
	}

	# Work bound to an owner ends unseen once the owner is gone or no
	# longer in this UI; it is called with the owner.
	method _run_frame_entry ($entry) {
		my @arguments;
		if ( $entry->{bound} ) {
			my $owner = $entry->{owner};
			if ( !defined $owner || !$self->owns($owner) ) {
				$entry->{done} = 1;
				return;
			}
			@arguments = ($owner);
		}
		$entry->{calls}++;
		my $finished = $entry->{code}->(@arguments);
		$entry->{done} = 1 if !$entry->{repeat} || $finished || ( defined $entry->{frames} && $entry->{calls} >= $entry->{frames} );
		return;
	}

	# Fills the viewport with spaces in the screen background and records
	# it as the background below every cell, so that the widgets, borders
	# and translucent boxes of the frame are painted over it instead of
	# over the terminal's own background. The target leaves the cells a
	# canvas keeps from the last frame as they are.
	method _paint_screen_background ($target) {
		my $width = $self->width;
		foreach my $y ( 0 .. $self->height - 1 ) {
			$buffer->[$y] = [ ($_screen_background_attr) x $width ];
			$target->fill_row( 0, $y, $width, $_screen_background_attr );
		}
		return;
	}

	method after_draw ( $code, %options ) {
		push @_frame_work, $self->_frame_work_entry( after_draw => $code, %options );
		return $self;
	}

	# A registration with the owner and name of one still queued replaces
	# it: the old one ends, the new one is queued last.
	method each_draw ( $code, %options ) {
		my $entry = $self->_frame_work_entry( each_draw => $code, %options );
		$entry->{repeat} = 1;
		if ( defined $entry->{key} ) {
			$_->{done} = 1 foreach grep { defined $_->{key} && $_->{key} eq $entry->{key} } @_frame_work;
			@_frame_work = grep { !$_->{done} } @_frame_work;
		}
		push @_frame_work, $entry;
		return $self;
	}

	method _frame_work_entry ( $method, $code, %options ) {
		my %known   = map  { $_ => 1 } @{ $FRAME_WORK_OPTIONS{$method} };
		my @unknown = grep { !$known{$_} } sort keys %options;
		die "Term::Fabulous::Render: $method does not take @unknown (known: @{ $FRAME_WORK_OPTIONS{$method} })" if @unknown;
		die "Term::Fabulous::Render: $method needs a code reference, got " . describe($code) unless ref $code eq 'CODE';
		my $bound = exists $options{owner};
		die "Term::Fabulous::Render: $method takes a widget as its owner, got " . describe( $options{owner} ) if $bound && !is_widget( $options{owner} );
		my $name   = exists $options{name}   ? string( "Term::Fabulous::Render: $method", name => $options{name} )               : undef;
		my $frames = exists $options{frames} ? positive_integer( "Term::Fabulous::Render: $method", frames => $options{frames} ) : undef;
		my $entry  = {
			code   => $code,
			bound  => $bound,
			owner  => $options{owner},
			key    => defined $name ? ( $bound ? refaddr( $options{owner} ) : '' ) . "\0$name" : undef,
			frames => $frames,
			calls  => 0,
		};
		weaken $entry->{owner} if $bound;
		return $entry;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Render - Role that paints Clay render commands into
terminal cells

=head1 SYNOPSIS

	use Object::Pad 0.825;
	use Clay::UI;
	use Term::Fabulous::Render;
	use Term::Fabulous::Render::Target::Grid;

	# A UI class that paints into memory and never sees a pointer.
	class My::Snapshot :isa(Clay::UI) :does(Term::Fabulous::Render) {
		field $cell_target :reader = Term::Fabulous::Render::Target::Grid->new;

		method pointer_state () { return undef }
	}

	my $ui = My::Snapshot->new( root => $root, width => 10, height => 2 );
	$ui->draw;
	my ( $glyph, $fg, $bg ) = @{ $ui->cell_target->cell( 0, 0 ) };

=head1 DESCRIPTION

Most programs never use this module directly. L<Term::Fabulous> (for
the terminal) and L<Term::Fabulous::Static> (for text output) already
compose it. Read on if you want to write your own UI class, for example
one that paints into a different kind of output, or want to know
exactly how a frame is painted. To write a widget of your own you do not
need this module: build it on the existing widgets as
L<Term::Fabulous::Manual::CustomWidgets> explains (a widget that draws
itself is a L<Term::Fabulous::Widget::Canvas>).

Term::Fabulous::Render is an L<Object::Pad> role for a subclass of
L<Clay::UI>. It turns a laid-out widget tree into terminal cells:
L</draw> asks Clay::UI for the frame's render commands (rectangles,
borders, text, clipping and canvases) and paints each of them, cell by
cell. Where the cells go is decided by an object the class provides,
the I<cell target> (see L</CELL TARGET>).

The role is composed of smaller roles, one per kind of render command:
L<Term::Fabulous::Render::Rectangle>, L<Term::Fabulous::Render::Border>,
L<Term::Fabulous::Render::Text> and L<Term::Fabulous::Render::Canvas>.
What a frame paints where is worked out once per frame, before any
painting, by L<Term::Fabulous::Render::Frame>.

When it is constructed, the role checks C<output_mode> and installs its
own measure-text callback in Clay::UI (C<measure_text>), which reports
text widths in terminal columns (see L<Term::Fabulous::Unicode>). The
constructors of L<Term::Fabulous> and L<Term::Fabulous::Static> die
when given a C<measure_text> of their own.

=head1 REQUIREMENTS OF THE CONSUMING CLASS

The class that composes this role must provide:

=over

=item * the methods of L<Clay::UI>: C<render>, C<widget_for>, C<measure_text>, C<width> and C<height> (subclass Clay::UI);

=item * C<pointer_state> (see L</pointer_state>);

=item * C<screen_background> (see L</SCREEN BACKGROUND>);

=item * C<cell_target>, which returns the object the frames are painted into (see L</CELL TARGET>).

=back

=head1 CONSTRUCTOR PARAMETERS

=over

=item C<output_mode>

The termbox2 output mode. It must be C<TB_OUTPUT_TRUECOLOR> (from
L<Term::Fabulous::Termbox>), which is also the default, because Term::Fabulous always
paints 24-bit colors. Any other value dies with
C<Term::Fabulous::Render: output_mode must be TB_OUTPUT_TRUECOLOR>.
There is no reason to pass it.

=item C<theme>

The L<Term::Fabulous::Theme> the widgets draw with: a theme object or
the name of a built-in theme (C<dark>, C<light>). Default: C<dark>.
See L</theme>.

=back

=head1 METHODS

=head2 theme

	my $theme = $ui->theme;
	$ui->theme('light');
	$ui->theme( Term::Fabulous::Theme->from_file('ocean.kdl') );

Accessor for the theme. Without an argument it returns the
L<Term::Fabulous::Theme> object; with one it sets the theme (an object
or a built-in name; anything else dies), makes every widget read its
looks again, calls C<looks_changed> on every widget of the tree that
has such a method (see L<Term::Fabulous::Role::Themed/looks_changed>)
and draws a frame. Widgets that were given a color or a border style
explicitly keep it; see L<Term::Fabulous::Manual::Looks/THEMES>.

=head2 theme_for

	my $theme = $ui->theme_for($widget);

The theme a widget of the tree draws with: the one L</theme> returns.
L<Term::Fabulous::Role::Themed> asks this method whenever a widget
looks its looks up, so a subclass of the UI class can override it to
give a part of its tree another theme, for example a preview of a theme
next to the controls that edit it (L<Term::Fabulous::ThemeEditor> does
that):

	class My::UI :isa(Term::Fabulous) {
		field $preview :param;          # a Box: the part drawn in $preview_theme
		field $preview_theme = 'light';

		method theme_for :override ($widget) {
			return $self->SUPER::theme_for($widget) unless $preview->contains($widget);
			return Term::Fabulous::Theme->builtin($preview_theme);
		}

		method preview_theme ($name) {
			$preview_theme = $name;
			$self->refresh_looks;    # what theme_for returns changed
			return $self;
		}
	}

The override must be cheap (it runs for every widget once after every
change of the looks) and must call L</refresh_looks> whenever what it
returns changes. The screen background always comes from L</theme>.

=head2 refresh_looks

	$ui->refresh_looks;

Makes every widget read its looks again, calls C<looks_changed> on
every widget of the tree that has such a method and draws a frame, as
setting L</theme> does. Call it after a change that L</theme_for>
reports. Returns the UI.

=head2 draw

	$ui->draw;
	$ui->draw( scroll_cells => [ $columns, $rows ] );

Lays out and paints one frame:

=over

=item 1.

Calls Clay::UI's C<render>, passing the pointer from L</pointer_state>
(when it is defined) and the scroll amount. Clay::UI fires its pointer
events (hover, press, scroll) during this call.

=item 2.

Builds the L<Term::Fabulous::Render::Frame> of the commands: their
paint order, the clip rect of each and the cells each paints.
L</last_frame> returns it from now on.

=item 3.

Sizes every canvas to its new content box and decides which canvases
can keep the cells of the previous frame
(L<Term::Fabulous::Render::Canvas/plan_canvases>). Canvases fire
C<CanvasResize> here.

=item 4.

Calls the cell target's C<begin_frame>, paints the screen background
(see L</SCREEN BACKGROUND>), paints every render command in paint
order, hands a target that shows sixel the frame's pictures (see
L</show_sixels>) and calls C<end_frame>.

=item 5.

Calls L<Term::Fabulous::Render::Canvas/finish_canvases>, which
remembers this completely painted frame for the comparison in step 3 of
the next frame. If painting died, this step is skipped and the next
frame paints every canvas in full.

=item 6.

Runs the work registered with L</after_draw> and L</each_draw>, in
the order it was registered. If painting died, it stays registered for
the next frame.

=back

C<scroll_cells> scrolls the scroll container under the pointer (see
L<Term::Fabulous::Widget::ScrollBox>) by C<[$columns, $rows]> cells
before the layout is computed. Positive values reveal content
above and to the left (the content moves down and right on screen), as
turning a mouse wheel up does; negative values reveal content below and
to the right. Clay keeps
the result within the content. L<Term::Fabulous> passes the wheel
notches since the last frame here.

Any other argument dies. Render command types other than rectangle,
border, text, scissor (clipping) and custom (canvas) die (see
L<Term::Fabulous::Render::Frame/new>); Term::Fabulous widgets produce
only these. With the termbox2 cell target, the terminal must have been
opened (L<Term::Fabulous/run> and L<Term::Fabulous/step> do that);
otherwise termbox2 ignores the drawing.

=head2 after_draw

	$ui->after_draw( sub {
		my $box = $ui->bounding_box($row) // return;
		...;    # the geometry of the frame just drawn
	} );

	$ui->after_draw( sub ($chooser) { $chooser->close_unless_focused }, owner => $chooser );

Queues a code reference that L</draw> calls once, after the next frame
has been painted completely. Use it for work that needs the layout of a
frame that has not been drawn yet, for example to scroll a row into
view that was only just added: Clay::UI's C<bounding_box> and
C<scroll_state> then answer for that frame. A change the callback makes
(a scroll position, a widget property) shows in the frame after it,
which is due at once. A callback may queue another one; it runs after
the following frame.

Without options the code is called with no arguments. With
C<< owner => $widget >> it is I<owner-bound>: the UI holds the widget
weakly and calls C<< $code->($widget) >>, or skips the call when the
widget has been freed or is no longer part of this UI by then (see
L<Clay::UI/owns>). That is how a widget asks for work after a frame
without a closure that keeps it alive. Widgets usually go through
L<Term::Fabulous::Widget/each_frame>.

Anything but a code reference, an owner that is not a widget or
another option dies. Returns the UI object. Every callback that is due
runs even if an earlier one dies; the first exception then leaves
C<draw>.

=head2 each_draw

	$ui->each_draw( sub ($view) { $view->report_position; return 0 }, owner => $view, name => 'report' );
	$ui->each_draw( sub ($box) { return $box->try_again }, owner => $box, name => 'retry', frames => 8 );
	$ui->each_draw( \&refresh_status );

Registers a code reference that L</draw> calls after every frame from
the next one on, until the registration ends. It ends

=over

=item *

when the code returns a true value (return 0 to keep it);

=item *

after C<frames> calls, when C<frames> is given: the code runs after the
first C<frames> frames drawn after the registration at most, whatever
it returns. Without C<frames> there is no limit;

=item *

for an owner-bound registration (C<< owner => $widget >>, as for
L</after_draw>), when the owner has been freed or is no longer part of
this UI, without a call;

=item *

when a callback dies (see L</after_draw>);

=item *

when another registration with the same C<name> replaces it: one with
the same owner, or, for a registration without an owner, another one
without an owner. The old one ends, the new one is queued last. Give a
name to work a widget may ask for repeatedly, such as a retry, so that
only the latest request runs.

=back

The code is called with the owner, or with no arguments without one.
Registrations run in the order they were made, after-draw and
each-draw work together. C<name> must be a string and C<frames> a
positive integer; another option dies, as for L</after_draw>. Returns
the UI object.

=head2 last_frame

	my $frame = $ui->last_frame;
	my @indices = $frame->topmost_at( $x, $y );

The L<Term::Fabulous::Render::Frame> of the last L</draw>: its render
commands in paint order, the clip rect of each and the cells each
painted. L<Term::Fabulous> hit-tests every mouse report with it. Before
the first frame, an empty Frame of the current size. The Frame is
complete even when painting the frame died partway, so it always
describes one whole layout. Use
C<< $ui->widget_for( $command->{userData} ) >> to get the widget a
command belongs to.

=head2 clip_rect

	my ( $x0, $y0, $x1, $y1 ) = @{ $ui->clip_rect };

The rectangle of cells the render command being painted may touch, as
a new array reference (see L<Term::Fabulous::Render::Frame/clip_rect>).
The paint roles call it from their render command handlers; it dies
when no command is being painted
(C<Term::Fabulous::Render: clip_rect is only known while a render command is painted>).

=head2 pointer_state

	method pointer_state () { return { x => 12, y => 3, down => 0 } }

Required from the consuming class: C<undef> when there is no pointer,
or a hash reference with the pointer's cell C<x> and C<y> (from 0) and
whether the left button is held (C<down>, 0 or 1).

L</draw> gives Clay the center of that cell (C<x + 0.5>, C<y + 0.5>),
not its corner: Clay counts the right and bottom edge of a box as part
of the box, so the corner of a cell would also be "over" the widgets to
the left of and above it. As a consequence, the C<x> and C<y> of
Clay::UI's C<OnPress> and C<OnRelease> events are cell centers, such
as C<12.5>.

=head1 HOW COMMANDS ARE PAINTED

Clay positions boxes in fractional layout units. They are snapped to
whole cells (see L<Term::Fabulous::Render::Geometry/cell_rect>) and
clipped to the viewport (C<width> x C<height>) and to the innermost
scissor around the command (see L<Term::Fabulous::Render::Frame>). Nothing outside
these limits is painted. Colors are turned into termbox2 attributes as
described in L<Term::Fabulous::Render::Attr>; alpha 0 means "no color",
and only a background with an alpha from 1 to 254 is blended.

=over

=item Rectangles

A widget's background. Its cells are filled with spaces in the
background color. A translucent background is blended with what lies
below it, covering the glyphs there or letting them show through as the
widget's C<glyphs_show_through> says. A widget whose C<reverse_video>
is true (a pressed L<Term::Fabulous::Widget::Button>) adds reverse
video to its background, so everything painted on it later swaps its
colors. See
L<Term::Fabulous::Render::Rectangle>.

=item Text

One line of a Text widget, in its text color plus its bold, italic and
underline style bits. It starts at the top-left cell of its box;
every grapheme cluster takes as many columns as termbox2 will use for
it. A cluster that would cross the right edge of the box or of the clip
area ends the line. The background of each cell is whatever was painted
there before. See L<Term::Fabulous::Render::Text>.

=item Canvases

The cells of a L<Term::Fabulous::Widget::Canvas>, painted into its
content box. Clay carries a canvas's background in the canvas's own
command; the frame paints it as a rectangle before the canvas, so the
background lies below the cells. See L<Term::Fabulous::Render::Canvas>.

=item Borders

The border of a widget composing L<Term::Fabulous::Role::HasBorderStyle>,
in its border styles. See L<Term::Fabulous::Render::Border>.

=item Scissors

Start and end of a clipping area, for example around the content of a
scroll container. They paint nothing themselves; the Frame turns them
into the clip rects of the commands between them. See
L<Term::Fabulous::Render::Frame>.

=back

=head1 SCREEN BACKGROUND

	method screen_background () { return $color }    # a Term::Fabulous::Color, or undef

Before the render commands of a frame are painted, the whole viewport
(the screen, or the rows of an inline region) is filled with spaces in
the color the consuming class returns from C<screen_background>, and
that color is recorded as the background below every cell. So the
widgets, their borders and their translucent backgrounds are painted
over it, not over whatever the terminal shows where a program sets no
color, and a theme made for a light background is readable on a dark
terminal. The cells a canvas keeps from the last frame are left alone.
A translucent color is painted opaque here, since there is nothing
below it to blend with. Widgets that need the color they lie on (the
unset cells of a canvas, the cells of a table, the ink of a chart) ask
L<Term::Fabulous::Widget/background_below>, which ends at this color.

L<Term::Fabulous> returns the C<background> token of its theme, or
C<undef> for a token with alpha 0, which leaves the terminal's own
background (see L<Term::Fabulous::Theme/Tokens>).
L<Term::Fabulous::Static> returns C<undef>: its lines are printed into
whatever the terminal shows.

=head1 CELL TARGET

	method cell_target () { return $grid }

The paint roles do not write to the terminal themselves. They compute a
glyph and two termbox2 attributes per cell and hand them to the I<cell
target>, the object the consuming class returns from C<cell_target>.
The renderer asks for it once per render command, so C<cell_target>
should return a stored object, not build one. The distribution has two:

=over

=item L<Term::Fabulous::Terminal::Termbox::Cells>

Draws into the terminal through termbox2. L<Term::Fabulous> paints into
the cell target of its terminal
(L<Term::Fabulous::Role::Terminal/cell_target>), which is this one for
the real terminal.

=item L<Term::Fabulous::Render::Target::Grid>

Keeps the cells in memory. Used by L<Term::Fabulous::Static> and by
L<Term::Fabulous::Terminal::Memory>.

=back

Both compose L<Term::Fabulous::Render::Target::Mask>, which implements
all methods below except C<painted_cell> on top of a few primitives;
write your own target the same way, and give it a C<painted_cell> of its
own. All coordinates are cells, counted from 0 at the top-left, and
always lie inside the viewport and the clip rect of the command:
clipping happens before a target method is called.

=head2 begin_frame

	$target->begin_frame(@kept_rects);

Called once before the commands of a frame are painted. Resets every
cell outside the given C<[x0, y0, x1, y1]> rectangles (all cells when
none are given). The cells inside them must keep what the previous
frame painted there, and writes into them are ignored until the
rectangle is released with L</release_rect>.

=head2 end_frame

	$target->end_frame;

Called once after all commands of a frame are painted. Releases all
kept rectangles and shows the frame.

=head2 release_rect

	$target->release_rect($rect);

Stops protecting one of the rectangles given to L</begin_frame>
(identified by being the same array reference). The canvas that owns it
then paints its changed cells into it.

=head2 set_cell

	$target->set_cell( $x, $y, $glyph, $fg, $bg );

Paints one cell: C<$glyph> is a character string with one character
(the base character of a grapheme cluster), C<$fg> and C<$bg> are
termbox2 attributes.

=head2 extend_cell

	$target->extend_cell( $x, $y, $character );

Appends a combining character (a character string of length one) to the
cell set last at that position, to complete a grapheme cluster.

=head2 fill_row

	$target->fill_row( $x, $y, $columns, $bg );

Paints C<$columns> cells of spaces with the background attribute C<$bg>,
starting at C<($x, $y)> and going right.

=head2 painted_cell

	my ( $glyph, $fg, $bg ) = $target->painted_cell( $x, $y );

Not part of L<Term::Fabulous::Render::Target::Mask>: every target
provides it itself. L<Term::Fabulous::Render::Rectangle> calls it to
repaint the glyphs below a translucent background. Reads back what the frame holds at a cell so far: the glyph (a
character string, the base character plus any combining characters),
its foreground and its background attribute. Returns an empty list when
nothing was painted there. The cell to the right of a wide glyph is
not written for it, so reading it gives what was painted there before
the glyph. Kept rectangles do not affect reading.

=head2 show_sixels

	$target->show_sixels(@placements);

Only for a target that composes L<Term::Fabulous::Render::Target::Sixel>,
which both targets of the distribution do. The renderer calls it once
per frame, after the render commands are painted and before
L</end_frame>, with the sixel pictures of the frame's canvases
(L<Term::Fabulous::Render::Canvas/sixel_placements>), none when its
C<sixel_cell_size> is empty. The role describes the placements and the
other two methods it requires.

=head1 SEE ALSO

L<Term::Fabulous>, L<Term::Fabulous::Static>, L<Clay::UI>,
L<Term::Fabulous::Render::Frame>, L<Term::Fabulous::Render::Target::Mask>,
L<Term::Fabulous::Render::Attr>.

=cut
