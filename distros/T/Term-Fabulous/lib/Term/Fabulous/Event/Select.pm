package Term::Fabulous::Event::Select;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Select :isa(Clay::UI::Events::Event) :strict(params) {
	field $item  :param :reader;
	field $index :param :reader;
	field $open  :param :reader = 1;

	ADJUST {
		die "Term::Fabulous::Event::Select: index must be a non-negative integer, got " . ( defined $index ? "'$index'" : 'undef' )
			unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/;
		$open = $open ? 1 : 0;
	}

	method event_name :common { 'Select' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Select - The user opened or closed an item of an accordion, or chose a tab

=head1 SYNOPSIS

	$accordion->on( Select => sub ($event) {
		my $item = $event->item;
		$status->text( $event->open ? 'Opened ' . $item->title : 'Closed ' . $item->title );
		return;
	} );

	$tabs->on( Select => sub ($event) {
		$status->text( 'Showing ' . $event->item->title );
		return;
	} );

=head1 DESCRIPTION

A widget that lets the user pick one of its items fires C<Select> on
itself when the user does so:

=over

=item *

A L<Term::Fabulous::Widget::Accordion>, when the user opens or closes
one of its items: with a click on the item's header, with C<Enter> or
C<Space> while the header has the focus, or through
C<< $accordion->choose($index) >>, which acts as the user does. Opening
and closing from your program (C<open>, C<close>, C<open_all>,
C<close_all>, C<< $item->open(1) >>) fires nothing. When opening one
item closes another, because the accordion allows one open item at a
time, only the item the user acted on fires.

=item *

A L<Term::Fabulous::Widget::Tabs>, when the user chooses another tab:
with a click on it, with an arrow key, C<Home> or C<End> while the
active tab has the focus, with C<Ctrl+PageUp> or C<Ctrl+PageDown>
from anywhere inside, or through C<< $tabs->choose($index) >>. The
item is the page now shown. Choosing from your program (C<select>,
C<< $page->active(1) >>) fires nothing, and so does choosing the tab
that is active already.

=item *

A L<Term::Fabulous::Widget::Tabs::Bar> used on its own, likewise; the
item is then the tab, a L<Term::Fabulous::Widget::Tabs::Button>. Under
a Tabs, the bar's event does not bubble past the Tabs, which fires its
own with the page.

=item *

A L<Term::Fabulous::Widget::DocumentTabs>, when the user clicks one of
its tabs, the active one included, or an arrow at one of its ends,
which chooses the next hidden tab on that side. The item is a copy of
the tab's hash, as the DocumentTabs drew it, with the program's own
keys. The DocumentTabs does not make the tab active itself: the program
shows the document and sets C<active>, which fires nothing.

=back

It is a L<Clay::UI::Events::Event> whose name is C<Select>; listen for
it with C<< $widget->on( Select => sub ($event) { ... } ) >>. It
bubbles to the widget's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the accordion, the Tabs, the bar or the
DocumentTabs.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Select->new( item => $item, index => 2, open => 1 );

The widgets build these events themselves; build one yourself only to
test your listeners, or to fire C<Select> from a widget of your own.
Unknown parameters die, and so does an C<index> that is not a
non-negative integer.

=over

=item C<item>

Required. See L</item>.

=item C<index>

Required. See L</index>.

=item C<open>

A boolean. Default: 1. See L</open>.

=back

=head1 METHODS

=head2 item

The widget the user chose: a L<Term::Fabulous::Widget::Accordion::Item>,
a L<Term::Fabulous::Widget::Tabs::Page> (from a Tabs) or a
L<Term::Fabulous::Widget::Tabs::Button> (from a bar on its own). From
a L<Term::Fabulous::Widget::DocumentTabs>, the tab: a hash reference
with C<title>, C<modified>, C<error>, C<closable> and the program's own
keys (see L<Term::Fabulous::Widget::DocumentTabs/tabs>).

=head2 index

Its position among the accordion's items or the tabs, from 0.

=head2 open

1 when the item was opened or the tab chosen, 0 when an accordion
item was closed.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Accordion>, L<Term::Fabulous::Widget::Tabs>,
L<Term::Fabulous::Widget::Tabs::Bar>, L<Term::Fabulous::Widget::DocumentTabs>,
L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Manual::Layout/ACCORDIONS>,
L<Term::Fabulous::Manual::Layout/TABS>.

=cut
