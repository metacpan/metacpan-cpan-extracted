package Term::Fabulous::Event::RowActivate;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::RowActivate :isa(Clay::UI::Events::Event) :strict(params) {
	field $row_id :param :reader = undef;
	field $row :param;

	ADJUST {
		die "Term::Fabulous::Event::RowActivate: row must be a hash reference" unless ref $row eq 'HASH';
		$row = {%$row};
	}

	method event_name :common { 'RowActivate' }

	method row () { return {%$row} }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::RowActivate - The user activated a row of a table

=head1 SYNOPSIS

	$table->on( RowActivate => sub ($event) {
		open_document( $event->row->{path} );
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<RowActivate> on itself when
the user presses C<Enter> on a row or double-clicks it: the action that
opens or edits the row. C<Enter> on a group header opens or closes the
group instead. C<Enter> pressed in a widget inside a cell (a button, a
text field) and a double click on such a widget are left to that
widget and fire no C<RowActivate>.

It is a L<Clay::UI::Events::Event> whose name is C<RowActivate>; listen
for it with C<< $table->on( RowActivate => sub ($event) { ... } ) >>. It
bubbles to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::RowActivate->new( row_id => ..., row => ... );

The table builds these events itself; build one yourself only to test
your listeners. C<row> is required. Unknown parameters die, and so do
array and hash parameters of the wrong kind; they are copied.

=over

=item C<row_id>

See L</row_id>.

=item C<row>

See L</row>.

=back

=head1 METHODS

=head2 row_id

The id of the row.

=head2 row

A copy of the row's data (a new hash reference).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::Tables/Show a list of hashes in a table (sort, select, open a row)>.

=cut
