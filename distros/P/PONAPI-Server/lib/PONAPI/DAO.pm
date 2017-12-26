# ABSTRACT: Data Abstraction Object class
package PONAPI::DAO;

use Moose;

use PONAPI::DAO::Request::Retrieve;
use PONAPI::DAO::Request::RetrieveAll;
use PONAPI::DAO::Request::RetrieveRelationships;
use PONAPI::DAO::Request::RetrieveByRelationship;
use PONAPI::DAO::Request::Create;
use PONAPI::DAO::Request::CreateRelationships;
use PONAPI::DAO::Request::Update;
use PONAPI::DAO::Request::UpdateRelationships;
use PONAPI::DAO::Request::Delete;
use PONAPI::DAO::Request::DeleteRelationships;

has repository => (
    is       => 'ro',
    does     => 'PONAPI::Repository',
    required => 1,
);

has version => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has json => (
    is      => 'ro',
    isa     => JSON::MaybeXS::JSON(),
    default => sub { JSON::MaybeXS->new->allow_nonref->utf8->canonical },
);

sub retrieve_all             { shift->_action( 'PONAPI::DAO::Request::RetrieveAll'            , @_ ) }
sub retrieve                 { shift->_action( 'PONAPI::DAO::Request::Retrieve'               , @_ ) }
sub retrieve_relationships   { shift->_action( 'PONAPI::DAO::Request::RetrieveRelationships'  , @_ ) }
sub retrieve_by_relationship { shift->_action( 'PONAPI::DAO::Request::RetrieveByRelationship' , @_ ) }
sub create                   { shift->_action( 'PONAPI::DAO::Request::Create'                 , @_ ) }
sub create_relationships     { shift->_action( 'PONAPI::DAO::Request::CreateRelationships'    , @_ ) }
sub update                   { shift->_action( 'PONAPI::DAO::Request::Update'                 , @_ ) }
sub update_relationships     { shift->_action( 'PONAPI::DAO::Request::UpdateRelationships'    , @_ ) }
sub delete : method          { shift->_action( 'PONAPI::DAO::Request::Delete'                 , @_ ) }
sub delete_relationships     { shift->_action( 'PONAPI::DAO::Request::DeleteRelationships'    , @_ ) }

sub _action {
    my $self         = shift;
    my $action_class = shift;

    my $ponapi_parameters = @_ == 1 ? $_[0] : +{ @_ };
    $ponapi_parameters->{repository} = $self->repository;
    $ponapi_parameters->{version}    = $self->version;
    $ponapi_parameters->{json}       = $self->json;

    local $@;
    my @ret;
    eval {
        @ret = $action_class->new($ponapi_parameters)->execute();
        1;
    } or do {
        my $e = $@ || 'Unknown error';
        @ret = PONAPI::Exception
                    ->new_from_exception($e)
                    ->as_response;
    };

    return @ret;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO - Data Abstraction Object class

=head1 VERSION

version 0.003002

=head1 SYNOPSIS

    use PONAPI::DAO;
    my $dao = PONAPI::DAO->new( repository => $repository );

    my ($status, $doc) = $dao->retrieve( type => $type, id => $id );
    die "retrieve failed; status $status, $doc->{errors}[0]{detail}"
        if $doc->{errors};

    use Data::Dumper;
    say Dumper($doc->{data});

    # Fetch all resources of this type
    $dao->retrieve_all( type => $type );

    # Fetch all the relationships of $rel_type for the requested resource
    $dao->retrieve_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
    );

    # Like the above, but fetches full resources instead of just relationships
    $dao->retrieve_by_relationship(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
    );

    # Create a new resource
    $dao->create(
        type => $type,
        data => {
            type          => $type,
            attributes    => { ... },
            relationships => { ... },
        }
    );

    # *Add* a new entry to the relationships between $type and $rel_type
    $dao->create_relationsips(
        type     => $type,
        rel_type => $rel_type,
        data => [
            { ... },
        ]
    );

    # Update the attributes and/or relationships of a resource
    $dao->update(
        type => $type,
        id   => $id,
        data => {
            type          => $type,
            id            => $id,
            attributes    => { ... },
            relationships => { ... },
        },
    );

    # Update the relationships of a given type for one resource
    $dao->update_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
        data     => $update_data,
    );

    # Delete a resource
    $dao->delete(
        type => $type,
        id   => $id,
    );

    # Delete the members from the relationship
    $dao->delete_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
        data     => [
            { ... }, ...
        ],
    );

=head1 DESCRIPTION

Data Access Object for the JSON API.  This sits in between a server
and a L<repository|"PONAPI::Repository">.

All public DAO methods will return a 3-item list of a status, headers,
and the response body; this can then be fed directly to a PSGI application:

If present, the C<data> key of the response will contain either a
resource, or an arrayref of resources.  Resources are represented as
plain hashrefs, and they B<must> include both a C<type> and C<id>; they
may also contain additional keys.  See L<http://jsonapi.org/format/#document-resource-objects>
for a more in-depth description.

=head1 METHODS

=head2 new

Create a new instance of PONAPI::DAO.

    my $DAO = PONAPI::DAO->new(
        repository => $repository,
    );

Where C<$repository> implements the L<PONAPI::Repository> role.

As expanded below in L</"Return value of update operations">, the JSON API specification requires some
update operations returning C<200 OK> to also do a C<retrieve> and include
it in the response.
By default, C<PONAPI::DAO> will simply turn those C<200 OK> into
C<202 Accepted>, avoiding the need to do the extra fetch.  If needed, the
full 200 responses can be re-enabled by passing
C<respond_to_updates_with_200 =E<gt> 1,> to C<new>.

=head1 API METHODS

With the exception of C<create> and C<retrieve_all>, the type and id arguments are mandatory
for all operations.

=head2 retrieve

Retrieve a resource.  Returns both the status of the request and
the document to be encoded.

    my ( $status, $doc ) = $dao->retrieve( type => "articles", id => 1 );

    if ( $doc->{errors} ) {
        die "Welp! Got some errors: ", join "\n",
                map $_->{detail}, @{ $doc->{errors} };
    }

    say $doc->{data}{attributes}{title};

This accepts several optional values:

=over 4

=item fields

Allows fetching only specific fields of the resource:

    # This will fetch the entire resource
    $dao->retrieve(type => "articles", id => 1);

    # This will only fetch the title attribute
    $dao->retrieve(
        type   => "articles",
        id     => 1,
        fields => { articles => [qw/ title /] },
    );

Note how the fields fetched are requested per attribute type.  This allows you to
request specific fields in resources fetched through C<include>.

=item include

Allows including related resources.

    # The response will contain a top-level 'include' key with the
    # article's author
    $dao->retrieve(type => "articles", id => 1, include => [qw/ author /]);

    # We can combine include with C<fields> to fetch just the author's name:
    my $response = $dao->retrieve(
        id      => 1,
        type    => "articles",
        include => [qw/ author /],
        fields  => { author => [qw/ name /] }
    );

These will show up in the document in the top-level "included" key.

=item page

Used to provide pagination information to the underlaying repository.
Each implementation may provide a different pagination strategy.

=item filter

Entirely implementation-specific.

=back

=head2 retrieve_all

As you might expect, this is similar to C<retrieve>.  The returned document
will contain an arrayref of resource, rather than a single resource.

Depending on the implementation, you may be able to combine this with
C<filter> to retrieve multiple specific resources in a single request.

C<retrieve_all> takes all the same optional arguments as C<retrieve>,
plus one of its own:

=over 1

=item sort

Sorting strategy for the request.  Implementation-specific.

=back

=head2 retrieve_relationships

This retrieves all relationships of C<$type>.  Will return either an
arrayref or a hashref, depending on whether the requested relationship is
one-to-one or one-to-many:

    # Retrieves all comments made for an article
    $doc = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
    );
    # articles-to-comments is one-to-many, so it returns an arrayref
    say scalar @{ $doc->{data} };

    $doc = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
    );
    # articles-to-author is one-to-one, so it returns a hashref
    say $doc->{data}{id};

Takes two optional arguments, C<filter> and C<page>; both are entirely
implementation specific.

=head2 retrieve_by_relationships

Like C<retrieve_relationships>, but fetches full resources, rather than
identifier objects.

    # One-to-many relationship, this returns an arrayref of resource hashrefs.
    $dao->retrieve_by_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
    );
    # Same as:
    $doc      = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
    );
    $comments = $dao->retrieve_all(
        type   => $doc->{data}{type},
        filter => { id => [ map $_->{id}, @{ $doc->{data} } ] },
    );

    # One-to-one relationship
    $doc = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
    );
    # Same as:
    $doc    = $dao->retrieve_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
    );
    $author = $dao->retrieve(
        type => $doc->{data}{type},
        id   => $doc->{data}{id},
    );

Takes the same optional arguments as C<retrieve> and C<retrieve_all>, whichever is applicable.

=head2 delete

Deletes a resource.

    $dao->delete( type => "articles", id => 1 );

May or may not return a document with a top-level meta key.

=head2 create

Creates a resource.

    $dao->create(
        type => "articles",
        data => {
            type          => "articles",
            attributes    => { ... },
            relationships => { ... },
        },
    );

This is one of the few methods where the C<id> is optional.  If provided, the underlaying
implementation may choose to use it, instead of generating a new idea for the created resource.

If successful, the response will include both a C<Location> header specifying
where the new resource resides, and a document that includes the newly
created resource.

=head2 update

Updates a resource.  This can be used to either update the resource attributes,
or its relationships; for the latter, you may want to consider using C<update_relationships>,
C<create_relationships>, or C<delete_relationships> instead.

    # Change article's title
    $dao->update(
        type => "articles",
        id   => 1,
        data => {
            type       => "articles",
            id         => 1,
            attributes => { title => "Updated title!" },
        }
    );

    # Change the article's author
    $dao->update(
        type => "articles",
        id   => 1,
        data => {
            type          => "articles",
            id            => 1,
            relationships => {
                author => { type => "people", id => 99 },
            },
        },
    );

    # Switch the tags of the article to a new set of tags
    $dao->update(
        type => "articles",
        id   => 1,
        data => {
            type          => "articles",
            id            => 1,
            relationships => {
                tags => [
                    { type => "tag", id => 4 },
                    { type => "tag", id => 5 },
                ],
            },
        },
    );

Missing attributes or relationships will B<not> be modified.

=head3 Return value of update operations

C<update>, C<delete_relationships>, C<create_relationships>, and
C<update_relationships> all follow the same rules for their responses.

If successful, they will return with either:

=over 3

=item 200 OK

If the update was successful and no extra data was updated, the response
will include a top-level C<meta> key, with a description of what was
updated.

Meanwhile, if the update was successful but more data than requested was
updated -- Consider C<updated-at> columns in a table -- then the request
will return both a top-level C<meta> key, and a top-level C<data> key,
containing the results of a C<retrieve> operation on the primary updated
resource.  Since this behavior can be undesirable, unless C<PONAPI::DAO-E<gt>new>
was passed C<respond_to_updates_with_200 =E<gt> 1>, this sort of response is
disabled, and the server will instead respond with a L</"202 Accepted">,
described below.

=item 202 Accepted

The response will include a top-level C<meta> key, with a human-readable
description of the success.

This is used when the server accepted the operation, but hasn't yet
completed it;  "Completed" being purposely very ambiguous.  In a SQL-based
implementation, it might simply mean that the change hasn't fully replicated
yet.

=item 204 No Content

If the operation was successful and nothing beyond the requested was modified,
the server may choose to send a 204 with no body, instead of a 200.

=back

=head2 delete_relationships

Remove members from a one-to-many relationship.

    # Remove two comments from the article
    $dao->delete(
        type     => "articles",
        id       => 1,
        rel_type => "comments',
        data     => [
            { type => "comment", id => 44 },
            { type => "comment", id => 89 },
        ],
    );

See also L</"Return value of update operations">.

=head2 update_relationships

Update the relationships of C<$rel_type>; this will replace all relationships
of the requested type with the ones provided.  Note that different semantics
are used for one-to-one and one-to-many relationships:

    # Replace all comments
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
        # articles-to-comments is one-to-many, so it gets an arrayref
        data     => [ { ... }, { ... } ],
    );

    # Change the author of the article
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
        # articles-to-authors is one-to-one, so it gets a simple hashref
        data     => { type => "people", id => 42 },
    );

    # Clear the comments of an article
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
        # Empty array to clear out a one-to-many
        data     => [],
    );

    # Clear the author of the relationship
    $dao->update_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "author",
        # undef to clear out one-to-one
        data     => undef,
    );

See also L</"Return value of update operations">.

=head2 create_relationships

Adds a new member to the specified one-to-many relationship.

    # Add a new, existing comment to the article
    $dao->create_relationships(
        type     => "articles",
        id       => 1,
        rel_type => "comments",
        data     => [
            { type => "comment", id => 55 },
        ],
    );

See also L</"Return value of update operations">.

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
