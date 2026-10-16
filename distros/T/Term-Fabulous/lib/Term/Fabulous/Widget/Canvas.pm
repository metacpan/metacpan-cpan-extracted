package Term::Fabulous::Widget::Canvas;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Canvas
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Feature::Compat::Try;
	use List::Util qw(max min);
	use POSIX qw(ceil);
	use Term::Fabulous::Check qw(describe);
	use Term::Fabulous::Event::CanvasResize;
	use Term::Fabulous::Render::Attr qw(cell_color_attr);
	use Term::Fabulous::Render::Geometry qw(cell_coordinate);
	use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns);

	use constant GLYPH_CACHE_LIMIT => 4096;

	# Stored in the cells a wide glyph covers to the right of its own cell.
	use constant TAIL => '';

	# Glyph records, shared by every cell showing the glyph:
	# [ $cluster, $columns, $base_character, @extending_characters ].
	my %glyph_by_string;
	my $SPACE = [ ' ', 1, ' ' ];

	field $columns :reader = 0;
	field $rows    :reader = 0;

	# Viewport cell of buffer cell (0, 0) in the last frame that laid it out.
	field @content_origin;

	# Cells by [y][x]: a glyph record, TAIL, or undef for an unset cell; the
	# attributes are undef where the cell has none of its own.
	field @glyph_rows;
	field @fg_rows;
	field @bg_rows;

	# The cells as take_changed_spans last handed them out, by [y][x], and
	# per row the [from, to) columns written since: only those can differ.
	field @taken_glyph_rows;
	field @taken_fg_rows;
	field @taken_bg_rows;
	field @written_spans;
	field $everything_changed = 1;

	# Set while the renderer runs refresh: those writes belong to the frame
	# being drawn and make no further frame due.
	field $_refreshing = 0;

	sub _is_tail ($cell) {
		return defined $cell && !ref $cell;
	}

	sub _glyph_of_cluster ($cluster) {
		my $glyph = $glyph_by_string{$cluster};
		return $glyph if defined $glyph;

		%glyph_by_string = () if keys(%glyph_by_string) >= GLYPH_CACHE_LIMIT;
		my ( $base, @extenders ) = split //, $cluster;
		return $glyph_by_string{$cluster} = [ $cluster, cluster_columns($cluster), $base, @extenders ];
	}

	sub _glyph ($string) {
		die "Term::Fabulous::Widget::Canvas: a glyph must be a non-empty string, got " . describe($string)
			unless defined $string && !ref $string && length $string;
		my $glyph = $glyph_by_string{$string};
		return $glyph if defined $glyph;

		my @clusters = grapheme_clusters($string);
		die "Term::Fabulous::Widget::Canvas: a glyph must be exactly one grapheme cluster, got " . scalar(@clusters) . " in '$string'"
			unless @clusters == 1;
		return _glyph_of_cluster( $clusters[0] );
	}

	sub _same_glyph ( $glyph, $other ) {
		return !defined $other unless defined $glyph;
		return 0 unless defined $other;
		return ref $glyph ? ref $other && $glyph->[0] eq $other->[0] : !ref $other;
	}

	sub _same_attr ( $attr, $other ) {
		return defined $attr ? defined $other && $attr == $other : !defined $other;
	}

	method contribute_custom ($config) {
		$config->{custom} = { custom_data => 1 };
		return;
	}

	method put ( $x, $y, $glyph, $fg = undef, $bg = undef ) {
		$self->_store( cell_coordinate( x => $x ), cell_coordinate( y => $y ), _glyph($glyph), cell_color_attr( fg => $fg ), cell_color_attr( bg => $bg ) );
		return $self->_cells_changed;
	}

	method put_text ( $x, $y, $text, $fg = undef, $bg = undef ) {
		die "Term::Fabulous::Widget::Canvas: text must be a string, got " . describe($text) unless defined $text && !ref $text;
		my ( $column,  $row )     = ( cell_coordinate( x => $x ),   cell_coordinate( y => $y ) );
		my ( $fg_attr, $bg_attr ) = ( cell_color_attr( fg => $fg ), cell_color_attr( bg => $bg ) );

		foreach my $cluster ( grapheme_clusters($text) ) {
			last if $column >= $columns;
			my $glyph = _glyph_of_cluster($cluster);
			$self->_store( $column, $row, $glyph, $fg_attr, $bg_attr );
			$column += $glyph->[1];
		}
		return $self->_cells_changed;
	}

	method fill ( $x, $y, $width, $height, $glyph, $fg = undef, $bg = undef ) {
		my ( $x0, $y0 ) = ( cell_coordinate( x => $x ), cell_coordinate( y => $y ) );
		my ( $x1, $y1 ) = ( $x0 + cell_coordinate( width => $width ), $y0 + cell_coordinate( height => $height ) );
		my $record = _glyph($glyph);
		my ( $fg_attr, $bg_attr ) = ( cell_color_attr( fg => $fg ), cell_color_attr( bg => $bg ) );

		# Glyphs repeat from x0 on; skip the repeats left of the buffer.
		my $step  = $record->[1];
		my $first = $x0 < 0 ? $x0 + $step * ceil( -$x0 / $step ) : $x0;
		foreach my $row ( max( $y0, 0 ) .. min( $y1, $rows ) - 1 ) {
			for ( my $column = $first; $column + $step <= min( $x1, $columns ); $column += $step ) {
				$self->_store( $column, $row, $record, $fg_attr, $bg_attr );
			}
		}
		return $self->_cells_changed;
	}

	method put_attrs ( $x, $y, $glyph, $fg_attr, $bg_attr ) {
		$self->_store( $x, $y, defined $glyph ? _glyph($glyph) : undef, $fg_attr, $bg_attr );
		return $self->_cells_changed;
	}

	method erase ( $x, $y ) {
		$self->_store( cell_coordinate( x => $x ), cell_coordinate( y => $y ), undef, undef, undef );
		return $self->_cells_changed;
	}

	# Every cell may differ now; take_changed_spans finds the ones that do.
	method clear () {
		@$_ = () foreach @glyph_rows, @fg_rows, @bg_rows;
		@written_spans = map { [ 0, $columns ] } 1 .. $rows;
		return $self->_cells_changed;
	}

	method _cells_changed () {
		return $self if $_refreshing;
		return $self->mark_changed;
	}

	# What the cells show, from the widget's own state; called by the
	# renderer before it paints them. A plain canvas is drawn into by its
	# users and has nothing to do.
	method refresh () {
		return;
	}

	# A sixel picture the terminal draws over the cells; called by the
	# renderer after it painted them, on a target that shows sixel. A
	# plain canvas has none.
	method sixel_data (%frame) {
		return undef;
	}

	method refresh_for_frame () {
		$_refreshing = 1;
		try {
			$self->refresh;
		}
		catch ($error) {
			$_refreshing = 0;
			die $error;
		}
		$_refreshing = 0;
		return;
	}

	method cell ( $x, $y ) {
		my ( $column, $row ) = ( cell_coordinate( x => $x ), cell_coordinate( y => $y ) );
		return undef if $row < 0 || $row >= $rows || $column < 0 || $column >= $columns;

		my $glyph = $glyph_rows[$row][$column];
		return undef unless ref $glyph;
		return [ $glyph->[0], $fg_rows[$row][$column], $bg_rows[$row][$column] ];
	}

	method cell_at ($event) {
		return () unless @content_origin;
		my ( $column, $row ) = ( $event->x - $content_origin[0], $event->y - $content_origin[1] );
		return () if $row < 0 || $row >= $rows || $column < 0 || $column >= $columns;
		return ( $column, $row );
	}

	# Records where the frame being drawn puts the buffer. Nothing is drawn
	# from it, and the renderer calls this every frame, so it does not mark
	# the canvas changed.
	method set_content_origin ( $x, $y ) {
		@content_origin = ( $x, $y );
		return;
	}

	method content_origin () {
		return @content_origin;
	}

	method cell_row ($y) {
		return ( $glyph_rows[$y], $fg_rows[$y], $bg_rows[$y] );
	}

	method take_changed_spans () {
		my @spans;
		if ($everything_changed) {
			@spans = map { [ 0, $columns ] } 1 .. $rows;
		}
		else {
			foreach my $y ( 0 .. $#written_spans ) {
				my $span = $self->_changed_span_of($y) // next;
				$spans[$y] = $span;
			}
		}
		$self->_remember_taken( $everything_changed ? map { [ 0, $columns ] } 1 .. $rows : @written_spans );
		@written_spans      = ();
		$everything_changed = 0;
		return \@spans;
	}

	# The written columns of a row that differ from what was taken, as one
	# [from, to) span, or undef. A write never splits a wide glyph without
	# changing its first cell, so a span never starts in an unchanged one.
	method _changed_span_of ($y) {
		my $written = $written_spans[$y] // return undef;
		my ( $glyphs,       $fgs, $bgs )             = ( $glyph_rows[$y], $fg_rows[$y], $bg_rows[$y] );
		my ( $taken_glyphs, $taken_fgs, $taken_bgs ) = ( $taken_glyph_rows[$y] // [], $taken_fg_rows[$y] // [], $taken_bg_rows[$y] // [] );
		my ( $first,        $last );
		foreach my $x ( $written->[0] .. $written->[1] - 1 ) {
			next if _same_glyph( $glyphs->[$x], $taken_glyphs->[$x] ) && _same_attr( $fgs->[$x], $taken_fgs->[$x] ) && _same_attr( $bgs->[$x], $taken_bgs->[$x] );
			$first //= $x;
			$last = $x;
		}
		return defined $first ? [ $first, $last + 1 ] : undef;
	}

	method _remember_taken (@spans) {
		foreach my $y ( 0 .. $#spans ) {
			my $span    = $spans[$y] // next;
			my @columns = $span->[0] .. $span->[1] - 1;
			@{ $taken_glyph_rows[$y] //= [] }[@columns] = @{ $glyph_rows[$y] }[@columns];
			@{ $taken_fg_rows[$y] //= [] }[@columns]    = @{ $fg_rows[$y] }[@columns];
			@{ $taken_bg_rows[$y] //= [] }[@columns]    = @{ $bg_rows[$y] }[@columns];
		}
		return;
	}

	method content_insets () {
		my $padding = $self->to_config->{layout}{padding} // {};
		return map { $padding->{$_} // 0 } qw(left top right bottom);
	}

	method fit_to ( $new_columns, $new_rows ) {
		die "Term::Fabulous::Widget::Canvas: fit_to needs a non-negative integer size, got " . describe($new_columns) . " x " . describe($new_rows)
			unless grep( { defined && /\A[0-9]+\z/ } $new_columns, $new_rows ) == 2;
		return if $new_columns == $columns && $new_rows == $rows;

		foreach my $rows_of_cells ( \@glyph_rows, \@fg_rows, \@bg_rows ) {
			$#$rows_of_cells = $new_rows - 1;
			foreach my $cells (@$rows_of_cells) {
				$cells //= [];
				$#$cells = $new_columns - 1 if @$cells > $new_columns;
			}
		}
		_unset_cut_glyph( $_, $new_columns ) foreach @glyph_rows;

		( $columns, $rows ) = ( $new_columns + 0, $new_rows + 0 );
		@written_spans      = ();
		@$_                 = () foreach \@taken_glyph_rows, \@taken_fg_rows, \@taken_bg_rows;
		$everything_changed = 1;
		$self->mark_changed;
		$self->fire_event( Term::Fabulous::Event::CanvasResize->new( columns => $columns, rows => $rows ) );
		return;
	}

	# A wide glyph that no longer fits at the right edge leaves its cells unset.
	sub _unset_cut_glyph ( $glyphs, $columns ) {
		my $head = $columns - 1;
		$head-- while $head > 0 && _is_tail( $glyphs->[$head] );
		return unless ref $glyphs->[$head] && $head + $glyphs->[$head][1] > $columns;
		$glyphs->[$_] = undef foreach $head .. $columns - 1;
		return;
	}

	# Writes one glyph (undef unsets the cell). Writes that do not fit into
	# the buffer are dropped. A wide glyph partly overwritten here leaves
	# spaces in its other cells.
	method _store ( $x, $y, $glyph, $fg, $bg ) {
		my $width = defined $glyph ? $glyph->[1] : 1;
		return if $y < 0 || $y >= $rows || $x < 0 || $x + $width > $columns;

		my ( $glyphs, $fgs, $bgs ) = ( $glyph_rows[$y], $fg_rows[$y], $bg_rows[$y] );
		my ( $from, $to ) = ( $x, $x + $width );
		my $first = $glyphs->[$x];
		if ( defined $first && !ref $first ) {
			$from-- while _is_tail( $glyphs->[$from] );
			$glyphs->[$_] = $SPACE foreach $from .. $x - 1;
		}
		while ( $to < $columns && _is_tail( $glyphs->[$to] ) ) {
			$glyphs->[ $to++ ] = $SPACE;
		}

		( $glyphs->[$x], $fgs->[$x], $bgs->[$x] ) = ( $glyph, $fg, $bg );
		if ( $width > 1 ) {
			my @covered = ( $x + 1 .. $x + $width - 1 );
			@{$glyphs}[@covered] = (TAIL) x @covered;
			@{$fgs}[@covered]    = ($fg) x @covered;
			@{$bgs}[@covered]    = ($bg) x @covered;
		}

		return if $everything_changed;
		my $span = $written_spans[$y];
		if ( !defined $span ) {
			$written_spans[$y] = [ $from, $to ];
			return;
		}
		$span->[0] = $from if $from < $span->[0];
		$span->[1] = $to if $to > $span->[1];
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Canvas - A widget you draw on cell by cell

=head1 SYNOPSIS

	use Clay::XS qw(sizing_grow);
	use Term::Fabulous::Color;
	use Term::Fabulous::Widget::Canvas;

	my $canvas = Term::Fabulous::Widget::Canvas->new(
		background_color => [ 10, 10, 20, 255 ],
		layout           => { sizing => { width => sizing_grow(), height => sizing_grow() } },
	);

	# The canvas gets its size from the layout; draw when it is known.
	$canvas->on( CanvasResize => sub ($event) {
		$canvas->clear;
		$canvas->put_text( 0, 0, "Gr\x{fc}\x{df}e", '#ffcc00' );           # a character string
		$canvas->put( 3, 1, "\x{2580}", 0xFF0000, 0x0000FF );               # red over blue
		$canvas->fill( 0, 2, 10, 1, '#', Term::Fabulous::Color->rgb( 0, 200, 0 ) );
		$canvas->put( $_, $event->rows - 1, "\x{2500}", 0x808080 ) foreach 0 .. $event->columns - 1;
		return;
	} );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/example-canvas.svg" alt="Three waves in red, blue and green on a canvas, drawn with half blocks"></p>

=end html

F<examples/canvas.pl> animates three waves on a canvas and redraws only
the cells that change.

=head1 DESCRIPTION

A Canvas is a L<Term::Fabulous::Widget::Box> that holds a grid of
cells you fill yourself: any character (more exactly, any grapheme
cluster) in any foreground and background color at any cell. Use it for
plots, maps, games, images made of half blocks (see
L<Term::Fabulous::Widget::PixelCanvas>) and anything else that is not
made of boxes and text. For charts of data, the chart widgets
(L<Term::Fabulous::Widget::Chart> and its subclasses) are canvases that
draw themselves.

The cells are drawn inside the canvas's content box, that is the
canvas without its border and padding. A Canvas has every parameter of
a Box, so it can have a background, a border and padding around the
drawing.

=head2 Buffer size

The layout decides how big the canvas is, and the cell buffer follows:
before the first frame it has 0 x 0 cells, and every time the content
box gets a new size (the first frame, terminal resizes, layout
changes), the buffer is resized to it and the canvas fires a
C<CanvasResize> event (L<Term::Fabulous::Event::CanvasResize>) just
before that frame is drawn. Cells that are still inside the new size
keep their contents; a wide character cut by the new right edge is
removed. Draw in a C<CanvasResize> listener (and whenever your data
changes); drawing outside the buffer, including everything drawn
before the first frame, is silently dropped. For a canvas of a known,
constant size, use C<sizing_fixed> for both axes.

=head2 Cells

A cell is either unset, or holds one grapheme cluster (what a reader
sees as one character, for example C<e> followed by a combining accent)
with an optional foreground and an optional background color.

=over

=item * An unset cell, and a set cell without a background color, show
the canvas's C<background_color>. When the canvas has none, they show
the background of the nearest ancestor that has one (translucent ones
count; the cell is blended over it), or else the screen color of the
theme, or else (in a L<Term::Fabulous::Static>) the terminal's default
background: L<Term::Fabulous::Widget/background_below> with
C<< translucent => 1 >>.

=item * A cell without a foreground color uses the terminal's default
foreground color.

=item * A character that is two columns wide, such as most CJK
characters and many emoji, covers the cell to its right as well.
Writing into either of its cells replaces the other one with a space in
the same colors. A wide character that would cross the right edge of
the buffer is not drawn.

=item * Control characters are shown as U+FFFD (the replacement
character); a TAB is shown as a space.

=back

=head2 Colors

Every C<$fg> and C<$bg> argument accepts:

=over

=item * a packed integer C<0xRRGGBB> (fastest; C<0x000000> is black),

=item * C<undef> for "no color of its own" (see L</Cells>),

=item * a L<Term::Fabulous::Color> object,

=item * anything C<< Term::Fabulous::Color->new( color => ... ) >>
accepts: C<'#rrggbb'>, C<'rgb(r, g, b)'>, C<'hsl(h, s%, l%)'>,
C<[r, g, b]>, C<[r, g, b, a]>, C<{ r => ..., g => ..., b => ... }>, ...

=back

A color with alpha 0 counts as no color; any other alpha is drawn
fully opaque. Integers above C<0xFFFFFF> and invalid colors die.

=head2 Coordinates

C<$x> is the column and C<$y> the row in the buffer, both counted from
0 at the top-left corner of the content box. Coordinates and sizes may
be any finite numbers; they are rounded down to whole cells, so a
plotter can pass computed positions directly. C<undef>, strings that
are not numbers, C<NaN> and infinities die.

=head2 Efficient updates

The canvas remembers which cells changed since it was last drawn:
cells that hold something else now, not cells that were only written
again with what they held. Under L<Term::Fabulous>, a canvas that is in
the same place as in the previous frame and that nothing else is drawn
over sends only its changed cells to the terminal; so clearing a canvas
and drawing the same content again costs nothing on the terminal. You can therefore redraw a few cells
many times per second (an animation, a live chart) cheaply. A canvas
is drawn in full in the first frame, after it moved or changed size,
while it is scrolled, and while other widgets (including its own
children) overlap it. See L<Term::Fabulous::Render::Canvas>.

=head1 CONSTRUCTOR

=head2 new

	my $canvas = Term::Fabulous::Widget::Canvas->new(%parameters);

All parameters are optional; unknown parameters die. A Canvas takes
exactly the parameters of L<Term::Fabulous::Widget::Box>: C<id>,
C<layout>, C<background_color>, C<bordered>, C<border_color>,
C<border_style>, ... (see L<Term::Fabulous::Widget/new>). Without a
C<sizing>, the canvas has no content and therefore a 0 x 0 buffer, so
always give it a size.

=head1 METHODS

The drawing methods (C<put>, C<put_text>, C<fill>, C<erase>, C<clear>)
return the canvas, so calls chain:
C<< $canvas->clear->put_text( 0, 0, 'Score: 0' ) >>. A drawn change
appears in the next frame, also when it is drawn from a timer: the
drawing methods mark the canvas changed (see
L<Clay::UI::Role::Core::Element/mark_changed>). A Canvas also has all
methods of L<Term::Fabulous::Widget>.

=head2 put

	$canvas->put( $x, $y, $glyph );
	$canvas->put( $x, $y, $glyph, $fg );
	$canvas->put( $x, $y, $glyph, $fg, $bg );

Sets one cell. C<$glyph> is a character string (not UTF-8 bytes) of
exactly one grapheme cluster, such as C<'#'>, C<"\x{2588}"> or
C<"e\x{301}">; an empty string, several clusters or a reference die.
C<$fg> and C<$bg> are optional colors (see L</Colors>).

=head2 put_text

	$canvas->put_text( $x, $y, $text );
	$canvas->put_text( $x, $y, $text, $fg, $bg );

Writes a character string from C<($x, $y)> to the right, one cluster
per cell (two for wide characters), all in the same colors. The text
does not wrap: clusters beyond the right edge of the buffer are
dropped. C<$text> may be empty; C<undef> or a reference dies.

=head2 fill

	$canvas->fill( $x, $y, $width, $height, $glyph );
	$canvas->fill( $x, $y, $width, $height, $glyph, $fg, $bg );

Puts C<$glyph> into every cell of the rectangle that starts at
C<($x, $y)> and is C<$width> columns wide and C<$height> rows high. A
wide glyph is repeated every two columns. Parts outside the buffer are
skipped; a width or height of 0 or less fills nothing. Use
C<< fill( $x, $y, $w, $h, ' ', undef, $color ) >> for a solid colored
rectangle.

=head2 erase

	$canvas->erase( $x, $y );

Unsets one cell, so it shows the background again.

=head2 clear

	$canvas->clear;

Unsets every cell. The buffer keeps its size.

=head2 cell

	if ( my $cell = $canvas->cell( $x, $y ) ) {
		my ( $glyph, $fg_attr, $bg_attr ) = @$cell;
		...
	}

Reads one cell back. Returns C<[ $glyph, $fg, $bg ]> for a set cell, or
C<undef> for an unset cell, for the right half of a wide character and
for a position outside the buffer. C<$glyph> is the cluster as it is
shown (control characters already replaced). C<$fg> and C<$bg> are not
the colors you passed but termbox2 attribute numbers (see
L<Term::Fabulous::Render::Attr>), or C<undef> where the cell has no
color of its own; compare them with
C<Term::Fabulous::Render::Attr::cell_color_attr( fg => $color )>.

=head2 cell_at

	$canvas->on( Mouse => sub ($event) {
		my ( $x, $y ) = $canvas->cell_at($event) or return Clay::UI::Enum::Result->CONTINUE;
		$canvas->put( $x, $y, '*', 0xFFFF00 );
		return;
	} );

Translates a mouse position into buffer coordinates. Takes a
L<Term::Fabulous::Event::Mouse> (or any object with C<x> and C<y>
methods giving a terminal cell) and returns the buffer cell
C<($x, $y)> under it, based on where the canvas was drawn in the last
frame. Returns the empty list when the position is outside the buffer
(for example on the border or the padding) or before the first frame.

=head2 content_origin

	my ( $left, $top ) = $canvas->content_origin;

The terminal cell where buffer cell C<(0, 0)> was drawn in the last
frame, or the empty list before the first frame. It can lie outside the
terminal when the canvas is scrolled or partly clipped.

=head2 columns

	my $width = $canvas->columns;

The width of the buffer in cells; 0 before the first frame.

=head2 rows

	my $height = $canvas->rows;

The height of the buffer in cells; 0 before the first frame.

=head1 EVENTS

=over

=item C<CanvasResize> (L<Term::Fabulous::Event::CanvasResize>)

Fired on the canvas when the layout gives its buffer a new size, before
the frame that shows it is drawn. C<< $event->columns >> and
C<< $event->rows >> are the new size; they are also available as
C<< $canvas->columns >> and C<< $canvas->rows >>. Draw (again) in a
listener; anything drawn in it appears in the same frame.

=item C<Mouse> (L<Term::Fabulous::Event::Mouse>)

Fired for mouse buttons and the wheel over the canvas, including over its
unset cells. Use L</cell_at> to find the cell.

=item C<MouseMove> (L<Term::Fabulous::Event::MouseMove>)

Fired when the pointer moves over the canvas with no button held. It
has C<x> and C<y> like a C<Mouse> event, so L</cell_at> takes it too.

=back

=head1 MOUSE

A Canvas does nothing with the mouse by itself; listen for C<Mouse>
(and C<MouseMove>) events and use L</cell_at>. The recipe
L<Term::Fabulous::Cookbook::Canvases/Paint with the mouse (Canvas, clicks and drags)>
paints with clicks and drags.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>. The
drawing itself is done from Perl:

=for highlighter language=kdl

	use Term::Fabulous::Widget::Canvas as Canvas

	Canvas "chart" {
		sizing width=grow height="fixed(10)"
		background_color "#0a0a14"
	}

=head1 EXAMPLES

A bar chart that is redrawn whenever the canvas changes size:

=for highlighter language=perl

	use Clay::XS qw(sizing_grow sizing_fixed);
	use List::Util qw(max);
	use Term::Fabulous::Widget::Canvas;

	my @values = ( 3, 7, 2, 9, 5 );
	my $chart  = Term::Fabulous::Widget::Canvas->new(
		layout => { sizing => { width => sizing_grow(), height => sizing_fixed(8) } },
	);

	sub draw_chart () {
		my $scale = $chart->rows / max(@values);
		$chart->clear;
		foreach my $index ( 0 .. $#values ) {
			my $height = int( $values[$index] * $scale + 0.5 );
			$chart->fill( 3 * $index, $chart->rows - $height, 2, $height, "\x{2588}", 0x50A0FF );
		}
		return;
	}
	$chart->on( CanvasResize => sub ($event) { draw_chart(); return } );

Call C<draw_chart()> again whenever C<@values> changes; the next frame
shows the new bars. Complete programs are in
L<Term::Fabulous::Cookbook::Canvases>; for real charts, see
L<Term::Fabulous::Widget::BarChart>.

=head1 SUBCLASS INTERFACE

=head2 put_attrs

	$canvas->put_attrs( $x, $y, $glyph, $fg_attr, $bg_attr );

Like L</put> but without any conversion, for subclasses that draw a
lot of cells (L<Term::Fabulous::Widget::PixelCanvas>, the input
widgets). C<$x> and C<$y> must be integers; C<$fg_attr> and C<$bg_attr>
must be termbox2 attributes or C<undef>, as L</cell> returns them
(convert colors once with
C<Term::Fabulous::Render::Attr::cell_color_attr>). An C<undef> glyph
unsets the cell. Returns the canvas.

=head1 RENDERER INTERFACE

These methods are called by L<Term::Fabulous::Render::Canvas> while a
frame is drawn. Applications do not call them.

=head2 content_insets

	my ( $left, $top, $right, $bottom ) = $canvas->content_insets;

The number of cells between the widget's outer box and its content box
on each side: padding plus one cell where a border is drawn on the side
(see L<Term::Fabulous::Role::HasBorderStyle/drawn_border_sides>).

=head2 set_content_origin

	$canvas->set_content_origin( $x, $y );

Records the terminal cell where the content box starts, for
L</cell_at> and L</content_origin>.

=head2 fit_to

	$canvas->fit_to( $columns, $rows );

Resizes the buffer and fires C<CanvasResize>, unless it already has
that size. Dies unless both are non-negative integers.

=head2 refresh

	method refresh :override () { ... }

A hook for subclasses that paint from state of their own. The renderer
calls it for every canvas of a frame, after L</fit_to> and before it
paints the cells, through C<refresh_for_frame>. A plain canvas does
nothing here: its users draw into it themselves.
L<Term::Fabulous::Widget::Input> paints itself here. Cell writes made
while it runs belong to the frame being drawn, so they do not mark the
canvas changed and make no further frame due.

=head2 refresh_for_frame

	$canvas->refresh_for_frame;

Calls L</refresh> as the renderer does
(L<Term::Fabulous::Render::Canvas/plan_canvases>); you do not call it
yourself.

=head2 sixel_data

	method sixel_data :override (%frame) { ... }

A hook for subclasses that show a sixel picture over their cells, as
L<Term::Fabulous::Widget::Sixel> does. On a cell target that shows
sixel (L<Term::Fabulous::Render::Target::Sixel>), the renderer calls it
for every visible canvas of a frame, after the frame's cells are
painted (L<Term::Fabulous::Render::Canvas/sixel_placements>), with:

=over

=item C<shown>

The C<[x0, y0, x1, y1]> cells of the content box the picture covers,
counted from the content box's top left cell: the visible ones the
target can show.

=item C<covered>

The C<[x0, y0, x1, y1]> rectangles among them that the frame paints
over, in the same coordinates; they may overlap.

=item C<cell_size>

C<[width, height]>, the pixels of a cell.

=back

Returns the picture of the C<shown> cells as SIXEL data,
C<(x1 - x0) * width> pixels wide and C<(y1 - y0) * height> pixels
high, transparent in the C<covered> cells; or C<undef> for none, which a plain canvas returns.
The renderer calls it every frame, so a subclass keeps the data of the
last call while nothing changed.

=head2 take_changed_spans

	my $spans = $canvas->take_changed_spans;

An array reference indexed by row: C<[ $from, $to ]> (C<$to>
exclusive) covering the columns whose cells differ from what the last
call handed out, or C<undef> for an unchanged row; a cell written again
with the same glyph and colors does not count. After a resize, every
row is reported in full. The changes are forgotten.

=head2 cell_row

	my ( $glyphs, $fgs, $bgs ) = $canvas->cell_row($y);

The three array references holding row C<$y>. A glyph entry is
C<undef> (unset), C<''> (the right half of a wide character) or
C<[ $cluster, $columns, $base_character, @combining_characters ]>.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Charts/CANVASES> (the guide),
L<Term::Fabulous::Widget::PixelCanvas>,
L<Term::Fabulous::Event::CanvasResize>, L<Term::Fabulous::Render::Canvas>,
L<Term::Fabulous::Cookbook::Canvases>, the example program
F<examples/canvas.pl>.

=cut
