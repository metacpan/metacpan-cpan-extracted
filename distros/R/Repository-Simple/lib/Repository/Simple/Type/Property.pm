package Repository::Simple::Type::Property;

use strict;
use warnings;

use Carp;

our $VERSION = '0.06';

use Repository::Simple::Type::Value::Scalar;
use Repository::Simple::Util;
use Scalar::Util qw( weaken );

our @CARP_NOT = qw( Repository::Simple::Util );

=head1 NAME

Repository::Simple::Type::Property - Types for repository properties

=head1 SYNOPSIS

See L<Repository::Simple::Type::Node/"SYNOPSIS">.

=head1 DESCRIPTION

Property types are used to determine information about what kind of information is acceptable for a property and how it may be updated. This class provides a flexible way of describing the possible values, a method for marshalling and unmarshalling those values to and from a scalar for storage, and other metadata about possible values.

=head2 METHODS

=over

=item $type = Repository::Simple::Type::Property-E<gt>new(%args)

Creates a new property type with the given arguments, C<%args>. 

The following arguments are used:

=over

=item engine (required)

This is a reference to the storage engine owning this property type.

=item name (required)

This is a short identifying name for the type. This should be a fully qualified name, e.g., "ns:name".

=item auto_created

This property should be set to true if the creation of a node containing a property of this type triggers the creation of a property of this type.

By default, this value is false.

=item updatable

This property should be set to true if the value stored in the property cannot be changed.

By default, this value is false.

=item removable

When this property is set to a true value, this property may not be set to C<undef> or deleted. 

By default, this value is false.

=item value_type

This property should be set to an instance of L<Repository::Simple::Type::Value> for the type of value that is stored in it.

By default, this is set to an instance of L<Repository::Simple::Type::Value::Scalar>.

=back

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    if (!defined $args{engine}) {
        croak 'The "engine" argument must be given.';
    }

    weaken $args{engine};

    if (!defined $args{name}) {
        croak 'The "name" argument must be given.';
    }

    $args{auto_created} ||= 0;
    $args{updatable}    ||= 0;
    $args{removable}    ||= 0;
    $args{value_type}   ||= Repository::Simple::Type::Value::Scalar->new;

    return bless \%args, $class;
}

=item $name = $type-E<gt>name

This method returns the name of the type.

=cut

sub name {
    my $self = shift;
    return $self->{name};
}

=item $auto_created = $type-E<gt>auto_created

Returns a true value if the property is automatically created with the parent.

=cut

sub auto_created {
    my $self = shift;
    return $self->{auto_created};
}

=item $updatable = $type-E<gt>updatable

Returns a true value if the value may be changed.

=cut

sub updatable {
    my $self = shift;
    return $self->{updatable};
}

=item $removable = $type-E<gt>removable

Returns a true value if the value may be removed from it's parent node.

=cut

sub removable {
    my $self = shift;
    return $self->{removable};
}

=item $value_type = $type-E<gt>value_type

Returns the value type of the properties value.

=cut

sub value_type {
    my $self = shift;
    return $self->{value_type};
}

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2005 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
