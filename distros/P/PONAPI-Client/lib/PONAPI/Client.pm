# ABSTRACT: Client to a {JSON:API} service (http://jsonapi.org/) v1.0
package PONAPI::Client;

our $VERSION = '0.002010';

use Moose;

use JSON::MaybeXS qw( decode_json );

use PONAPI::Client::Request::Create;
use PONAPI::Client::Request::CreateRelationships;
use PONAPI::Client::Request::Retrieve;
use PONAPI::Client::Request::RetrieveAll;
use PONAPI::Client::Request::RetrieveRelationships;
use PONAPI::Client::Request::RetrieveByRelationship;
use PONAPI::Client::Request::Update;
use PONAPI::Client::Request::UpdateRelationships;
use PONAPI::Client::Request::Delete;
use PONAPI::Client::Request::DeleteRelationships;

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'localhost' },
);

has port => (
    is      => 'ro',
    isa     => 'Num',
    default => sub { 5000 },
);

has send_version_header => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 1 },
);

has send_escape_values_header => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 1 },
);

has 'uri_base' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => sub { '' },
);

has ua => (
    is      => 'ro',
    does    => 'PONAPI::Client::Role::UA',
    lazy    => 1,
    builder => '_build_hijk_ua',
);

### public methods

sub create {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::Create->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub create_relationships {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::CreateRelationships->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve_all {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::RetrieveAll->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::Retrieve->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve_relationships {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::RetrieveRelationships->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub retrieve_by_relationship {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::RetrieveByRelationship->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub update {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::Update->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub update_relationships {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::UpdateRelationships->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub delete : method {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::Delete->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

sub delete_relationships {
    my ($self)  = @_;
    my $request = PONAPI::Client::Request::DeleteRelationships->new( _args(@_) );
    return $self->_send_ponapi_request( $request->request_params );
}

### private methods

sub _build_hijk_ua {
    require PONAPI::Client::UA::Hijk;
    return PONAPI::Client::UA::Hijk->new();
}

sub _args {
    my $self = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    $args{uri_base} = $self->uri_base;
    return %args;
}

sub _http_request {
    my ($self) = @_;
    return $self->ua->send_http_request($_[1]);
}

my %DEFAULT_HEADER_OVERRIDE;

# $self->add_to_default_headers([ header1 => value1 ], [header2 => value2], ...)

sub add_to_default_headers {
    my ($self, @headers) = @_;

    $DEFAULT_HEADER_OVERRIDE{$_->[0]} = $_->[1] for @headers;
}

sub _send_ponapi_request {
    my $self = shift;
    my %args = @_;

    my @mt_header = (
        ( $args{body} ? 'Content-Type' : 'Accept' ),
        'application/vnd.api+json'
    );

    my ($status, $content, $failed, $e);
    ($status, $content) = do {
        local $@;
        eval {

            my $request = {
                %args,
                host => $self->host,
                port => $self->port,
                head => [
                    @mt_header,
                    ( $self->send_version_header
                        ? ( 'X-PONAPI-Client-Version' => '1.0' )
                        : ()
                    ),
                    ( $self->send_escape_values_header
                        ? ( 'X-PONAPI-Escaped-Values' => '1' )
                        : ()
                    ),
                    %DEFAULT_HEADER_OVERRIDE,
                ],
            };

            $self->ua->before_request($request);

            my $res = $self->_http_request($request);
            $status  = $res->{status};

            $self->ua->after_request($res);

            $content = $res->{body} ? decode_json( $res->{body} ) : '';
            1;
        }
        or do {
            ($failed, $e) = (1, $@||'Unknown error');
        };

        if ( $failed ) {
            $status ||= 400;
            $content  = {
                errors  => [ { detail => $e, status => $status } ],
            };
        }

        ($status, $content);
    };

    return ($status, $content);
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client - Client to a {JSON:API} service (http://jsonapi.org/) v1.0

=head1 VERSION

version 0.002010

=head1 SYNOPSIS

    use PONAPI::Client;
    my $client = PONAPI::Client->new(
        host => $host,
        port => $port,
    );

    $client->retrieve_all( type => $type );

    $client->retrieve(
        type => $type,
        id   => $id,
    );

    $client->retrieve_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
    );

    $client->retrieve_by_relationship(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
    );

    $client->create(
        type => $type,
        data => {
            attributes    => { ... },
            relationships => { ... },
        },
    );

    $client->delete(
        type => $type,
        id   => $id,
    );

    $client->update(
        type => $type,
        id   => $id,
        data => {
            type => $type,
            id   => $id,
            attributes    => { ... },
            relationships => { ... },
        }
    );

    $client->delete_relationships(
        type => $type,
        id   => $id,
        rel_type => $rel_type,
        data => [
            { type => $rel_type, id => $rel_id },
            ...
        ],
    );

    $client->create_relationships(
        type => $type,
        id   => $id,
        rel_type => $rel_type,
        data => [
            { type => $rel_type, id => $rel_id },
            ...
        ],
    );

    $client->update_relationships(
        type => $type,
        id   => $id,
        rel_type => $rel_type,
        # for a one-to-one:
        data => { type => $rel_type, id => $rel_id },
        # or for a one-to-many:
        data => [
            { type => $rel_type, id => $rel_id },
            ...
        ],
    );

    # If the endpoint uses an uncommon url format:
    $client->retrieve(
        type => 'foo',
        id   => 43,
        # Will generate a request to
        # host:port/type_foo_id_43
        uri_template => "type_{type}_id_{id}",
    );

=head1 DESCRIPTION

C<PONAPI::Client> is a L<{JSON:API}|http://jsonapi.org/> compliant client;
it should be able to communicate with any API-compliant service.

The client does a handful of checks required by the spec, then uses L<Hijk>
to communicate with the service.

In most cases, all API methods return a response document:

    my $response = $client->retrieve(...);

In list context however, all api methods will return the request status and
the document:

    my ($status, $response) = $client->retrieve(...)

Response documents will look something like these:

    # Successful retrieve(type => 'articles', id => 2)
    {
        jsonapi  => { version => "1.0"         },
        links    => { self    => "/articles/2" },
        data     => { ... },
        meta     => { ... }, # May not be there
        included => [ ... ], # May not be there, see C<include>
    }

    # Successful retrieve_all( type => 'articles' )
    {
        jsonapi => { version => "1.0"       },
        links   => { self    => "/articles" }, # May include pagination links
        data    => [
            { ... },
            { ... },
            ...
        ],
        meta     => { ... }, # May not be there
        included => [ ... ], # May not be there, see C<include>
    }

    # Successful create(type => 'foo', data => { ... })
    {
        jsonapi => { version => "1.0"                 },
        links   => { self => "/foo/$created_id"       },
        data    => { type => 'foo', id => $created_id },
    }

    # Successful update(type => 'foo', id => 2, data => { ... })
    {
        jsonapi => { version => "1.0" },
        links   => { self => "/foo/2" }, # may not be there
        meta    => { ...              }, # may not be there
    }

    # Error, see http://jsonapi.org/format/#error-objects
    {
        jsonapi => { version => "1.0" },
        errors  => [
            { ... }, # error 1
            ...      # potentially others
        ],
    }

However, there are situations where the server may respond with a
C<204 No Content> and no response document; depending on the situation,
it might be worth checking the status.

=for TODO Do we want to explain how to create your own subclass of the client?

=head1 METHODS

=head2 new

Creates a new C<PONAPI::Client> object.  Takes a couple of attributes:

=over 4

=item host

The hostname (or IP address) of the service.  Defaults to localhost.

=item port

Port of the service.  Defaults to 5000.

=item send_version_header

Sends a C<X-PONAPI-Client-Version> header set to the {JSON:API} version the
client supports.  Defaults to true.

=back

=head2 retrieve_all

    retrieve_all( type => $type, %optional_arguments )

Retrieves B<all> resources of the given type.  In SQL, this is similar to
C<SELECT * FROM $type>.

This handles several arguments:

=over 4

=item fields

L<Spec|http://jsonapi.org/format/#fetching-sparse-fieldsets>.

Instead of returning every attribute and relationship from a given resource,
C<fields> can be used to specify exactly what is returned.

This excepts a hashref of arrayrefs, where the keys are types, and the values
are either attribute names, or relationship names.

    $client->retrieve_all(
        type   => 'people',
        fields => { people => [ 'name', 'age' ] }
    )

Note that an attribute not being in fields means the opposite to
an attribute having empty fields:

    # No attributes or relationships for both people and comments
    $client->retrieve_all(
        type   => 'people',
        fields => { people => [], comments => [] },
    );

    # No attributes or relationships for comments, but
    # ALL attributes and relationships for people
    $client->retrieve_all(
        type   => 'people',
        fields => { comments => [] },
    );

=item include

L<Spec|http://jsonapi.org/format/#fetching-includes>.

C<include> can be used to fetch related resources.
The example below is fetching both all the people, and all comments made by
those people:

    my $response = $client->retrieve_all(
        type   => 'people',
        include => ['comments']
    );

C<include> expects an arrayref of relationship names.  In the response,
the resources fetched will be in an arrayref under the top-level C<included>
key:

    say $_->{attributes}{body} for @{ $response->{included} }

=item page

L<Spec|http://jsonapi.org/format/#fetching-pagination>.

Requests that the server paginate the results.  Each endpoint may have different
pagination rules.

=item sort

L<Spec|http://jsonapi.org/format/#fetching-sorting>.

Requests that the server sort the results in a given way:

    $client->retrieve_all(
        type => 'people',
        sort => [qw/ age  /], # sort by age, ascending
    );

    $client->retrieve_all(
        type => 'people',
        sort => [qw/ -age /], # sort by age, descending
    );

Although not all endpoints will support this, it may be possible to sort by
a relationship's attribute:

    $client->retrieve_all(
        type => 'people',
        sort => [qw/ -comments.created_date /],
    );

=item filter

L<Spec|http://jsonapi.org/format/#fetching-filtering>.

This one is entirely dependent on the endpoint.  It's usually employed
to act as a C<WHERE> clause:

    $client->retrieve_all(
        type   => 'people',
        filter => {
            id  => [ 1, 2, 3, 4, 6 ], # IN ( 1, 2, ... )
            age => 34,                # age = 34
        },
    );

Sadly, more complex filters are currently not available.

=back

=head2 retrieve

    retrieve( type => $type, id => $id, %optional_arguments )

Similar to C<retrieve_all>, but retrieves a single resource.

=head2 retrieve_relationships

    retrieve_relationships( type => $type, id => $id, rel_type => $rel_type, %optional_arguments )

Retrieves all of C<$id>'s relationships to C<$rel_type> as resource identifiers;
that is, as hashrefs that contain only C<type> and C<id>:

    # retrieve_relationships(type=>'people', id=>2, rel_type=>'comments')
    {
        jsonapi => { version => "1.0" },
        data    => [
            { type => 'comments', id => 4  },
            { type => 'comments', id => 9  },
            { type => 'comments', id => 14 },
        ]
    }

These two do roughly the same thing:

    my $response      = $client->retrieve( type => $type, id => $id );
    my $relationships = $response->{data}{relationships}{$rel_type};
    say join ", ", map $_->{id}, @$relationships;

    my $response = $client->retrieve_relationships(
        type     => $type,
        id       => $id,
        rel_type => $rel_type,
    );
    my $relationships = $response->{data};
    say join ", ", map $_->{id}, @$relationships;

However, C<retrieve_relationships> also allows you to page those
relationships, which may be quite useful.

Keep in mind that C<retrieve_relationships> will return an arrayref for
one-to-many relationships, and a hashref for one-to-ones.

=head2 retrieve_by_relationship

    retrieve_by_relationship( type => $type, id => $id, rel_type => $rel_type, %optional_arguments )

C<retrieve_relationships> on steroids.  It behaves the same way, but will
retrieve full resources, not just resource identifiers; because of this,
you can also potentially apply more complex filters and sorts.

=head2 create

    create( type => $type, data => { ... }, id => $optional )

Create a resource of type C<$type> using C<$data> to populate it.
Data B<must> include the type, and may include two other keys: C<attributes>
and C<relationships>:

    $client->create(
        type => 'comments',
        data => {
            type          => 'comments',
            attributes    => { body => 'abc' },
            relationships => {
                author   => { type => 'people', id => 55 },
                liked_by => [
                    { type => 'people', id => 55  },
                    { type => 'people', id => 577 },
                ],
            }
        }
    }

An optional C<id> may be provided, in which case the server may choose to use
it when creating the new resource.

=head2 update

    update( type => $type, id => $id, data => { ... } )

Can be used to update the resource.  Data B<must> have C<type> and C<id> keys:

    $client->create(
        type => 'comments',
        id   => 5,
        data => {
            type          => 'comments',
            id            => 5,
            attributes    => { body => 'new body!' },
            relationships => {
                author   => undef, # no author
                liked_by => [
                    { type => 'people', id => 79 },
                ],
            }
        }
    }

An empty arrayref (C<[]>) can be used to clear one-to-many relationships, and
C<undef> to clear one-to-one relationships.

A successful C<update> will always return a response document; see the spec
for more details.

L<Spec|http://jsonapi.org/format/#crud-updating>.

=head2 delete

    delete( type => $type, id => $id )

Deletes the resource.

=head2 update_relationships

   update_relationships( type => $type, id => $id, rel_type => $rel_type, data => $data )

Update a resource's relationships.  Basically a shortcut to using C<update>.

For one-to-one relationships, C<data> can be either a single hashref, or undef.
For one-to-many relationships, C<data> can be an arrayref; an empty arrayref
means 'clear the relationship'.

=head2 create_relationships

   create_relationships( type => $type, id => $id, rel_type => $rel_type, data => [{ ... }] )

Adds to the specified one-to-many relationship.

=head2 delete_relationships

   delete_relationships( type => $type, id => $id, rel_type => $rel_type, data => [{ ... }] )

Deletes from the specified one-to-many relationship.

=head1 Endpoint URI format

By default, C<PONAPI::Client> assumes urls on the endpoint are in this format:

    retrieve_all:               /$type
    retrieve:                   /$type/$id
    retrieve_by_relationships:  /$type/$id/$rel_type
    retrieve_relationships:     /$type/$id/relationships/$rel_type

    create:                     /$type or /$type/$id
    delete:                     /$type/$id
    update:                     /$type/$id

    update_relationships:       /$type/$id/relationships/$rel_type
    create_relationships:       /$type/$id/relationships/$rel_type
    delete_relationships:       /$type/$id/relationships/$rel_type

    # Will generate a request to /foo/99
    $client->retrieve(
        type => 'foo',
        id   => 99,
    );

However, if another format is needed, two approaches are possible:

=head2 URI paths have a common prefix

If all the endpoint urls have a common prefix, ala C</v1/articles>
instead of simply C</articles>, then you can just set C<uri_base>
as needed:

    $client->retrieve(
        type     => 'foo',
        id       => 99,
        uri_base => '/v1'
    );

We can also set this when creating the client; if done this way,
all requests generated from this client will include the base:

    my $new_client = PONAPI::Client->new(
        uri_base => '/v1',
        ...
    );

    # This will generate a request to /v1/foo/99
    $new_client->retrieve(
        type => 'foo',
        id   => 99,
    );

=head2 Completely different uris

If the endpoint's expected formats are wildly different, you can specify
C<uri_template> with your request:

    # Will generate a request to id_here_99_and_type_there/foo
    $client->retrieve(
        type => 'foo',
        id   => 99,
        uri_template => 'id_here_{id}_and_type_there/{type}'
    );

These placeholders are recognized:

=over 4

=item * type

=item * id

=item * rel_type

=back

This can only be done on a per-request basis.

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
