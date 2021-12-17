#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Keyword::MultiSub 0.02;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=encoding UTF-8

=head1 NAME

C<Syntax::Keyword::MultiSub> - multiple dispatch on subroutines

=head1 SYNOPSIS

   use v5.26;
   use Syntax::Keyword::MultiSub;
   use experimental 'signatures';

   multi sub max()          { return undef; }
   multi sub max($x)        { return $x; }
   multi sub max($x, @more) { my $y = max(@more);
                              return $x > $y ? $x : $y; }

   say max(1, 2, 15, 3, 4);  # prints 15

=head1 DESCRIPTION

This module provides a new keyword, C<multi>, to put before subroutine
declarations, which permits multiple distinct function bodies to be provided,
which take different parameters. A call to a C<multi sub> will invoke
whichever function body best fits the arguments passed.

Currently this module can only make dispatching decisions based on the number
of arguments as compared to the number of signature parameters each body was
expecting. It requires F<perl> version 5.26 or above, in order to get enough
support from signatures. Note also enabling this module does not enable the
C<signatures> feature; you must do that independently.

=cut

=head1 KEYWORDS

=head2 multi

   multi sub NAME (SIGNATURE) { BODY... }

Declares an alternative for the C<multi sub> of the given name. Each
alternative will be distinguished by the number of parameters its signature
declares. If the signature includes optional parameters, this alternative is
considered to cover the entire range from none to all of the optional ones
being present. The ranges of parameter count covered by every alternative to
a given function name must be non-overlapping; it is a compiletime error for
two function bodies to claim the same number of parameters.

Each of the non-final alternatives for any given name must use only scalar
parameters (though some may be optional); but as a special-case, the final
alternative may end in a slurpy parameter (either an array or a hash). If this
is the case then it will be considered for dispatch if none of the previous
alternatives match, as long as it has at least the minimum number of required
parameters present.

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
   $^H{"Syntax::Keyword::MultiSub/multi"}++;

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 WITH OTHER MODULES

=head2 Future::AsyncAwait

As of L<Future::AsyncAwait> version 0.55 a cross-module integration test
asserts that the C<multi> modifier can be applied to C<async sub>.

   use Future::AsyncAwait;
   use Syntax::Keyword::MultiSub;

   async multi sub f () { return "nothing"; }
   async multi sub f ($key) { return await get_thing($key); }

=head1 TODO

=over 4

=item *

Much better error checking and diagnostics for function bodies that don't use
signatures.

=item *

Cross-module testing with L<Object::Pad> (for C<multi method>). This may
require a better combined implementation, to be aware of method resolution
order, inheritence, etc...

=item *

An eventual consideration of type assertions or value testing, as well as
simple argument count.

This particular task is likely to be a large undertaking as it spans several
other areas of language. As well as types on parameters, it would be nice to 
put them on lexical variables, object slots, C<match/case> comparisons, and so
on. It would be a shame to invent a special mechanism for one of these areas
that could not be reüsed by the others.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
