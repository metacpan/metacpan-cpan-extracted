package Term::Fabulous::Widget::Table::Cell;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Role::Layout::GridCell;
use Term::Fabulous::Widget::Box;

class Term::Fabulous::Widget::Table::Cell
	:isa(Term::Fabulous::Widget::Box)
	:does(Clay::UI::Role::Layout::GridCell)
	:strict(params)
{
	use Term::Fabulous::Check qw(one_of);

	# Which part of the table the cell belongs to ('header', 'filter',
	# 'body', 'ledge'), the line it shows (a line key of the table's model;
	# undef outside the body) and its column (a column key, '' for the
	# selection column, undef for a cell that spans the columns).
	field $part       :param :reader = 'body';
	field $line_key   :param :reader = undef;
	field $column_key :param :reader = undef;

	ADJUST {
		one_of( $self, part => $part, qw(header filter body ledge) );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Cell - A cell of a table

=head1 DESCRIPTION

The box L<Term::Fabulous::Widget::Table> puts around every cell it
shows: header cells, filter fields, data cells, the cells that span the
columns (group headers, the text of an empty table) and the empty cells
of the I<ledges>, the rows that only draw the top of the frame (without
column titles) or its bottom (see
L<Term::Fabulous::Widget::Table::Borders/Who draws it>). It is a
L<Term::Fabulous::Widget::Box> that composes
L<Clay::UI::Role::Layout::GridCell>, so the table's grids size it as the
cell of its column and row. The table gives it its background, padding
and border (the grid lines), and its content: the widget a column's
C<cell> option returns, or a L<Term::Fabulous::Widget::Text>.

The table builds and changes these boxes itself; do not change them.
They are useful for reading: a C<Mouse> event on a table cell has the
cell (or a widget inside it) as its target, and C<line_key>,
C<column_key> and C<part> tell which cell it is.

=head1 METHODS

=head2 part

C<'header'>, C<'filter'>, C<'body'> or C<'ledge'>.

=head2 line_key

The key of the line of the table's model the cell belongs to (see
L<Term::Fabulous::Widget::Table::Model/Lines>), or C<undef> outside the
body.

=head2 column_key

The key of the cell's column; C<''> for the selection column, C<undef>
for a cell that spans the columns.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>.

=cut
