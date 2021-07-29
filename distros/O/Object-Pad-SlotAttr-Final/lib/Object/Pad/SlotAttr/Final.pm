#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Object::Pad::SlotAttr::Final 0.01;

use v5.14;
use warnings;

use Object::Pad 0.47;
BEGIN {
   $Object::Pad::VERSION eq "0.47" or
      die "Require exactly Object::Pad version 0.47";
}

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::SlotAttr::Final> - declare C<Object::Pad> slots readonly after construction

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::SlotAttr::Final;

   class Rectangle {
      has $width  :param :reader :Final;
      has $height :param :reader :Final;

      has $area :reader :Final;

      ADJUST {
         $area = $width * $height;
      }
   }

=head1 DESCRIPTION

This module provides a third-party slot attribute for L<Object::Pad>-based
classes, which declares that the slot it is attached to shall be set as
readonly when the constructor returns, disallowing further modification to it.

B<WARNING> The ability for L<Object::Pad> to take third-party slot attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental. As
a further point, it is currently pinned to requiring an exact
C<$Object::Pad::VERSION> of 0.47, to defend against possible API or ABI
breakage. It is expected that as the API eventually stablises, this
restriction can be removed.

=head1 SLOT ATTRIBUTES

=head2 :Final

   has $slot :Final ...;
   has $slot :Final ... = DEFAULT;

Declares that the slot variable will be set readonly at the end of the
constructor, after any assignments from C<:param> declarations or C<ADJUST>
blocks. At this point, the value cannot otherwise be modified by directly
writing into the slot variable.

   has $slot :Final;

   ADJUST { $slot = 123; }    # this is permitted

   method m { $slot = 456; }  # this will fail

Note that this is only a I<shallow> readonly setting; if the slot variable
contains a reference to a data structure, that structure itself remains
mutable.

   has $aref :Final;
   ADJUST { $aref = []; }

   method more { push @$aref, "another"; }   # this is permitted

=cut

sub import
{
   $^H{"Object::Pad::SlotAttr::Final/Final"}++;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
