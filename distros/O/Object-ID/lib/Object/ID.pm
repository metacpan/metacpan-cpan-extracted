package Object::ID;

use 5.008_008;

use strict;
use warnings;

use version; our $VERSION = qv("v0.1.2");

# Over 2x faster than Hash::Util::FieldHash
use Hash::FieldHash qw(fieldhashes);
use Sub::Name qw(subname);

# Even though we're not using Exporter, be polite for introspection purposes
our @EXPORT = qw(object_id object_uuid);

sub import {
    my $caller = caller;

    for my $method (qw<object_id object_uuid>) {
        my $name = "$caller\::$method";
        no strict 'refs';
        # In a client class using namespace::autoclean, the exported methods
        # are indistinguishable from exported functions, and therefore get
        # autocleaned out of existence.  So use subname() to rename them as
        # things that namespace::autoclean will interpret as methods.
        *$name = subname($name, \&$method);
    }
}


# All glory to Vincent Pit for coming up with this implementation
{
    fieldhashes \my(%IDs, %UUIDs);

    my $Last_ID = "a";
    sub object_id {
        my $self = shift;

        # This is 15% faster than ||=
        return $IDs{$self} if exists $IDs{$self};
        return $IDs{$self} = ++$Last_ID;
    }

    if ( eval { require Data::UUID } ) {
        my $UG;

        *object_uuid = sub {
            my $self = shift;

            # Because the mere presense of a Data::UUID object will
            # cause problems with threads, don't initialize it until
            # absolutely necessary.
            $UG ||= Data::UUID->new;

            return $UUIDs{$self} if exists $UUIDs{$self};
            return $UUIDs{$self} = $UG->create_str;
        }
    }
    else {
        *object_uuid = sub {
            require Carp;
            Carp::croak("object_uuid() requires Data::UUID");
        };
    }
}


=head1 NAME

Object::ID - A unique identifier for any object

=head1 SYNOPSIS

    package My::Object;

    # Imports the object_id method
    use Object::ID;


=head1 DESCRIPTION

This is a unique identifier for any object, regardless of its type,
structure or contents.  Its features are:

    * Works on ANY object of any type
    * Does not modify the object in any way
    * Does not change with the object's contents
    * Is O(1) to calculate (ie. doesn't matter how big the object is)
    * The id is unique for the life of the process
    * The id is always a true value


=head1 USAGE

Object::ID is a role, rather than inheriting its methods they are
imported into your class.  To make your class use Object::ID, simply
C<< use Object::ID >> in your class.

    package My::Class;

    use Object::ID;

Then write your class however you want.


=head1 METHODS

The following methods are made available to your class.

=head2 object_id

    my $id = $object->object_id;

Returns an identifier unique to the C<$object>.

The identifier is not related to the content of the object.  It is
only unique for the life of the process.  There is no guarantee as to
the format of the identifier from version to version.

For example:

    my $obj = My::Class->new;
    my $copy = $obj;

    # This is true, $obj and $copy refer to the same object
    $obj->object_id eq $copy->object_id;

    my $obj2 = My::Class->new;

    # This is false, $obj and $obj2 are different objects.
    $obj->object_id eq $obj2->object_id;

    use Clone;
    my $clone = clone($obj);

    # This is false, even though they contain the same data.
    $obj->object_id eq $clone->object_id;

=head2 object_uuid

    my $uuid = $object->object_uuid

Like C<< $object->object_id >> but returns a UUID unique to the $object.

Only works if Data::UUID is installed.

See L<Data::UUID> for more details about UUID.


=head1 FAQ

=head2 Why not just use the object's reference?

References are not unique over the life of a process.  Perl will reuse
references of destroyed objects, as demonstrated by this code snippet:

    {
        package Foo;

        sub new {
            my $class = shift;
            my $string = shift;
            return bless {}, $class;
        }
    }

    for(1..3) {
        my $obj = Foo->new;
        print "Object's reference is $obj\n";
    }

This will print, for example, C<< Object's reference is
Foo=HASH(0x803704) >> three times.


=head2 How much memory does it use?

Very little.

Object::ID stores the ID and address of each object you've asked the
ID of.  Once the object has been destroyed it no longer stores it.  In
other words, you only pay for what you use.  When you're done with it,
you don't pay for it any more.


=head1 LICENSE

Copyright 2010, Michael G Schwern <schwern@pobox.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>


=head1 THANKS

Thank you to Vincent Pit for coming up with the implementation.

=cut

1;
