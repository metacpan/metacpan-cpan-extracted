#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024-- leonerd@leonerd.org.uk

package Syntax::Keyword::PhaserExpression 0.01;

use v5.18;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Keyword::PhaserExpression> - phasers as arbitrary expressions rather than blocks

=head1 SYNOPSIS

=for highlighter language=perl

   use Syntax::Keyword::PhaserExpression;

   if( BEGIN $ENV{DEBUG} ) {
      printf STDERR "Here's a debugging message> %s\n", gen_debug();
   }

=head1 DESCRIPTION

This module provides a syntax plugin that alters the behaviour of perl's
C<BEGIN> keyword. This allows hoisting an expression to be evaluated at
compile-time, and replace its result into the compiled code. This may be
useful for performance, to avoid otherwise-expensive calls whose value won't
change, or to inline constants for other performance-related benefits.

There may also be situations where it is useful to have expressions evaluated
early enough in compiletime so that their effects can influence the
compilation of later code.

=cut

=head1 KEYWORDS

=cut

=head2 BEGIN

   BEGIN expr...

An expression prefixed with the C<BEGIN> keyword is evaluated as soon as it is
compiled. The scalar result is then captured and inlined, as a constant, into
the surrounding code.

As the expression is not a full block, it does not create a surrounding scope
that hides lexical variables inside it. This can be useful for assigning a
value to a variable at compiletime so that later compiletime expressions can
see its value.

   BEGIN my $arg = "the value";
   use Some::Module arg => $arg;

Note that the expression may not start with an open brace (C<{>) character, as
that is used by regular Perl's C<BEGIN> block. This module does not replace
that syntax.

=cut

=head1 TODO

=over 4

=item *

Implement some other phaser keywords. C<CHECK> and C<INIT> might be useful.
Not C<END> for obvious reasons. ;)

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
