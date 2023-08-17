#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk

package Syntax::Operator::Identical 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=encoding UTF-8

=head1 NAME

C<Syntax::Operator::Identical> - almost certainly a terrible idea; don't use this

=head1 SYNOPSIS

You almost certainly don't want to use this.

However, if despite all my warnings you still want to, then on Perl v5.38 or
later:

   use v5.38;
   use Syntax::Operator::Identical;

   my $x = ...;
   my $y = ...;

   if( $x ≡ $y ) {
      say "x and y are identical";
   }

Or via L<Syntax::Keyword::Match> on Perl v5.14 or later:

   use v5.14;
   use Syntax::Keyword::Match;
   use Syntax::Operator::Identical;

   my $x = ...;

   match($x : ≡) {
      case(undef) { say "The value is not defined" }
      case(123)   { say "The value is identical to 123" }
      case("abc") { say "The value is identical to abc" }
   }

=head1 DESCRIPTION

This module provides an infix operator that implements an identity test
between two values, in a way somewhat similar to the now-deprecated smartmatch
(C<~~>) operator, or other similar ideas.

It is probably not a good idea to use this operator; it is written largely as
a demonstration on how such an operator I<could> be implemented, as well as to
illustrate how fragile it is, in particular around the "is it a string or a
number?" part of the logic.

=head2 Comparison Logic

This operator acts symmetrically; that is, given any pair of values C<$x> and
C<$y>, the result of C<$x ≡ $y> will be the same as C<$y ≡ $x>. It uses the
following rules:

=over 4

=item * Definedness

If both values are C<undef>, the operator yields true. Otherwise, if one value
is defined and the other is not, it yields false.

=item * Booleans (on Perl v5.36 or later)

If both values are booleans (as according to C<builtin::isbool>), then the
operator returns true or false depending on whether they have the same value.
Otherwise, if only one is a boolean then it yields false.

=item * References

If both values are references, the operator yields true or false depending on
whether they both refer to the same thing. Otherwise, if only one is a
reference it returns false.

=item * Non-references

For any other pairs of values, if I<either> value has a numerical part, then a
numerical comparison is made as per the C<==> operator, and if that is false
then this operator yields false. Then, if I<either> value has a stringy part,
then a string comparison is made as per the C<eq> operator, and if that is
false then this operator yields false. Because non-defined and reference
values have already been considered at this point, at least one of these tests
must necessarily be performed.

At this point, if there are no other reasons to reject it, the operator yields
true.

=back

As a consequence of the boolean rule, on Perl v5.36 or later, real boolean
values are not identical to either the numfied or stringified values they
would yield.

   (5 == 5) == 1;   # is true
   (5 == 5) ≡  1;   # is false

   (5 == 5) eq "1";   # is true
   (5 == 5) ≡  "1";   # is false

As a consequence of the reference rule, references are not identical to a
numified or stringified copy of themselves.

   my $aref = [];

   $aref == 0+$aref;   # is true
   $aref ≡  0+$aref;   # is false

   $aref eq "$aref";   # is true
   $aref ≡  "$aref";   # is false

Also as a consequence of the reference rule, any reference to an object is
never considered identical to a plain string or number, I<even if> that object
overloads the string or number comparison operators in a way that would
consider it to be.

As a consequence of the final non-reference rule, comparisons between a
mixture of pure-number and pure-string values will be more strict than either
the C<==> or C<eq> operator alone would perform. Both operators must consider
the values equal for it to pass.

   10 == "10.0";   # is true
   10 ≡  "10.0";   # is false, because eq says so

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->import_into( $caller, @_ );
}

sub unimport
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->unimport_into( $caller, @_ );
}

sub import_into   { shift->apply( 1, @_ ) }
sub unimport_into { shift->apply( 0, @_ ) }

sub apply
{
   my $pkg = shift;
   my ( $on, $caller, @syms ) = @_;

   @syms or @syms = qw( identical );

   my %syms = map { $_ => 1 } @syms;
   if( delete $syms{identical} ) {
      $on ? $^H{"Syntax::Operator::Identical/identical"}++
          : delete $^H{"Syntax::Operator::Identical/identical"};
   }

   foreach (qw( is_identical is_not_identical )) {
      next unless delete $syms{$_};

      no strict 'refs';
      $on ? *{"${caller}::$_"} = \&{$_}
          : warn "TODO: implement unimport of package symbol";
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 ≡, =:=

   my $equal = $lhs ≡ $rhs;
   my $equal = $lhs =:= $rhs;

Yields true if the two operands are identical, using the rules defined above.
The two different spellings are aliases; the latter is simply an ASCII-safe
variant to avoid needing to type the C<≡> symbol.

=head2 ≢, !:=

   my $unequal = $lhs ≢ $rhs;
   my $unequal = $lhs !:= $rhs;

The complement operator to C<≡>; yielding true where it would yield false, and
vice versa. The two different spellings are aliases; the latter is simply an
ASCII-safe variant to avoid needing to type the C<≢> symbol.

=head1 FUNCTIONS

As a convenience, the following functions may be imported which implement the
same behaviour as the infix operators, though are accessed via regular
function call syntax.

These wrapper functions are implemented using L<XS::Parse::Infix>, and thus
have an optimising call-checker attached to them. In most cases, code which
calls them should not in fact have the full runtime overhead of a function
call because the underlying test operator will get inlined into the calling
code at compiletime. In effect, code calling these functions should run with
the same performance as code using the infix operators directly.

=head2 is_identical

   my $equal = is_identical( $lhs, $rhs );

A function version of the C<≡> operator.

=head2 is_not_identical

   my $unequal = is_not_identical( $lhs, $rhs );

A function version of the C<≢> operator.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
