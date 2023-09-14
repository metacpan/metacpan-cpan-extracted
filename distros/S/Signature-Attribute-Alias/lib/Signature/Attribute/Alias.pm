#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Signature::Attribute::Alias 0.01;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Signature::Attribute::Alias> - make signature parameters that alias caller-provided values

=head1 SYNOPSIS

   use v5.26;
   use Sublike::Extended;
   use Signature::Attribute::Alias;
   use experimental 'signatures';

   extended sub trim_spaces ($s :Alias) {
      $s =~ s/^\s+//;
      $s =~ s/\s+$//;
   }

   my $string = "  hello, world!    ";
   trim_spaces $string;
   say "<$string>";

=head1 DESCRIPTION

This module provides a third-party subroutine parameter attribute via
L<XS::Parse::Sublike>, which declares that the parameter will alias the value
passed by the caller, rather than take a copy of it.

B<WARNING> The ability for sublike constructions to take third-party parameter
attributes is still new and highly experimental, and subject to much API
change in future. As a result, this module should be considered equally
experimental. Core perl's parser does not permit parameters to take
attributes. This ability must be requested specially; either by using
L<Sublike::Extended>, or perhaps enabled directly by some other sublike
keyword using the C<XS::Parse::Sublike> infrastructure.

=head1 PARAMETER ATTRIBUTES

=head2 :Alias

   extended sub f($x :Alias) { ... }

Declares that the lexical variable created by the parameter will be an alias
to the value passed in by the caller rather than, as would normally be the
case, simply contain a copy it. This means that any modifications of the
lexical within the subroutine will be reflected in the value from the caller -
which, therefore - must be mutable.

It is not automatically an error if the caller passes in an immutable value
(such as a constant), but any attempt to modify it will yield the usual
"Modification of read-only value attempted ..." warning from within the body
of the subroutine.

This attribute can only be applied to positional, scalar parameters that are
mandatory; i.e. do not have a defaulting expression.

=cut

sub import
{
   $^H{"Signature::Attribute::Alias/Alias"}++;
}

sub unimport
{
   delete $^H{"Signature::Attribute::Alias/Alias"};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
