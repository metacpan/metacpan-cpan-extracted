#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2021 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::Class 0.56;

use v5.14;
use warnings;

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

=head1 CONSTRUCTOR

=head2 for_class

   $metaclass = Object::Pad::MOP::Class->for_class( $class )

I<Since version 0.38.>

Returns the metaclass instance associated with the given class name.

=cut

sub for_class
{
   shift;
   my ( $targetclass ) = @_;

   return $targetclass->META;
}

=head2 for_caller

   $metaclass = Object::Pad::MOP::Class->for_caller;

I<Since version 0.38.>

A convenient shortcut for obtaining the metaclass instance of the calling
package scope. Often handy during C<BEGIN> blocks of the class itself to
perform adjustments or additions.

   class Some::Class::Here 1.234 {
      BEGIN {
         my $meta = Object::Pad::MOP::Class->for_caller;
         ...
      }
   }

=cut

sub for_caller
{
   return shift->for_class( caller );
}

=head2 begin_class

   BEGIN {
      my $metaclass = Object::Pad::MOP::Class->begin_class( $name, %args )
      ...
   }

I<Since version 0.46.>

Creates a new class of the given name and yields the metaclass for it. This
must be done during C<BEGIN> time, as it creates a deferred code block at
C<UNITCHECK> time of its surrounding scope, which is used to finalise the
constructed class.

Takes the following additional named arguments:

=over 4

=item extends => STRING

An optional name of a superclass that this class will extend.

=back

=head2 begin_role

I<Since version 0.46.>

As L</begin_class> but creates a role instead of a class.

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

=head2 direct_roles

   @roles = $metaclass->direct_roles

Returns a list of the roles introduced by this class (i.e. added by `does`
declarations but not inherited from the superclass), as
L<Object::Pad::MOP::Class> instances.

This method is also aliased as C<roles>.

=head2 all_roles

   @roles = $metaclass->all_roles

I<Since version 0.56.>

Returns a list of all the roles implemented by this class (i.e. including
those inherited from the superclass), as L<Object::Pad::MOP::Class> instances.

=head2 add_role

   $metaclass->add_role( $rolename )
   $metaclass->add_role( $rolemeta )

I<Since verison 0.56.>

Adds a new role to the list of those implemented by the class.

The new role can be specified either as a plain string giving its name, or as
an C<Object::Pad::MOP::Class> meta instance directly.

Before version 0.56 this was called C<compose_role>.

=head2 add_BUILD

   $metaclass->add_BUILD( $code )

Adds a new C<BUILD> block to the class, as a CODE reference.

=head2 add_method

   $metamethod = $metaclass->add_method( $name, $code )

Adds a new named method to the class under the given name, as CODE reference.

Returns an instance of L<Object::Pad::MOP::Method> to represent it.

=head2 get_own_method

   $metamethod = $metaclass->get_own_method( $name )

Returns an instance of L<Object::Pad::MOP::Method> to represent the method of
the given name, if one exists. If not an exception is thrown.

This can only see directly-applied methods; that is, methods created by the
C<method> keyword on the class itself, or added via L</add_method>. This will
not see other names in the package stash, even if they contain a C<CODE> slot,
nor will it see methods inherited from a superclass.

=head2 add_slot

   $metaslot = $metaclass->add_slot( $name, %args )

Adds a new slot to the class, using the given name (which must begin with the
sigil character C<$>, C<@> or C<%>).

Recognises the following additional named arguments:

=over 4

=item default => SCALAR

I<Since version 0.43.>

Provides a default value for the slot; similar to using the syntax

   has $slot = SCALAR;

This value may be C<undef>, to set the value as being optional if it
additionally has a parameter name.

=item param => STRING

I<Since version 0.43.>

Provides a parameter name for the slot; similar to setting it using the
C<:param> attribute. This parameter will be required unless a default value is
set (such value may still be C<undef>).

=item reader => STRING

=item writer => STRING

=item mutator => STRING

I<Since version 0.46.>

=item accessor => STRING

I<Since version 0.56.>

Provides method names for generated reader, writer, lvalue-mutator or
reader+writer accessor methods, similar to setting them via the C<:reader>,
C<:writer>, C<:mutator> or C<:accessor> attributes.

=item weak => BOOL

I<Since version 0.46.>

If true, reference values assigned into the slot by the constructor or
accessor methods will be weakened, similar to setting the C<:weak> attribute.

=back

Returns an instance of L<Object::Pad::MOP::Slot> to represent it.

=head2 get_slot

   $metaslot = $metaclass->get_slot( $name )

Returns an instance of L<Object::Pad::MOP::Slot> to represent the slot of the
given name, if one exists. If not an exception is thrown.

=head2 slots

   @metaslots = $metaclass->slots

I<Since version 0.42.>

Returns a list of L<Object::Pad::MOP::Slot> instances to represent all the
slots of the class. This list may be empty.

=cut

*roles = \&direct_roles;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
