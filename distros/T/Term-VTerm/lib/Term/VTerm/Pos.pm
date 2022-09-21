#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Term::VTerm::Pos 0.08;

use v5.14;
use warnings;

require Term::VTerm;

=head1 NAME

C<Term::VTerm::Pos> - represent an onscreen position for C<Term::VTerm>

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $pos = Term::VTerm::Pos->new( row => $row, col => $col )

Returns a new C<Term::VTerm::Pos> instance.

=cut

sub new
{
   my ( $class, %args ) = @_;
   $class->_new( $args{row}, $args{col} )
}

=head1 ACCESSORS

=head2 row

=head2 col

   $row = $pos->row

   $col = $pos->col

The row and column number of the position, 0-indexed.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
