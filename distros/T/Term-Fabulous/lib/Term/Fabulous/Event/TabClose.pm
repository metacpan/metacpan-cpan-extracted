package Term::Fabulous::Event::TabClose;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::TabClose :isa(Clay::UI::Events::Event) :strict(params) {
	use Term::Fabulous::Check qw(describe non_negative_integer);

	field $item  :param :reader;
	field $index :param :reader;

	ADJUST {
		die "Term::Fabulous::Event::TabClose: item must be a hash reference, got " . describe($item) unless ref $item eq 'HASH';
		$index = non_negative_integer( $self, index => $index );
	}

	method event_name :common { 'TabClose' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::TabClose - The user asked to close a document tab

=head1 SYNOPSIS

	$tabs->on( TabClose => sub ($event) {
		my $document = $documents[ $event->index ];
		return ask_save_first($document) if $document->is_modified;
		splice @documents, $event->index, 1;
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::DocumentTabs> fires C<TabClose> on itself
when the user asks to close one of its tabs: with a click on the
tab's close mark, or with a middle click anywhere on the tab. A tab
whose C<closable> is 0 has no close mark and fires nothing.

The tabs do not remove the tab themselves. The program decides: it
may close the document at once, ask whether to save it first, or keep
it open. To close it, it removes the tab from the list it gave the
tabs (or from what its code reference returns) and sets
C<active> to the tab that should be shown now.

It is a L<Clay::UI::Events::Event> whose name is C<TabClose>. It
bubbles to the widget's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the DocumentTabs.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::TabClose->new( item => $tab, index => 2 );

The widget builds these events itself; build one yourself only to test
your listeners. Both parameters are required, and unknown parameters
die, and so do an C<item> that is not a hash reference and an
C<index> that is not a non-negative integer. The C<name> and
C<bubble_mode> parameters of L<Clay::UI::Events::Event> are accepted.

=head1 METHODS

=head2 item

The tab, a hash reference as the DocumentTabs shows it (see
L<Term::Fabulous::Widget::DocumentTabs/tabs>).

=head2 index

Its position among the tabs, from 0.

=head1 SEE ALSO

L<Term::Fabulous::Widget::DocumentTabs>, L<Term::Fabulous::Event::TabAdd>,
L<Term::Fabulous::Event::Select>, L<Clay::UI::Events::Event>.

=cut
