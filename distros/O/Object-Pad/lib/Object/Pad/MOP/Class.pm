#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2021 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::Class;

use v5.14;
use warnings;

our $VERSION = '0.36';

# This is an XS-implemented object type provided by Object::Pad itself
require Object::Pad;

=head1 NAME

C<Object::Pad::MOP::Class> - meta-object representation of a C<Object::Pad> class

=head1 DESCRIPTION

Instances of this class represent a class or role implemented by
L<Object::Pad>. Accessors provide information about the class or role, and
methods that can alter the class, typically by adding new elements to it, 
allow a program to extend existing classes.

Where possible, this API is designed to be compatible with L<MOP::Class>.

This API should be considered experimental even within the overall context in
which C<Object::Pad> is expermental.

=cut

=head1 METHODS

=head2 is_class

=head2 is_role

   $bool = $metaclass->is_class
   $bool = $metaclass->is_role

Exactly one of these methods will return true, depending on whether this
metaclass instance represents a true C<class>, or a C<role>.

=head2 name

   $name = $metaclass->name

Returns the name of the class, as a plain string.

=head2 superclasses

   @classes = $metaclass->superclasses

Returns a list of superclasses, as L<Object::Pad::MOP::Class> instances.

Because C<Object::Pad> does not support multiple superclasses, this list will
contain at most one item.

=head2 roles

   @roles = $metaclass->roles

Returns a list of roles implemented by this class, as
L<Object::Pad::MOP::Class> instances.

=head2 compose_role

   $metaclass->compose_role( $rolename )
   $metaclass->compose_role( $rolemeta )

Adds a new role to the list of those implemented by the class.

The new role can be specified either as a plain string giving its name, or as
an C<Object::Pad::MOP::Class> meta instance directly.

=head2 add_BUILD

   $metaclass->add_BUILD( $code )

Adds a new C<BUILD> block to the class, as a CODE reference.

=head2 add_method

   $metamethod = $metaclass->add_method( $name, $code )

Adds a new named method to the class under the given name, as CODE reference.

Returns an instance of L<Object::Pad::MOP::Method> to represent it.

=head2 get_own_method

   $metamethod = $metaclass->get_own_method( $name )

Returns an instance of L<Object::Pad::MOP::Slot> to represent the method of
the given name, if one exists. If not an exception is thrown.

This can only see directly-applied methods; that is, methods created by the
C<method> keyword on the class itself, or added via L</add_method>. This will
not see other names in the package stash, even if they contain a C<CODE> slot,
nor will it see methods inherited from a superclass.

=head2 add_slot

   $metaslot = $metaclass->add_slot( $name )

Adds a new slot to the class, using the given name (which must begin with the
sigil character C<$>, C<@> or C<%>).

Returns an instance of L<Object::Pad::MOP::Slot> to represent it.

=head2 get_slot

   $metaslot = $metaclass->get_slot( $name )

Returns an instance of L<Object::Pad::MOP::Slot> to represent the slot of the
given name, if one exists. If not an exception is thrown.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
