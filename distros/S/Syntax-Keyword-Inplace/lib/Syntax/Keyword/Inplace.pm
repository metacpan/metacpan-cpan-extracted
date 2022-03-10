#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Inplace 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Keyword::Inplace> - syntax for making inplace changes to variables

=head1 SYNOPSIS

   use Syntax::Keyword::Inplace;

   my $var = "some value here";
   inplace uc $var;        # equivalent to  $var = uc $var;

   print $var;             # prints "SOME VALUE HERE"

=head1 DESCRIPTION

This module provides a syntax plugin that implements a single keyword,
C<inplace>, which acts on function calls (or function-like perl operators)
to make them modify the target expression.

Perl has a large number of function-like operators that look at a single
expression argument and return some new value based on it. Sometimes the
result of calling one of these is immediately assigned back into the same
variable again, in code that looks like C<$var = func($var)>. It is for these
situations where this module is intended to apply.

=cut

=head1 KEYWORDS

=head2 inplace

   inplace FUNC( EXPR )

The C<inplace> keyword modifies the behaviour of the following expression,
which must be a function call or function-like core perl operator, which takes
exactly one argument. That single argument must be valid as an lvalue (i.e.
the target of an assignment). At runtime the function is called on that
argument expression and the result of the function call is stored back into
that expression.

   my $var = ...;
   inplace foo( $var );    # equivalent to  $var = foo( $var )

If the expression is more complex than a single variable directly, then any
side-effects involved in generating it only happen once.

   inplace foo( $hash{some_function_call()} );

   # equivalent to
   #   my $tmp_key = some_function_call();
   #   $hash{$tmp_key} = foo( $hash{$tmp_key} );

=cut

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub import_into
{
   my $class = shift;
   my ( $caller, @syms ) = @_;

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Keyword::Inplace/inplace"}++;

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
