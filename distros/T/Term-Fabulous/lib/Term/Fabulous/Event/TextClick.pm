package Term::Fabulous::Event::TextClick;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::TextClick :isa(Clay::UI::Events::Event) :strict(params) {
	use Term::Fabulous::Check qw(describe non_negative_integer);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_MIDDLE TB_KEY_MOUSE_RIGHT);

	my %IS_BUTTON = map { $_ => 1 } TB_KEY_MOUSE_LEFT, TB_KEY_MOUSE_MIDDLE, TB_KEY_MOUSE_RIGHT;

	field $button     :param :reader;
	field $x          :param :reader;
	field $y          :param :reader;
	field $offset     :param :reader;
	field $word       :param :reader = undef;
	field $word_start :param :reader = undef;
	field $word_end   :param :reader = undef;
	field $spans      :param = [];
	field $link       :param :reader = undef;
	field $link_index :param :reader = undef;

	ADJUST {
		die "Term::Fabulous::Event::TextClick: button must be TB_KEY_MOUSE_LEFT, TB_KEY_MOUSE_MIDDLE or TB_KEY_MOUSE_RIGHT, got " . describe($button)
			unless defined $button && !ref $button && $IS_BUTTON{$button};
		$x      = non_negative_integer( $self, x      => $x );
		$y      = non_negative_integer( $self, y      => $y );
		$offset = non_negative_integer( $self, offset => $offset );
		die "Term::Fabulous::Event::TextClick: word, word_start and word_end are given together or not at all"
			unless ( grep { defined } $word, $word_start, $word_end ) % 3 == 0;
		die "Term::Fabulous::Event::TextClick: spans must be an array reference, got " . describe($spans) unless ref $spans eq 'ARRAY';
		die "Term::Fabulous::Event::TextClick: link and link_index are given together or not at all" unless defined $link == defined $link_index;
		$link_index = non_negative_integer( $self, link_index => $link_index ) if defined $link_index;
	}

	method event_name :common () {
		return 'TextClick';
	}

	method spans () {
		return [ map { [ $_->[0], $_->[1], { %{ $_->[2] } } ] } @$spans ];
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Event::TextClick - A mouse button pressed on a character
of a text

=head1 SYNOPSIS

	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_RIGHT);

	$panel->on( TextClick => sub ($event) {
		my $word = $event->word // return;    # undef on a blank
		show_definition($word) if $event->button == TB_KEY_MOUSE_RIGHT;
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous> fires C<TextClick> on a L<Term::Fabulous::Widget::Text>
when a mouse button is pressed on one of its characters: the topmost
thing painted in the cell under the pointer in the last frame is a
line of the text, and the cell holds a character (not the empty rest
of the line). Drags, releases and the wheel fire none.

It comes after the C<Mouse> event of the same press, which goes to the
widget around the text as always (see
L<Term::Fabulous::Manual::Events/MOUSE>), and it bubbles from the text
to its ancestors, so a container can listen for clicks on any text
inside it: C<< $event->target >> is the text widget. A left press on a
link of a Text fires L<LinkActivate|Term::Fabulous::Event::LinkActivate>
after it.

The event is a L<Clay::UI::Events::Event> whose name is C<TextClick>.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::TextClick->new(
		button => TB_KEY_MOUSE_LEFT,
		x      => 12,
		y      => 3,
		offset => 4,
	);

The text widget builds these events (see
L<Term::Fabulous::Widget::Text/click_at>); build one yourself only to
test your listeners. Unknown parameters die, as do the values named
below. The C<name> and C<bubble_mode> parameters of
L<Clay::UI::Events::Event> are accepted.

=over

=item C<button>

Required. C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_MIDDLE> or
C<TB_KEY_MOUSE_RIGHT>.

=item C<x>, C<y>

Required. The cell of the pointer, counted from 0 at the top left
corner of the terminal.

=item C<offset>

Required. Where the clicked character is in the widget's text, in
characters from 0. For a character made of several code points (a
letter with a combining accent) it is the offset of the first one.

=item C<word>, C<word_start>, C<word_end>

The word the character belongs to, the run of non-blank characters
around it, with its offset and the offset after its last character.
Given together or not at all; C<undef> when the clicked character is
blank.

=item C<spans>

The spans of a Text that cover the character, as
L<Term::Fabulous::Widget::Text/spans> gives them. Default: C<[]>.

=item C<link>, C<link_index>

The target of the Text's link the character lies in, and the
link's index among the widget's links (see
L<Term::Fabulous::Widget::Text/links>). Given together or not at
all; default C<undef>.

=back

=head1 METHODS

=head2 button

	my $button = $event->button;

The button that was pressed: C<TB_KEY_MOUSE_LEFT>,
C<TB_KEY_MOUSE_MIDDLE> or C<TB_KEY_MOUSE_RIGHT>.

=head2 x

	my $column = $event->x;

The column of the pointer.

=head2 y

	my $row = $event->y;

The row of the pointer.

=head2 offset

	my $offset = $event->offset;

The offset of the clicked character in the text.

=head2 word

	my $word = $event->word;    # or undef

The word under the pointer: the run of non-blank characters the
clicked character belongs to, with any punctuation in it (C<"Foo::Bar,">).
C<undef> on a blank.

=head2 word_start

	my $start = $event->word_start;    # or undef

The offset of the word's first character.

=head2 word_end

	my $end = $event->word_end;    # or undef

The offset after the word's last character.

=head2 spans

	foreach my $span ( @{ $event->spans } ) {
		my ( $start, $end, $style ) = @$span;
		...
	}

The spans of a Text that cover the clicked character, in the order
they apply: C<[ $start, $end, $style ]> with the normalized style hash.
Empty for a plain Text. The result is a copy.

=head2 link

	my $target = $event->link;    # or undef

The target of the link under the pointer: whatever the program gave
the link (a string from markup). C<undef> when the character lies in no
link.

=head2 link_index

	my $index = $event->link_index;    # or undef

The index of that link among the widget's links, or C<undef>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Text/click_at>,
L<Term::Fabulous::Event::LinkActivate>, L<Term::Fabulous::Event::Mouse>,
L<Term::Fabulous::Manual::Events>, and the recipe
L<Term::Fabulous::Cookbook::KeyboardAndMouse/React to a click on a word (TextClick)>,
which shows every field of the event.

=cut
