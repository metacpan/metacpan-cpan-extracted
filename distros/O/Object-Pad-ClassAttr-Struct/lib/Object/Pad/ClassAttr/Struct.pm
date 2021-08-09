#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Object::Pad::ClassAttr::Struct 0.01;

use v5.14;
use warnings;

use Object::Pad 0.50;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::ClassAttr::Struct> - declare an C<Object::Pad> class to be struct-like

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::ClassAttr::Struct;

   class Colour :Struct {
      # These get :param :mutator automatically
      has $red   = 0;
      has $green = 0;
      has $blue  = 0;

      # Additional methods are still permitted
      method lightness {
         return ($red + $green + $blue) / 3;
      }
   }

   my $cyan = Colour->new( green => 1, blue => 1 );

=head1 DESCRIPTION

This module provides a third-party class attribute for L<Object::Pad>-based
classes, which applies some attributes automatically to every slot added to
the class, as a convenient shortcut for making structure-like classes.

=head1 CLASS ATTRIBUTES

=head2 :Struct

   class Name :Struct ... { ... }

Automatically applies the C<:param> and C<:mutator> attributes to every slot
defined on the class.

=cut

sub import
{
   $^H{"Object::Pad::ClassAttr::Struct/Struct"}++;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
