#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Object::Pad::SlotAttr::LazyInit 0.02;

use v5.14;
use warnings;

use Object::Pad 0.50;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::SlotAttr::LazyInit> - lazily initialise C<Object::Pad> slots at first read

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::SlotAttr::LazyInit;

   class Item {
      has $uuid :reader :param :LazyInit(_make_uuid);

      method _make_uuid {
         require Data::GUID;
         return Data::GUID->new->as_string;
      }
   }

=head1 DESCRIPTION

This module provides a third-party slot attribute for L<Object::Pad>-based
classes, which declares that the slot it is attached to has a lazy
initialisation method, which will be called the first time the slot's value
is read from.

B<WARNING> The ability for L<Object::Pad> to take third-party slot attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

=head1 SLOT ATTRIBUTES

=head2 :LazyInit

   has $slot :LazyInit(NAME) ...;

Declares that if the slot variable is read from before it has been otherwise
initialised, then the named method will be called first to create an initial
value for it. Initialisation by either by a C<:param> declaration, explicit
assignment into it, or the use of a C<:writer> accessor will set the value for
the slot and mean the lazy initialiser will not be invoked.

After it has been invoked, the value is stored by the slot and thereafter it
will behave as normal; subsequent reads will return the current value, and the
initialiser method will not be invoked again.

In order to avoid the possibility of accidental recursion when generating the
value, it is recommended that the logic in the lazy initialisation method be
as self-contained as possible; ideally not invoking any methods on C<$self>,
and only making use of other slots already declared before the slot being
initialised. By placing the initialiser method immediately after the slot
declaration, before any other slots, you can reduce the possilibity of getting
stuck in such a manner.

   has $slot_zero :param;

   has $slot_one :LazyInit(_make_one);
   method _make_one {
      # we can safely use $slot_zero in here
   }

   has $slot_two :LazyInit(_make_two);
   method _make_two {
      # we can safely use $slot_zero and $slot_one
   }

=cut

sub import
{
   $^H{"Object::Pad::SlotAttr::LazyInit/LazyInit"}++;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
