#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021,2022 -- leonerd@leonerd.org.uk

package Syntax::Operator::In 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::In> - placeholder module for infix element-of-list meta-operator

=head1 DESCRIPTION

This empty module is a placeholder for eventually implementing syntax for a
generic element-of-list meta-operator, perhaps using syntax such as the
following:

   use Syntax::Operator::In;

   if($x in<eq> @some_strings) {
      say "x is one of the given strings";
   }

It is currently empty, because the underlying syntax parsing module,
L<XS::Parse::Infix>, does not yet support the additional syntax required to
parameterize this meta-operator.

Instead, for operators that already specialize on string or numerical
equality, see instead L<Syntax::Operator::Elem>.

=head1 TODO

=over 4

=item *

Improve runtime performance of compiletime-constant sets of strings, by
detecting when the RHS contains string constants and convert it into a hash
lookup.

=item *

The real C<in> meta-operator. This first requires more extensive parsing
support from L<XS::Parse::Infix>.

=item *

Consider cross-module integration with L<Syntax::Keyword::Match>, permitting

   match($val : elem) {
      case(@arr_of_strings) { ... }
   }

Or perhaps this would be too weird, and maybe C<match/case> should have an
"any-of" list/array matching ability itself. See also
L<https://rt.cpan.org/Ticket/Display.html?id=143482>.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
