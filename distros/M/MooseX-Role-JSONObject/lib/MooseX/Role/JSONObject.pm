#!/usr/bin/perl

package MooseX::Role::JSONObject;

use v5.012;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.0");

use Moose::Role;
use Method::Signatures;

use MooseX::Role::JSONObject::Util;

method to_json()
{
	return MooseX::Role::JSONObject::Util::meta_to_json(
	    $self, $self->meta);
}

method from_json($class:, HashRef $data)
{
	my $cls = ref $class || $class;
	my $meta = Class::MOP::Class->initialize($cls);

	return MooseX::Role::JSONObject::Util::meta_from_json(
	    $data, $meta);
}

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Role::JSONObject - create/store an object in a JSON-like hash

=head1 SYNOPSIS

    package foo;
    
    use Moose;
    with 'MooseX::Role::JSONObject';
    
    ...
    
    my $obj = foo->new(...);
    my $data = $obj->to_json();
    ...
    my $newobj = foo->from_json($data);

=head1 DESCRIPTION

The C<MooseX::Role::JSONObject> role provides two methods, C<to_json()>
and C<from_json()>, for storing and retrieving a Moose object's attributes
and, if they are Moose objects themselves, their attributes recursively.
This is mainly useful in two cases: creating an object and all of its
attributes from a hash parsed from a JSON string or storing an object and
all its attributes as a hash to be written to a JSON string.

=head1 METHODS

The C<MooseX::Role::JSONObject> role provides two methods:

=over 4

=item * C<to_json()>

The C<to_json()> method takes no parameters and returns a hash reference
containing the object's data.

=item * C<from_json($data)>

The C<from_json()> class method creates a new object with the specified
values for its attributes.  If any of its attributes are Moose objects,
C<from_json()> will create new instances for those recursively and
populate them from the data.

Currently the C<from_json()> method always creates a new object; even
though it may be invoked on an already existing object instance, it will
not modify the instance's attributes, but return a new one instead.

=back

=head1 SEE ALSO

L<MooseX::Role::JSONObject::Meta::Trait>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

