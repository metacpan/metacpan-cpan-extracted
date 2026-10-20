package Term::Fabulous::Widget::Text;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Events::Emitter;
use Term::Fabulous::Role::MarkedText;

our $VERSION = '0.05';

class Term::Fabulous::Widget::Text
	:isa(Term::Fabulous::Widget::TextNode)
	:does(Term::Fabulous::Role::CanParseLayout)
	:does(Term::Fabulous::Role::Themed)
	:does(Clay::UI::Role::Events::Emitter)
	:does(Term::Fabulous::Role::MarkedText)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::UI::Revision qw(bump_revision);
	use Clay::XS qw(CLAY_TEXT_WRAP_WORDS CLAY_TEXT_WRAP_NEWLINES CLAY_TEXT_WRAP_NONE CLAY_TEXT_ALIGN_LEFT CLAY_TEXT_ALIGN_CENTER CLAY_TEXT_ALIGN_RIGHT);
	use List::Util qw(first min sum0);
	use Term::Fabulous::Check qw(boolean class_names color non_negative_integer one_of positive_integer);
	use Term::Fabulous::Color;
	use Term::Fabulous::Event::LinkActivate;
	use Term::Fabulous::Event::TextClick;
	use Term::Fabulous::Render::Attr qw(color_attr);
	use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC TB_UNDERLINE TB_KEY_MOUSE_LEFT);
	use Term::Fabulous::Text::Markup qw(parse_markup);
	use Term::Fabulous::Text::Marks;
	use Term::Fabulous::Theme;
	use Term::Fabulous::Unicode qw(string_columns);

	my %WRAP_MODE_BY_NAME      = ( words => CLAY_TEXT_WRAP_WORDS, newlines => CLAY_TEXT_WRAP_NEWLINES, none  => CLAY_TEXT_WRAP_NONE );
	my %TEXT_ALIGNMENT_BY_NAME = ( left  => CLAY_TEXT_ALIGN_LEFT, center   => CLAY_TEXT_ALIGN_CENTER,  right => CLAY_TEXT_ALIGN_RIGHT );

	# The keys a focused text uses; an action returns whether it did
	# anything, and a key that did nothing goes on to the ancestors.
	my %ACTION_OF_KEY = (
		Left  => sub ($self) { $self->select_previous_link },
		Right => sub ($self) { $self->select_next_link },
		Enter => sub ($self) { $self->activate_link },
	);

	field $id        :param :reader = undef;
	field $bold      :param = 0;
	field $italic    :param = 0;
	field $underline :param = 0;
	field $classes   :param = [];

	# Whether the program gave a text_color (BUILDARGS says so); without
	# one the theme's text color is drawn. The Clay::UI::Text field always
	# holds a color; the role knows whether it is an explicit one.
	field $_has_text_color :param(_has_text_color) = 0;

	# The markup the text, spans and links came from, or undef when they
	# were given directly.
	field $markup :param = undef;

	# The spans, the highlights (what a search marks, painted over the
	# spans) and the links of the text, with the count of its changes
	# (Term::Fabulous::Text::Marks).
	field $marks;

	# The selected link (the one Enter follows) and the one under the
	# mouse pointer, as indices into the links.
	field $selected_link = undef;
	field $hovered_link  = undef;

	# Whether the key and focus listeners are registered: only once the
	# text has a link, since only then it can take the focus.
	field $listening = 0;

	# The runs of the whole text (see line_styles), computed on demand and
	# dropped whenever the text, its styles, its links or the theme change.
	field $runs            = undef;
	field $runs_generation = -1;

	# Markup is parsed before the parent sees the text, so that a markup
	# string is just another way to give text, spans and links. Clay::UI
	# validates text_color before any ADJUST of this class runs, so it is
	# converted while the arguments are still a plain list.
	sub BUILDARGS ( $class, %params ) {
		if ( defined $params{markup} ) {
			die "Term::Fabulous::Widget::Text: markup cannot be given together with text or spans or links" if exists $params{text} || exists $params{spans} || exists $params{links};
			@params{qw(text spans links)} = parse_markup( $params{markup} );
		}
		return %params unless defined $params{text_color};
		$params{text_color}      = color( $class, text_color => $params{text_color} );
		$params{_has_text_color} = 1;
		return %params;
	}

	ADJUST :params ( :$spans //= [], :$links //= [] ) {
		$bold      = boolean( $self, bold      => $bold );
		$italic    = boolean( $self, italic    => $italic );
		$underline = boolean( $self, underline => $underline );
		$classes   = class_names( $self, classes => $classes );
		$self->set_look( text_color => $self->SUPER::text_color ) if $_has_text_color;

		$marks = Term::Fabulous::Text::Marks->new( owner => ref($self), text => $self->SUPER::text, spans => $spans, links => $links );
		$self->_listen if $marks->link_count;
	}

	# ---------------------------------------------------------------------
	# Style words and the text color
	# ---------------------------------------------------------------------

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
	# another theme, from now on; the runs were made with the old one.
	method tree_changed :override () {
		$self->SUPER::tree_changed;
		$self->_forget_own_looks;
		$runs = undef;
		return;
	}

	# The color the text is drawn in. The nearest ancestor that colors the
	# text inside it (a Button, say) decides, given the explicit color if
	# there is one; otherwise the explicit color, or the theme's.
	method text_config :override () {
		my $config   = $self->SUPER::text_config;
		my $explicit = $self->_explicit_text_color;
		my $colorer  = first { $_->can('child_text_color') } $self->ancestors;
		my $color    = defined $colorer ? $colorer->child_text_color($explicit) : undef;
		return { %$config, text_color => $color // $explicit // $self->look('color') };
	}

	# ---------------------------------------------------------------------
	# The text, its spans and its markup
	# ---------------------------------------------------------------------

	# Setting the text drops the spans, the highlights and the links: they
	# pointed into the old one.
	method text :override (@new) {
		return $self->SUPER::text unless @new;
		my $text = $self->SUPER::text(@new);
		$marks->set_text($text);
		$markup = undef;
		$self->_forget_link_state;
		$self->_links_changed;
		return $text;
	}

	method markup (@new) {
		return $markup unless @new;
		my ( $text, $spans, $links ) = parse_markup( $new[0] );
		$self->SUPER::text($text);
		$marks->set_text($text)->set_spans($spans);
		$self->_forget_link_state;
		$marks->add_link( @{$_}[ 2, 0, 1 ] ) foreach @$links;
		$self->_listen if @$links && !$listening;
		$markup = $new[0];
		$self->_links_changed;
		return $markup;
	}

	# Term::Fabulous::Role::MarkedText: the marks and what follows from a
	# change of them. Spans given by hand replace the markup's.
	method text_marks () {
		return $marks;
	}

	method marks_changed ($is_content) {
		$markup = undef if $is_content;
		$self->_forget_runs;
		return;
	}

	method _forget_runs () {
		$runs = undef;
		bump_revision();
		return;
	}

	# ---------------------------------------------------------------------
	# Links
	# ---------------------------------------------------------------------

	method links () {
		return $marks->links;
	}

	# The selected and the hovered link stay the same links. The first
	# link makes the text able to take the focus, so the key and focus
	# listeners start here.
	method add_link ( $target, $start = 0, $end = undef ) {
		my $position = $marks->add_link( $target, $start, $end );
		$selected_link++ if defined $selected_link && $selected_link >= $position;
		$hovered_link++ if defined $hovered_link   && $hovered_link >= $position;
		$self->_listen unless $listening;
		$markup = undef;
		$self->_links_changed;
		return $self;
	}

	method clear_links () {
		$markup = undef;
		$marks->clear_links;
		$self->_forget_link_state;
		$self->_links_changed;
		return $self;
	}

	method link_at ($offset) {
		return $marks->link_at($offset);
	}

	method _listen () {
		$listening = 1;
		my $continue = Clay::UI::Enum::Result->CONTINUE;
		$self->on(
			KeyPress => sub ( $self, $event ) {
				my $action = $ACTION_OF_KEY{ $event->main_key_name // '' } // return $continue;
				return $action->($self) ? undef : $continue;
			},
			owner => $self
		);
		$self->on( OnFocus => sub ( $self, $event ) { $self->select_next_link unless defined $self->selected_link; return $continue }, owner => $self );
		$self->on( OnBlur  => sub ( $self, $event ) { $self->select_link(undef);                                   return $continue }, owner => $self );
		return;
	}

	# Without telling the focus: a text that gets new links at once keeps
	# the focus.
	method _forget_link_state () {
		( $selected_link, $hovered_link ) = ();
		return;
	}

	# Whether the widget can take the focus may have changed with its links.
	method _links_changed () {
		$self->_forget_runs;
		$self->focus_eligibility_changed;
		return;
	}

	method _checked_link_index ( $what, $index ) {
		return undef unless defined $index;
		$index = non_negative_integer( $self, $what, $index );
		my $count = $marks->link_count;
		die "Term::Fabulous::Widget::Text: $what $index is not a link; the text has $count links" if $index >= $count;
		return $index;
	}

	method selected_link () {
		return $selected_link;
	}

	method select_link ($index) {
		$index = $self->_checked_link_index( link => $index );
		return $self if ( $index // -1 ) == ( $selected_link // -1 );
		$selected_link = $index;
		$self->_forget_runs;
		return $self;
	}

	# The selection stops at the first and the last link.
	method select_next_link () {
		my $next = defined $selected_link ? $selected_link + 1 : 0;
		return 0 if $next >= $marks->link_count;
		$self->select_link($next);
		return 1;
	}

	method select_previous_link () {
		my $previous = defined $selected_link ? $selected_link - 1 : $marks->link_count - 1;
		return 0 if $previous < 0;
		$self->select_link($previous);
		return 1;
	}

	method activate_link (@index) {
		my $index = @index ? $self->_checked_link_index( link => $index[0] ) : $selected_link;
		return 0 unless defined $index;
		my ( $start, $end, $target ) = @{ $marks->links->[$index] };
		$self->fire_event( Term::Fabulous::Event::LinkActivate->new( link => $target, index => $index, start => $start, end => $end ) );
		return 1;
	}

	method hovered_link () {
		return $hovered_link;
	}

	method hover_link ($index) {
		$index = $self->_checked_link_index( link => $index );
		return $self if ( $index // -1 ) == ( $hovered_link // -1 );
		$hovered_link = $index;
		$self->_forget_runs;
		return $self;
	}

	# A text takes the focus while it has links to select.
	method accepts_focus :override () {
		return $marks->link_count ? 1 : 0;
	}

	# ---------------------------------------------------------------------
	# Searching (Term::Fabulous::Role::Searchable, through
	# Term::Fabulous::Role::MarkedText): the one text
	# ---------------------------------------------------------------------

	# The text shows itself; where a character lies is known once it was
	# painted (Term::Fabulous::Render::Frame's text_rows).
	method reveal_text ( $key, $offset ) {
		return [ $self, undef ];
	}

	# ---------------------------------------------------------------------
	# Height before layout
	# ---------------------------------------------------------------------

	# The rows the text takes in the given number of columns, as Clay will
	# wrap it: at the spaces and the line breaks for the words mode, at the
	# line breaks only for the newlines mode, never for none.
	method estimated_rows ($columns) {
		$columns = positive_integer( $self, columns => $columns );
		return length $self->text ? 1 : 0 if $self->_stays_on_one_line;
		my @lines = split /\n/, $self->text, -1;
		return scalar @lines unless $self->_wraps_words;
		return sum0 map { _wrapped_rows( $_, $columns ) } @lines;
	}

	# The row, from 0, that the character at the offset lies on when the
	# text is wrapped to the columns, counted as estimated_rows counts.
	method row_of_offset ( $offset, $columns ) {
		$offset  = min( non_negative_integer( $self, offset => $offset ), length $self->text );
		$columns = positive_integer( $self, columns => $columns );
		return 0 if $self->_stays_on_one_line;
		my @lines  = split /\n/, substr( $self->text, 0, $offset ), -1;
		my $last   = pop(@lines) // '';
		my $before = $self->_wraps_words ? sum0( map { _wrapped_rows( $_, $columns ) } @lines ) : scalar @lines;
		my $rest   = ( split /\n/, substr( $self->text, $offset - length $last ), 2 )[0] // '';
		return $before + ( $self->_wraps_words ? _row_in_line( $rest, length $last, $columns ) : 0 );
	}

	method _wraps_words () {
		return ( $self->wrap_mode // CLAY_TEXT_WRAP_WORDS ) == CLAY_TEXT_WRAP_WORDS ? 1 : 0;
	}

	# Clay lays out the none mode as one line, newlines included.
	method _stays_on_one_line () {
		return ( $self->wrap_mode // CLAY_TEXT_WRAP_WORDS ) == CLAY_TEXT_WRAP_NONE ? 1 : 0;
	}

	# Clay wraps a line at the spaces, and only there (a no-break space is
	# part of its word). It measures every word together with the space
	# after it, and a word that does not fit on the row starts the next
	# one; a word wider than the row has a row of its own, and runs past
	# its end.
	sub _wrapped_rows ( $line, $columns ) {
		return 1 + _row_in_line( $line, length $line, $columns );
	}

	# The row of the word that holds the character at the offset of a line
	# (the last word, past its end).
	sub _row_in_line ( $line, $offset, $columns ) {
		my @words = split / /, $line, -1;
		my ( $row, $used, $position ) = ( 0, 0, 0 );
		foreach my $index ( 0 .. $#words ) {
			my $width = _columns_of( $words[$index] ) + ( $index < $#words ? 1 : 0 );
			if ( $used > 0 && $used + $width > $columns ) { ( $row, $used ) = ( $row + 1, $width ) }
			else                                          { $used += $width }
			$position += length( $words[$index] ) + 1;
			last if $offset < $position;
		}
		return $row;
	}

	# A printable ASCII character takes one column. Most words are such,
	# and asking Unicode for every word takes three times as long.
	sub _columns_of ($word) {
		return $word =~ /\A[\x20-\x7E]*\z/ ? length $word : string_columns($word);
	}

	# ---------------------------------------------------------------------
	# Clicks
	# ---------------------------------------------------------------------

	# Fires TextClick with what lies at the offset; a left click on a link
	# selects and follows it.
	method click_at ( $offset, $button, $x, $y ) {
		$offset = non_negative_integer( $self, offset => $offset );
		my $text = $self->text;
		die ref($self) . ": offset $offset lies past the text (" . length($text) . " characters)" if $offset >= length $text;
		my $index = $self->link_at($offset);
		$self->fire_event(
			Term::Fabulous::Event::TextClick->new(
				button => $button,
				x      => $x,
				y      => $y,
				offset => $offset,
				_word_around( $text, $offset ),
				spans => [ grep { $_->[0] <= $offset && $offset < $_->[1] } @{ $self->spans } ],
				defined $index ? ( link => $marks->links->[$index][2], link_index => $index ) : (),
			)
		);
		return $self unless $button == TB_KEY_MOUSE_LEFT && defined $index;
		$self->select_link($index);
		$self->activate_link($index);
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

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# The runs the renderer paints a line with: the part of the text's runs
	# that covers the characters [offset, offset + length). A text without
	# spans, highlights or links has none; the renderer paints it plain.
	method line_styles ( $offset, $length ) {
		return [] if $length <= 0 || !$marks->has_marks;
		my $generation = Term::Fabulous::Theme::generation();
		if ( !defined $runs || $runs_generation != $generation ) {
			$runs            = $self->_runs_of_text;
			$runs_generation = $generation;
		}

		my @slice;
		my $position = 0;
		foreach my $run (@$runs) {
			my $run_start = $position;
			$position += $run->[0];
			next if $position <= $offset;
			last if $run_start >= $offset + $length;

			my $from = $run_start < $offset          ? $offset           : $run_start;
			my $to   = $position > $offset + $length ? $offset + $length : $position;
			push @slice, [ $to - $from, @{$run}[ 1 .. 4 ] ];
		}
		return \@slice;
	}

	# The whole text cut at every span, highlight and link boundary, each
	# piece with the style its spans give it, the highlights over them,
	# and over those the look of the link it lies in, its palette tokens
	# in the colors of the theme the text draws with
	# (Term::Fabulous::Text::Marks). A run is the tuple
	# Term::Fabulous::Render::Text paints with:
	# [ $characters, $set, $clear, $fg_attr, $bg_attr ], the style's bits
	# and its colors as termbox attributes (undef: the color is not
	# touched), converted once here rather than in every frame.
	method _runs_of_text () {
		my $links = $marks->links;
		my @over  = map { [ @{ $links->[$_] }[ 0, 1 ], $self->_link_style($_) ] } 0 .. $#$links;
		return [
			map {
				my ( $from, $to, $style ) = @$_;
				[ $to - $from, $style->{set}, $style->{clear}, _attr_of( $style->{color} ), _attr_of( $style->{background} ) ]
			} @{ $marks->runs( theme => $self->drawing_theme, over => \@over ) }
		];
	}

	# The look of a link from the theme's text.link slots: underlined in
	# the normal and the hovered state, not underlined when selected.
	method _link_style ($index) {
		my $state
			= defined $selected_link && $index == $selected_link ? 'selected'
			: defined $hovered_link  && $index == $hovered_link  ? 'hovered'
			:                                                      'normal';
		my $underline = $state eq 'selected' ? 0 : TB_UNDERLINE;
		return {
			set        => $underline,
			clear      => TB_UNDERLINE & ~$underline,
			color      => $self->look( 'link',            $state ),
			background => $self->look( 'link.background', $state ),
		};
	}

	sub _attr_of ($rgba) {
		return undef unless defined $rgba;
		return color_attr( Term::Fabulous::Color->new( color => $rgba ) );
	}

	# ---------------------------------------------------------------------
	# KDL
	# ---------------------------------------------------------------------

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
			markup         => \&_parse_markup,
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

	method _parse_markup ($kid) {
		my $markup_value = $self->kdl_argument($kid);
		die "Term::Fabulous::Widget::Text: 'markup' needs a string argument" unless $markup_value->is_string;
		$self->markup( $markup_value->value );
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

Term::Fabulous::Widget::Text - A piece of text inside a box: plain,
with styled spans, highlights and links

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

	# Markup in the syntax of Python's rich library:
	my $hint = Term::Fabulous::Widget::Text->new(
		markup => 'Press [bold]Enter[/] to save, [bold red]Esc[/] to leave. [dim]Unsaved changes are lost.[/]',
	);

	# Or text and spans:
	my $line = Term::Fabulous::Widget::Text->new(
		text  => 'error: file not found',
		spans => [ [ 0, 6, 'bold red' ] ],
	);
	$line->stylize( 'underline', 7, 11 );    # "file"
	$line->stylize('on #3a3f4b');            # the whole text

	# Links, followed with a click or with Tab, Left/Right and Enter:
	my $help = Term::Fabulous::Widget::Text->new(
		markup => 'See [link=https://perl.org]perl.org[/link] or the [link=faq]FAQ[/link].',
	);
	$help->on( LinkActivate => sub ($event) {
		open_page( $event->link );    # 'https://perl.org' or 'faq'
		return;
	} );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-text.svg" alt="Colored words, a sentence wrapped left-aligned, centered and right-aligned, and text in five scripts"></p>

=end html

The program is F<examples/widgets/text.pl>.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-rich-text.svg" alt="A hint with a bold Enter and a red Esc, a log line with a bold red error and an underlined file name, a row of the words bold, italic, underline, reverse, dim, strike and overline each in its style, a wrapped paragraph whose italic green span and highlighted span continue on the next line, and a line of three links: FAQ underlined in blue, guide selected in dark text on blue, perl.org hovered in white on gray"></p>

=end html

The program is F<examples/widgets/rich-text.pl>. The C<links> row shows
links in their three looks: C<FAQ> as every link looks, C<guide>
selected with Tab and Right, and C<perl.org> under the mouse pointer.

=head1 DESCRIPTION

A Text widget shows text inside its parent widget, usually a
L<Term::Fabulous::Widget::Box>. The layout makes it as wide as its
longest line and, in the default wrap mode, wraps it at spaces when
the parent is too narrow and starts a new line at every C<"\n"> (see
C<wrap_mode> under L</new> for the others). Text has a color but no
background of its own: every cell shows the background that was
painted below it.

A Text widget is a leaf: it cannot have children, and it has no
border, padding or background. To give text a background, a border or
a fixed size, put it in a Box. Mouse events (C<Mouse>, C<MouseMove>)
go to the box behind a text. A mouse button pressed on a character of
the text also fires L<TextClick|Term::Fabulous::Event::TextClick> on
the Text, with the character and the word under the pointer, so that
the widgets around it can react to the words that were clicked (see
L</click_at>).

The characters of a text can differ in look: a I<span> covers a range
of the text and sets or clears style bits (bold, italic, underline,
reverse, dim, blink, strike, overline, conceal), a text color and a
background for the characters it covers. Clay lays the text out the
same way with or without spans; the renderer then paints each wrapped
line with the spans applied. C<text_color>, C<bold>, C<italic> and
C<underline> are the base look of the whole text, and a span changes
it where the span lies.

Spans are given as C<[ $start, $end, $style ]>: the character offsets
of the first character and of the one after the last, and a style
string or hash of L<Term::Fabulous::Text::Style> (C<'bold red on
#202020'>). They may overlap: later spans win where they do. A span
boundary inside a grapheme cluster (a letter with a combining accent,
an emoji with a modifier) snaps to the cluster. A color in a style may
be a palette token of the theme (C<'bold accent'>): the text looks it
up in its theme when it paints, so a theme switch recolors it. See
L<Term::Fabulous::Manual::Looks/Styled spans inside one text>.

Markup writes the same thing inline: C<[bold]Enter[/]>; see
L<Term::Fabulous::Text::Markup> for the syntax.

I<Highlights> are a second set of ranges, painted over the spans and
kept apart from them: what a search marks in a text, without touching
the styles the program gave it (see L</highlights> and
L<Term::Fabulous::Role::Searchable>).

A text can also have I<links>: ranges of its text that point to a
target and that the user can follow with the mouse or the keyboard
(see L</LINKS>). A text with links is a Tab stop; one without never
has the keyboard focus.

F<examples/text-features.pl> shows the wrap modes, line height, bold,
italic and underlined text, wide characters and control characters:

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/example-text-features.svg" alt="Text wrapped at spaces in a narrow panel and text broken only at newlines; a two-line text with line height 2; plain, bold, italic, underlined and combined styles; Latin, Japanese, emoji and combining accents ending in the same column; a tab shown as a space and control characters shown as replacement characters"></p>

=end html

L<The text section of the looks guide|Term::Fabulous::Manual::Looks/TEXT>
explains all of this with examples. The class is built on L<Clay::UI::Text>.
The painter of spans, highlights and links needs L<Clay::XS> 0.05 or
later, which tells it where every wrapped line starts in the text.

=head1 CONSTRUCTOR

=head2 new

	my $text = Term::Fabulous::Widget::Text->new(%parameters);

All parameters are optional; unknown parameters die. Every parameter
also has a method of the same name: C<id> and C<links> only read
(change the links with L</add_link> and L</clear_links>), all others
are accessors.

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

Inside a disabled L<Term::Fabulous::Widget::Button>, the text is drawn
in the button's C<disabled_color> instead, whatever its C<text_color>.

=item C<classes>

An array reference of strings. Default: C<[]>. Names that select the
theme's variants of the C<text> family, as for
L<Term::Fabulous::Widget/classes>.

=item C<bold>

=item C<italic>

=item C<underline>

Booleans, default 0: draw the characters bold, italic or underlined.
Any true or false value; references die. Terminals show these styles
with the font they have, so a font without an italic face may show
italic text upright. They take no space and do not change the layout.
They apply to the whole text; a span styles a range of it. See
L<Term::Fabulous::Manual::Looks/Bold, italic and underline>.

=item C<spans>

An array reference of spans C<[ $start, $end, $style ]>. Default:
C<[]>. Offsets are non-negative integers with
C<< $start <= $end <= length $text >>; C<$style> is a style string or
hash. Anything else dies.

=item C<links>

An array reference of links C<[ $start, $end, $target ]>. Default:
C<[]>. Offsets are non-negative integers with
C<< $start < $end <= length $text >>; C<$target> is any defined value,
kept as it is. Links must not overlap. Anything else dies.

=item C<markup>

A string in the markup syntax of L<Term::Fabulous::Text::Markup>, which
gives the text, the spans and the links; it cannot be given together
with C<text>, C<spans> or C<links>. Invalid markup dies. Put text
from outside (a file name, user input) into markup with
L<Term::Fabulous::Text::Markup/escape_markup>.

=item C<can_focus>

A boolean, default 1: whether the widget takes the keyboard focus
while it has links (see L</Keyboard>). Pass 0 for a text whose links
a widget around it selects. Its accessor is that of
L<Clay::UI::Role::Interaction::Focusable/can_focus>.

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
at C<"\n">) and C<CLAY_TEXT_WRAP_NONE> (never: the whole text is one
line, and a C<"\n"> in it is shown as a control character, see
L<Term::Fabulous::Manual::Looks/Control characters>). A line
that is not broken keeps its width as long as the widgets beside it can
still get narrower; after that it is cut off at the right edge of its
parent (inside a box that scrolls sideways it keeps its width).

No mode breaks a word: a single word that is wider than the space
available, or text without spaces such as a Japanese sentence, is
never broken. With C<CLAY_TEXT_WRAP_WORDS> it runs past the right
edge of its parent and is cut off only at the edge of the terminal or
of an enclosing L<Term::Fabulous::Widget::ScrollBox>; with the other
modes it is cut off like any line. See
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
L<Term::Fabulous::Widget>).

=head2 text

	my $text = $label->text;
	$label->text($new_text);

Accessor. Without an argument it returns the current value; with an
argument it sets it and returns the new value. An invalid value dies
like the constructor parameter. The change shows in the next frame. The
text is a character string; the layout adapts to the new length.
Setting the text drops every span, every highlight, every link and the
markup, because they pointed into the old text. A text that has the
focus loses it, since it has no links left.

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

=head2 markup

	my $markup = $text->markup;    # undef when the text was not given as markup
	$text->markup('[bold]New[/] text');

Accessor. Without an argument it returns the markup the text, spans
and links were last set from, or C<undef> when they were given or
changed directly. With an argument it replaces the text, the spans and
the links with what the markup says, drops the highlights, and returns
the markup. No link is selected or hovered afterwards. A text that has
the focus keeps it when the new markup has links, and loses it when it
has none. Invalid markup dies and leaves the widget as it was. The
change shows in the next frame. Put text from outside (a file name,
user input) into markup with
L<Term::Fabulous::Text::Markup/escape_markup>.

=head2 spans

	my $spans = $text->spans;    # [ [ 0, 6, { set => ..., clear => ..., color => ..., background => ... } ], ... ]
	$text->spans( [ [ 0, 6, 'bold red' ] ] );

Accessor for the spans, in the order they apply, each with its
normalized style hash (see L<Term::Fabulous::Text::Style/Style hashes>);
a palette token stays the token's name. The reader returns a copy.
Writing replaces every span (the markup is then C<undef>) and returns
the new spans; invalid ranges or styles die (see
L<Term::Fabulous::Text::Marks/set_spans>). The change shows in the next
frame. This accessor, L</stylize>, L</clear_spans>, L</highlights>,
L</clear_highlights> and L</content_revision> come from
L<Term::Fabulous::Role::MarkedText>, which
L<Term::Fabulous::Widget::CodeBlock> composes too. C<text_marks>
returns the widget's L<Term::Fabulous::Text::Marks>; C<marks_changed>
is the role's hook, not for programs.

=head2 stylize

	$text->stylize( 'bold red', 0, 6 );
	$text->stylize('on #3a3f4b');    # the whole text

Adds a span after the existing ones, so it wins where they overlap.
C<$start> defaults to 0, C<$end> to the length of the text. Returns
the widget, so calls chain. Invalid offsets or styles die. The change
shows in the next frame.

=head2 clear_spans

	$text->clear_spans;

Drops every span, keeping the text, the highlights and the links.
Returns the widget.

=head2 highlights

	$text->highlights( [ [ 4, 10, 'on selection' ] ] );
	my $highlights = $text->highlights;

Accessor for the highlights: ranges C<[ $start, $end, $style ]> like
spans, painted over the spans and under the links, and kept apart from
them. Setting replaces every highlight; the spans, the markup and the
links stay, and so does L</content_revision>, because highlights are
not content. The reader returns a copy with normalized styles. Invalid
ranges or styles die. The change shows in the next frame.

=head2 clear_highlights

	$text->clear_highlights;

Drops every highlight. Returns the widget.

=head2 content_revision

	my $revision = $text->content_revision;

A counter that grows whenever the text, the spans, the markup or the
links change. A caller that recorded offsets into the text compares it
to tell whether they still point where they did. Highlights, the
selected link and the hovered link leave it alone.

=head2 links

	my $links = $text->links;    # [ [ 4, 12, 'https://perl.org' ], ... ]

The links C<[ $start, $end, $target ]>, ordered by their start. An
index into this list is how the other link methods and the events name
a link. The result is a copy; the targets are the values given.

=head2 add_link

	$text->add_link( 'https://perl.org', 4, 12 );
	$text->add_link($page);    # the whole text

Adds a link to C<$target>, any defined value. C<$start> defaults to 0,
C<$end> to the length of the text. The link takes its place by its
start, so the indices of the links after it grow by one; the selected
and the hovered link stay the same links. An empty link, one that
overlaps another, invalid offsets and an undefined target die. Returns
the widget. The change shows in the next frame.

=head2 clear_links

	$text->clear_links;

Drops every link, and with them the selected and the hovered link.
Returns the widget. A text that has the focus loses it.

=head2 link_at

	my $index = $text->link_at($offset);    # or undef

The index of the link the character at C<$offset> lies in, or C<undef>.
An offset that is not a non-negative integer dies; an offset at or past
the end of the text gives C<undef>.

=head2 selected_link

	my $index = $text->selected_link;    # or undef

The index of the selected link, the one C<Enter> follows, or C<undef>.

=head2 select_link

	$text->select_link(2);
	$text->select_link(undef);    # none

Selects the link with that index, or none. An index that is not a link
dies. Returns the widget. The change shows in the next frame.

=head2 select_next_link, select_previous_link

	$text->select_next_link or say 'that was the last link';

Selects the link after (before) the selected one; without a selected
link, the first (last) link. Returns 1 when the selection moved, 0 at
the end of the links or without links.

=head2 activate_link

	$text->activate_link;       # the selected link
	$text->activate_link(1);    # the second link

Fires L<LinkActivate|Term::Fabulous::Event::LinkActivate> on the widget
for the link with the given index, or for the selected one. Returns 1,
or 0 when no index was given and no link is selected. An index that is
not a link dies.

=head2 hovered_link

	my $index = $text->hovered_link;    # or undef

The index of the link under the mouse pointer, or C<undef>.

=head2 hover_link

	$text->hover_link(0);

Called by L<Term::Fabulous> when the pointer moves onto a link
(C<undef> when it leaves it). Gives the link its hovered look. Returns
the widget. An index that is not a link dies.

=head2 accepts_focus

	my $takes_focus = $text->accepts_focus;

1 while the widget has links, 0 otherwise (see
L<Clay::UI::Role::Interaction::Focusable>). Whether it can take the
focus now is C<can_focus>, which also asks the C<can_focus> parameter.

=head2 estimated_rows

	my $rows = $text->estimated_rows($columns);

The rows the text will take when it is laid out in that many columns,
worked out as Clay wraps it: at the spaces and the line breaks for
C<CLAY_TEXT_WRAP_WORDS>, at the line breaks only for
C<CLAY_TEXT_WRAP_NEWLINES>, never for C<CLAY_TEXT_WRAP_NONE> (one row,
newlines included). A word wider than the columns takes a row of its own. Widgets that build only
part of their content, such as L<Term::Fabulous::Widget::DocumentView>,
ask this before the text was ever laid out; see
L<Term::Fabulous::Widget/estimated_rows>. C<$columns> must be a
positive integer.

=head2 row_of_offset

	my $row = $text->row_of_offset( $offset, $columns );

The row, from 0, of the character at C<$offset> when the text is laid
out in that many columns, wrapped as L</estimated_rows> counts. Past
the end of the text it is the last row. L<Term::Fabulous::Widget::DocumentView>
scrolls a search match into view with it when Clay left the match's
line out of the last frame, below the window. Both arguments are
checked.

=head2 search_texts, search_revision, highlight_text, clear_text_highlights, reveal_text

The methods of L<Term::Fabulous::Role::Searchable>, which a Text does
for its one text (through L<Term::Fabulous::Role::MarkedText>):
C<search_texts> returns one entry, C<[ undef, $text ]>,
C<search_revision> is L</content_revision>, C<highlight_text> sets
L</highlights>, C<clear_text_highlights> clears them, and
C<reveal_text> returns the text itself with no row, since where a
character lies is known once the text was painted (see
L<Term::Fabulous::Render::Frame/text_rows>). The widget also has
C<search_serial> (see L<Term::Fabulous::Role::Searchable/search_serial>).

=head2 tree_changed

Clay::UI calls it on every widget of a subtree whose place in a tree
changed (see L<Clay::UI::Role::Layout::HasParent/tree_changed>). A Text
forgets the looks it fetched here, as
L<Term::Fabulous::Widget/tree_changed> does, and the runs it painted
with, since the new tree may have another theme.

=head2 click_at

	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT);

	$text->click_at( $offset, TB_KEY_MOUSE_LEFT, $x, $y );

Fires L<TextClick|Term::Fabulous::Event::TextClick> on the widget for a
press of the mouse button (C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_MIDDLE>
or C<TB_KEY_MOUSE_RIGHT>) on the character at C<$offset> of the text,
with the pointer at the cell C<$x>, C<$y>. The event carries the word
the character belongs to (the run of non-blank characters around it),
the spans that cover the character and the link it lies in, if any.
For the left button on a link it then selects the link and fires
C<LinkActivate>. L<Term::Fabulous> calls it after the C<Mouse> event
of every button press on a character of the text; call it yourself to
click a text in a test. An offset that is not a character of the text
dies. Returns the widget.

=head2 line_styles

	my $runs = $text->line_styles( $offset, $length );

Used by the renderer (L<Term::Fabulous::Render::Text>) for each wrapped
line: the characters C<[ $offset, $offset + $length )> of the text cut
into runs of one look, as
C<[ $characters, $set, $clear, $fg_attr, $bg_attr ]>: the number of
characters, the termbox2 style bits the run's spans, highlights and
link set and clear, and the text and background attributes they give
it, C<undef> where the base look stays. An empty array reference for a
text without spans, highlights and links, which the renderer paints plain.
The runs are computed once per change of the text, the spans, the
highlights, the links, the selected or hovered link, or the theme.

=head1 LINKS

A link is a range of the text with a I<target>: a string from markup
(C<[link=TARGET]...[/link]>), or any defined value given to L</links>
or L</add_link>, such as an object of your program. The widget does
not go anywhere itself; it tells the program which link the user
followed with a L<LinkActivate|Term::Fabulous::Event::LinkActivate>
event, which bubbles from the text to its ancestors.
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Follow links in a text (Text links)>
builds a small help browser with them;
L<Term::Fabulous::Manual::Looks/Links inside a text> shows their looks.

=head2 Looks

A link has one of three looks: I<normal>, I<hovered> while the mouse
pointer is over it, and I<selected> while it is the link C<Enter>
follows (a selected link under the pointer looks selected). The picture
under L</SYNOPSIS> shows all three. The theme gives the colors, from
the slots C<link> (the color of the words) and C<link.background> of
the C<text> family (see
L<Term::Fabulous::Theme/Families, slots and states>); the default
themes use these tokens:

=over

=item * normal: underlined, in C<accent>, on the background below the
text;

=item * C<hovered>: underlined, in C<text_bright> on
C<hover_background>;

=item * C<selected>: C<text_inverse> on C<accent>, not underlined.

=back

A link sets only the color of its words, their underline and, where the
theme gives the link a background, their background, over whatever the
spans and highlights give them; the other styles stay. So
C<[bold][link=x]word[/link][/]> is a bold link, and a red span over a
link is drawn in the link color.

A theme of your own changes the looks for every text. This one draws
links in the C<success> green, and the selected link as dark text on
that green, as in the picture of
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Follow links in a text (Text links)>:

	my $theme = Term::Fabulous::Theme->new(
		name    => 'green-links',
		extends => 'dark',
		slots   => {
			'text.link'                     => 'success',
			'text.link.selected'            => 'text_inverse',
			'text.link.background.selected' => 'success',
		},
	);
	my $ui = Term::Fabulous->new( root => $root, theme => $theme );

A slot name without a state (C<text.link>) sets the normal look; the
hovered and the selected look keep their own defaults until you set
them too. Set C<text.link.background> to a token or color to give
every link a background. The underline is not a theme setting.

=head2 Mouse

A left click on a link focuses the text (when it can take the focus),
selects the link and fires C<LinkActivate>, after the C<TextClick> of
the same press (see L<Term::Fabulous::Event::TextClick>). The middle
and the right button fire only C<TextClick>. The pointer over a link
gives it the hovered look. L<Term::Fabulous> asks the terminal to
report the pointer as it moves; on a terminal that does not report
plain movement, links never look hovered.

=head2 Keyboard

A text with links is a Tab stop, unless it was created with
C<< can_focus => 0 >>; a text without links never takes the focus.
When it gets the focus and no link is selected, the first link is
selected. While it has the focus, C<Right> selects the next link,
C<Left> the previous one, and C<Enter> fires C<LinkActivate> for the
selected link; a key that moves nothing (C<Right> on the last link,
C<Enter> without a selected link) goes on to the ancestors, and every
other key does too. When it loses the focus, the selection is dropped.
When its markup is replaced while it has the focus, it keeps the focus
but selects no link until the user presses C<Right> (the first link)
or C<Left> (the last).

=head2 Links in a bigger widget

A widget that shows many texts (a document view, a help browser) may
rather keep the focus itself and move one selection across all of
them: show the selection with L</select_link> on the text that has it
(and C<undef> on the others), and follow the selected link from the
widget's own key handling with L</activate_link>, which fires
C<LinkActivate> on that text:

	# $block is the text with the selected link, $index the link's index.
	$block->select_link($index);
	...
	$block->activate_link;    # on Enter: LinkActivate bubbles up from $block

Clicks still select the clicked link and fire C<LinkActivate> from the
text, so the widget can listen for it to move its selection along.
L<Term::Fabulous::Widget::DocumentView> does all of this for the texts
of its items.

=head1 EVENTS

A Text fires C<TextClick> (L<Term::Fabulous::Event::TextClick>) when a
mouse button is pressed on one of its characters, and C<LinkActivate>
(L<Term::Fabulous::Event::LinkActivate>) when a link is followed; both
bubble to the widgets around the text. The recipe
L<Term::Fabulous::Cookbook::KeyboardAndMouse/React to a click on a word (TextClick)>
looks up the clicked word, and
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Follow links in a text (Text links)>
follows the links. A Text can fire events of your own with
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

	Text "hint" {
		markup "Press [bold]Enter[/] to save"
	}

The node's argument (C<"greeting">) is the C<id>. Inside the block:

=over

=item C<text "...">

Exactly one string. It is used as is, so write any characters directly
(KDL files are UTF-8).

=item C<markup "...">

Exactly one string in the markup syntax of
L<Term::Fabulous::Text::Markup>, which gives the text, the spans and
the links. C<markup> and C<text> replace each other: whichever comes
last wins. Spans and links cannot be given in KDL other than through
markup.

=item C<text_color "...">

Exactly one argument: any color string L<Term::Fabulous::Color>
understands, such as C<"#ffffff">, C<"rgb(255, 255, 255)"> or
C<"hsl(0, 0%, 100%)">.

=item C<classes "name" ...>

One or more strings; see the C<classes> parameter of L</new>.

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
booleans, and C<classes>, C<text>, C<markup>, C<wrap_mode> and
C<text_alignment> are structured properties the Text parses itself;
see L</KDL PROPERTIES>.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Looks/TEXT>, L<Term::Fabulous::Widget::Box>,
L<Term::Fabulous::Text::Style>, L<Term::Fabulous::Text::Markup>,
L<Term::Fabulous::Event::LinkActivate>, L<Term::Fabulous::Event::TextClick>,
L<Term::Fabulous::Role::Searchable>, L<Term::Fabulous::Unicode>,
L<Clay::UI::Text>,
L<Term::Fabulous::Cookbook::GettingStarted/Wrap, align and space text>,
L<Term::Fabulous::Cookbook::GettingStarted/Show non-ASCII text (umlauts, CJK, combining accents)>,
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Follow links in a text (Text links)>,
L<Term::Fabulous::Cookbook::KeyboardAndMouse/React to a click on a word (TextClick)>.

=cut
