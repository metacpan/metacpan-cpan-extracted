package Term::Fabulous::Event::SelectionChange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::SelectionChange :isa(Clay::UI::Events::Event) :strict(params) {
	field $selected_ids :param;
	field $added_ids    :param;
	field $removed_ids  :param;

	ADJUST {
		die "Term::Fabulous::Event::SelectionChange: selected_ids must be an array reference" unless ref $selected_ids eq 'ARRAY';
		$selected_ids = [@$selected_ids];
		die "Term::Fabulous::Event::SelectionChange: added_ids must be an array reference" unless ref $added_ids eq 'ARRAY';
		$added_ids = [@$added_ids];
		die "Term::Fabulous::Event::SelectionChange: removed_ids must be an array reference" unless ref $removed_ids eq 'ARRAY';
		$removed_ids = [@$removed_ids];
	}

	method event_name :common { 'SelectionChange' }

	method selected_ids () { return [@$selected_ids] }
	method added_ids ()    { return [@$added_ids] }
	method removed_ids ()  { return [@$removed_ids] }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::SelectionChange - The user changed which rows of a table are selected

=head1 SYNOPSIS

	$table->on( SelectionChange => sub ($event) {
		my @ids = @{ $event->selected_ids };
		$status->text( @ids . ' selected' );
		say "now selected: $_" foreach @{ $event->added_ids };
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<SelectionChange> on itself
when the user changes which rows are selected.

With C<< selection => 'multiple' >>: a click on a row (selects it
alone), a C<Ctrl>- or C<Alt>-click on a row or a click into the
selection column (toggle the row), a C<Shift>-click or C<Shift> with a
movement key (select the range from the anchor), C<Space> (toggles the
cursor's row), C<Ctrl+A>, and a click on the selection column's header
or C<Enter> or C<Space> on it in header mode (select every filtered row,
or none when all of them are selected).

With C<< selection => 'single' >>: the cursor moving onto a row, a click
on a row, and C<Space>.

It fires only when the selection changed, after the
L<Term::Fabulous::Event::CursorMove> the same action causes. Changes
your program makes (C<select>, C<deselect>, C<set_selection>, ...) fire
nothing, and neither do rows leaving the selection because they were
removed. Selection modes are explained in
L<Term::Fabulous::Manual::TableRows/Selection>.

It is a L<Clay::UI::Events::Event> whose name is C<SelectionChange>;
listen for it with
C<< $table->on( SelectionChange => sub ($event) { ... } ) >>. It
bubbles to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::SelectionChange->new( selected_ids => ..., added_ids => ..., removed_ids => ... );

The table builds these events itself; build one yourself only to test
your listeners. Unknown parameters die, and so does a C<selected_ids>,
C<added_ids> or C<removed_ids> that is missing or not an array
reference; they are copied.

=over

=item C<selected_ids>

See L</selected_ids>.

=item C<added_ids>

See L</added_ids>.

=item C<removed_ids>

See L</removed_ids>.

=back

=head1 METHODS

=head2 selected_ids

The ids of all selected rows after the change, in the order of the data
(a new array reference).

=head2 added_ids

The ids that were selected by this change (a new array reference).

=head2 removed_ids

The ids that were deselected by this change (a new array reference).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::Tables/Show a list of hashes in a table (sort, select, open a row)>.

=cut
