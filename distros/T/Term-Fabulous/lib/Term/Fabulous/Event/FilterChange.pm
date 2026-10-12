package Term::Fabulous::Event::FilterChange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::FilterChange :isa(Clay::UI::Events::Event) :strict(params) {
	field $column :param :reader;
	field $text   :param :reader;
	field $error  :param :reader = undef;

	method event_name :common { 'FilterChange' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::FilterChange - The user typed into a filter field of a table

=head1 SYNOPSIS

	$table->on( FilterChange => sub ($event) {
		$status->text( $event->error // sprintf '%d of %d rows', scalar $table->filtered_row_ids, $table->row_count );
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<FilterChange> on itself when
the user changes the text of a field in its filter row (see
L<Term::Fabulous::Widget::Table/filter_row>), by typing or by clearing
a non-empty field with C<Escape>, after the table has applied the text.
A text that is not a valid filter expression leaves the column
unfiltered and is shown in the C<error_color>; C<error> says why.
Setting filters from your program (C<filter>, C<filter_text>,
C<search>, ...) fires nothing. The filter row and its expressions are
explained in L<Term::Fabulous::Manual::TableRows/The filter row>.

It is a L<Clay::UI::Events::Event> whose name is C<FilterChange>;
listen for it with
C<< $table->on( FilterChange => sub ($event) { ... } ) >>. It bubbles
to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::FilterChange->new( column => ..., text => ..., error => ... );

The table builds these events itself; build one yourself only to test
your listeners. Unknown parameters die, and so does a missing C<column>
or C<text>.

=over

=item C<column>

See L</column>.

=item C<text>

See L</text>.

=item C<error>

See L</error>.

=back

=head1 METHODS

=head2 column

The key of the column whose field changed.

=head2 text

The text of the field.

=head2 error

C<undef> when the text is a valid filter expression (or empty),
otherwise why it is not one, for example
C<< 'abc' is not a number filter (use 5, >5, >=5, <5, <=5, !=5 or 5..10) >>.
The same message is available as
C<< $table->filter_error($column) >>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::TableRows/Let the user filter rows (filter row and search box)>.

=cut
