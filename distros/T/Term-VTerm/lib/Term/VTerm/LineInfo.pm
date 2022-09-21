#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Term::VTerm::LineInfo 0.08;

use v5.14;
use warnings;

require Term::VTerm;

=head1 NAME

C<Term::VTerm::LineInfo> - line information for C<Term::VTerm>

=cut

=head1 ACCESSORS

=cut

=head2 doubleheight

   $dh = $lineinfo->doubleheight

Returns 0 on single-height lines, 1 on the top row of a double-height line, 
and 2 on the bottom row.

=head2 doublewidth

   $dw = $lineinfo->doublewidth

Returns true on lines that are set as double-width.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
