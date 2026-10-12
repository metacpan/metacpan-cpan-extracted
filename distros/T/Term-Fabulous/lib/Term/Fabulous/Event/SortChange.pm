package Term::Fabulous::Event::SortChange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::SortChange :isa(Clay::UI::Events::Event) :strict(params) {
	field $sort :param;

	ADJUST {
		die "Term::Fabulous::Event::SortChange: sort must be an array reference of [ key, direction ] pairs" unless ref $sort eq 'ARRAY' && !grep { ref $_ ne 'ARRAY' } @$sort;
		$sort = [ map { [@$_] } @$sort ];
	}

	method event_name :common { 'SortChange' }

	method sort () {
		return [ map { [@$_] } @$sort ];
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::SortChange - The user changed how a table is sorted

=head1 SYNOPSIS

	$table->on( SortChange => sub ($event) {
		my @keys = map { "$_->[0] ($_->[1])" } @{ $event->sort };
		$status->text( @keys ? "sorted by @keys" : 'unsorted' );
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<SortChange> on itself when
the user sorts it by a C<sortable> column: a click on the column's
header (with C<Shift>, C<Ctrl> or C<Alt> it adds the column to the
sort), or C<Enter> or C<Space> on the header in header mode (see
L<Term::Fabulous::Widget::Table/KEYS>). Each of these cycles the column
from ascending to descending to unsorted. A column with
C<< sortable => 0 >> ignores them and fires nothing. Sorting from your program
(L<Term::Fabulous::Widget::Table/sort_by>, C<clear_sort>) fires nothing.
Sorting is explained in L<Term::Fabulous::Manual::TableRows/SORTING>.

It is a L<Clay::UI::Events::Event> whose name is C<SortChange>; listen
for it with C<< $table->on( SortChange => sub ($event) { ... } ) >>. It
bubbles to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::SortChange->new( sort => ... );

The table builds these events itself; build one yourself only to test
your listeners. Unknown parameters die, and so does a C<sort> that is
not an array reference of array references; it is copied.

=over

=item C<sort>

See L</sort>.

=back

=head1 METHODS

=head2 sort

The new sort: a new array reference of
C<[ $column_key, 'asc' or 'desc' ]> pairs, the first one sorting first;
empty when the table is unsorted.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::TableRows/Sort rows, also with your own comparison>.

=cut
