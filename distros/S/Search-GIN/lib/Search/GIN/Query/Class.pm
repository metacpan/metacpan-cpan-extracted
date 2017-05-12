use strict;
use warnings;
package Search::GIN::Query::Class;
# ABSTRACT: Create class-based GIN queries

our $VERSION = '0.11';

use Moose;
use Carp qw(croak);
use namespace::autoclean;

with qw(
    Search::GIN::Query
    Search::GIN::Keys::Deep
);

has no_check => (
    isa => "Bool",
    is  => "rw",
    default => 0,
);

has class => (
    isa => "ArrayRef | Str",
    is  => "ro",
    predicate => "has_class",
);

has does => (
    isa => "ArrayRef | Str",
    is  => "ro",
    predicate => "has_does",
);

has blessed => (
    isa => "Str",
    is  => "ro",
    predicate => "has_blessed",
);

sub BUILD {
    my $self = shift;

    croak "One of 'class', 'does', or 'blessed' is required"
        unless $self->has_class or $self->has_does or $self->has_blessed;
}

sub extract_values {
    my $self = shift;

    return (
        method => "all",
        values => [ $self->process_keys({
            ( $self->has_class   ? ( class   => $self->class   ) : () ),
            ( $self->has_does    ? ( does    => $self->does    ) : () ),
            ( $self->has_blessed ? ( blessed => $self->blessed ) : () ),
        }) ],
    );
}

sub consistent {
    my ( $self, $index, $object ) = @_;

    return 1 if $self->no_check;

    if ( $self->has_blessed ) {
        return unless ref($object) eq $self->blessed;
    }

    if ( $self->has_class ) {
        return unless $self->check_object($object, isa => $self->class);
    }

    if ( $self->has_does ) {
        return unless $self->check_object($object, DOES => $self->does);
    }

    return 1;
}

sub check_object {
    my ( $self, $object, $check, $classes ) = @_;

    my @classes = ref($classes) ? @$classes : $classes;

    foreach my $class ( @classes ) {
        $object->$check($class) or return;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Query::Class - Create class-based GIN queries

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use Search::GIN::Query::Class;

    my $query = Search::GIN::Query::Class->new(
        class => 'Person',
    );

=head1 DESCRIPTION

Creates a class-based GIN query that can be used to search records in a storage.

This is a ready-to-use query that uses class definitions (specifically C<class>,
C<does> and C<blessed>) to search through the storage.

=head1 METHODS/SUBROUTINES

=head2 new

Creates a new query.

=head1 ATTRIBUTES

=head2 class

The class of the object you want to find.

    my $query = Search::GIN::Query::Class->new(
        class => 'Person',
    );

=head2 does

A role consumed by the object you want to find.

    my $query = Search::GIN::Query::Class->new(
        does => 'TheMonkey',
    );

=head2 blessed

The name of the package that the object is blessed into.

    my $query = Search::GIN::Query::Class->new(
        blessed => 'Person',
    );

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman), Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
