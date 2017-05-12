use strict;
use warnings;
package Search::GIN::Query::Attributes;
# ABSTRACT: Create attributes-based GIN queries

our $VERSION = '0.11';

use Moose;
use Carp qw(croak);
use namespace::autoclean;

with qw(
    Search::GIN::Query
    Search::GIN::Keys::Deep
);

has attributes => (
    isa => "HashRef",
    is  => "rw",
    required => 1,
);

has compare => (
    isa => "Str|CodeRef",
    is  => "rw",
    default => "compare_naive",
);

sub extract_values {
    my $self = shift;

    return (
        method => "all",
        values => [ $self->process_keys($self->attributes) ],
    );
}

sub consistent {
    my ( $self, $index, $obj ) = @_;

    my $class = ref $obj;

    my $meta = Class::MOP::get_metaclass_by_name($class);

    my $query = $self->attributes;

    my %got;

    foreach my $attr_name ( keys %$query ) {
        my $expected = $query->{$attr_name};

        my $meta_attr = $meta->find_attribute_by_name($attr_name) || return;
        $got{$attr_name} = $meta_attr->get_value($obj);
    }

    my $cmp = $self->compare;

    return $self->$cmp( \%got, $query );
}

sub compare_naive {
    my ( $self, $got, $exp ) = @_;

    return unless keys %$got == keys %$exp;

    foreach my $key ( keys %$exp ) {
        return unless overload::StrVal($got->{$key}) eq overload::StrVal($exp->{$key});
    }

    return 1;
}

sub compare_test_deep {
    my ( $self, $got, $exp ) = @_;

    require Test::Deep::NoTest;
    Test::Deep::NoTest::eq_deeply($got, $exp);
}

# FIXME Data::Compare too

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Query::Attributes - Create attributes-based GIN queries

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use Search::GIN::Query::Attributes;

    my $query = Search::GIN::Query::Attributes->new(
        attributes => {
            name => 'Homer',
        },
    );

=head1 DESCRIPTION

Creates an attributes-based GIN query that can be used to search records in a
storage.

This is a ready-to-use query that uses an object's attributes to search through
the storage.

=head1 METHODS/SUBROUTINES

=head2 new

Creates a new query.

=head1 ATTRIBUTES

=head2 attributes

Attributes of the object you want to find.

    my $query = Search::GIN::Query::Attributes->new(
        attributes => {
            name => 'Homer',
            city => 'Springfield',
        },
    );

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman), Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
