package Term::Fabulous::Widget::Text;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Events::Emitter;

our $VERSION = '0.02';

class Term::Fabulous::Widget::Text
	:isa(Term::Fabulous::Widget::TextNode)
	:does(Term::Fabulous::Role::CanParseLayout)
	:does(Term::Fabulous::Role::Themed)
	:does(Clay::UI::Role::Events::Emitter)
	:strict(params)
{
	use Clay::XS qw(CLAY_TEXT_WRAP_WORDS CLAY_TEXT_WRAP_NEWLINES CLAY_TEXT_WRAP_NONE CLAY_TEXT_ALIGN_LEFT CLAY_TEXT_ALIGN_CENTER CLAY_TEXT_ALIGN_RIGHT);
	use Clay::UI::Revision qw(bump_revision);
	use Term::Fabulous::Check qw(boolean class_names color non_negative_integer one_of);
	use Term::Fabulous::Event::TextClick;
	use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC TB_UNDERLINE);

	my %WRAP_MODE_BY_NAME      = ( words => CLAY_TEXT_WRAP_WORDS, newlines => CLAY_TEXT_WRAP_NEWLINES, none  => CLAY_TEXT_WRAP_NONE );
	my %TEXT_ALIGNMENT_BY_NAME = ( left  => CLAY_TEXT_ALIGN_LEFT, center   => CLAY_TEXT_ALIGN_CENTER,  right => CLAY_TEXT_ALIGN_RIGHT );

	field $id        :param :reader = undef;
	field $bold      :param = 0;
	field $italic    :param = 0;
	field $underline :param = 0;
	field $classes   :param = [];

	# Whether the program gave a text_color (BUILDARGS says so); without
	# one the theme's text color is drawn. The Clay::UI::Text field always
	# holds a color; the role knows whether it is an explicit one.
	field $_has_text_color :param(_has_text_color) = 0;

	ADJUST {
		$bold      = boolean( $self, bold      => $bold );
		$italic    = boolean( $self, italic    => $italic );
		$underline = boolean( $self, underline => $underline );
		$classes   = class_names( $self, classes => $classes );
		$self->set_look( text_color => $self->SUPER::text_color ) if $_has_text_color;
	}

	method _set_style ( $name, $field_ref, @new ) {
		return $$field_ref unless @new;
		$$field_ref = boolean( $self, $name => $new[0] );
		bump_revision();
		return $$field_ref;
	}

	method bold      (@new) { return $self->_set_style( bold      => \$bold,      @new ) }
	method italic    (@new) { return $self->_set_style( italic    => \$italic,    @new ) }
	method underline (@new) { return $self->_set_style( underline => \$underline, @new ) }

	# The termbox2 style bits the renderer adds to the text color.
	method style_attrs () {
		return ( $bold ? TB_BOLD : 0 ) | ( $italic ? TB_ITALIC : 0 ) | ( $underline ? TB_UNDERLINE : 0 );
	}

	# Clay::UI validates text_color before any ADJUST of this class runs,
	# so it is converted while the arguments are still a plain list.
	sub BUILDARGS ( $class, %params ) {
		return %params unless defined $params{text_color};
		$params{text_color}      = color( $class, text_color => $params{text_color} );
		$params{_has_text_color} = 1;
		return %params;
	}

	# The value a name stands for in %$value_by_name; an unknown name dies
	# with the known ones.
	sub _named ( $what, $value_by_name, $name ) {
		return $value_by_name->{ one_of( 'Term::Fabulous::Widget::Text', $what, $name, keys %$value_by_name ) };
	}

	# The reader returns the color the text is drawn in: the explicit one,
	# or the theme's. undef is not a color; reset_look returns to the theme.
	method text_color :override (@new) {
		return $self->_explicit_text_color // $self->look('color') unless @new;
		return $self->set_look( text_color => $self->SUPER::text_color( color( $self, text_color => $new[0] ) ) );
	}

	method _explicit_text_color () {
		return $self->has_look_override('text_color') ? $self->SUPER::text_color : undef;
	}

	# ---------------------------------------------------------------------
	# The theme (Term::Fabulous::Role::Themed)
	# ---------------------------------------------------------------------

	method theme_family :common () {
		return 'text';
	}

	method themed_params :common () {
		return ( text_color => [ 'color', 'normal' ] );
	}

	method look_state () {
		return 'normal';
	}

	method look_reset ($name) {
		return;
	}

	method classes (@new) {
		return [@$classes] unless @new;
		$classes = class_names( $self, classes => $new[0] );
		$self->forget_looks;
		$self->mark_changed;
		return [@$classes];
	}

	# A text that joins or leaves a tree may be in another UI, with
	# another theme, from now on.
	method tree_changed :override () {
		$self->SUPER::tree_changed;
		$self->_forget_own_looks;
		return;
	}

	# The color the text is drawn in. The nearest ancestor that colors the
	# text inside it (a Button, say) decides, given the explicit color if
	# there is one; otherwise the explicit color, or the theme's.
	method text_config :override () {
		my $config   = $self->SUPER::text_config;
		my $explicit = $self->_explicit_text_color;
		for ( my $node = $self->parent; defined $node; $node = $node->parent ) {
			next unless $node->can('child_text_color');
			my $color = $node->child_text_color($explicit) // last;
			return { %$config, text_color => $color };
		}
		return { %$config, text_color => $explicit // $self->look('color') };
	}

	# ---------------------------------------------------------------------
	# Clicks
	# ---------------------------------------------------------------------

	method click_at ( $offset, $button, $x, $y ) {
		$offset = non_negative_integer( $self, offset => $offset );
		my $text = $self->text;
		die ref($self) . ": offset $offset lies past the text (" . length($text) . " characters)" if $offset >= length $text;
		$self->fire_event(
			Term::Fabulous::Event::TextClick->new(
				button => $button,
				x      => $x,
				y      => $y,
				offset => $offset,
				_word_around( $text, $offset ),
				$self->_click_details($offset),
			)
		);
		return $self;
	}

	# The run of non-blank characters around the offset, as the word,
	# word_start and word_end parameters of a TextClick; none on a blank.
	sub _word_around ( $text, $offset ) {
		return () if substr( $text, $offset, 1 ) =~ /\s/;
		my ($head) = substr( $text, 0, $offset ) =~ /(\S*)\z/;
		my ($tail) = substr( $text, $offset ) =~ /\A(\S*)/;
		return ( word => $head . $tail, word_start => $offset - length $head, word_end => $offset + length $tail );
	}

	# What a subclass adds to a TextClick at the offset: a RichText its
	# spans and its link there.
	method _click_details ($offset) {
		return ();
	}

	method layout_properties :common () {
		return (
			font_id        => 'scalar',
			font_size      => 'scalar',
			letter_spacing => 'scalar',
			line_height    => 'scalar',
			text_color     => 'color',
			classes        => \&_parse_classes,
			bold           => 'boolean',
			italic         => 'boolean',
			underline      => 'boolean',
			text           => \&_parse_text,
			wrap_mode      => \&_parse_wrap_mode,
			text_alignment => \&_parse_text_alignment,
		);
	}

	method _parse_classes ($kid) {
		$self->classes( $self->kdl_strings($kid) );
		return;
	}

	method _parse_text ($kid) {
		my $text = $self->kdl_argument($kid);
		die "Term::Fabulous::Widget::Text: 'text' needs a string argument" unless $text->is_string;
		$self->text( $text->value );
		return;
	}

	method _parse_wrap_mode ($kid) {
		$self->wrap_mode( _named( wrap_mode => \%WRAP_MODE_BY_NAME, $self->kdl_argument($kid)->as_perl ) );
		return;
	}

	method _parse_text_alignment ($kid) {
		$self->text_alignment( _named( text_alignment => \%TEXT_ALIGNMENT_BY_NAME, $self->kdl_argument($kid)->as_perl ) );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Text - A piece of text inside a box

=head1 SYNOPSIS

	use utf8;    # this source file contains non-ASCII text
	use Term::Fabulous::Widget::Text;

	my $title = Term::Fabulous::Widget::Text->new(
		text       => 'Settings',
		text_color => [ 255, 255, 255, 255 ],
	);

	# Text is a character string, like everywhere in Term::Fabulous:
	my $greeting = Term::Fabulous::Widget::Text->new(
		id         => 'greeting',
		text       => 'Grüße',
		text_color => [ 230, 230, 230, 255 ],
	);

	# Later, change what it shows:
	$greeting->text('Hello again');

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-text.svg" alt="Colored words, a sentence wrapped left-aligned, centered and right-aligned, and text in five scripts"></p>

=end html

The program is F<examples/widgets/text.pl>.

=head1 DESCRIPTION

A Text widget shows text inside its parent widget, usually a
L<Term::Fabulous::Widget::Box>. The layout makes it as wide as its
longest line, wraps it at spaces when the parent is too narrow, and
starts a new line at every C<"\n">. Text has a color but no background
of its own: every cell shows the background that was painted below it.

A Text widget is a leaf: it cannot have children, and it has no
border, padding or background. To give text a background, a border or
a fixed size, put it in a Box. Mouse events (C<Mouse>, C<MouseMove>)
go to the box behind a text, and a Text never has the keyboard focus
(a L<Term::Fabulous::Widget::RichText> with links does). A mouse button
pressed on a character of the text also fires
L<TextClick|Term::Fabulous::Event::TextClick> on the Text, with the
character and the word under the pointer, so that the widgets around
it can react to the words that were clicked (see L</click_at>).

F<examples/text-features.pl> shows the wrap modes, line height, bold,
italic and underlined text, wide characters and control characters:

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/example-text-features.svg" alt="Text wrapped at spaces in a narrow panel and text broken only at newlines; a two-line text with line height 2; plain, bold, italic, underlined and combined styles; Latin, Japanese, emoji and combining accents ending in the same column; a tab shown as a space and control characters shown as replacement characters"></p>

=end html

L<The text section of the looks guide|Term::Fabulous::Manual::Looks/TEXT>
explains all of this with examples. The class is built on L<Clay::UI::Text>.

=head1 CONSTRUCTOR

=head2 new

	my $text = Term::Fabulous::Widget::Text->new(%parameters);

All parameters are optional; unknown parameters die. Every parameter
except C<id> also has an accessor of the same name.

=over

=item C<text>

A character string, like all text in Term::Fabulous. Default: C<''>.

Bytes read from a file, a command or a socket must be decoded first
with C<Encode::decode('UTF-8', $bytes)>; otherwise each byte is shown
as one Latin-1 character. Text read from a KDL layout is used as is.
See L<Term::Fabulous::Manual::Looks/Text is character strings>.

Control characters are never sent to the terminal: a TAB is shown as
one space and every other control character, a carriage return
included, as U+FFFD (see L<Term::Fabulous::Manual::Looks/Control characters>).
Wide characters (most CJK characters and emoji) take two cells (see
L<Term::Fabulous::Manual::Looks/Wide characters and emoji>). C<undef>
and references die.

=item C<text_color>

The color of the characters, in any format L<Term::Fabulous::Color>
accepts: C<[r, g, b, a]> (or C<[r, g, b]>), C<{ r, g, b, a }>, a string
such as C<'#ffffff'> or C<'rgb(255, 255, 255)'>, a packed C<0xRRGGBB>
integer, or a Term::Fabulous::Color object such as an item of
L<Term::Fabulous::Enum::WebColor>; it is stored as C<[r, g, b, a]>. An
alpha from 1 to 254 is drawn opaque. Default: the theme's C<text.color>
(C<[220, 223, 228, 255]> in the dark theme), or, inside a widget that
colors its texts (a L<Term::Fabulous::Widget::Button>), that widget's
text look. Pass C<[0, 0, 0, 0]> (alpha 0) for the terminal's default
foreground color. See L<Term::Fabulous::Manual::Looks/COLORS> and
L<Term::Fabulous::Manual::Looks/THEMES>.

=item C<classes>

An array reference of strings. Default: C<[]>. Names that select the
theme's variants of the C<text> family, as for
L<Term::Fabulous::Widget/classes>.

Inside a disabled L<Term::Fabulous::Widget::Button>, the text is drawn
in the button's C<disabled_color> instead, whatever its C<text_color>.

=item C<bold>

=item C<italic>

=item C<underline>

Booleans, default 0: draw the characters bold, italic or underlined.
Any true or false value; references die. Terminals show these styles
with the font they have, so a font without an italic face may show
italic text upright. They take no space and do not change the layout.
These three are the only text styles, and they apply to the whole
text; a L<Term::Fabulous::Widget::RichText> styles ranges of it. See
L<Term::Fabulous::Manual::Looks/Bold, italic and underline>.

=item C<id>

A string naming the widget, for your own use (for example to find a
Text in a tree built from a layout). Default: none. Unlike a Box's id,
it is not passed to Clay and does not need to be unique, and
L<Term::Fabulous::Widget/remove_child_with_id> does not remove Text
widgets by id (L<Term::Fabulous::Widget/remove_child> removes the widget
itself). Read it with C<< $text->id >>; there is no writer.
L<C<find_by_id>|Term::Fabulous::Widget/find_by_id> finds Text widgets by this id.

=item C<wrap_mode>

How lines are broken, one of the L<Clay::XS> constants:
C<CLAY_TEXT_WRAP_WORDS> (the default: break at C<"\n"> and, where the
text does not fit, at spaces), C<CLAY_TEXT_WRAP_NEWLINES> (break only
at C<"\n">) and C<CLAY_TEXT_WRAP_NONE> (the same as C<CLAY_TEXT_WRAP_NEWLINES>, because
Clay lays out both alike). A line
that is not broken may be wider than the parent; it is cut off at the
right edge of the terminal.

With every mode, only spaces are break points: a single word that is
wider than the space available, or text without spaces such as a
Japanese sentence, is never broken: it runs past the right edge of its parent and is cut
off only at the edge of the terminal or of an enclosing
L<Term::Fabulous::Widget::ScrollBox>. See
L<Term::Fabulous::Manual::Looks/Wrapping>.

=item C<text_alignment>

C<CLAY_TEXT_ALIGN_LEFT> (the default), C<CLAY_TEXT_ALIGN_CENTER> or
C<CLAY_TEXT_ALIGN_RIGHT>. Aligns the lines of a multi-line text against
each other, within the width of its longest line. It has no visible
effect on a single line: to center a Text in its box, set
C<child_alignment> in the box's C<layout> (see
L<Term::Fabulous::Widget/new>).

=item C<line_height>

The number of rows each line takes, an integer from 0 to 65535; other
values (such as C<1.5>) die. Default: 0, which means one row, like 1.
A line is drawn in the middle row of its rows (the upper middle row
when the number is even), so with C<2> an empty row follows every line.
See L<Term::Fabulous::Manual::Looks/Line height>.

=item C<font_id>

=item C<font_size>

=item C<letter_spacing>

Accepted because Clay::UI supports them, but without effect in a
terminal: every character is drawn in the terminal's font, one
character per cell. Each is an integer from 0 to 65535; other values
die. Defaults: C<font_id> 0, C<font_size> 16, C<letter_spacing> 0.

=back

=head1 METHODS

Besides the accessors below, a Text widget has the methods C<parent>,
C<root>, C<ui> and C<on> that every widget has (see
L<Term::Fabulous::Widget>); C<on> is rarely useful, because no events
are fired on Text widgets.

=head2 text

	my $text = $label->text;
	$label->text($new_text);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. The change shows in the next frame. The
text is a character string; the layout adapts to the new length.

=head2 text_color

	my $rgba = $label->text_color;
	$label->text_color( [ 255, 80, 80, 255 ] );
	$label->text_color('#ff5050');

Accessor. Without an argument it returns the color in use, the given
one or the theme's, as C<[r, g, b, a]>; with an argument it sets it, in
any format the constructor parameter accepts, and returns the stored
C<[r, g, b, a]>. An invalid value dies like the constructor parameter,
and so does C<undef>: C<< $label->reset_look('text_color') >> returns
the text to the theme. The change shows in the next frame.

=head2 classes

	$label->classes( ['muted'] );

Accessor for the C<classes> parameter, as
L<Term::Fabulous::Widget/classes>.

=head2 reset_look

	$label->reset_look('text_color');

Drops the given C<text_color>, so the theme's text color is drawn
again; see L<Term::Fabulous::Widget/reset_look>.

=head2 bold

	$label->bold(1);

=head2 italic

	$label->italic(1);

=head2 underline

	$label->underline(1);

Accessors for the constructor parameters of the same names (0 or 1).
Without an argument they return the current value; with an argument
they set it and return the new value. The change shows in the next
frame.

=head2 style_attrs

	my $bits = $label->style_attrs;

The termbox2 style bits (C<TB_BOLD>, C<TB_ITALIC>, C<TB_UNDERLINE>, see
L<Term::Fabulous::Termbox>) of the current C<bold>, C<italic> and
C<underline> values, combined; 0 for plain text. The renderer adds them
to the text color.

=head2 id

	my $id = $label->id;

The C<id> given to the constructor, or C<undef>. There is no writer.

=head2 wrap_mode

	$label->wrap_mode(CLAY_TEXT_WRAP_NONE);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. The change shows in the next frame. The
reader returns C<undef> when it was never set, which behaves as
C<CLAY_TEXT_WRAP_WORDS>.

=head2 text_alignment

	$label->text_alignment(CLAY_TEXT_ALIGN_RIGHT);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. The change shows in the next frame. The
reader returns C<undef> when it was never set, which behaves as
C<CLAY_TEXT_ALIGN_LEFT>.

=head2 line_height

	$label->line_height(2);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. The change shows in the next frame.

=head2 font_id

	$label->font_id(1);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. It has no effect in a terminal.

=head2 font_size

	$label->font_size(16);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. It has no effect in a terminal; the
default is 16.

=head2 letter_spacing

	$label->letter_spacing(0);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. It has no effect in a terminal.

=head2 tree_changed

Clay::UI calls it on every widget of a subtree whose place in a tree
changed (see L<Clay::UI::Role::Layout::HasParent/tree_changed>). A Text
forgets the looks it fetched here, as
L<Term::Fabulous::Widget/tree_changed> does.

=head2 click_at

	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT);

	$text->click_at( $offset, TB_KEY_MOUSE_LEFT, $x, $y );

Fires L<TextClick|Term::Fabulous::Event::TextClick> on the widget for a
press of the mouse button (C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_MIDDLE>
or C<TB_KEY_MOUSE_RIGHT>) on the character at C<$offset> of the text,
with the pointer at the cell C<$x>, C<$y>. The event carries the word
the character belongs to (the run of non-blank characters around it).
L<Term::Fabulous> calls it after the C<Mouse> event of every button
press on a character of the text; call it yourself to click a text in
a test. An offset that is not a character of the text dies. Returns
the widget.

=head1 EVENTS

A Text fires C<TextClick> (L<Term::Fabulous::Event::TextClick>) when a
mouse button is pressed on one of its characters; it bubbles to the
widgets around the text. The recipe
L<Term::Fabulous::Cookbook::KeyboardAndMouse/React to a click on a word (TextClick)>
looks up the clicked word. A Text can fire events of your own with
C<fire_event> (L<Clay::UI::Role::Events::Emitter>), and C<on> adds
listeners to it.

=head1 KDL PROPERTIES

=for highlighter language=kdl

	Text "greeting" {
		text "Gr\u{fc}\u{df}e, world"
		text_color "#e6e6e6"
		bold #true
		line_height 2
		wrap_mode newlines
		text_alignment center
	}

The node's argument (C<"greeting">) is the C<id>. Inside the block:

=over

=item C<text "...">

Exactly one string. It is used as is, so write any characters directly
(KDL files are UTF-8).

=item C<text_color "...">

Exactly one argument: any color string L<Term::Fabulous::Color>
understands, such as C<"#ffffff">, C<"rgb(255, 255, 255)"> or
C<"hsl(0, 0%, 100%)">.

=item C<bold #true>

=item C<italic #true>

=item C<underline #true>

Exactly one boolean each: C<#true>, C<#false>, C<1> or C<0>.

=item C<wrap_mode words>

Exactly one name: C<words> (C<CLAY_TEXT_WRAP_WORDS>), C<newlines>
(C<CLAY_TEXT_WRAP_NEWLINES>) or C<none> (C<CLAY_TEXT_WRAP_NONE>). See
the C<wrap_mode> parameter of L</new>.

=item C<text_alignment left>

Exactly one name: C<left> (C<CLAY_TEXT_ALIGN_LEFT>), C<center>
(C<CLAY_TEXT_ALIGN_CENTER>) or C<right> (C<CLAY_TEXT_ALIGN_RIGHT>). See
the C<text_alignment> parameter of L</new>.

=item C<line_height N>

=item C<font_id N>

=item C<font_size N>

=item C<letter_spacing N>

One integer each; see L</new>. C<font_id>, C<font_size> and
C<letter_spacing> have no effect in a terminal.

=back

An unknown C<wrap_mode> or C<text_alignment> name dies with the known
names. Any other property dies. A Text node cannot have child widgets.

=head1 SUBCLASS INTERFACE

These methods are used by L<Term::Fabulous::Layout>; you do not call
them yourself.

=head2 layout_properties

=for highlighter language=perl

	my %kind_of = Term::Fabulous::Widget::Text->layout_properties;

The table of the properties a layout may set (see
L<Term::Fabulous::Role::CanParseLayout/layout_properties>): C<font_id>,
C<font_size>, C<letter_spacing> and C<line_height> are scalars,
C<text_color> is a color, C<bold>, C<italic> and C<underline> are
booleans, and C<text>, C<wrap_mode> and
C<text_alignment> are structured properties the Text parses itself; see
L</KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Looks/TEXT>, L<Term::Fabulous::Widget::Box>,
L<Term::Fabulous::Widget::RichText>, L<Term::Fabulous::Unicode>,
L<Clay::UI::Text>,
L<Term::Fabulous::Cookbook::GettingStarted/Wrap, align and space text>,
L<Term::Fabulous::Cookbook::GettingStarted/Show non-ASCII text (umlauts, CJK, combining accents)>.

=cut
