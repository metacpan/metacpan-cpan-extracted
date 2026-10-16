package Term::Fabulous::Event::PageChange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::PageChange :isa(Clay::UI::Events::Event) :strict(params) {
	field $page      :param :reader;
	field $page_size :param :reader;

	method event_name :common { 'PageChange' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::PageChange - The user turned the page of a table or changed its page size

=head1 SYNOPSIS

	$table->on( PageChange => sub ($event) {
		load_more() if $event->page == $table->page_count;
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<PageChange> on itself when
the user turns to another page: with the buttons of its pager,
C<Ctrl+PageUp> or C<Ctrl+PageDown>, or C<Ctrl+Home> or C<Ctrl+End>
when the first or the last line is on another page. It also fires when
the user chooses another page size in the pager, even when the page
number stays the same.

Changing the page or the page size from your program
(L<Term::Fabulous::Widget::Table/page>, C<next_page>,
C<previous_page>, L<Term::Fabulous::Widget::Table/page_size>) fires
nothing, and neither does the page following the cursor after the view
changed (a filter, a sort, rows added or removed). Pages are explained
in L<Term::Fabulous::Manual::TableRows/PAGES>.

It is a L<Clay::UI::Events::Event> whose name is C<PageChange>; listen
for it with C<< $table->on( PageChange => sub ($event) { ... } ) >>. It
bubbles to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::PageChange->new( page => ..., page_size => ... );

The table builds these events itself; build one yourself only to test
your listeners. Unknown parameters die, and so does a missing C<page>
or C<page_size>.

=over

=item C<page>

See L</page>.

=item C<page_size>

See L</page_size>.

=back

=head1 METHODS

=head2 page

The page shown now, counted from 1.

=head2 page_size

The number of lines per page (0: no pages).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::TableRows/Split many rows into pages (pager and page sizes)>.

=cut
