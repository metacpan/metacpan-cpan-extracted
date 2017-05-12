package Net::PMP::Client;
use Moose;
with 'MooseX::SimpleConfig';
use Carp;
use Data::Dump qw( dump );
use LWP::UserAgent 6;    # SSL verification bug fixed in 6.03
use HTTP::Request;
use MIME::Base64;
use JSON;
use Net::PMP::AuthToken;
use Net::PMP::CollectionDoc;
use Net::PMP::Schema;
use Net::PMP::Credentials;
use URI;
use Try::Tiny;

our $VERSION = '0.006';

has '+configfile' =>
    ( default => $ENV{PMP_CLIENT_CONFIG} || ( $ENV{HOME} . '/.pmp.yaml' ) );
has 'host' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default => sub { $ENV{PMP_CLIENT_HOST} || 'https://api-sandbox.pmp.io/' },
);
has 'id'     => ( is => 'rw', isa => 'Str',  required => 1, );
has 'secret' => ( is => 'rw', isa => 'Str',  required => 1, );
has 'debug'  => ( is => 'rw', isa => 'Bool', default  => 0, );
has 'ua' => ( is => 'rw', isa => 'LWP::UserAgent', builder => '_init_ua', );
has 'pmp_content_type' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {'application/vnd.collection.doc+json'},
);
has 'last_response' => ( is => 'rw', isa => 'HTTP::Response', );

# TODO add strict mode where schema validation is enforced client-side on save()
#has 'strict' => ( is => 'rw', isa => 'Bool', default => sub {0} );

# some constructor-time setup
sub BUILD {
    my $self = shift;
    $self->{host} =~ s/\/$//;    # no trailing slash
    $self->{_last_token_ts} = 0;
    $self->get_token();               # initiate connection
    $self->_set_home_doc_config();    # basic introspection
    return $self;
}

sub _init_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new(
        agent    => 'net-pmp-perl-' . $VERSION,
        ssl_opts => { verify_hostname => 1 },
    );

# if Compress::Zlib is installed, this should handle gzip transparently.
# thanks to
# http://stackoverflow.com/questions/1285305/how-can-i-accept-gzip-compressed-content-using-lwpuseragent
    my $can_accept = HTTP::Message::decodable();
    $ua->default_header( 'Accept-Encoding' => $can_accept );

    if ( $self->debug ) {
        $ua->add_handler( "request_send",  sub { shift->dump; return } );
        $ua->add_handler( "response_done", sub { shift->dump; return } );
    }

    return $ua;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Net::PMP::Client - Perl client for the Public Media Platform

=head1 SYNOPSIS

 use Net::PMP::Client;
 
 my $host = 'https://api-sandbox.pmp.io';
 my $client_id = 'i-am-a-client';
 my $client_secret = 'i-am-a-secret';

 # instantiate a client
 my $client = Net::PMP::Client->new(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 ); 

 # authenticate
 my $token = $client->get_token();
 if ($token->expires_in() < 10) {
     die "Access token expires too soon. Not enough time to make a request. Mayday, mayday!";
 }
 printf("PMP token is: %s\n, $token->as_string());

 # search
 my $search_results = $client->search({ tag => 'samplecontent', profile => 'story' });  
 my $results = $search_results->get_items();
 printf( "total: %s\n", $results->total );
 while ( my $r = $results->next ) { 
     printf( '%s: %s [%s]', $results->count, $r->get_uri, $r->get_title, ) );
 }   
 
=cut

=head1 DESCRIPTION

Net::PMP::Client is a Perl client for the Public Media Platform API (http://docs.pmp.io/).

=head1 METHODS

=head2 new( I<args> )

Instantiate a Client object. I<args> may consist of:

=over

=item host

Default is C<https://api-sandbox.pmp.io>.

=item id (required)

The client id. See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Authenticating-with-the-API#generating-credentials>.

=item secret (required)

The client secret. See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Authenticating-with-the-API#generating-credentials>.

=item debug

Boolean. Default is off.

=item ua

A LWP::UserAgent object.

=item pmp_content_type

Defaults to C<application/vnd.collection.doc+json>. Change at your peril.

=back

=head2 BUILD

Internal method for object construction.

=head2 last_response

Returns the most recent HTTP::Response object. Useful for debugging client behaviour.

=head2 get_home_doc

Returns the CollectionDoc for the API root. This object is cached for performance reasons.

=cut

sub get_home_doc {
    my $self = shift;
    return $self->{_home_doc};
}

=head2 get_token([I<refresh>],[I<warning_ttl>])

Returns a Net::PMP::AuthToken object. The optional I<refresh> boolean indicates
that the Client should ignore any cached token and fetch a fresh one.

If get_home_doc() is undefined (i.e., no initial access has been attempted),
then this method will return undef.

If the token will expire in less than I<warning_ttl> seconds, the client will sleep()
that long and then refresh itself. The default is 10 seconds.

=cut

sub get_token {
    my $self        = shift;
    my $refresh     = shift || 0;
    my $warning_ttl = shift || 10;

    # use cache?
    if (   !$refresh
        and $self->{_token}
        and $self->{_token}->expires_in() > $warning_ttl )
    {
        my $tok = $self->{_token};
        if ( $self->{_last_token_ts} ) {
            $tok->expires_in(
                $tok->expires_in - ( time() - $self->{_last_token_ts} ) );
        }
        $self->{_last_token_ts} = time();
        return $tok;
    }

    if ( $self->{_token} and $self->{_token}->expires_in() <= $warning_ttl ) {
        if ( $self->debug ) {
            warn sprintf(
                "Token will expire in %d seconds. Sleeping for that long...\n",
                $self->{_token}->expires_in() );
        }
        sleep( $self->{_token}->expires_in() + 1 );   # let server side expire
    }

    # fetch new token
    my $home_doc = $self->get_home_doc();

    # we have a chicken-and-egg situation on the first home doc request,
    # but the home doc doesn't require a token,
    # so just skip it if not defined.
    if ( !$home_doc ) {
        return;
    }
    my $auth_links = $home_doc->get_links('auth');
    my $uri
        = $auth_links->rels('urn:collectiondoc:form:issuetoken')->[0]->href;
    my $request = HTTP::Request->new( POST => $uri );
    my $hash = encode_base64( join( ':', $self->id, $self->secret ), '' );
    $request->header( 'Accept'       => 'application/json' );
    $request->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
    $request->header( 'Authorization' => 'Basic ' . $hash );
    $request->content('grant_type=client_credentials');
    my $response = $self->ua->request($request);

    if ( $response->code != 200 ) {
        croak "Invalid response from authn server: " . $response->status_line;
    }

    $self->last_response($response);

    # unpack response
    my $token = try {
        decode_json( $response->decoded_content );
    }
    catch {
        croak "Invalid authn response: " . $response->decoded_content;
    };
    $self->{_token}         = Net::PMP::AuthToken->new($token);
    $self->{_last_token_ts} = time();
    return $self->{_token};
}

=head2 revoke_token

Expires the currently active AuthToken.

=cut

sub revoke_token {
    my $self       = shift;
    my $auth_links = $self->get_home_doc()->get_links('auth');
    my $uri
        = $auth_links->rels('urn:collectiondoc:form:revoketoken')->[0]->href;
    my $hash = encode_base64( join( ':', $self->id, $self->secret ), '' );
    my $request = HTTP::Request->new( DELETE => $uri );
    $request->header( 'Authorization' => 'Basic ' . $hash );
    my $response = $self->ua->request($request);

    if ( $response->code != 204 ) {
        croak "Invalid response from authn server: " . $response->status_line;
    }
    $self->{_token} = undef;
    return $self;
}

=head2 get_credentials_uri

Returns the URI for the Credentials API.

=cut

sub get_credentials_uri {
    my $self       = shift;
    my $auth_links = $self->get_home_doc()->get_links('auth');
    my $uri
        = $auth_links->rels('urn:collectiondoc:form:createcredentials')->[0]
        ->href;
    return URI->new($uri);
}

=head2 create_credentials( I<params>  )

Instantiates credentials at server. I<params> should be a hash of key/value pairs.

=over 

=item username (required)

=item password (required)

=item scope (default: read)

=item expires (default: 86400)

=item label (default: null)

=back

Returns a Net::PMP::Credentials object.

=cut

sub create_credentials {
    my $self   = shift;
    my %params = @_;
    my $user   = delete $params{username} or croak "username required";
    my $pass   = delete $params{password} or croak "password required";

    # validate input
    my @valid_params = qw( scope expires label token_expires_in );
    my %post_params;
    for my $p (@valid_params) {
        if (    exists $params{$p}
            and defined $params{$p}
            and length $params{$p} )
        {
            $post_params{$p} = delete $params{$p};
        }
    }

    # special case
    if ( $post_params{expires} ) {
        $post_params{token_expires_in} = delete $post_params{expires};
    }
    $post_params{label} ||= 'null'; # Net::PMP::Credentials requires it be set

    my $uri = $self->get_credentials_uri();
    my $hash = encode_base64( join( ':', $user, $pass ), '' );
    if ( $self->debug ) {
        warn "POST with $user:$pass => $hash\n";
    }
    my $request = HTTP::Request->new( POST => $uri );
    $request->header( 'Authorization' => 'Basic ' . $hash );
    $request->header( 'Accept'        => 'application/json' );
    $request->header( 'Content-Type' => 'application/x-www-form-urlencoded' );

    # mimic what HTTP::Request::Common does for POST
    my $url = URI->new('http:');
    $url->query_form(%post_params);
    $request->content( $url->query );

    # send request
    my $response = $self->ua->request($request);
    if ( $response->code != 200 ) {
        croak "Invalid response from authn server: " . $response->status_line;
    }
    $self->last_response($response);

    # unpack response
    my $creds = try {
        decode_json( $response->decoded_content );
    }
    catch {
        croak "Invalid authn response: " . $response->decoded_content;
    };
    return Net::PMP::Credentials->new($creds);
}

=head2 delete_credentials( I<params> )

Deletes credentials at the server.

I<params> should consist of:

=over

=item username

=item password

=item client_id

=back

=cut

sub delete_credentials {
    my $self      = shift;
    my %params    = @_;
    my $user      = $params{username} or croak "username required";
    my $pass      = $params{password} or croak "password required";
    my $client_id = $params{client_id} or croak "client_id required";

    my $uri     = $self->get_credentials_uri() . '/' . $client_id;
    my $hash    = encode_base64( join( ':', $user, $pass ), '' );
    my $request = HTTP::Request->new( DELETE => $uri );
    $request->header( 'Authorization' => 'Basic ' . $hash );
    $request->header( 'Accept'        => 'application/json' );
    $request->header( 'Content-Type'  => $self->pmp_content_type );

    # send request
    my $response = $self->ua->request($request);
    if ( $response->code != 204 ) {
        croak "Invalid response from authn server: " . $response->status_line;
    }
    $self->last_response($response);

    return $response;
}

=head2 uri_for_doc(I<guid>)

Returns full URI for I<guid>.

=cut

sub uri_for_doc {
    my $self = shift;
    my $guid = shift or croak "guid required";
    return $self->{_home_doc}->query('urn:collectiondoc:hreftpl:docs')
        ->as_uri( { guid => $guid } );
}

=head2 uri_for_profile(I<profile>)

Returns full URI for I<profile>.

=cut

sub uri_for_profile {
    my $self = shift;
    my $profile = shift or croak "profile required";
    return sprintf( "%s/profiles/%s", $self->host, $profile );
}

=head2 uri_for_schema(I<schema>)

Returns full URI for I<schema>.

=cut

sub uri_for_schema {
    my $self = shift;
    my $schema = shift or croak "schema required";
    return sprintf( "%s/schemas/%s", $self->host, $schema );
}

=head2 get(I<uri>)

Issues a GET request on I<uri> and decodes the JSON response into a Perl
scalar.

If the GET request returns a 404 (Not Found) will return 0 (zero).

If the GET request returns anything other than 200, will croak.

If the GET request returns 200, will return the JSON response, decoded.

=cut

sub get {
    my $self    = shift;
    my $uri     = shift or croak "uri required";
    my $request = HTTP::Request->new( GET => $uri );
    $request->header(
        'Accept' => 'application/json; ' . $self->pmp_content_type, );

    # the initial GET of home doc does not require a token.
    my $token = $self->get_token();
    if ($token) {
        $request->header( 'Authorization' =>
                sprintf( '%s %s', $token->token_type, $token->access_token )
        );
    }
    my $response = $self->ua->request($request);

    # retry if 401
    if ( $response->code == 401 ) {

        # occasional persistent 401 errors?
        sleep(1);
        $token = $self->get_token(1);
        $request->header( 'Authorization' =>
                sprintf( '%s %s', $token->token_type, $token->access_token )
        );

        #sleep(1);
        $response = $self->ua->request($request);
        $self->debug and warn "retry GET $uri\n" . dump($response);
    }

    $self->last_response($response);

    if ( $response->code == 404 ) {
        return 0;
    }

    if ( $response->code != 200 or !$response->decoded_content ) {
        croak "Unexpected response for GET $uri: " . $response->status_line;
    }

    my $json = try {
        decode_json( $response->decoded_content );
    }
    catch {
        croak "Invalid JSON in response: $@ : " . $response->decoded_content;
    };
    return $json;
}

sub _set_home_doc_config {
    my $self = shift;
    $self->{_home_doc} ||= $self->get_doc();
    if ( !$self->{_home_doc} ) {
        confess "Failed to GET home doc from " . $self->host;
    }
    my $edit_links = $self->{_home_doc}->get_links('edit');
    $self->{_doc_edit_link}
        = $edit_links->rels("urn:collectiondoc:form:documentsave")->[0];
}

=head2 get_doc_edit_link

Retrieves the base doc edit link object for the API.

=cut

sub get_doc_edit_link {
    my $self = shift;
    return $self->{_doc_edit_link} if $self->{_doc_edit_link};
    $self->_set_home_doc_config();
    return $self->{_doc_edit_link};
}

=head2 put(I<doc_object>)

Write I<doc_object> to the server. I<doc_object> should be an instance
of L<Net::PMP::CollectionDoc>.

Returns the JSON response from the server on success, croaks on failure.

Normally you should use save() instead of put() directly, since save()
optionally validates the I<doc_object> before calling put() and makes
sure there is a B<guid> and B<href> defined.

=cut

sub put {
    my $self = shift;
    my $doc = shift or croak "doc required";
    if ( !blessed $doc or !$doc->isa('Net::PMP::CollectionDoc') ) {
        croak "doc must be a Net::PMP::CollectionDoc object";
    }
    my $uri     = $doc->get_publish_uri( $self->get_doc_edit_link );
    my $request = HTTP::Request->new( PUT => $uri );
    my $token   = $self->get_token();
    my $body    = $doc->as_json();
    if ( $self->debug ) {
        warn "PUT $uri\n" . dump( $doc->as_hash() ) . "\n";
        warn "JSON: $body\n";
    }
    $request->header( 'Accept'       => 'application/json' );
    $request->header( 'Content-Type' => $self->pmp_content_type );
    $request->header( 'Authorization' =>
            sprintf( '%s %s', $token->token_type, $token->access_token ) );
    $request->content($body);
    my $response = $self->ua->request($request);

    # retry if 401
    if ( $response->code == 401 ) {

        # occasional persistent 401 errors?
        sleep(1);
        $token = $self->get_token(1);
        $request->header( 'Authorization' =>
                sprintf( '%s %s', $token->token_type, $token->access_token )
        );

        #sleep(1);
        $response = $self->ua->request($request);
        $self->debug and warn "retry PUT $uri\n" . dump($response);
    }

    $self->last_response($response);

    if ( $response->code !~ m/^20[02]$/ or !$response->decoded_content ) {
        croak sprintf( "Unexpected response for PUT %s: %s\n%s\n",
            $uri, $response->status_line, $response->content );
    }

    my $json = try {
        decode_json( $response->decoded_content );
    }
    catch {
        croak "Invalid JSON in response: $_ : " . $response->decoded_content;
    };
    return $json;
}

=head2 delete(I<doc_object>)

Remove I<doc_object> from the server. Returns true on success, croaks on failure.

=cut

sub delete {
    my $self = shift;
    my $doc = shift or croak "doc required";
    if ( !blessed $doc or !$doc->isa('Net::PMP::CollectionDoc') ) {
        croak "doc must be a Net::PMP::CollectionDoc object";
    }
    my $uri     = $doc->get_publish_uri( $self->get_doc_edit_link );
    my $request = HTTP::Request->new( DELETE => $uri );
    my $token   = $self->get_token();
    $request->header( 'Accept'       => 'application/json' );
    $request->header( 'Content-Type' => $self->pmp_content_type );
    $request->header( 'Authorization' =>
            sprintf( '%s %s', $token->token_type, $token->access_token ) );
    my $response = $self->ua->request($request);

    # retry if 401
    if ( $response->code == 401 ) {

        # occasional persistent 401 errors?
        sleep(1);
        $token = $self->get_token(1);
        $request->header( 'Authorization' =>
                sprintf( '%s %s', $token->token_type, $token->access_token )
        );

        $response = $self->ua->request($request);
        $self->debug and warn "retry DELETE $uri\n" . dump($response);
    }

    $self->last_response($response);

    if ( $response->code != 204 ) {
        croak sprintf( "Unexpected response for DELETE %s: %s\n%s\n",
            $uri, $response->status_line, $response->content );
    }
    return 1;
}

=head2 get_doc( [I<uri>] [,I<tries>] ) 

Returns a Net::PMP::CollectionDoc representing I<uri>. Defaults
to the API base endpoint if I<uri> is omitted or false.

If I<uri> is not found, returns 0 (zero) just like get().

The second, optional parameter I<tries> indicates how many re-tries should
be attempted when the response is a 404. This feature helps compenstate
for occasional latency on the server between an initial save and subsequent
read, since PUT and DELETE requests always return a 202 (accepted but not
necessarily acted upon). The default is 1 try.

=cut

sub get_doc {
    my $self  = shift;
    my $uri   = shift || $self->host;
    my $tries = shift || 1;

    # optimize a little for the root doc
    if ( $uri eq $self->host and $self->{_home_doc} ) {
        return $self->{_home_doc};
    }

    my $response;
    my $attempts = 0;
    while ( !$response and $attempts++ < $tries ) {
        $response = $self->get($uri);
        $self->debug and warn dump $response;
        if ( !$response and $attempts < $tries ) {
            $self->debug
                and warn "search returned 404 - sleeping and trying again\n";
            sleep(1);
        }
    }

    return $response unless $response;    # 404

    # convert JSON response into a CollectionDoc
    # check content type to determine object
    if ( $self->last_response->content_type eq 'application/schema+json' ) {
        return Net::PMP::Schema->new($response);
    }

    my $doc = Net::PMP::CollectionDoc->new($response);

    return $doc;
}

=head2 get_doc_by_guid(I<guid>)

Like get_doc() but takes a I<guid> as argument.

=cut

sub get_doc_by_guid {
    my $self = shift;
    my $guid = shift or croak "guid required";
    return $self->get_doc( $self->uri_for_doc($guid) );
}

=head2 search( I<opts> [,I<tries>] )

Search in the 'urn:collectiondoc:query:docs' namespace.

Returns a Net::PMP::CollectionDoc object for I<opts>.
I<opts> are passed directly to the query link URI template.
See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Query-Link-Relation>.

The second, optional parameter I<tries> is passed internally to get_doc().
See the description of get_doc().

=cut

sub search {
    my $self  = shift;
    my $opts  = shift or croak "options required";
    my $tries = shift || 1;
    my $uri   = $self->{_home_doc}->query('urn:collectiondoc:query:docs')
        ->as_uri($opts);

    # debugging option
    if ( $ENV{PMP_CLIENT_DEBUG} and $ENV{PMP_APPEND_RANDOM_STRING} ) {
        my $rand_guid = Net::PMP::CollectionDoc->create_guid();
        $uri .= '&random=' . $rand_guid;
    }

    return $self->get_doc( $uri, $tries );
}

=head2 save(I<doc_object>)

Write I<doc_object> to the server. I<doc_object> may be a L<Net::PMP::Profile> object,
in which case the as_doc() method is called on it, or it may be a L<Net::PMP::CollectionDoc> object.

Returns a L<Net::PMP::CollectionDoc> object with its URI updated to reflect the server response. 

=cut

sub save {
    my $self = shift;
    my $doc = shift or croak "doc object required";
    if ( blessed $doc and $doc->isa('Net::PMP::Profile') ) {
        $doc = $doc->as_doc();
    }
    if ( !blessed $doc or !$doc->isa('Net::PMP::CollectionDoc') ) {
        croak "doc must be a Net::PMP::CollectionDoc object";
    }

    # if $doc has no guid (necessary for PUT) create one
    if ( !$doc->get_guid ) {
        $doc->set_guid();
    }

    # similar for href
    if ( !$doc->href ) {
        $doc->href( $self->uri_for_doc( $doc->get_guid ) );
    }

    my $saved = $self->put($doc);
    $self->debug and warn dump $saved;

    $doc->set_uri( $saved->{url} );

    return $doc;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
