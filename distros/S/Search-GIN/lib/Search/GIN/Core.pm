use strict;
use warnings;
package Search::GIN::Core;
# ABSTRACT: Core of Search::GIN

our $VERSION = '0.11';

use Moose::Role;
use Data::Stream::Bulk::Util qw(bulk unique);
use namespace::autoclean;

with qw(
    Search::GIN::Driver
    Search::GIN::Extract
);

requires qw(
    objects_to_ids
    ids_to_objects
);

has distinct => (
    isa => "Bool",
    is  => "rw",
    default => 0, # FIXME what should the default be?
);

sub query {
    my ( $self, $query, @args ) = @_;

    my %args = (
        distinct => $self->distinct,
        @args,
    );

    my @spec = $query->extract_values($self);

    my $ids = $self->fetch_entries(@spec);

    $ids = unique($ids) if $args{distinct};

    return $ids->filter(sub { [ grep { $query->consistent($self, $_) } $self->ids_to_objects(@$_) ] });
}

sub remove {
    my ( $self, @items ) = @_;

    my @ids = $self->objects_to_ids(@items);

    $self->remove_ids(@ids);
}

sub insert {
    my ( $self, @items ) = @_;

    my @ids = $self->objects_to_ids(@items);

    my @entries;

    foreach my $item ( @items ) {
        my @keys = $self->extract_values( $item, gin => $self );
        my $id = shift @ids;

        $self->insert_entry( $id, @keys );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Core - Core of Search::GIN

=head1 VERSION

version 0.11

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman), Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
