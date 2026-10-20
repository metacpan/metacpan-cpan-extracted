package Term::Fabulous::Event::LinkActivate;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::LinkActivate :isa(Clay::UI::Events::Event) :strict(params) {
	use Term::Fabulous::Check qw(non_negative_integer);

	field $link  :param :reader;
	field $index :param :reader;
	field $start :param :reader;
	field $end   :param :reader;

	ADJUST {
		die "Term::Fabulous::Event::LinkActivate: link must be defined" unless defined $link;
		$index = non_negative_integer( $self, index => $index );
		$start = non_negative_integer( $self, start => $start );
		$end   = non_negative_integer( $self, end   => $end );
		die "Term::Fabulous::Event::LinkActivate: end $end lies before start $start" if $end < $start;
	}

	method event_name :common () {
		return 'LinkActivate';
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Event::LinkActivate - The user followed a link of a
Text

=head1 SYNOPSIS

	$help->on( LinkActivate => sub ($event) {
		open_page( $event->link );    # the link's target
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::Text> fires C<LinkActivate> on itself when
the user follows one of its links, whichever way: a left click on the
link, or C<Enter> while the Text has the focus and a link is selected.
C<< $text->activate_link >>
(L<Term::Fabulous::Widget::Text/activate_link>) fires it from code; a
widget that moves one selection across many texts follows links that way
(see L<Term::Fabulous::Widget::Text/Links in a bigger widget>). The
widget does not go anywhere itself: what a link means is the program's
business, and C<link> is the target the program gave it.

It is a L<Clay::UI::Events::Event> whose name is C<LinkActivate>, and it
bubbles from the Text to its ancestors, so a container can follow
the links of every text inside it. C<< $event->target >> is the
Text (C<target> is the widget, as for every event; the link's
target is C<link>).

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::LinkActivate->new(
		link  => 'https://perl.org',
		index => 0,
		start => 4,
		end   => 12,
	);

The Text builds these events itself; build one yourself to test
your listeners, or to fire it from a widget of your own that shows
links some other way. All four parameters are required; C<link> may be
anything but C<undef>, the others are non-negative integers with
C<< start <= end >>. Unknown parameters die. The C<name> and
C<bubble_mode> parameters of L<Clay::UI::Events::Event> are accepted.

=head1 METHODS

=head2 link

	my $target = $event->link;

The target of the link: a string from markup, or whatever the program
gave L<add_link|Term::Fabulous::Widget::Text/add_link>.

=head2 index

	my $index = $event->index;

The index of the link among the Text's links.

=head2 start

	my $start = $event->start;

The offset of the link's first character in the text.

=head2 end

	my $end = $event->end;

The offset after the link's last character.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Text/LINKS>,
L<Term::Fabulous::Event::TextClick>,
L<Term::Fabulous::Manual::Events>, and the recipe
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Follow links in a text (Text links)>.

=cut
