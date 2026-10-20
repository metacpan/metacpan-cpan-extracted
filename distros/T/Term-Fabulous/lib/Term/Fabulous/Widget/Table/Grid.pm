package Term::Fabulous::Widget::Table::Grid;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Grid;

class Term::Fabulous::Widget::Table::Grid :does(Clay::UI::Grid) :strict(params) {
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Grid - The grids of a table

=head1 DESCRIPTION

A plain L<Clay::UI::Grid>. L<Term::Fabulous::Widget::Table> lays out
its header and its body each in one; the body grid shares the columns of
the header grid (C<share_columns_with>), so the columns line up while
the body scrolls below the header. The table changes their rows itself.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Clay::UI::Grid>.

=cut
