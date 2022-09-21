#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Term::VTerm::GlyphInfo 0.08;

use v5.14;
use warnings;

require Term::VTerm;

=head1 NAME

C<Term::VTerm::GlyphInfo> - glyph information for C<Term::VTerm>

=cut

=head1 ACCESSORS

=cut

=head2 chars

   @chars = $info->chars

A list of Unicode character numbers. This list does not include the
terminating 0.

=head2 width

   $width = $info->width

The width of this glyph in screen columns.

=head2 str

   $str = $info->str

A Unicode string containing the characters.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
