#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Term::VTerm::Rect 0.07;

use v5.14;
use warnings;

require Term::VTerm;

=head1 NAME

C<Term::VTerm::Rect> - represent an onscreen rectangle for C<Term::VTerm>

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $rect = Term::VTerm::Rect->new(
      start_row => ..., end_row => ...,
      start_col => ..., end_col => ...,
   )

Returns a new C<Term::VTerm::Rect> instance.

=cut

sub new
{
   my ( $class, %args ) = @_;
   $class->_new( $args{start_row}, $args{end_row}, $args{start_col}, $args{end_col} )
}

=head1 ACCESSORS

=cut

=head2 start_row

=head2 start_col

   $row = $rect->start_row

   $col = $rect->start_col

The row and column number of the top left corner of the rectangle.

=head2 end_row

=head2 end_col

   $row = $rect->end_row

   $col = $rect->end_col

The row and column number of the cell just after the bottom right corner of
the rectangle; i.e. exclusive limit.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
