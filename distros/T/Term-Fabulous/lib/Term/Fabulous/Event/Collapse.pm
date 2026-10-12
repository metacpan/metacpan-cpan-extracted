package Term::Fabulous::Event::Collapse;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Collapse :isa(Clay::UI::Events::Event) :strict(params) {
	field $row_id :param :reader = undef;
	field $group_path :param = undef;

	ADJUST {
		die "Term::Fabulous::Event::Collapse: group_path must be undef or an array reference" if defined $group_path && ref $group_path ne 'ARRAY';
		$group_path = [@$group_path] if defined $group_path;
	}

	method event_name :common { 'Collapse' }

	method group_path () { return defined $group_path ? [@$group_path] : undef }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Collapse - The user closed a row or a group of a table

=head1 SYNOPSIS

	$table->on( Collapse => sub ($event) {
		say 'closed ', defined $event->row_id ? 'row ' . $event->row_id : "group @{ $event->group_path }";
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Table> fires C<Collapse> on itself when the
user closes an open tree row (hiding its children) or an open group:
with a click on the marker in front of it or, for a group, anywhere on
its header; with C<Left> or C<-> on it; or with C<Enter> or C<Space> on
a group header. A click fires it after the
L<Term::Fabulous::Event::CursorMove> the click causes.

Closing from your program (C<collapse>, C<collapse_all>,
C<collapse_group>, C<collapse_all_groups>) fires nothing. Its
counterpart is L<Term::Fabulous::Event::Expand>. Groups and trees are
explained in L<Term::Fabulous::Manual::TableRows/Opening and closing groups>
and L<Term::Fabulous::Manual::TableRows/Opening and closing tree rows>.

It is a L<Clay::UI::Events::Event> whose name is C<Collapse>; listen
for it with C<< $table->on( Collapse => sub ($event) { ... } ) >>. It
bubbles to the table's ancestors like every event (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Collapse->new( row_id => ..., group_path => ... );

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

The id of the row that was closed, or C<undef> for a group.

=head2 group_path

For a group, the values of the group and of the groups around it,
outermost first (a new array reference); C<undef> for a row.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::TableRows/Group rows by a column (collapsible group headers)>,
L<Term::Fabulous::Cookbook::TableRows/Show nested data as a tree (expand and collapse rows)>.

=cut
