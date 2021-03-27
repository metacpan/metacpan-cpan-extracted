package Search::Typesense::Collection;

use v5.16.0;

use Moo;
with qw(Search::Typesense::Role::Request);

use Carp 'croak';
use Search::Typesense::Types qw(
  HashRef
  InstanceOf
  NonEmptyStr
  Str
  compile
);

=head1 NAME

Search::Typesense::Collection - CRUD for Typesense collections

=head1 SYNOPSIS

    my $typesense = Search::Typesense->new(
        host    => $host,
        api_key => $key,
    );
    my $collections = $typesense->collections;

The instantiation of this module is for internal use only. The methods are
public.

=head2 C<get>

    if ( my $collections = $typesense->collections->get ) {
        # returns all collections
    }
    if ( my $collections = $typesense->collections->get($collection_name) ) {
        # returns collection matching $collection_name, if any
    }

Response shown at L<https://typesense.org/docs/0.19.0/api/#retrieve-collection>

=cut

our $VERSION = '0.07';

=head2 C<search>

    my $results = $typesense->collections->search($collection_name, {q => 'London'});

The parameters for C<$query> are defined at
L<https://typesense.org/docs/0.19.0/api/#search-collection>, as are the results.

Unlike other methods, if we find nothing, we still return the data structure
(instead of C<undef> instead of a 404 exception).

=cut

sub search {
    my ( $self, $collection, $query ) = @_;
    state $check = compile( NonEmptyStr, HashRef );
    ( $collection, $query ) = $check->( $collection, $query );

    unless ( exists $query->{q} ) {
        croak("Query parameter 'q' is required for searching");
    }
    my $tx = $self->_GET(
        path  => [ 'collections', $collection, 'documents', 'search' ],
        query => $query,
        return_transaction => 1,
    ) or return;
    return $tx->res->json;
}

sub get {
    my ( $self, $collection ) = @_;
    state $check = compile(Str);
    my @collection = $check->( $collection // '' );
    return $self->_GET( path => [ 'collections', @collection ] );
}

=head2 C<create>

    my $collection = $typesense->collections->create(\%definition);

Arguments and response as shown at
L<https://typesense.org/docs/0.19.0/api/#create-collection>

=cut

sub create {
    my ( $self, $collection_definition ) = @_;
    state $check = compile(HashRef);
    ($collection_definition) = $check->($collection_definition);
    my $fields = $collection_definition->{fields};

    foreach my $field (@$fields) {
        if ( exists $field->{facet} ) {
            $field->{facet}
              = $field->{facet} ? Mojo::JSON->true : Mojo::JSON->false;
        }
    }

    return $self->_POST(
        path => ['collections'],
        body => $collection_definition
    );
}

=head2 C<delete>

    my $response = $typesense->collections->delete($collection_name);

Response shown at L<https://typesense.org/docs/0.19.0/api/#drop-collection>

=cut

sub delete {
    my ( $self, $collection ) = @_;
    state $check = compile(NonEmptyStr);
    ($collection) = $check->($collection);
    return $self->_DELETE( path => [ 'collections', $collection ] );
}

=head2 C<delete_all>

    $typesense->collections->delete_all;

Deletes everything from Typesense. B<Use with caution>!

=cut

sub delete_all {
    my ($self) = @_;
    my $collections = $self->get;
    foreach my $collection (@$collections) {
        my $name = $collection->{name};
        $self->delete($name);
    }
}

1;

