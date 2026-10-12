package Term::Fabulous::Widget::RichText;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::FocusableText;

our $VERSION = '0.02';

class Term::Fabulous::Widget::RichText
	:isa(Term::Fabulous::Widget::FocusableText)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::UI::Revision qw(bump_revision);
	use List::Util qw(first);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Check qw(non_negative_integer);
	use Term::Fabulous::Color;
	use Term::Fabulous::Event::LinkActivate;
	use Term::Fabulous::Render::Attr qw(color_attr);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_UNDERLINE);
	use Term::Fabulous::Text::Markup qw(parse_markup);
	use Term::Fabulous::Text::Style qw(compose_styles style);
	use Term::Fabulous::Theme;

	# The markup the text, spans and links came from, or undef when they
	# were given directly.
	field $markup :param = undef;

	# The spans as given, checked in ADJUST; the array holds the checked ones.
	field $given_spans :param(spans) = undef;
	field @spans;    # [ $start, $end, $style ]

	# The links as given, checked in ADJUST; the array holds the checked
	# ones, ordered by their start, none overlapping another.
	field $given_links :param(links) = undef;
	field @links;    # [ $start, $end, $target ]

	# The selected link (the one Enter follows) and the one under the
	# mouse pointer, as indices into @links.
	field $selected_link = undef;
	field $hovered_link  = undef;

	# The runs of the whole text (see line_styles), computed on demand and
	# dropped whenever the text, the spans, the links or the theme change.
	field $runs            = undef;
	field $runs_generation = -1;

	# The keys a focused RichText uses; an action returns whether it did
	# anything, and a key that did nothing goes on to the ancestors.
	my %ACTION_OF_KEY = (
		Left  => sub ($self) { $self->select_previous_link },
		Right => sub ($self) { $self->select_next_link },
		Enter => sub ($self) { $self->activate_link },
	);

	# Markup is parsed before the parent sees the text, so that a markup
	# string is just another way to give text, spans and links.
	sub BUILDARGS ( $class, %params ) {
		return $class->SUPER::BUILDARGS(%params) unless defined $params{markup};
		die "Term::Fabulous::Widget::RichText: markup cannot be given together with text or spans or links" if exists $params{text} || exists $params{spans} || exists $params{links};
		my ( $text, $spans, $links ) = parse_markup( $params{markup} );
		return $class->SUPER::BUILDARGS( %params, text => $text, spans => $spans, links => $links );
	}

	ADJUST {
		die "Term::Fabulous::Widget::RichText: spans must be an array reference of [start, end, style]" if defined $given_spans  && ref $given_spans ne 'ARRAY';
		die "Term::Fabulous::Widget::RichText: links must be an array reference of [start, end, target]" if defined $given_links && ref $given_links ne 'ARRAY';
		@spans       = map { $self->_checked_span($_) } @{ $given_spans // [] };
		$given_spans = undef;
		$self->_insert_link( $self->_checked_link($_) ) foreach @{ $given_links // [] };
		$given_links = undef;

		weaken( my $weak_self = $self );
		my $continue = Clay::UI::Enum::Result->CONTINUE;
		$self->on(
			KeyPress => sub ($event) {
				my $action = $ACTION_OF_KEY{ $event->main_key_name // '' } // return $continue;
				return $action->($weak_self) ? undef : $continue;
			}
		);
		$self->on( OnFocus => sub ($event) { $weak_self->select_next_link unless defined $weak_self->selected_link; return $continue } );
		$self->on( OnBlur  => sub ($event) { $weak_self->select_link(undef);                                        return $continue } );
	}

	# A copy of a span with its offsets checked against the text and its
	# style normalized.
	method _checked_span ($span) {
		die "Term::Fabulous::Widget::RichText: a span is [start, end, style]" unless ref $span eq 'ARRAY' && @$span == 3;
		my ( $start, $end, $style ) = @$span;
		return $self->_span( $style, $start, $end );
	}

	method _span ( $style, $start, $end ) {
		return [ $self->_checked_range( 'span', $start, $end ), style($style) ];
	}

	method _checked_range ( $what, $start, $end ) {
		$start = non_negative_integer( $self, "$what start", $start );
		$end   = non_negative_integer( $self, "$what end",   $end );
		my $length = length $self->text;
		die "Term::Fabulous::Widget::RichText: $what end $end lies before its start $start" if $end < $start;
		die "Term::Fabulous::Widget::RichText: $what end $end lies past the text ($length characters)" if $end > $length;
		return ( $start, $end );
	}

	method _checked_link ($link) {
		die "Term::Fabulous::Widget::RichText: a link is [start, end, target]" unless ref $link eq 'ARRAY' && @$link == 3;
		my ( $start, $end, $target ) = @$link;
		return $self->_link( $target, $start, $end );
	}

	method _link ( $target, $start, $end ) {
		die "Term::Fabulous::Widget::RichText: a link needs a target" unless defined $target;
		( $start, $end ) = $self->_checked_range( 'link', $start, $end );
		die "Term::Fabulous::Widget::RichText: a link must not be empty, got $start to $end" if $start == $end;
		return [ $start, $end, $target ];
	}

	# Puts a checked link in its place by start; the selected and the
	# hovered link stay the same links.
	method _insert_link ($link) {
		my ( $start, $end ) = @$link;
		my $overlapped = first { $_->[0] < $end && $start < $_->[1] } @links;
		die "Term::Fabulous::Widget::RichText: the link $start to $end overlaps the link $overlapped->[0] to $overlapped->[1]" if defined $overlapped;
		my $position = first { $links[$_][0] > $start } 0 .. $#links;
		$position //= scalar @links;
		splice @links, $position, 0, $link;
		$selected_link++ if defined $selected_link && $selected_link >= $position;
		$hovered_link++ if defined $hovered_link   && $hovered_link >= $position;
		return;
	}

	method _forget_runs () {
		$runs = undef;
		bump_revision();
		return;
	}

	# Whether the widget can take the focus may have changed with its links.
	method _links_changed () {
		$self->_forget_runs;
		$self->focus_eligibility_changed;
		return;
	}

	# Setting the text drops the spans and the links: they pointed into the
	# old one.
	method text :override (@new) {
		return $self->SUPER::text unless @new;
		my $text = $self->SUPER::text(@new);
		@spans  = ();
		$markup = undef;
		$self->_drop_links;
		return $text;
	}

	method _drop_links () {
		$self->_forget_links;
		$self->_links_changed;
		return;
	}

	# Without telling the focus: a RichText that gets new links at once
	# keeps the focus.
	method _forget_links () {
		@links = ();
		( $selected_link, $hovered_link ) = ();
		return;
	}

	method markup (@new) {
		return $markup unless @new;
		my ( $text, $spans, $links ) = parse_markup( $new[0] );
		$self->SUPER::text($text);
		@spans = @$spans;
		$self->_forget_links;
		$self->_insert_link($_) foreach @$links;
		$markup = $new[0];
		$self->_links_changed;
		return $markup;
	}

	method spans () {
		return [ map { [ $_->[0], $_->[1], { %{ $_->[2] } } ] } @spans ];
	}

	method stylize ( $style, $start = 0, $end = undef ) {
		push @spans, $self->_span( $style, $start, $end // length $self->text );
		$markup = undef;
		$self->_forget_runs;
		return $self;
	}

	method clear_spans () {
		@spans  = ();
		$markup = undef;
		$self->_forget_runs;
		return $self;
	}

	# ---------------------------------------------------------------------
	# Links
	# ---------------------------------------------------------------------

	method links () {
		return [ map { [@$_] } @links ];
	}

	method add_link ( $target, $start = 0, $end = undef ) {
		$self->_insert_link( $self->_link( $target, $start, $end // length $self->text ) );
		$markup = undef;
		$self->_links_changed;
		return $self;
	}

	method clear_links () {
		$markup = undef;
		$self->_drop_links;
		return $self;
	}

	method link_at ($offset) {
		$offset = non_negative_integer( $self, offset => $offset );
		return first { $links[$_][0] <= $offset && $offset < $links[$_][1] } 0 .. $#links;
	}

	method _checked_link_index ( $what, $index ) {
		return undef unless defined $index;
		$index = non_negative_integer( $self, $what, $index );
		die "Term::Fabulous::Widget::RichText: $what $index is not a link; the text has " . scalar(@links) . " links" if $index > $#links;
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
		return 0 if $next > $#links;
		$self->select_link($next);
		return 1;
	}

	method select_previous_link () {
		my $previous = defined $selected_link ? $selected_link - 1 : $#links;
		return 0 if $previous < 0;
		$self->select_link($previous);
		return 1;
	}

	method activate_link (@index) {
		my $index = @index ? $self->_checked_link_index( link => $index[0] ) : $selected_link;
		return 0 unless defined $index;
		my ( $start, $end, $target ) = @{ $links[$index] };
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

	# A RichText takes the focus while it has links to select.
	method accepts_focus :override () {
		return @links ? 1 : 0;
	}

	# ---------------------------------------------------------------------
	# Clicks
	# ---------------------------------------------------------------------

	method _click_details :override ($offset) {
		my $index = $self->link_at($offset);
		return (
			spans => [ grep { $_->[0] <= $offset && $offset < $_->[1] } @{ $self->spans } ],
			defined $index ? ( link => $links[$index][2], link_index => $index ) : (),
		);
	}

	# A left click on a link selects and follows it.
	method click_at :override ( $offset, $button, $x, $y ) {
		$self->SUPER::click_at( $offset, $button, $x, $y );
		return $self unless $button == TB_KEY_MOUSE_LEFT;
		my $index = $self->link_at($offset) // return $self;
		$self->select_link($index);
		$self->activate_link($index);
		return $self;
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# The runs the renderer paints a line with: the part of the text's runs
	# that covers the characters [offset, offset + length).
	method line_styles ( $offset, $length ) {
		return [] if $length <= 0;
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

	# The whole text cut at every span and link boundary, each piece with
	# the style its spans give it and, over them, the look of the link it
	# lies in. A run is the tuple Term::Fabulous::Render::Text paints with:
	# [ $characters, $set, $clear, $fg_attr, $bg_attr ], the style's bits
	# and its colors as termbox attributes (undef: the color is not
	# touched), converted once here rather than in every frame.
	method _runs_of_text () {
		my $length = length $self->text;
		return [ [ $length, 0, 0, undef, undef ] ] unless ( @spans || @links ) && $length;

		my %seen;
		my @boundaries = sort { $a <=> $b } grep { !$seen{$_}++ } 0, $length, map { @{$_}[ 0, 1 ] } @spans, @links;
		my @runs;
		foreach my $index ( 0 .. $#boundaries - 1 ) {
			my ( $from, $to ) = @boundaries[ $index, $index + 1 ];
			my @styles = map { $_->[2] } grep { $_->[0] <= $from && $_->[1] >= $to } @spans;
			my $link   = first { $links[$_][0] <= $from && $links[$_][1] >= $to } 0 .. $#links;
			push @styles, $self->_link_style($link) if defined $link;
			push @runs,   [ $to - $from, _look_of(@styles) ];
		}
		return \@runs;
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

	# The set and clear bits and the color attributes that the given
	# styles, stacked in order, give a piece of text.
	sub _look_of (@styles) {
		my $style = compose_styles(@styles);
		return ( $style->{set}, $style->{clear}, _attr_of( $style->{color} ), _attr_of( $style->{background} ) );
	}

	sub _attr_of ($rgba) {
		return undef unless defined $rgba;
		return color_attr( Term::Fabulous::Color->new( color => $rgba ) );
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			markup => \&_parse_markup,
		);
	}

	method _parse_markup ($kid) {
		my $markup_value = $self->kdl_argument($kid);
		die "Term::Fabulous::Widget::RichText: 'markup' needs a string argument" unless $markup_value->is_string;
		$self->markup( $markup_value->value );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::RichText - Text with styled spans and links: bold
words, colored phrases, highlighted ranges, links to follow

=head1 SYNOPSIS

	use Term::Fabulous::Widget::RichText;

	# Markup in the syntax of Python's rich library:
	my $hint = Term::Fabulous::Widget::RichText->new(
		markup => 'Press [bold]Enter[/] to save, [bold red]Esc[/] to leave. [dim]Unsaved changes are lost.[/]',
	);

	# Or text and spans:
	my $line = Term::Fabulous::Widget::RichText->new(
		text  => 'error: file not found',
		spans => [ [ 0, 6, 'bold red' ] ],
	);
	$line->stylize( 'underline', 7, 11 );    # "file"
	$line->stylize('on #3a3f4b');            # the whole text

	# Links, followed with a click or with Tab, Left/Right and Enter:
	my $help = Term::Fabulous::Widget::RichText->new(
		markup => 'See [link=https://perl.org]perl.org[/link] or the [link=faq]FAQ[/link].',
	);
	$help->on( LinkActivate => sub ($event) {
		open_page( $event->link );    # 'https://perl.org' or 'faq'
		return;
	} );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-rich-text.svg" alt="A hint with a bold Enter and a red Esc, a log line with a bold red error and an underlined file name, a row of the words bold, italic, underline, reverse, dim, strike and overline each in its style, a wrapped paragraph whose italic green span and highlighted span continue on the next line, and a line of three links: FAQ underlined in blue, guide selected in dark text on blue, perl.org hovered in white on gray"></p>

=end html

The program is F<examples/widgets/rich-text.pl>. The last two rows show
links in their three looks: C<FAQ> as every link looks, C<guide>
selected with Tab and Right, and C<perl.org> under the mouse pointer.

=head1 DESCRIPTION

A RichText is a L<Term::Fabulous::Widget::Text> whose characters can
differ in look: a I<span> covers a range of the text and sets or
clears style bits (bold, italic, underline, reverse, dim, blink,
strike, overline, conceal), a text color and a background for the
characters it covers. Clay lays the text out exactly like a Text,
wrapping and aligning it; the renderer then paints each wrapped line
with the spans applied. Everything a Text does, a RichText does too:
C<text_color>, C<bold>, C<italic> and C<underline> are the base look
of the whole text, and a span changes it where the span lies.

Spans are given as C<[ $start, $end, $style ]>: the character offsets
of the first character and of the one after the last, and a style
string or hash of L<Term::Fabulous::Text::Style> (C<'bold red on
#202020'>). They may overlap: later spans win where they do. A span
boundary inside a grapheme cluster (a letter with a combining accent,
an emoji with a modifier) snaps to the cluster.

Markup writes the same thing inline: C<[bold]Enter[/]>; see
L<Term::Fabulous::Text::Markup> for the syntax.

A RichText can also have I<links>: ranges of its text that point to a
target and that the user can follow with the mouse or the keyboard
(see L</LINKS>). Like every Text, a RichText fires
L<TextClick|Term::Fabulous::Event::TextClick> when a mouse button is
pressed on one of its characters (see
L<Term::Fabulous::Widget::Text/click_at>).

The painter of a RichText needs L<Clay::XS> 0.05 or later, which
tells it where every wrapped line starts in the text.

=head1 CONSTRUCTOR

=head2 new

	my $text = Term::Fabulous::Widget::RichText->new(%parameters);

All parameters of L<Term::Fabulous::Widget::Text/new>, plus:

=over

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
with C<text>, C<spans> or C<links>. Invalid markup dies.

=item C<can_focus>

A boolean, default 1: whether the widget takes the keyboard focus
while it has links (see L</Keyboard>). Pass 0 when a widget around it
selects its links instead (see L</Links in a bigger widget>). Its
accessor is that of L<Clay::UI::Role::Interaction::Focusable/can_focus>.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Text>, plus:

=head2 text

	$text->text('Plain again');

As for a Text, and setting it drops every span, every link and the
markup, because they pointed into the old text. A RichText that has the
focus loses it, since it has no links left.

=head2 markup

	my $markup = $text->markup;    # undef when the text was not given as markup
	$text->markup('[bold]New[/] text');

Accessor. Without an argument it returns the markup the text, spans
and links were last set from, or C<undef> when they were given or
changed directly. With an argument it replaces the text, the spans and
the links with what the markup says, and returns the markup. No link is
selected or hovered afterwards. A RichText that has the focus keeps it
when the new markup has links, and loses it when it has none. Invalid
markup dies and leaves the widget as it was. The change shows in the
next frame.

=head2 spans

	my $spans = $text->spans;    # [ [ 0, 6, { set => ..., clear => ..., color => ..., background => ... } ], ... ]

The spans, in the order they apply, each with its normalized style
hash (see L<Term::Fabulous::Text::Style/Style hashes>). The result is
a copy.

=head2 stylize

	$text->stylize( 'bold red', 0, 6 );
	$text->stylize('on #3a3f4b');    # the whole text

Adds a span after the existing ones, so it wins where they overlap.
C<$start> defaults to 0, C<$end> to the length of the text. Returns
the widget, so calls chain. Invalid offsets or styles die. The change
shows in the next frame.

=head2 clear_spans

	$text->clear_spans;

Drops every span, keeping the text and the links. Returns the widget.

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
Returns the widget. A RichText that has the focus loses it.

=head2 link_at

	my $index = $text->link_at($offset);    # or undef

The index of the link the character at C<$offset> lies in, or C<undef>.

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
the widget.

=head2 accepts_focus

	my $takes_focus = $text->accepts_focus;

1 while the widget has links, 0 otherwise (see
L<Clay::UI::Role::Interaction::Focusable>). Whether it can take the
focus now is C<can_focus>, which also asks the C<can_focus> parameter.

=head2 click_at

	$text->click_at( $offset, TB_KEY_MOUSE_LEFT, $x, $y );

As for a Text (L<Term::Fabulous::Widget::Text/click_at>): fires
C<TextClick>, which here also carries the spans and the link at the
offset. For the left button on a link it then selects the link and
fires C<LinkActivate>. Returns the widget.

=head2 line_styles

	my $runs = $text->line_styles( $offset, $length );

Used by the renderer (L<Term::Fabulous::Render::Text>) for each wrapped
line: the characters C<[ $offset, $offset + $length )> of the text cut
into runs of one look, as
C<[ $characters, $set, $clear, $fg_attr, $bg_attr ]>: the number of
characters, the termbox2 style bits the run's spans and link set and
clear, and the text and background attributes they give it, C<undef>
where the base look stays. The runs are computed once per change of
the text, the spans, the links, the selected or hovered link, or the
theme.

=head1 LINKS

A link is a range of the text with a I<target>: a string from markup
(C<[link=TARGET]...[/link]>), or any defined value given to L</links>
or L</add_link>, such as an object of your program. The widget does
not go anywhere itself; it tells the program which link the user
followed with a L<LinkActivate|Term::Fabulous::Event::LinkActivate>
event, which bubbles from the RichText to its ancestors.

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
spans give them; the other styles of the spans stay. So
C<[bold][link=x]word[/link][/]> is a bold link, and a red span over a
link is drawn in the link color.

A theme of your own changes the looks for every RichText. This one
draws links in the C<success> green, and the selected link as dark
text on that green, as in the picture of
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Follow links in a text (RichText links)>:

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

A left click on a link focuses the RichText (when it can take the
focus), selects the link and fires C<LinkActivate>, after the
C<TextClick> of the same press (see L<Term::Fabulous::Event::TextClick>).
The middle and the right button fire only C<TextClick>. The pointer
over a link gives it the hovered look. L<Term::Fabulous> asks the
terminal to report the pointer as it moves; on a terminal that does not
report plain movement, links never look hovered.

=head2 Keyboard

A RichText with links is a Tab stop, unless it was created with
C<< can_focus => 0 >>. When it gets the focus and no link is selected,
the first link is selected. While it has the focus, C<Right> selects
the next link, C<Left> the previous one, and C<Enter> fires
C<LinkActivate> for the selected link; a key that moves nothing (C<Right>
on the last link, C<Enter> without a selected link) goes on to the
ancestors, and every other key does too. When it loses the focus, the
selection is dropped. When its markup is replaced while it has the
focus, it keeps the focus but selects no link until the user presses
C<Right> (the first link) or C<Left> (the last).

=head2 Links in a bigger widget

A widget that shows many RichTexts (a document view, a help browser)
may rather keep the focus itself and move one selection across all of
them: create the RichTexts with C<< can_focus => 0 >>, show the
selection with L</select_link> on the RichText that has it (and
C<undef> on the others), and follow the selected link from the
widget's own key handling with L</activate_link>, which fires
C<LinkActivate> on that RichText:

	# $block is the RichText with the selected link, $index the link's index.
	$block->select_link($index);
	...
	$block->activate_link;    # on Enter: LinkActivate bubbles up from $block

Clicks still select the clicked link and fire C<LinkActivate> from the
RichText, so the widget can listen for it to move its selection
along.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Text/KDL PROPERTIES>, plus
C<markup>:

=for highlighter language=kdl

	RichText "hint" {
		markup "Press [bold]Enter[/] to save"
	}

C<markup> and C<text> replace each other: whichever comes last wins.
Spans and links cannot be given in KDL other than through markup.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Text>, L<Term::Fabulous::Text::Style>,
L<Term::Fabulous::Text::Markup>, L<Term::Fabulous::Event::LinkActivate>,
L<Term::Fabulous::Event::TextClick>, L<Term::Fabulous::Manual::Looks/TEXT>,
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Follow links in a text (RichText links)>,
L<Term::Fabulous::Cookbook::KeyboardAndMouse/React to a click on a word (TextClick)>.

=cut
