package Term::Fabulous::Event::CursorMove;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::CursorMove :isa(Clay::UI::Events::Event) :strict(params) {
	field $row_id :param :reader = undef;
	field $group_path :param = undef;

	ADJUST {
		die "Term::Fabulous::Event::CursorMove: group_path must be undef or an array reference" if defined $group_path && ref $group_path ne 'ARRAY';
		$group_path = [@$group_path] if defined $group_path;
	}

	method event_name :common { 'CursorMove' }

	method group_path () { return defined $group_path ? [@$group_path] : undef }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::CursorMove - The cursor of a table moved to another line

=head1 SYNOPSIS

	$table->on( CursorMove => sub ($event) {
		my $id = $event->row_id // return;    # undef on a group header
		$details->text( describe( $table->row($id) ) );
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<CursorMove> on itself when
the user moves its cursor (the highlighted line keyboard commands act
on) to another line: with C<Up>, C<Down>, C<PageUp>, C<PageDown>,
C<Home> or C<End> (also with C<Shift> in a table with
C<< selection => 'multiple' >>), with C<Ctrl+Home> or C<Ctrl+End>, with
C<Left> or C<Right> in a tree or in groups (to the parent row, the first
child or the group header), with a click on a row, a group header or
a marker, or by turning the page (C<Ctrl+PageUp>, C<Ctrl+PageDown>, the
pager), which puts the cursor on the first line of the new page.

Moving the cursor from your program
(L<Term::Fabulous::Widget::Table/cursor>,
L<Term::Fabulous::Widget::Table/page>) fires nothing, and neither does
the cursor moving because its line left the view (filtered out, below
a collapsed row or group, removed).

It fires before the L<Term::Fabulous::Event::SelectionChange>, the
L<Term::Fabulous::Event::PageChange> and the
L<Term::Fabulous::Event::Expand> or L<Term::Fabulous::Event::Collapse>
the same action causes. The cursor is explained in
L<Term::Fabulous::Manual::TableRows/The cursor>.

It is a L<Clay::UI::Events::Event> whose name is C<CursorMove>; listen
for it with C<< $table->on( CursorMove => sub ($event) { ... } ) >>. It
bubbles to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::CursorMove->new( row_id => ..., group_path => ... );

The table builds these events itself; build one yourself only to test
your listeners. Unknown parameters die, and so does a C<group_path>
that is not C<undef> or an array reference; it is copied.

=over

=item C<row_id>

See L</row_id>.

=item C<group_path>

See L</group_path>.

=back

=head1 METHODS

=head2 row_id

The id of the row the cursor is on now, or C<undef> when it is on a
group header.

=head2 group_path

On a group header, the values of the group and of the groups around it,
outermost first (a new array reference); C<undef> on a row.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::Tables/Show a list of hashes in a table (sort, select, open a row)>.

=cut
