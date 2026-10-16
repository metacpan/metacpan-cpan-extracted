package Term::Fabulous::Event::ColumnsChange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::ColumnsChange :isa(Clay::UI::Events::Event) :strict(params) {
	field $visible :param;

	ADJUST {
		die "Term::Fabulous::Event::ColumnsChange: visible must be an array reference" unless ref $visible eq 'ARRAY';
		$visible = [@$visible];
	}

	method event_name :common { 'ColumnsChange' }

	method visible () { return [@$visible] }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::ColumnsChange - The user chose which columns of a table are shown

=head1 SYNOPSIS

	$table->on( ColumnsChange => sub ($event) {
		save_setting( columns => join ',', @{ $event->visible } );
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<ColumnsChange> on itself each
time the user shows or hides a column in its column chooser (see
L<Term::Fabulous::Widget::Table/open_column_chooser>).
The methods L<show_columns|Term::Fabulous::Widget::Table/show_columns> and its relatives fire
nothing. The column chooser is explained in
L<the column chooser section of the tables guide|Term::Fabulous::Manual::Tables/Choosing the visible columns>.

It is a L<Clay::UI::Events::Event> whose name is C<ColumnsChange>;
listen for it with
C<< $table->on( ColumnsChange => sub ($event) { ... } ) >>. It bubbles
to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::ColumnsChange->new( visible => ... );

The table builds these events itself; build one yourself only to test
your listeners. C<visible> is required and must be an array reference;
it is copied. Unknown parameters die.

=over

=item C<visible>

See L</visible>.

=back

=head1 METHODS

=head2 visible

The keys of the visible columns, in their order (a new array
reference).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Manual::Tables/Choosing the visible columns>,
L<Term::Fabulous::Cookbook::Tables/Let the user choose the visible columns (column chooser)>.

=cut
