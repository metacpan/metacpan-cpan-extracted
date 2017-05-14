package Myco::Entity;

###############################################################################
# $Id: Entity.pm,v 1.6 2006/03/31 19:12:57 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity - common base class for all Myco entity classes.

=head1 SYNOPSIS

 ### Entity class definition

 package Myco::Foo;
 use base qw(Myco::Entity);

 # Start building metadata
 my $metadata = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'Foo' }
  );

 $metadata->add_attribute(name => 'attr1', type => 'string');
 $metadata->add_attribute(name => 'attr2', type => 'string');

 #    class-specific methods defined ...
 #

 # Fill in $schema with all added_attributes and discover other metadata
 $metadata->activate_class;



 ### Entity class usage

 use Myco::Foo;

 # Constructor
 $obj = Myco::Foo->new;
 $obj = Myco::Foo->new(attr1 => value, attr2 => value);

 # Access class metadata (see Myco::Entity::Meta)
 $meta = Myco::Foo->introspect;
 $meta = $obj->introspect;

 # Accessors
 $obj->get_attr1;              # get attribute value
 $obj->set_attr1('value');     # set attribute value

 # Instance methods
 $id = $obj->save;             # update object's state in persistent
                               # storage, create new record if needed;
                               # returns object's Tangram id
 $obj->destroy;
 $obj->modify(attr1 => val, attr2 => val);
 $object_id = $obj->id;
 $obj->is_transient;           # returns true if object is in Tangram
                               # transient storage

 ## object retrieval (see class Myco documentation
 #    for full detail)

 $obj = Myco->load($object_id);

 # fetch all objects of given type
 @objects = Myco->select(ref $obj);


=head1 DESCRIPTION

Provides, via inheritence, common interface in support of basic lifecycle
needs for myco entity objects.

This is accomplished through the encapsulation of the CPAN module
Class::Tangram which provides a basis for "in-memory" object behavior.
Consult its documentation for details on schema definition syntax,
getter/setter behavior, check functions, etc.

The common interface for object persistence behavior (referred within
myco as "transaction" behavior) is provided through defintion of a handful
of related instance methods.  This is done with reliance on the services of
the class Myco, which encapsulates the functionality of Tangram::Storage and
provides system-wide connection handling.

=cut

### an object of this class ISA
use base qw(Class::Tangram);

### Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use Set::Object;
use Tangram::Type::TimeAndDate;
use Myco::Entity::Meta;

# Any other entity class dependencies must appear after next section
#  this class (next line) doesn't want the 'template' attribs
use Myco::Entity::Event;
use Myco::Util::DateTime;

use constant EVENT => 'Myco::Entity::Event';
use constant DATETIME => 'Myco::Util::DateTime';

### Template attributes (_added_ [not inherited] to scheme of all sub-classes)
my $md = Myco::Entity::Meta->new
  ( name => __PACKAGE__ );

$md->add_attribute(name => 'owner_',
                   template => 1,
		   type => 'ref',
		   tangram_options => {  class => 'Myco::Person', },
                  );

$md->add_attribute(name => 'changedate_',
                   template => 1,
		   type => 'rawdatetime',
                  );
$md->add_attribute(name => 'changedby_',
                   template => 1,
		   type => 'ref',
		   tangram_options => {  class => 'Myco::User', },
                  );

$md->add_attribute(name => 'createdate_',
                   template => 1,
		   type => 'rawdatetime',
                  );
$md->add_attribute(name => 'createdby_',
                   template => 1,
		   type => 'ref',
		   tangram_options => {  class => 'Myco::User', },
                  );

$md->activate_class;


### Entity class dependencies
# See bogus (compile loop breaking) placement of
#     Myco::UI::Auth loading in new()

### Class variables
my $_event_cache;

=head1 CLASS SETUP

Class meta data and object schema definition is managed via
L<Myco::Entity::Meta|Myco::Entity::Meta>.  Typical
class setup begins like this:

 package Foo;
 use base qw(Myco::Entity);
 my $metadata = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'foo' }
  );

The 'tangram' parameter passes in an anonymous hash containing a
L<Class::Tangram|Class::Tangram>-style schema definition [but --without-- a
'fields' key!].  The creation of the $metadata object is normally followed
by one or more calls to C<$metadata-E<gt>add_attribute()> each of which
adds an attribute to the schema, along with establishing associated metadata.

At the very end of the class file comes the following, which triggers a
final phase of metadata discovery and makes the object schema active.

 $metadata->activate_class;

=head2 Class setup in Class::Tangram $schema style

Alternately the schema may be specified as a fully laid-out $schema data
structure, with no C<$metadata->E<gt>add_attribute() calls.  In this
case the C<activate_class()> method will parse $schema and fill out the
$metadata object with what it finds.  This may be of use when converting
an existing class or when the Class::Tangram style is simply preferred.

=over 4

=item B<import_schema> [deprecated]

 Myco::Entity::import_schema('Myco::Foo');

Informs Class::Tangram about classE<39>s schema so it can take care of
in-memory behavior.  ***If Myco::Entity::Meta is in use then direct
use of this method should be avoided.

=cut

sub import_schema {
    Class::Tangram::import_schema($_[0]);
}

=back

=head1 CONSTRUCTOR

=over 4

=item B<new>

 $obj = Myco::Foo->new;
 $obj = Myco::Foo->new(attr1 => value, attr2 => value);

Object constructor.  See Class::Tangram documentation.  Will throw an
exception if a required attribute is missing from parameter list.

=back

=cut

##############################################################################
# Constants
##############################################################################

=head1 CLASS / INSTANCE METHODS

See Class::Tangram for other available methods.

=head2 new

  $obj->set(attribute => $value, ...);

Constructs the new object. Overrides C<Class::Tangram::set()> in order to
initiate the Event Cache.

=cut

sub new {

    # Don't want this here... but it'll do for now
#    require Myco::UI::Auth;

    my $invocant = shift;
    my $class = ref $invocant || $invocant || '';

    my $entity = $class->SUPER::new(@_);


### DISABLED FOR NOW
#    # find the immediate caller
#    my $i = 0;
#    $i++ while UNIVERSAL::isa( $entity, scalar(caller($i)) || ";->" );
#    unless ( caller($i) =~ /Tangram/ ) {
#        $entity->set_createdate_( DATETIME->date('YYYY-MM-DD') );
#        my $u = Myco::UI::Auth->get_current_user;
#        $entity->set_createdby_($u) if $u;
#    }

    unless ($class eq EVENT) {
        $_event_cache =  EVENT->get_event_cache
          unless $_event_cache;
        # Initiate the Event Cache with a 'Create' event.
        EVENT->new( entity => $entity, kind => 1 );
    }
    return $entity;
}

sub DESTROY {
    my $self = shift;
    # Check if this is itself an event object
    unless (ref $self eq EVENT) {
        delete $_event_cache->{"$self"} if exists $_event_cache->{"$self"};
    }
    $self->SUPER::DESTROY(@_);
}

=head2 set

  $obj->set(attribute => $value, ...);

Sets the value of an attribute. Overrides C<Class::Tangram::set()> in order to
enforce access control.

=cut

sub _set {
    my $self = shift;
    # No point in continuing if they're not specifying any attributes to set!
    return unless @_;
    if (my $u = Myco::UI::Auth->get_current_user) {
        # Check for access.
        my $md = $self->introspect;
        my $uroles = $u->get_roles_hash;
      CLASS: {
            if (%$uroles) {
                my $al = $md->get_access_list;
                # If there are no roles on this class, jump out of the block.
                # This should probably be changed at some point so that the
                # access becomes better enforced.
                last CLASS unless $al->{rw} || $al->{ro};
                # Only check read/write for set().
                my $croles = $al->{rw} || [];
                foreach my $cr (@$croles) {
                    # If the role exists, class-level access is granted. Jump
                    # out of this block.
                    last CLASS if $uroles->{$cr};
                }
                # If we get here, they simply don't have permission to access
                # objects of this class.
                Myco::Exception::Authz->throw
                  (error => "You do not have permission to edit " .
                   ref $self . " objects");
            }
        } # CLASS:
        # Okay, if we get here, they have permission to access objects of
        # this class. Now let's check the attributes they're trying to
        # set.
        my $attrs = $md->get_attributes;
        my %params = @_;
        my @nope;
      ATTR: {
            foreach my $attr (keys %params) {
                my $al = $attrs->{$attr}->get_access_list;
                # If there are no attribute roles, skip to the next
                # attribute. This should probably be changed at some point
                # so that the access becomes better enforced.
                next ATTR unless $al->{rw} || $al->{ro};
                # Only check read/write for set().
                if (my $aroles = $al->{rw}) {
                    foreach my $ar (@$aroles) {
                        # Skip to the next attribute if they have permission to
                        # access the current attribute.
                        next ATTR if $uroles->{$ar};
                        # Otherwise, save this attribute name.
                        push @nope, $attr;
                    }
                } else {
                    # No read/write roles, so access is denied.
                    push @nope, $attr;
                }
            }
        } # ATTR:
        # Now check to see if we grabbed any attributes that they can't
        # access.
        if (@nope) {
            my $pl = $#nope == 0 ? '' : 's';
            local $" = "', '";
            Myco::Exception::Authz->throw
                ( error => "You do not have permission to edit the '@nope' " .
                  "attribute$pl of " . ref $self . " objects");
        }
    }
    # Put each attribute in the event cache before leaving to do the SUPER::set
    if (ref $self ne EVENT) {
        my %params = @_;
        foreach my $attr (keys %params) {
            #
            # implement code to:
            # skip if the object does not have an ID (i.e. its only transient)
            #
#            _build_event_cache( $self, $attr, $params{$attr} );
        }
    }

    # We now return to our regularly-scheduled set method.
    $self->SUPER::set(@_);
}

=head2 get

  my $value = $obj->get($attribute);

Returns the value of an attribute. Overrides C<Class::Tangram::get()> in order
to enforce access control.

=cut

sub _get {
    my $self = shift;
    # No point in continuing if they're not specifying an attributes to get!
    return unless $_[0];
    if (my $u = Myco::UI::Auth->get_current_user) {
        # Check for access.
        my $md = $self->introspect;
        my $uroles = $u->get_roles_hash;
      CLASS: {
            if (%$uroles) {
                my $al = $md->get_access_list;
                # Get the class roles or, if there are none, jump out of the
                # loop. This should probably be changed at some point so that
                # the access becomes better enforced.
                last CLASS unless $al->{rw} || $al->{ro};
                # We check both read/write and read only for the get() method.
                my $rw = $al->{rw} || [];
                my $ro = $al->{ro} || [];
                foreach my $cr (@$rw, @$ro) {
                    # Jump out of this block if they have permission.
                    last CLASS if $uroles->{$cr};
                }
                # If we get here, they simply don't have permission to access
                # objects of this class.
                Myco::Exception::Authz->throw
                    (error => "You do not have permission to read " .
                     ref $self . " objects");
            }
        } # CLASS:
        # Okay, if we get here, they have permission to access this class.
        # Now let's check the attributes they're trying to get.
        my $attrs = $md->get_attributes;
      ATTR: {
            # They can fetch only one attribute at a time, according to the
            # Class::Tangram spec for get().
            my $attr = $_[0];
            my $al = $attrs->{$attr}->get_access_list;
            # If there are no attribute roles, bugger out. This should
            # probably be changed at some point so that the access becomes
            # better enforced.
            last ATTR unless $al->{rw} || $al->{ro};
            # We check both read/write and read only for the get() method.
            my $rw = $al->{rw} || [];
            my $ro = $al->{ro} || [];
            foreach my $ar (@$rw, @$ro) {
                # Jump out of this block if they have permission.
                last ATTR if $uroles->{$ar};
            }
            # If we get here, they don't have permission.
            Myco::Exception::Authz->throw
              (error => "You do not have permission to read the '$attr' " .
               "attribute of " . ref $self . " objects");
        } # ATTR:
    }
    # We now return to our regularly-scheduled get method.
    $self->SUPER::get(@_);
}

=over 4

=item B<save>

 $id = $obj->save;

Updates database state to be consistent with objectE<39>s current in-memory
representation.  If object is not already persistent, it is inserted into
the database.  The Tangram object ID is returned.

=cut

sub save {
    my $self = shift;

    use Myco;

#    my $u = Myco::UI::Auth->get_current_user || undef;
#    $self->set_owner_($u->get_person) if $u;

    if ( Myco->is_transient($self) ) {
#        $self->set_changedby_($u) if $u;
#        $self->set_changedate_( DATETIME->date('YYYY-MM-DD') );
        Myco->update($self);
        Myco->id($self);
    } else {
        Myco->insert($self);
    }
}


=item B<destroy>

 $obj->destroy;

Removes object from persistent storage and does its best to remove
it from memory as well.  This memory cleanup process includes:

=over 3

=item *

Clearing all attributes that hold references to other objects (via a call to $obj->clear_refs.  See L<Class::Tangram|Class::Tangram>).

=item *

Clearing the Tangram transient storage reference to object.

=item *

Setting to undef the caller object reference.  If no other references to
the object exist Perl will do its usual garbage collection.


=back

This method is just an encapsulation of the call 'Myco->destroy($obj)'.

=cut

#Removes object from persistent storage and does the best it can to remove
#it from memory as well (as with any Perl data structure the object will not
#be freed from memory if any other references to it exist).

sub destroy { Myco->destroy($_[0]) }


# deprecated?
sub attr_kill_handle {
    return \ $_[0]->{$_[1]};
}


=item B<modify>

 $obj->modify(attr1 => value, attr2 => value);

Modifies one or more object attributes and updates objectE<39>s persistence
storage state as well.

=cut

sub modify {
	my ($self, %params) = @_;
	while ( my($key, $value) = each %params ) {
		$self->$key($value);
	}
	Myco->storage->update($self);
}


=item B<id>

 $id = $obj->id;

Returns the Tangram persistence object identifier (typcially for use with later
calls to Myco->load() ).

=cut

sub id { Myco->id($_[0]) };

=item B<is_transient>

 if ($obj->is_transient) { ... };

Returns true if object is currently in Tangram transient storage.

=cut

sub is_transient { Myco->is_transient($_[0]) };
	
=item B<introspect>

 $meta = Myco::Foo->introspect;
 $meta = $obj->introspect;

Returns the Myco::Entity::Meta metadata object that describes the
referent, or undef if none exists.

=cut

# introspect() is implemented in Myco::Entity::Meta, which installs
#   it in the entity class when $metadata->activate_class() is called.


# private...  [used by Myco::Program::enroll() ...]?
sub _remove_base_assoc_member {
    my ($self, $member, $group_arg) = @_;
    my $class = ref($self) || $self;
    if (!ref($self) && !$group_arg) {
        Myco::Exception::DataValidation->throw
          (error => "Method syntax error - ${class}->something needs a " .
                    "$class as second argument");
    }
    my $group = $group_arg || $self;

    if ( $group_arg && (ref($group_arg) ne $class) ) {
#	my ($class, $sub) = @{ [ caller($self) ] }[0,3];
#       Myco::Exception::DataValidation->throw
#	  (error => "Method syntax error - ${class}->${sub} needs a " .
#                   "$class as a second argument");
#	$class =  ref $self;
        Myco::Exception::DataValidation->throw
	  (error => "Method syntax error - ${class}->something needs a " .
                    "$class as second argument");
    }

    my $member_r = Myco->remote(ref $member);
    my $group_r = Myco->remote(ref $group);
    my $assoc_r = Myco->remote('Myco::Association');
	
    my $cur = Myco->cursor($assoc_r, ($member_r==$member)
			   & $member_r->{stuff}->includes($assoc_r)
			   & $group_r->{members}->includes($assoc_r)
			   & ($group_r==$group));
    my $assoc = $cur->current;
    return undef unless ($assoc);
    $member->stuff->remove($assoc);
    $group->members->remove($assoc);
    Myco->update($member);
    Myco->update($group);
    $group->destroy(\$assoc);
    return 1;
}

1;
__END__


=head1 SEARCHING AND LOADING

Retrieval of objects from persistent storage is accomplished via related
class methods of the class Myco.  See L<Myco|Myco>.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Charles Owens <czbsd@cpan.org>

=head1 SEE ALSO

L<Myco::Entity::Meta|Myco::Entity::Meta>,
L<Class::Tangram|Class::Tangram>,
L<Tangram|Tangram>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<Myco|Myco>,
L<myco-mkentity|mkentity>

=cut
