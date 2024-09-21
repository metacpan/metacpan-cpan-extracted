#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2023 -- leonerd@leonerd.org.uk

package Object::Pad::MOP::Class 0.814;

use v5.18;
use warnings;
use Carp;

# This is an XS-implemented object type provided by Object::Pad itself
require Object::Pad;

=head1 NAME

C<Object::Pad::MOP::Class> - meta-object representation of a C<Object::Pad> class

=head1 DESCRIPTION

=for highlighter language=perl

Instances of this class represent a class or role implemented by
L<Object::Pad>. Accessors provide information about the class or role, and
methods that can alter the class, typically by adding new elements to it, 
allow a program to extend existing classes.

Where possible, this API is designed to be compatible with L<MOP::Class>.

This API should be considered B<experimental>, and will emit warnings to that
effect. They can be silenced with

   use Object::Pad qw( :experimental(mop) );

or

   use Object::Pad::MOP::Class qw( :experimental(mop) );

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
   my $caller = shift;

   Object::Pad->_import_experimental( \@_, qw( mop ) );

   croak "Unrecognised import symbols @_" if @_;
}

=head1 CONSTRUCTOR

=head2 for_class

   $metaclass = Object::Pad::MOP::Class->for_class( $class );

I<Since version 0.38.>

Returns the metaclass instance associated with the given class name. Throws an
exception if the requested class is not using C<Object::Pad>.

=head2 try_for_class

   $metaclass = Object::Pad::MOP::Class->try_for_class( $class );

I<Since version 0.808.>

If the given class name is built using C<Object::Pad> then returns the
metaclass instance for it. If not, returns C<undef>.

=cut

sub try_for_class
{
   shift;
   my ( $targetclass ) = @_;

   my $level = 0;
   $level++ while (caller $level)[0] eq __PACKAGE__;

   my $callerhints = (caller $level)[10];
   if( !$callerhints or !$callerhints->{"Object::Pad/experimental(mop)"} ) {
      warnings::warnif experimental =>
        "Object::Pad::MOP is experimental and may be changed or removed without notice";
   }

   my $code = do {
      my $fqname = "${targetclass}::META";
      no strict 'refs';
      defined &$fqname or return undef;
      \&{"${targetclass}::META"};
   };

   return $code->( $targetclass );
}

sub for_class
{
   my $self = shift;
   my ( $targetclass ) = @_;

   return $self->try_for_class( $targetclass ) //
      croak "Cannot obtain Object::Pad::MOP::Class for '$targetclass' as it does not appear to be based on Object::Pad";
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

=head2 create_class

   my $metaclass = Object::Pad::MOP::Class->create_class( $name, %args );

I<Since version 0.61.>

Creates a new class of the given name and yields the metaclass for it.

Takes the following additional named arguments:

=over 4

=item extends => STRING

=item isa => STRING

An optional name of a superclass that this class will extend. These options
are synonyms; new code should use C<isa>, as C<extends> will eventually be
removed.

=back

Once created, this metaclass must be sealed using the L</seal> method before
it can be used to actually construct object instances.

=head2 create_role

   my $metaclass = Object::Pad::MOP::Class->create_role( $name, %args );

I<Since version 0.61.>

As L</create_class> but creates a role instead of a class.

=cut

sub create_class { shift->_create_class( shift, @_ ); }
sub create_role  { shift->_create_role ( shift, @_ ); }

=head2 begin_class

   BEGIN {
      my $metaclass = Object::Pad::MOP::Class->begin_class( $name, %args );
      ...
   }

I<Since version 0.46.>

A variant of L</create_class> which sets the newly-created class as the
current complication scope of the surrounding code, allowing it to accept
C<Object::Pad> syntax forms such as C<has> and C<method>.

This must be done during C<BEGIN> time because of this compiletime effect.
It additionally creates a deferred code block at C<UNITCHECK> time of its
surrounding scope, which is used to finalise the constructed class. In this
case you do not need to remember to call L</seal> on it; this happens
automatically.

=head2 begin_role

I<Since version 0.46.>

As L</begin_class> but creates a role instead of a class.

=cut

sub begin_class { shift->_create_class( shift, _set_compclassmeta => 1, @_ ); }
sub begin_role  { shift->_create_role ( shift, _set_compclassmeta => 1, @_ ); }

=head1 METHODS

=head2 is_class

=head2 is_role

   $bool = $metaclass->is_class;
   $bool = $metaclass->is_role;

Exactly one of these methods will return true, depending on whether this
metaclass instance represents a true C<class>, or a C<role>.

=head2 name

   $name = $metaclass->name;

Returns the name of the class, as a plain string.

=head2 superclasses

   @classes = $metaclass->superclasses;

Returns a list of superclasses, as L<Object::Pad::MOP::Class> instances.

Because C<Object::Pad> does not support multiple superclasses, this list will
contain at most one item.

=head2 direct_roles

   @roles = $metaclass->direct_roles;

Returns a list of the roles introduced by this class (i.e. added by `does`
declarations but not inherited from the superclass), as
L<Object::Pad::MOP::Class> instances.

This method is also aliased as C<roles>.

=head2 all_roles

   @roles = $metaclass->all_roles;

I<Since version 0.56.>

Returns a list of all the roles implemented by this class (i.e. including
those inherited from the superclass), as L<Object::Pad::MOP::Class> instances.

=head2 add_role

   $metaclass->add_role( $rolename );
   $metaclass->add_role( $rolemeta );

I<Since version 0.56.>

Adds a new role to the list of those implemented by the class.

The new role can be specified either as a plain string giving its name, or as
an C<Object::Pad::MOP::Class> meta instance directly.

Before version 0.56 this was called C<compose_role>.

=head2 add_BUILD

   $metaclass->add_BUILD( $code );

Adds a new C<BUILD> block to the class, as a CODE reference.

=head2 add_method

   $metamethod = $metaclass->add_method( $name, %args, $code );

Adds a new named method to the class under the given name, as CODE reference.

Returns an instance of L<Object::Pad::MOP::Method> to represent it.

Recognises the following additional named arguments:

=over 4

=item common => BOOL

I<Since version 0.62.>

If true, the method is a class-common method.

=back

=head2 get_direct_method

   $metamethod = $metaclass->get_direct_method( $name );

Returns an instance of L<Object::Pad::MOP::Method> to represent the method of
the given name, if one exists. If not an exception is thrown.

This can only see directly-applied methods; that is, methods created by the
C<method> keyword on the class itself, or added via L</add_method>. This will
not see other names in the package stash, even if they contain a C<CODE> slot,
nor will it see methods inherited from a superclass.

This is also aliased as C<get_own_method> for compatibility with the
L<MOP::Class> interface.

=head2 get_method

   $metamethod = $metaclass->get_method( $name );

I<Since version 0.57.>

Returns an instance of L<Object::Pad::MOP::Method> to represent the method of
the given name, if one exists. If not an exception is thrown.

This will additionally search superclasses, and may return a method belonging
to a parent class.

=head2 direct_methods

   @metamethods = $metaclass->direct_methods;

I<Since version 0.57.>

Returns a list of L<Object::Pad::MOP::Method> instances to represent all the
direct methods of the class. This list may be empty.

=head2 all_methods

   @metamethods = $metaclass->all_methods;

I<Since version 0.57.>

Returns a list of L<Object::Pad::MOP::Method> instances to represent all the
methods of the class, including those inherited from superclasses. This list
may be empty.

=head2 add_field

   $metafield = $metaclass->add_field( $name, %args );

I<since version 0.60.>

Adds a new field to the class, using the given name (which must begin with the
sigil character C<$>, C<@> or C<%>).

Recognises the following additional named arguments:

=over 4

=item default => SCALAR

I<Since version 0.43.>

Provides a default value for the field; similar to using the syntax

   has $field = SCALAR;

This value may be C<undef>, to set the value as being optional if it
additionally has a parameter name.

=item param => STRING

I<Since version 0.43.>

Provides a parameter name for the field; similar to setting it using the
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

If true, reference values assigned into the field by the constructor or
accessor methods will be weakened, similar to setting the C<:weak> attribute.

=item attributes => ARRAY

I<Since version 0.811.>

Provides additional attributes to apply to the field, as if declared by
attribute syntax. This is largely useful for applying third-party field
attributes.

The referenced array should contain an even-sized list of pairs. The first of
each pair will be the name of an attribute, and the second will be a value to
pass (or C<undef> if not applicable). Note that if the third-party attribute
provides separate parse and apply phases in its hook functions, the parse part
will I<not> be invoked by this parameter. Whatever value is passed must be
something accepted by the apply phase alone.

=back

Returns an instance of L<Object::Pad::MOP::Field> to represent it.

=head2 add_slot

   $metafield = $metaclass->add_slot( $name, %args );

I<Now deprecated.>

Back-compatibility alias for C<add_field>.

=cut

sub add_slot
{
   my $self = shift;
   carp "->add_slot is now deprecated; use ->add_field instead";
   return $self->add_field( @_ );
}

=head2 get_field

   $metafield = $metaclass->get_field( $name );

I<Since version 0.60.>

Returns an instance of L<Object::Pad::MOP::Field> to represent the field of
the given name, if one exists. If not an exception is thrown.

=head2 get_slot

   $metafield = $metaclass->get_slot( $name );

I<Now deprecated.>

Back-compatibility alias for C<get_field>.

=cut

sub get_slot
{
   my $self = shift;
   carp "->get_slot is now deprecated; use ->get_field instead";
   return $self->get_field( @_ );
}

=head2 fields

   @metafields = $metaclass->fields;

I<Since version 0.60.>

Returns a list of L<Object::Pad::MOP::Field> instances to represent all the
fields of the class. This list may be empty.

=head2 slots

   @metafields = $metaclass->slots;

I<Since version 0.42; now deprecated.>

Back-compatibility alias for C<fields>.

=cut

sub slots
{
   my $self = shift;
   carp "->slots is now deprecated; use ->fields instead";
   return $self->fields;
}

*roles = \&direct_roles;

*get_own_method = \&get_direct_method;

=head2 add_required_method

   $metaclass->add_required_method( $name );

I<Since version 0.61.>

Adds a new required method to the role, whose name is given as a plain string.

Currently returns nothing. This should be considered temporary, as eventually
a metatype for required methods will be added, at which point this method can
return instances of it. It may also take additional parameters to define the
required method with. Currently extra parameters are not permitted.

=head2 required_method_names

   @names = $metaclass->required_method_names;

I<Since version 0.61.>

Returns a list names of required methods for the role, as plain strings.

This should be considered a temporary method. Currently there is no metatype
for required methods, so they are represented as plain strings. Eventually a
type may be defined and a C<required_methods> method will be added.

=cut

=head2 seal

   $metaclass->seal;

I<Since version 0.61.>

If the metaclass was created by L</create_class> or L</create_role>, this
method must be called once everything has been added into it, as the class
will not yet be ready to construct actual object instances before this is
done.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
