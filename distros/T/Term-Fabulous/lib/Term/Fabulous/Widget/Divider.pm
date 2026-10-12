package Term::Fabulous::Widget::Divider;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.02';

class Term::Fabulous::Widget::Divider
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use Clay::XS qw(sizing_grow);
	use List::Util qw(max);
	use Term::Fabulous::Check qw(boolean non_negative_integer one_of optional string);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Termbox qw(TB_BOLD);
	use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns string_columns);

	# The glyphs of a border style, by index: the top side runs along a
	# horizontal line, the left side along a vertical one.
	use constant HORIZONTAL_GLYPH => 1;
	use constant VERTICAL_GLYPH   => 3;

	my @POSITIONS = qw(start center end);

	field $vertical      :param = 0;
	field $text          :param = '';
	field $text_position :param = 'center';
	field $text_margin   :param = 1;
	field $text_padding  :param = 1;
	field $glyph         :param = undef;
	field $bold          :param = 0;

	ADJUST {
		$vertical      = boolean( $self, vertical => $vertical );
		$text          = string( $self, text => $text );
		$text_position = one_of( $self, text_position => $text_position, @POSITIONS );
		$text_margin   = non_negative_integer( $self, text_margin  => $text_margin );
		$text_padding  = non_negative_integer( $self, text_padding => $text_padding );
		$glyph         = $self->_checked_glyph($glyph);
		$bold          = boolean( $self, bold => $bold );
	}

	method theme_family :common () {
		return 'divider';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params, line_style => [ 'line.style', 'normal', 'border_style' ], color => [ 'line.color', 'normal', 'cell_color' ],
			text_color => [ 'text', 'normal', 'cell_color' ]
		);
	}

	method _checked_glyph ($value) {
		return optional( \&Term::Fabulous::Check::glyph, $self, glyph => $value );
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method _set ( $field_ref, $value ) {
		$$field_ref = $value;
		$self->mark_changed;
		return $$field_ref;
	}

	method vertical      (@new) { return @new ? $self->_set( \$vertical, boolean( $self, vertical => $new[0] ) )                      : $vertical }
	method text          (@new) { return @new ? $self->_set( \$text, string( $self, text => $new[0] ) )                               : $text }
	method text_position (@new) { return @new ? $self->_set( \$text_position, one_of( $self, text_position => $new[0], @POSITIONS ) ) : $text_position }
	method text_margin   (@new) { return @new ? $self->_set( \$text_margin, non_negative_integer( $self, text_margin => $new[0] ) )   : $text_margin }
	method text_padding  (@new) { return @new ? $self->_set( \$text_padding, non_negative_integer( $self, text_padding => $new[0] ) ) : $text_padding }
	method glyph         (@new) { return @new ? $self->_set( \$glyph, $self->_checked_glyph( $new[0] ) )                              : $glyph }
	method bold          (@new) { return @new ? $self->_set( \$bold, boolean( $self, bold => $new[0] ) )                              : $bold }

	method line_style (@new) {
		return @new ? $self->set_look( line_style => $new[0] ) : $self->look_value('line_style') // Term::Fabulous::Enum::BorderStyle->Solid;
	}
	method color      (@new) { return @new ? $self->set_look( color      => $new[0] ) : $self->look_value('color') }
	method text_color (@new) { return @new ? $self->set_look( text_color => $new[0] ) : $self->look_value('text_color') }

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			( map { $_ => 'boolean' } qw(vertical bold) ),
			( map { $_ => 'scalar' } qw(text text_position text_margin text_padding glyph) ),
		);
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# The glyph the line is drawn with.
	method line_glyph () {
		return $glyph // $self->line_style->glyphs->[ $vertical ? VERTICAL_GLYPH : HORIZONTAL_GLYPH ];
	}

	# The clusters of the text, each with its columns; a vertical divider
	# shows them one below the other.
	method _text_clusters () {
		return map { [ $_, cluster_columns($_) ] } grapheme_clusters($text);
	}

	# The cells the text takes along the line, padding included; 0 without
	# a text.
	method _text_length () {
		return 0 unless length $text;
		return 2 * $text_padding + ( $vertical ? scalar( $self->_text_clusters ) : string_columns($text) );
	}

	# The cells the line needs at least: the text with a cell of line on
	# each side, and the margin where the text sits at an end.
	method _min_length () {
		my $length = $self->_text_length;
		return 0 unless $length;
		return $length + 2 + ( $text_position eq 'center' ? 0 : $text_margin );
	}

	# The length of the line, which grows along it, and its thickness: one
	# cell, or the widest cluster of a vertical text.
	method natural_size () {
		my $thickness = $vertical ? max( 1, map { $_->[1] } $self->_text_clusters ) : 1;
		my $length    = sizing_grow( $self->_min_length );
		return $vertical ? ( $thickness, $length ) : ( $length, $thickness );
	}

	# Where the text starts along the line, or undef when it does not fit.
	method _text_start ($length) {
		my $text_length = $self->_text_length or return undef;
		return undef if $text_length > $length;
		return $text_margin < $length - $text_length ? $text_margin : 0 if $text_position eq 'start';
		return $length - $text_length - ( $text_margin < $length - $text_length ? $text_margin : 0 ) if $text_position eq 'end';
		return int( ( $length - $text_length ) / 2 );
	}

	method paint () {
		my ( $columns, $rows ) = ( $self->columns, $self->rows );
		my $line_fg = $self->color_attr( $self->color );
		my $text_fg = ( $self->color_attr( $self->text_color ) // 0 ) | ( $bold ? TB_BOLD : 0 );
		my $line    = $self->line_glyph;

		if ($vertical) {
			my $x     = int( ( $columns - 1 ) / 2 );
			my $start = $self->_text_start($rows);
			$self->put_attrs( $x, $_, $line, $line_fg, undef ) foreach 0 .. $rows - 1;
			return unless defined $start;
			my @clusters = $self->_text_clusters;
			my $y        = $start + $text_padding;
			$self->put_attrs( $x, $_,   ' ',     undef,    undef ) foreach $start .. $start + $self->_text_length - 1;
			$self->put_attrs( $x, $y++, $_->[0], $text_fg, undef ) foreach @clusters;
			return;
		}

		my $y     = int( ( $rows - 1 ) / 2 );
		my $start = $self->_text_start($columns);
		$self->fill_attrs( 0, $y, $columns, $line, $line_fg, undef );
		return unless defined $start;
		$self->fill_attrs( $start, $y, $self->_text_length, ' ', undef, undef );
		$self->paint_text( $start + $text_padding, $y, $text, $text_fg, undef );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Divider - A line between widgets, with an
optional text

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Divider;
	use Term::Fabulous::Enum::BorderStyle;

	# A line across the parent:
	my $rule = Term::Fabulous::Widget::Divider->new;

	# With a text in the middle, at the start or at the end:
	my $section = Term::Fabulous::Widget::Divider->new( text => 'Settings' );
	my $heading = Term::Fabulous::Widget::Divider->new( text => 'Files', text_position => 'start', bold => 1 );
	my $footer  = Term::Fabulous::Widget::Divider->new( text => 'end of list', text_position => 'end' );

	# Heavier, in color, or vertical between two columns:
	my $heavy  = Term::Fabulous::Widget::Divider->new( line_style => Term::Fabulous::Enum::BorderStyle->Double, color => '#61afef' );
	my $column = Term::Fabulous::Widget::Divider->new( vertical => 1 );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-divider.svg" alt="Dividers: a plain line, texts at the start, the center and the end, double and heavy lines in colors, and a vertical divider with a text between two columns"></p>

=end html

=head1 DESCRIPTION

The picture shows dividers in their forms: a plain line, lines with a
text at the start, in the center and at the end, lines in other styles
and colors, and a vertical divider with a text between two columns. The
program is F<examples/widgets/divider.pl>.

A divider separates the widgets above and below it (or left and right
of it, when it is vertical) with a line:

=for highlighter language=text

	────────────── Settings ──────────────
	── Files ─────────────────────────────
	───────────────────────── end of list ──

The line is drawn with the horizontal (or vertical) glyph of a
L<Term::Fabulous::Enum::BorderStyle>, C<Solid> unless told otherwise,
or with any glyph of your own. The text sits on the line with
C<text_padding> spaces on each side, and, at the start or the end,
C<text_margin> cells of line between it and the edge. A vertical
divider writes its text downwards, one character per row. A text that
does not fit is left out, and the line is drawn alone.

A divider takes no input and has no natural length of its own: it
grows along its line to the space its parent gives it (see L</SIZE>),
and is one cell thick. Being a L<Term::Fabulous::Widget::Display>, it
is painted again only when something about it changed.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $divider = Term::Fabulous::Widget::Divider->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters, ...)
and the ones below. All are optional; unknown parameters die.

=over

=item C<vertical>

A boolean. Default: 0, a horizontal line. True draws a vertical line
and writes the text downwards. Stored as 1 or 0; a reference dies.

=item C<text>

A character string. Default: C<''> (no text). Dies if not a string.

=item C<text_position>

C<start>, C<center> (the default) or C<end>: where the text sits along
the line. Anything else dies.

=item C<text_margin>

A non-negative integer. Default: 1. The cells of line between the edge
and the text when it sits at the start or the end. When the line is
too short for the margin, the text moves to the edge.

=item C<text_padding>

A non-negative integer. Default: 1. The spaces on each side of the
text.

=item C<line_style>

A L<Term::Fabulous::Enum::BorderStyle> item, or the name of one
(C<'Double'>). Default: the theme's C<divider.line.style>, C<Solid> in
the built-in themes. The line is drawn with the style's
top glyph, or its left glyph when the divider is vertical:
C<Solid> and C<Round> give a thin line, C<Heavy> a thick one,
C<Double> a double line, C<Dashed> a dashed one, C<Ascii> C<-> or C<|>,
C<Thick>, C<Block> and the shade styles block characters. Anything
else dies, naming the known styles.

=item C<glyph>

A single character one column wide, or C<undef>. Default: C<undef>,
the glyph of C<line_style>. A glyph of your own for the line, such as
C<'='> or C<'.'>; it wins over C<line_style>. Anything else dies.

=item C<color>

The color of the line, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. Default: the theme's
C<divider.line.color>, C<[90, 96, 110, 255]> in the dark theme, a gray.

=item C<text_color>

The color of the text. Default: the theme's C<divider.text>,
C<[150, 160, 180, 255]> in the dark theme, a lighter
gray.

=item C<bold>

A boolean. Default: 0. Whether the text is bold.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Display> (C<mark_changed>, the
Box and Canvas methods), plus an accessor for each constructor
parameter. Without an argument each returns the current value; with
one it sets the value, checked as C<new> checks it, marks the divider
changed (so the next frame paints it) and returns the new value. An
invalid value dies and leaves the old one.

=head2 vertical

	$divider->vertical(1);

Returns 1 or 0.

=head2 text

	$divider->text('Advanced');

=head2 text_position

	$divider->text_position('start');

=head2 text_margin

	$divider->text_margin(4);

=head2 text_padding

	$divider->text_padding(0);

=head2 line_style

	$divider->line_style( Term::Fabulous::Enum::BorderStyle->Heavy );
	$divider->line_style('Heavy');

The reader returns the L<Term::Fabulous::Enum::BorderStyle> item, also
when a name was written.

=head2 glyph

	$divider->glyph('=');
	$divider->glyph(undef);    # back to the style's glyph

=head2 color

	$divider->color('#61afef');

The reader returns C<[r, g, b, a]>.

=head2 text_color

	$divider->text_color( [ 255, 255, 255 ] );

The reader returns C<[r, g, b, a]>.

=head2 bold

	$divider->bold(1);

Returns 1 or 0.

=head2 line_glyph

	my $glyph = $divider->line_glyph;    # "\x{2500}"

The glyph the line is drawn with now: C<glyph>, or the glyph of
C<line_style> for the divider's direction. Read-only.

=head1 SIZE

A divider grows along its line: without a C<sizing> in its C<layout>
it is as wide (or, vertical, as high) as its parent lets it be, and
one cell thick (a vertical divider is as thick as its widest
character). With a text, the length is at least the text with its
padding, a cell of line on each side and the margin. Inside a parent
that fits its content, a divider without a text has no length to grow
into; give it a fixed sizing then:

	layout => { sizing => { width => sizing_fixed(30) } }

A horizontal divider that is more than one row high draws its line in
the middle row; a vertical one that is wider than its line draws it in
the middle column. See L<Term::Fabulous::Widget::Display/Size>.

=head1 EVENTS

A divider fires no events of its own. It paints every cell of its
line, so it receives C<Mouse> events for clicks on it.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<vertical> and C<bold> (C<#true> / C<#false>), C<text>,
C<text_position>, C<text_margin>, C<text_padding>, C<line_style> (the
name of a border style) and C<glyph> (strings), and C<color> and
C<text_color> (color strings):

=for highlighter language=kdl

	use Term::Fabulous::Widget::Divider as Divider

	Divider "settings" {
		text "Settings"
		text_position "start"
		line_style "Double"
		color "#61afef"
		bold #true
	}

=head1 EXAMPLES

=head2 A section heading

=for highlighter language=perl

	my $heading = Term::Fabulous::Widget::Divider->new(
		text          => 'Network',
		text_position => 'start',
		text_margin   => 2,
		bold          => 1,
		text_color    => [ 255, 255, 255, 255 ],
	);

=head2 Two columns with a line between them

	use Clay::XS qw(sizing_grow);

	my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$row->add_child( $left, Term::Fabulous::Widget::Divider->new( vertical => 1 ), $right );

=head1 SEE ALSO

L<Term::Fabulous::Widget::Display>, L<Term::Fabulous::Enum::BorderStyle>,
L<Term::Fabulous::Manual::Layout/DIVIDERS>,
L<Term::Fabulous::Manual::Looks/BORDERS>.

=cut
