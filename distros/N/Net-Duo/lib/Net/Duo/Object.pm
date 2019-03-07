# Helper base class for Duo objects.
#
# The Duo API contains a variety of objects, represented as JSON objects with
# multiple fields.  This objects often embed other objects inside them.  To
# provide a nice Perl API with getters, setters, and commit and delete methods
# on individual objects, we want to wrap these Duo REST API objects in Perl
# classes.
#
# This module serves as a base class for such objects and does the dirty work
# of constructing an object from decoded JSON data and building the accessors
# automatically from a field specification.
#
# SPDX-License-Identifier: MIT

package Net::Duo::Object 1.02;

use 5.014;
use strict;
use warnings;

use Carp qw(croak);
use JSON ();
use Sub::Install;

# Helper function to parse the data for a particular field specification.
#
# $spec - The field specification (a value in the hash from _fields)
#
# Returns: The type in scalar context
#          The type and then a reference to a hash of flags in array context
sub _field_type {
    my ($spec) = @_;
    my ($type, @flags);

    # If the specification is a reference, it's an array, with the first value
    # as type and the rest as flags.  Otherwise, it's a simple type.
    if (ref($spec) eq 'ARRAY') {
        ($type, @flags) = @{$spec};
    } else {
        $type = $spec;
    }

    # Return the appropriate value or values.
    return wantarray ? ($type, { map { $_ => 1 } @flags }) : $type;
}

# Helper function to do the data translation from the results of JSON parsing
# to our internal representation.  This mostly consists of converting nested
# objects into proper objects, but it also makes a deep copy of the data.
#
# This is broken into a separate function so that it can be used by both new()
# and commit().
#
# $self     - Class of object we're creating or an object of the right type
# $data_ref - Reference to parsed data from JSON
# $duo      - Net::Duo object to use for subobjects
#
# Returns: Reference to hash suitable for blessing as an object
sub _convert_data {
    my ($self, $data_ref, $duo) = @_;

    # Retrieve the field specification for this object.
    my $fields = $self->_fields;

    # Make a deep copy of the data following the field specification.
    my %result;
  FIELD:
    for my $field (keys %{$fields}) {
        next FIELD if (!exists($data_ref->{$field}));
        my $type  = _field_type($fields->{$field});
        my $value = $data_ref->{$field};
        if ($type eq 'simple') {
            $result{$field} = $value;
        } elsif ($type eq 'array') {
            $result{$field} = [@{$value}];
        } elsif (defined($value)) {
            my @objects;
            for my $object (@{$value}) {
                push(@objects, $type->new($duo, $object));
            }
            $result{$field} = \@objects;
        }
    }

    # Return the new data structure.
    return \%result;
}

# Create a new Net::Duo object.  This constructor can be inherited by all
# object classes.  It takes the decoded JSON and uses the field specification
# for the object to construct an object via deep copying.
#
# The child class must provide a static method fields() that returns a field
# specification.  See the documentation for more details.
#
# $class    - Class of object to create
# $duo      - Net::Duo object to use for further API calls on this object
# $data_ref - Object data as a reference to a hash (usually decoded from JSON)
#
# Returns: Newly-created object
sub new {
    my ($class, $duo, $data_ref) = @_;
    my $self = $class->_convert_data($data_ref, $duo);
    $self->{_duo} = $duo;
    bless($self, $class);
    return $self;
}

# Create a new object in Duo.  This constructor must be overridden by
# subclasses to pass in the additional URI parameter for the Duo API endpoint.
# It takes a reference to a hash representing the object values and returns
# the new object as an appropriately-blessed object.  Currently, no local data
# checking is performed on the provided data.
#
# The child class must provide a static method fields() that returns a field
# specification.  See the documentation for more details.
#
# $class    - Class of object to create
# $duo      - Net::Duo object to use to create the object
# $uri      - Duo endpoint to use for creation
# $data_ref - Data for new object as a reference to a hash
#
# Returns: Newly-created object
#  Throws: Net::Duo::Exception on any problem creating the object
sub create {
    my ($class, $duo, $uri, $data_ref) = @_;

    # Retrieve the field specification for this object.
    my $fields = $class->_fields;

    # Make a copy of the data and convert all boolean values.
    my %data = %{$data_ref};
  FIELD:
    for my $field (keys %data) {
        my ($type, $flags) = _field_type($fields->{$field});
        if ($flags->{boolean}) {
            $data{$field} = $data{$field} ? 'true' : 'false';
        } elsif ($flags->{zero_or_one}) {
            $data{$field} = $data{$field} ? 1 : 0;
        }
    }

    # Create the object in Duo.
    my $self = $duo->call_json('POST', $uri, \%data);

    # Add the Net::Duo object.
    $self->{_duo} = $duo;

    # Bless and return the new object.
    bless($self, $class);
    return $self;
}

# Commit changes to the object to Duo.  This method must be overridden by
# subclasses to pass in the additional URI parameter for the Duo API endpoint.
# It sends all of the fields that have been modified by setters, and then
# clears the flags that track modifications if the commit was successful.
#
# The child class must provide a static method fields() that returns a field
# specification.  See the documentation for more details.
#
# $self - Subclass of Net::Duo::Object
# $uri  - Duo endpoint to use for updates
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem modifying the object in Duo
sub commit {
    my ($self, $uri) = @_;

    # Retrieve the field specification for this object.
    my $fields = $self->_fields;

    # Iterate through the changed fields to build the data for Duo.  Remap
    # boolean fields to true or false here.
    my %data;
    for my $field (keys %{ $self->{_changed} }) {
        my ($type, $flags) = _field_type($fields->{$field});
        if ($flags->{boolean}) {
            $data{$field} = $self->{$field} ? 'true' : 'false';
        } elsif ($flags->{zero_or_one}) {
            $data{$field} = $self->{$field} ? 1 : 0;
        } else {
            $data{$field} = $self->{$field};
        }
    }

    # Modify the object in Duo.  Duo will return the resulting new object,
    # which we want to convert back to our internal representation.
    my $new_data_ref = $self->{_duo}->call_json('POST', $uri, \%data);
    $new_data_ref = $self->_convert_data($new_data_ref, $self->{_duo});

    # Duo may have changed or canonicalized the data, or someone else may have
    # changed other parts of the object, so replace all of our data with what
    # Duo now says the object looks like.  Save our private fields.  This is
    # more extensible than having a whitelist of private fields.
    delete $self->{_changed};
    for my $field (keys %{$self}) {
        next if ($field !~ m{ \A _ }xms);
        $new_data_ref->{$field} = $self->{$field};
    }
    %{$self} = %{$new_data_ref};
    return;
}

# Create all the accessor methods for the object fields.  This method is
# normally called via code outside of any method in the object class so that
# it is run when the class is first imported.
#
# The child class must provide a static method fields() that returns a field
# specification.  See the documentation for more details.
#
# $class - Class whose accessors we're initializing
#
# Returns: undef
sub install_accessors {
    my ($class) = @_;

    # Retrieve the field specification for this object.
    my $fields = $class->_fields;

    # Create an accessor for each one.
    for my $field (keys %{$fields}) {
        my ($type, $flags) = _field_type($fields->{$field});

        # For fields containing arrays, return a copy of the array instead
        # of the reference to the internal data structure in the object,
        # preventing client manipulation of our internals.
        my $code;
        if ($type eq 'simple') {
            $code = sub { my $self = shift; return $self->{$field} };
        } else {
            $code = sub {
                my $self = shift;
                return if !$self->{$field};
                return @{ $self->{$field} };
            };
        }

        # Create and install the accessor.
        my $spec = { code => $code, into => $class, as => $field };
        Sub::Install::install_sub($spec);

        # If the "set" flag is set, also generate a setter.
        if ($flags->{set}) {
            if ($type eq 'simple') {
                $code = sub {
                    my ($self, $value) = @_;
                    $self->{$field} = $value;
                    $self->{_changed}{$field} = 1;
                    return;
                };
            } else {
                $code = sub {
                    my ($self, @values) = @_;
                    $self->{$field} = [@values];
                    $self->{_changed}{$field} = 1;
                    return;
                };
            }
            $spec = { code => $code, into => $class, as => "set_$field" };
            Sub::Install::install_sub($spec);
        }
    }
    return;
}

# Returns the current contents of the object as JSON.  The json() method of
# nested objects is called to convert them in turn.
#
# $self - The object to convert to JSON
#
# Returns: JSON representation of the object using the Duo data model
sub json {
    my ($self) = @_;

    # Create a JSON encoder and decoder.
    my $json = JSON->new->utf8(1);

    # Retrieve the field specification for this object.
    my $fields = $self->_fields;

    # Iterate through the fields to build the data structure we'll convert to
    # JSON.  We have to do some data mapping and call the json() method on any
    # embedded objects.  This is unnecessarily inefficient since it converts
    # the children to JSON and then back again, purely for coding convenience.
    my %data;
  FIELD:
    for my $field (keys %{$self}) {
        next FIELD if ($field =~ m{ \A _ }xms);
        my ($type, $flags) = _field_type($fields->{$field});
        if ($type eq 'simple' || $type eq 'array') {
            if ($flags->{boolean}) {
                $data{$field} = $self->{$field} ? JSON::true : JSON::false;
            } elsif ($flags->{zero_or_one}) {
                $data{$field} = $self->{$field} ? 1 : 0;
            } else {
                $data{$field} = $self->{$field};
            }
        } else {
            my @children = map { $_->json } @{ $self->{$field} // [] };
            $data{$field} = [map { $json->decode($_) } @children];
        }
    }

    # Convert the result to JSON and return it.
    return $json->encode(\%data);
}

1;
__END__

=for stopwords
Allbery undef MERCHANTABILITY NONINFRINGEMENT sublicense getters JSON

=head1 NAME

Net::Duo::Object - Helper base class for Duo objects

=head1 SYNOPSIS

    package Net::Duo::Admin::Token 1.00;

    use parent qw(Net::Duo::Object);

    sub fields {
        return {
            token_id => 'simple',
            type     => 'simple',
            serial   => 'simple',
            users    => 'Net::Duo::Admin::User',
        };
    }

    Net::Duo::Admin::Token->install_accessors;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, LWP (also known as libwww-perl), Perl6::Slurp,
Sub::Install, and URI::Escape (part of URI), all of which are available
from CPAN.

=head1 DESCRIPTION

The Duo API contains a variety of objects, represented as JSON objects
with multiple fields.  This objects often embed other objects inside them.
To provide a nice Perl API with getters, setters, and commit and delete
methods on individual objects, we want to wrap these Duo REST API objects
in Perl classes.

This module serves as a base class for such objects and does the dirty
work of constructing an object from decoded JSON data and building the
accessors automatically from a field specification.

This class should normally be considered an internal implementation detail
of the Net::Duo API.  Only developers of the Net::Duo modules should need
to worry about it.  Callers can use other Net::Duo API objects without
knowing anything about how this class works.

=head1 FIELD SPECIFICATION

Any class that wants to use Net::Duo::Object to construct itself must
provide a field specification.  This is a data structure that describes
all the data fields in that object.  It is used by the generic
Net::Duo::Object constructor to build the Perl data structure for an
object, and by the install_accessors() class method to create the
accessors for the class.

The client class must provide a class method named _fields() that returns
a reference to a hash.  The keys of the hash are the field names of the
data stored in an object of that class.  The values specify the type of
data stored in that field.  Each value may be either a simple string or a
reference to an array, in which case the first value is the type and the
remaining values are flags.  The types must be chosen from the following:

=over 4

=item C<array>

An array of simple text, number, or boolean values.

=item C<simple>

A simple text, number, or boolean field,

=item I<class>

The name of a class.  This field should then contain an array of zero or
more instances of that class, and the constructor for that class will be
called with the resulting structures.

=back

The flags must be chosen from the following:

=over 4

=item C<boolean>

This is a boolean field.  Convert all values to C<true> or C<false> before
sending the data to Duo.  Only makes sense with a field of type C<simple>.

=item C<set>

Generate a setter for this field.  install_accessors() will, in addition
to adding a method to retrieve the value, will add a method named after
the field but prefixed with C<set_> that will set the value of that field
and remember that it's been changed locally.  Changed fields will then
be pushed back to Duo via the commit() method.

=item C<zero_or_one>

This is a boolean field that wants values of 0 or 1.  Convert all values
to C<1> or C<0> before sending the data to Duo.  Only makes sense with a
field of type C<simple>.

=back

=head1 CLASS METHODS

=over 4

=item create(DUO, URI, DATA)

A general constructor for creating a new object in Duo.  Takes a Net::Duo
object, the URI of the REST endpoint for object creation, and a reference
to a hash of object data.  This method should be overridden by subclasses
to provide the URI and only expose the DUO and DATA arguments to the
caller.  Returns the newly-blessed object containing the data returned by
Duo.

=item install_accessors()

Using the field specification, creates accessor functions for each data
field that return copies of the data stored in that field, or undef if
there is no data.

=item new(DUO, DATA)

A general constructor for Net::Duo objects.  Takes a Net::Duo object and a
reference to a hash, which contains the data for an object of the class
being constructed.  Using the field specification for that class, the data
will be copied out of the object into a Perl data structure, converting
nested objects to other Net::Duo objects as required.

=back

=head1 INSTANCE METHODS

=over 4

=item commit(URI)

A general method for committing changes to an object to Duo.  Takes the URI
of the REST endpoint for object modification.  This method should be
overridden by subclasses to provide the URI and only expose an
argument-less method.

After commit(), the internal representation of the object will be refreshed
to match the new data returned by the Duo API for that object.  Therefore,
other fields of the object may change after commit() if some other user has
changed other, unrelated fields in the object.

It's best to think of this method as a synchronize operation: changed data
is written back, overwriting what's in Duo, and unchanged data may be
overwritten by whatever is currently in Duo, if it is different.

=item json()

Convert the data stored in the object to JSON and return the results.  The
resulting JSON should match the JSON that one would get back from the Duo
web service when retrieving the same object (plus any changes made locally
to the object via set_*() methods).  This is primarily intended for
debugging dumps or for passing Duo objects to other systems via further
JSON APIs.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Russ Allbery <rra@cpan.org>

Copyright 2014 The Board of Trustees of the Leland Stanford Junior
University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

L<Net::Duo>

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/net-duo/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
