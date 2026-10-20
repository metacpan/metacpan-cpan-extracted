package Term::Fabulous::Widget::Table::Toggle;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

class Term::Fabulous::Widget::Table::Toggle :isa(Term::Fabulous::Widget::Box) :strict(params) {
	field $line_key :param :reader;
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Toggle - The marker that opens and closes a row or group of a table

=head1 DESCRIPTION

The small box in front of a tree row with children and of a group header
of a L<Term::Fabulous::Widget::Table>, which shows whether it is open
and opens or closes it when it is clicked. C<line_key> is the key of
its line in the table's model. The table builds and changes it; do not
change it.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>.

=cut
