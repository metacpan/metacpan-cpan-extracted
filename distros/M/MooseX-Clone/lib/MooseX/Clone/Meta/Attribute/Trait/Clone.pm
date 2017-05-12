package MooseX::Clone::Meta::Attribute::Trait::Clone;
# ABSTRACT: The attribute trait for deeply cloning attributes

our $VERSION = '0.06';

use Moose::Role;
use Carp qw(croak);
use Data::Visitor 0.24 ();
use namespace::autoclean;

with qw(MooseX::Clone::Meta::Attribute::Trait::Clone::Base);

sub Moose::Meta::Attribute::Custom::Trait::Clone::register_implementation { __PACKAGE__ }

has clone_only_objects => (
    isa => "Bool",
    is  => "rw",
    default => 0,
);

has clone_visitor => (
    isa => "Data::Visitor",
    is  => "rw",
    lazy_build => 1,
);

has clone_visitor_config => (
    isa => "HashRef",
    is  => "ro",
    default => sub { { } },
);

sub _build_clone_visitor {
    my $self = shift;

    require Data::Visitor::Callback;

    Data::Visitor::Callback->new(
        object => sub { $self->clone_object_value($_[1]) },
        tied_as_objects => 1,
        %{ $self->clone_visitor_config },
    );
}

sub clone_value {
    my ( $self, $target, $proto, @args ) = @_;

    if ( $self->has_value($proto) ) {
        my $clone = $self->clone_value_data( scalar($self->get_value($proto)), @args );

        $self->set_value( $target, $clone );
    } else {
        my %args = @args;

        if ( exists $args{init_arg} ) {
            $self->set_value( $target, $args{init_arg} );
        }
    }
}

sub clone_value_data {
    my ( $self, $value, @args ) = @_;

    if ( blessed($value) ) {
        return $self->clone_object_value($value, @args);
    } else {
        my %args = @args;

        if ( exists $args{init_arg} ) {
            return $args{init_arg};
        } else {
            unless ( $self->clone_only_objects ) {
                return $self->clone_any_value($value, @args);
            } else {
                return $value;
            }
        }
    }
}

sub clone_object_value {
    my ( $self, $value, %args ) = @_;

    if ( $value->can("clone") ) {
        my @clone_args;

        if ( exists $args{init_arg} ) {
            my $init_arg = $args{init_arg};

            if ( ref $init_arg ) {
                if ( ref $init_arg eq 'HASH' )  { @clone_args = %$init_arg }
                elsif ( ref $init_arg eq 'ARRAY' ) { @clone_args = @$init_arg }
                else {
                    croak "Arguments to a sub clone should be given in a hash or array reference";
                }
            } else {
                croak "Arguments to a sub clone should be given in a hash or array reference";
            }
        }

        return $value->clone(@clone_args);
    } else {
        croak "Cannot recursively clone a retarded object $value (" . overload::StrVal($value) . ") in " . $args{attr}->name . ". Try something better.";
    }
}

sub clone_any_value {
    my ( $self, $value, %args ) = @_;
    $self->clone_visitor->visit($value);
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Clone::Meta::Attribute::Trait::Clone - The attribute trait for deeply cloning attributes

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    # see MooseX::Clone

    has foo => (
        traits => [qw(Clone)],
        isa => "Something",
    );

    $object->clone; # will recursively call $object->foo->clone and set the value properly

=head1 DESCRIPTION

This meta attribute trait provides a C<clone_value> method, in the spirit of
C<get_value> and C<set_value>. This allows clone methods such as the one in
L<MooseX::Clone> to make use of this per-attribute cloning behavior.

=head1 DERIVATION

Deriving this role for your own cloning purposes is encouraged.

This will allow your fine grained cloning semantics to interact with
L<MooseX::Clone> in the Right™ way.

=head1 ATTRIBUTES

=over 4

=item clone_only_objects

Whether or not L<Data::Visitor> should be used to clone arbitrary structures.
Objects found in these structures will be cloned using L<clone_object_value>.

If true then non object values will be copied over in shallow cloning semantics
(shared reference).

Defaults to false (all reference will be cloned).

=item clone_visitor_config

A hash ref used to construct C<clone_visitor>. Defaults to the empty ref.

This can be used to alter the cloning behavior for non object values.

=item clone_visitor

The L<Data::Visitor::Callback> object that will be used to clone.

It has an C<object> handler that delegates to C<clone_object_value> and sets
C<tied_as_objects> to true in order to deeply clone tied structures while
retaining magic.

Only used if C<clone_only_objects> is false and the value of the attribute is
not an object.

=back

=head1 METHODS

=over 4

=item clone_value $target, $proto, %args

Clones the value the attribute encapsulates from C<$proto> into C<$target>.

=item clone_value_data $value, %args

Does the actual cloning of the value data by delegating to a C<clone> method on
the object if any.

If the object does not support a C<clone> method an error is thrown.

If the value is not an object then it will not be cloned.

In the future support for deep cloning of simple refs will be added too.

=item clone_object_value $object, %args

This is the actual workhorse of C<clone_value_data>.

=item clone_any_value $value, %args

Uses C<clone_visitor> to clone all non object values.

Called from C<clone_value_data> if the value is not an object and
C<clone_only_objects> is false.

=back

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
