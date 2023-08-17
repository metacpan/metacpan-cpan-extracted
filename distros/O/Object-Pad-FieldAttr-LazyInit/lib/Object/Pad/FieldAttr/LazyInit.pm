#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package Object::Pad::FieldAttr::LazyInit 0.06;

use v5.14;
use warnings;

use Object::Pad 0.66;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::FieldAttr::LazyInit> - lazily initialise C<Object::Pad> fields at first read

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::FieldAttr::LazyInit;

   class Item {
      field $uuid :reader :param :LazyInit(_make_uuid);

      method _make_uuid {
         require Data::GUID;
         return Data::GUID->new->as_string;
      }
   }

=head1 DESCRIPTION

This module provides a third-party field attribute for L<Object::Pad>-based
classes, which declares that the field it is attached to has a lazy
initialisation method, which will be called the first time the field's value
is read from.

B<WARNING> The ability for L<Object::Pad> to take third-party field attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

=head1 FIELD ATTRIBUTES

=head2 :LazyInit

   field $name :LazyInit(NAME) ...;

Declares that if the field variable is read from before it has been otherwise
initialised, then the named method will be called first to create an initial
value for it. Initialisation by either by a C<:param> declaration, explicit
assignment into it, or the use of a C<:writer> accessor will set the value for
the field and mean the lazy initialiser will not be invoked.

After it has been invoked, the value is stored by the field and thereafter it
will behave as normal; subsequent reads will return the current value, and the
initialiser method will not be invoked again.

In order to avoid the possibility of accidental recursion when generating the
value, it is recommended that the logic in the lazy initialisation method be
as self-contained as possible; ideally not invoking any methods on C<$self>,
and only making use of other fields already declared before the field being
initialised. By placing the initialiser method immediately after the field
declaration, before any other fields, you can reduce the possibility of
getting stuck in such a manner.

   field $field_zero :param;

   field $field_one :LazyInit(_make_one);
   method _make_one {
      # we can safely use $field_zero in here
   }

   field $field_two :LazyInit(_make_two);
   method _make_two {
      # we can safely use $field_zero and $field_one
   }

=cut

sub import
{
   $^H{"Object::Pad::FieldAttr::LazyInit/LazyInit"}++;
}

sub unimport
{
   delete $^H{"Object::Pad::FieldAttr::LazyInit/LazyInit"};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
