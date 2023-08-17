#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package Object::Pad::FieldAttr::Final 0.06;

use v5.14;
use warnings;

use Object::Pad 0.66;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::FieldAttr::Final> - declare C<Object::Pad> fields readonly after construction

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::FieldAttr::Final;

   class Rectangle {
      field $width  :param :reader :Final;
      field $height :param :reader :Final;

      field $area :reader :Final;

      ADJUST {
         $area = $width * $height;
      }
   }

=head1 DESCRIPTION

This module provides a third-party field attribute for L<Object::Pad>-based
classes, which declares that the field it is attached to shall be set as
readonly when the constructor returns, disallowing further modification to it.

B<WARNING> The ability for L<Object::Pad> to take third-party field attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

=head1 FIELD ATTRIBUTES

=head2 :Final

   field $name :Final ...;
   field $name :Final ... = DEFAULT;

Declares that the field variable will be set readonly at the end of the
constructor, after any assignments from C<:param> declarations or C<ADJUST>
blocks. At this point, the value cannot otherwise be modified by directly
writing into the field variable.

   field $x :Final;

   ADJUST { $x = 123; }    # this is permitted

   method m { $x = 456; }  # this will fail

Note that this is only a I<shallow> readonly setting; if the field variable
contains a reference to a data structure, that structure itself remains
mutable.

   field $aref :Final;
   ADJUST { $aref = []; }

   method more { push @$aref, "another"; }   # this is permitted

=cut

sub import
{
   $^H{"Object::Pad::FieldAttr::Final/Final"}++;
}

sub unimport
{
   delete $^H{"Object::Pad::FieldAttr::Final/Final"};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
