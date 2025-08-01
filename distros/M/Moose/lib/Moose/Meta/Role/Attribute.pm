package Moose::Meta::Role::Attribute;
our $VERSION = '2.4000';

use strict;
use warnings;

use List::Util 1.33 'all';
use Scalar::Util 'blessed', 'weaken';

use parent 'Moose::Meta::Mixin::AttributeCore', 'Class::MOP::Object';

use Moose::Util 'throw_exception';

__PACKAGE__->meta->add_attribute(
    'metaclass' => (
        reader => 'metaclass',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'associated_role' => (
        reader => 'associated_role',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    '_original_role' => (
        reader => '_original_role',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'is' => (
        reader => 'is',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'original_options' => (
        reader => 'original_options',
        Class::MOP::_definition_context(),
    )
);

sub new {
    my ( $class, $name, %options ) = @_;

    (defined $name)
        || throw_exception( MustProvideANameForTheAttribute => params => \%options,
                                                               class  => $class
                          );

    my $role = delete $options{_original_role};

    return bless {
        name             => $name,
        original_options => \%options,
        _original_role   => $role,
        %options,
    }, $class;
}

sub attach_to_role {
    my ( $self, $role ) = @_;

    ( blessed($role) && $role->isa('Moose::Meta::Role') )
        || throw_exception( MustPassAMooseMetaRoleInstanceOrSubclass => class  => $self,
                                                                        role   => $role
                          );

    weaken( $self->{'associated_role'} = $role );
}

sub original_role {
    my $self = shift;

    return $self->_original_role || $self->associated_role;
}

sub attribute_for_class {
    my $self = shift;

    my $metaclass = $self->original_role->applied_attribute_metaclass;

    return $metaclass->interpolate_class_and_new(
        $self->name    => %{ $self->original_options },
        role_attribute => $self,
    );
}

sub clone {
    my $self = shift;

    my $role = $self->original_role;

    return ( ref $self )->new(
        $self->name,
        %{ $self->original_options },
        _original_role => $role,
    );
}

sub is_same_as {
    my $self = shift;
    my $attr = shift;

    my $self_options = $self->original_options;
    my $other_options = $attr->original_options;

    return 0
        unless ( join q{|}, sort keys %{$self_options} ) eq ( join q{|}, sort keys %{$other_options} );

    for my $key ( keys %{$self_options} ) {
        return 0 if defined $self_options->{$key} && ! defined $other_options->{$key};
        return 0 if ! defined $self_options->{$key} && defined $other_options->{$key};

        next if all { ! defined } $self_options->{$key}, $other_options->{$key};

        return 0 unless $self_options->{$key} eq $other_options->{$key};
    }

    return 1;
}

1;

# ABSTRACT: The Moose attribute metaclass for Roles

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Meta::Role::Attribute - The Moose attribute metaclass for Roles

=head1 VERSION

version 2.4000

=head1 DESCRIPTION

This class implements the API for attributes in roles. Attributes in roles are
more like attribute prototypes than full blown attributes. While they are
introspectable, they have very little behavior.

=head1 METHODS

=head2 Moose::Meta::Role::Attribute->new(...)

This method accepts all the options that would be passed to the constructor
for L<Moose::Meta::Attribute>.

=head2 $attr->metaclass

=head2 $attr->is

Returns the option as passed to the constructor.

=head2 $attr->associated_role

Returns the L<Moose::Meta::Role> to which this attribute belongs, if any.

=head2 $attr->original_role

Returns the L<Moose::Meta::Role> in which this attribute was first
defined. This may not be the same as the value of C<associated_role()> for
attributes in a composite role, or when one role consumes other roles.

=head2 $attr->original_options

Returns a hash reference of options passed to the constructor. This is used
when creating a L<Moose::Meta::Attribute> object from this object.

=head2 $attr->attach_to_role($role)

Attaches the attribute to the given L<Moose::Meta::Role>.

=head2 $attr->attribute_for_class($metaclass)

Given an attribute metaclass name, this method calls C<<
$metaclass->interpolate_class_and_new >> to construct an attribute object
which can be added to a L<Moose::Meta::Class>.

=head2 $attr->clone

Creates a new object identical to the object on which the method is called.

=head2 $attr->is_same_as($other_attr)

Compares two role attributes and returns true if they are identical.

In addition, this class implements all informational predicates implements by
L<Moose::Meta::Attribute> (and L<Class::MOP::Attribute>).

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Jesse Luehrs <doy@cpan.org>

=item *

Shawn M Moore <sartak@cpan.org>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Chris Prather <chris@prather.org>

=item *

Matt S Trout <mstrout@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
