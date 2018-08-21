#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Dynamically;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Syntax::Keyword::Dynamically> - dynamically change the value of a variable

=head1 SYNOPSIS

   use Syntax::Keyword::Dynamically;

   my $logger = ...;

   sub operate
   {
      dynamically $logger->level = LOG_DEBUG;

      do_things();
   }

=head1 DESCRIPTION

This module provides a syntax plugin that implements a single keyword,
C<dynamically>, which alters the behaviour of a scalar assignment operation.
Syntactically and semantically it is similar to the built-in perl keyword
C<local>, but is implemented somewhat differently to give two key advantages
over regular C<local>:

=over 2

=item *

You can C<dynamically> assign to lvalue functions and accessors.

=item *

You can C<dynamically> assign to regular lexical variables.

=back

Semantically, the behaviour can be considered equivalent to

   {
      my $old = $VAR;
      $VAR = "new value";

      ...

      $VAR = $old;
   }

Except that the old value will also be restored in the case of exceptions,
C<goto>, C<next/last/redo> or similar ways to leave the controlling block
scope.

=cut

=head1 KEYWORDS

=head2 dynamically

   {
      dynamically LVALUE = EXPR;
      ...
   }

The C<dynamically> keyword modifies the behaviour of the following expression.
which must be a scalar assignemnt. Before the new value is assigned to the
lvalue, its current value is captured and stored internally within the Perl
interpreter. When execution leaves the controlling block for whatever reason,
as part of block scope cleanup the saved value is restored.

The LVALUE may be any kind of expression that allows normal scalar assignment;
lexical or package scalar variables, elements of arrays or hashes, or the
result of calling an C<:value> function or method.

If the LVALUE has any GET magic associated with it (including a C<FETCH>
method of a tied scalar) then this will be executed exactly once when the
C<dynamically> expression is evaluated.

If the LVALUE has any SET magic associated with it (including a C<STORE>
method of a tied scalar) then this will be executed exactly once when the
C<dynamically> expression is evaluated, and again a second time when the
controlling scope is unwound.

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

   @syms or @syms = qw( dynamically );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Keyword::Dynamically/dynamically"}++ if delete $syms{dynamically};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
