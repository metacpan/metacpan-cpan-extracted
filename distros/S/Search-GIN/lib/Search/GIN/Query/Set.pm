use strict;
use warnings;
package Search::GIN::Query::Set;
# ABSTRACT: Create queries with set operations

our $VERSION = '0.11';

use Moose;
use namespace::autoclean;

with qw(
    Search::GIN::Query
);

use constant 'method' => 'set';
use constant 'has_method' => 1;

has operation => (
    isa     => 'Str',
    is      => 'ro',
    default => 'UNION'
);

has subqueries => (
    isa => "ArrayRef",
    is  => "ro",
    required => 1,
);

has _processed => (
    is => "ro",
    lazy_build => 1,
);

sub _build__processed {
    my $self = shift;
    return [ map { { $_->extract_values, () } }
             @{$self->subqueries} ];
}

sub extract_values {
    my $self  = shift;

    return (
        subqueries => $self->_processed,
        operation  => $self->operation,
        method     => 'set'
    );
}

sub consistent {
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Query::Set - Create queries with set operations

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    # build a query like:
    # (type:pdf OR type:png) AND (name:Homer OR name:Bart)

    use Search::GIN::Query::Set;
    use Search::GIN::Query::Manual;

    my $query = Search::GIN::Query::Set->new(
        operation => 'INTERSECT',
        subqueries => [
            Search::GIN::Query::Manual->new(
                values => {
                   type => [qw(pdf png)]
                }
            ),
            Search::GIN::Query::Manual->new(
                values => {
                   name => [qw(Homer Bart)]
                }
            ),
        ]
    );

=head1 DESCRIPTION

Creates a manual GIN query that can be used to search using basic set
theory, in order to build more complex queries.

This query doesn't provide any specific search, it's just a set
operator for subqueries. You can build complex queries by using other
set queries as subqueries for a set query.

=head1 METHODS/SUBROUTINES

=head2 new

Creates a new query.

=head1 ATTRIBUTES

=head2 subqueries

The subqueries to process

=head2 operation

One of the basic set operators: "UNION", "INTERSECT" and "EXCEPT". The
default is "UNION"

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman), Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
