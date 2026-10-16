package Term::Fabulous::Event::Expand;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Expand :isa(Clay::UI::Events::Event) :strict(params) {
	field $row_id :param :reader = undef;
	field $group_path :param = undef;

	ADJUST {
		die "Term::Fabulous::Event::Expand: group_path must be undef or an array reference" if defined $group_path && ref $group_path ne 'ARRAY';
		$group_path = [@$group_path] if defined $group_path;
	}

	method event_name :common { 'Expand' }

	method group_path () { return defined $group_path ? [@$group_path] : undef }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Expand - The user opened a row or a group of a table

=head1 SYNOPSIS

	$tree->on( Expand => sub ($event) {
		my $id = $event->row_id // return;    # a group was opened
		$status->text( scalar( $tree->children_of($id) ) . ' entries in ' . $tree->row($id)->{name} );
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<Expand> on itself when the
user opens a tree row that has children (showing them) or a collapsed
group: with a click on the marker in front of it or, for a group,
anywhere on its header; with C<Right> or C<+> on it; or with C<Enter>
or C<Space> on a group header. A click fires it after the
L<Term::Fabulous::Event::CursorMove> the click causes.

Opening from your program (C<expand>, C<expand_all>, C<expand_group>,
C<expand_all_groups>) fires nothing, and neither does the table opening
rows to show what a filter found. Its counterpart is
L<Term::Fabulous::Event::Collapse>. Groups and trees are explained in
L<Term::Fabulous::Manual::TableRows/Opening and closing groups> and
L<Term::Fabulous::Manual::TableRows/Opening and closing tree rows>.

It is a L<Clay::UI::Events::Event> whose name is C<Expand>; listen for
it with C<< $table->on( Expand => sub ($event) { ... } ) >>. It bubbles
to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Expand->new( row_id => ..., group_path => ... );

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

The id of the row that was opened, or C<undef> for a group.

=head2 group_path

For a group, the values of the group and of the groups around it,
outermost first (a new array reference); C<undef> for a row.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::TableRows/Show nested data as a tree (expand and collapse rows)>,
L<Term::Fabulous::Cookbook::TableRows/Group rows by a column (collapsible group headers)>.

=cut
