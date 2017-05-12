package MooseX::Clone; # git description: 0.05-13-gd83ae68
# ABSTRACT: Fine-grained cloning support for Moose objects.

our $VERSION = '0.06';

use Moose::Role;
use Hash::Util::FieldHash::Compat qw(idhash);
use MooseX::Clone::Meta::Attribute::Trait::Clone;
use MooseX::Clone::Meta::Attribute::Trait::StorableClone;
use MooseX::Clone::Meta::Attribute::Trait::NoClone;
use MooseX::Clone::Meta::Attribute::Trait::Copy;
use namespace::autoclean;

sub clone {
    my ( $self, %params ) = @_;

    my $meta = $self->meta;

    my @cloning;

    idhash my %clone_args;

    attr: foreach my $attr ($meta->get_all_attributes()) {
        # collect all attrs that can be cloned.
        # if they have args in %params then those are passed to the recursive cloning op
        if ( $attr->does("MooseX::Clone::Meta::Attribute::Trait::Clone::Base") ) {
            push @cloning, $attr;

            if ( defined( my $init_arg = $attr->init_arg ) ) {
                if ( exists $params{$init_arg} ) {
                    $clone_args{$attr} = delete $params{$init_arg};
                }
            }
        }
    }

    my $clone = $meta->clone_object($self, %params);

    foreach my $attr ( @cloning ) {
        $clone->clone_attribute(
            proto => $self,
            attr => $attr,
            ( exists $clone_args{$attr} ? ( init_arg => $clone_args{$attr} ) : () ),
        );
    }

    return $clone;
}

sub clone_attribute {
    my ( $self, %args ) = @_;

    my ( $proto, $attr ) = @args{qw/proto attr/};

    $attr->clone_value( $self, $proto, %args );
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Clone - Fine-grained cloning support for Moose objects.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package Bar;
    use Moose;

    with qw(MooseX::Clone);

    has foo => (
        isa => "Foo",
        traits => [qw(Clone)], # this attribute will be recursively cloned
    );

    package Foo;
    use Moose;

    # this API is used/provided by MooseX::Clone
    sub clone {
        my ( $self, %params ) = @_;

        # ...
    }


    # used like this:

    my $bar = Bar->new( foo => Foo->new );

    my $copy = $bar->clone( foo => [ qw(Args for Foo::clone) ] );

=head1 DESCRIPTION

Out of the box L<Moose> only provides very barebones cloning support in order
to maximize flexibility.

This role provides a C<clone> method that makes use of the low level cloning
support already in L<Moose> and adds selective deep cloning based on
introspection on top of that. Attributes with the C<Clone> trait will handle
cloning of data within the object, typically delegating to the attribute
value's own C<clone> method.

=head1 TRAITS

=over 4

=item Clone

By default Moose objects are cloned like this:

    bless { %$old }, ref $old;

By specifying the L<Clone> trait for certain attributes custom behavior the
value's own C<clone> method will be invoked.

By extending this trait you can create custom cloning for certain attributes.

By creating C<clone> methods for your objects (e.g. by composing
L<MooseX::Compile>) you can make them interact with this trait.

=item NoClone

Specifies attributes that should be skipped entirely while cloning.

=back

=head1 METHODS

=over 4

=item clone %params

Returns a clone of the object.

All attributes which do the L<MooseX::Clone::Meta::Attribute::Trait::Clone>
role will handle cloning of that attribute. All other fields are plainly copied
over, just like in L<Class::MOP::Class/clone_object>.

Attributes whose C<init_arg> is in %params and who do the C<Clone> trait will
get that argument passed to the C<clone> method (dereferenced). If the
attribute does not self-clone then the param is used normally by
L<Class::MOP::Class/clone_object>, that is it will simply shadow the previous
value, and does not have to be an array or hash reference.

=back

=head1 TODO

Refactor to work in term of a metaclass trait so that C<< meta->clone_object >>
will still do the right thing.

=head1 THANKS

clkao made the food required to write this module

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
