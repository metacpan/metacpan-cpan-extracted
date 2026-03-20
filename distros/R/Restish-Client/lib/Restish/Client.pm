use strict;
package Restish::Client;

use Moo;
use Carp qw(croak);
use Data::Validate::URI qw(is_http_uri is_https_uri);
use HTTP::Headers;
use HTTP::Request;
use JSON qw(decode_json encode_json);
use LWP::UserAgent;
use Text::Sprintf::Named qw(named_sprintf);
use URI::Escape qw(uri_escape);
use URI::Query;
use HTTP::Cookies;

our $VERSION = '1.0';

our %VALID_METHOD = (
    GET     => 1,
    PUT     => 1,
    POST    => 1,
    DELETE  => 1,
    PATCH   => 1,
    LIST    => 1,
);

# Set this to enable the canonical encoding of json, for facilitating string
# comparisons. Only to be used when testing. https://metacpan.org/pod/JSON#canonical
our $CANONICAL = 0;

=head1 NAME

Restish::Client - A RESTish client...in perl!

=head1 SYNOPSIS

    use Restish::Client;

    my $client = Restish::Client->new(
        uri_host            => 'https://api.example.com/',
        head_params_default => { 'Authorization' => 'Bearer mytoken' },
    );

    # GET request
    my $data = $client->GET( uri => '/v1/users' );

    # POST with body parameters
    my $result = $client->POST(
        uri         => '/v1/users',
        body_params => { name => 'Alice', email => 'alice@example.com' },
    );

    # GET with URI template and query parameters
    my $user = $client->GET(
        uri             => '/v1/users/%(user_id)s',
        template_params => { user_id => '42' },
        query_params    => { format => 'json' },
    );

    if ($client->response_code == 200) {
        print $user->{name};
    }

=head1 DESCRIPTION

This module provides a Perl wrapper for the REST-like API's.

=head2 METHODS

=over 12

=item C<new>

    my $client = Restish::Client->new(
        uri_host            => 'https://vault.example.com/',
        head_params_default => { 'X-Vault-Token' => $a_token },
        agent_options       => { timeout => 5 },
        require_https       => 1,
        ssl_opts => {
            SSL_use_cert    => 1,
            SSL_cert_file   => "/etc/ssl/certs/cert.pem",
            SSL_key_file    => "/etc/ssl/private_keys/key.pem",
        },
        cookie_jar          => 1,
    );

Construct a new Restish::Client object. The uri_host is used as the base
uri for each API call, and serves as a template if string interpolation is used
(see below). 

Optionally provide any data that can be set via a mutator, such as
head_params_default or the ssl_opts.

Options can be passed to the user agent (currently LWP) via agent_options.

If require_https is set, new() will die if uri_host is not an https uri. 

=item C<head_params_default>

    $client->head_params_default({ 'X-Vault-Token' => $auth_token });

Supply a hashref specifying default header parameters to be sent with every
request using this object.

=cut

has head_params_default => (
    is      => 'rw',
    default => sub { {} },
    isa     => sub { 
            __PACKAGE__->error("Invalid parameter $_[0]; supply a hashref")
                unless ref $_[0] eq 'HASH'
           }
);

=item C<ssl_opts>

    $client->ssl_opts({ SSL_use_cert => 1 });

Supply a hashref specifying default LWP UserAgent SSL options to be sent with every
request using this object.

=cut

has ssl_opts => (
    is      => 'rw',
    default => sub { {} },
    isa     => sub { 
            __PACKAGE__->error("Invalid parameter $_[0]; supply a hashref")
                unless ref $_[0] eq 'HASH'
           }
);

=item C<cookie_jar>

    $client->cookie_jar(1);
    $client->cookie_jar(/path/to/cookiejar)

Enable LWP UserAgent's cookie_jar.  Optionally store the cookie jar to disk.

=cut

has cookie_jar => (
    is      => 'rw',
    default => undef,
);


=item C<request>

    $client->request( method      => 'POST',
                      uri         => 'already/escaped/path',  
                      query_params  => { param1 => value1, param2 => value2 },
                      body_params => { body_param1 => bvalue1, body_param2 => bvalue2 },
                      head_params => { X-Subject-Token => $subject_token } );

Send a request based off of the object's base uri_host, returning a Perl data
structure of the parsed JSON response in the event of a 2xx series response
code. c<method> and c<uri> are required. 

If the request returns a 4xx or 5xx response status code, the return value will
be 0.

The c<response_code>, c<response_header>, and c<response_body> methods can be
used to retrieve more information about the previous request.

The URI is specified as a string that supports Text::Sprintf::Named compatible
string interpretation. Interpolated values will be escaped, but the
non-interpolated section will not be escaped. The URI can begin with a slash or
the slash can be omitted.

    my $res = $client->request(
        method      => 'GET',
        uri         => '/%(tenant_id)s/%(other)s',
        template_params      => { tenant_id => 'cde381ab', other => 'blah' }
        );

Optionally specify parameters. URI parameters will be escaped in the query
string. Body parameters will be encoded as JSON. Head parameters will be sent
in addition to any default parameters specified using the
c<head_params_default> method.

Invalid parameters, such as an invalid uri or not supplying a hashref to
query_params, will result in an exception.

Instead of body_params, you can use raw_body to upload a file.
Use content_type to specify the Content-Type.

    my $res = $client->request(
        method       => 'POST',
        uri          => 'uploads.json',
        query_params => { filename => 'important-doc.pdf' },
        raw_body     => $file_data,
        content_type => 'application/pdf',
    );

=cut

sub request {
    my ($self, %params) = @_;

    # Check params
    # should probably use Params::Validate here

    # check to make sure all named params are valid to avoid cases like using
    # uri_params instead of query_params, which could potentially have bad
    # effects such as when deleting after using a filtered request where the
    # filter didn't actually apply
    my %valid_req_params = (
        method => 1,
        uri => 1,
        template_params => 1,
        query_params => 1,
        body_params => 1,
        head_params => 1,

        # to pass in a file
        raw_body => 1,
        content_type => 1,
    );

    foreach (keys %params) {
        $self->error("Invalid named parameter supplied to Restish::Client->request: $_")
            unless defined $valid_req_params{$_};
    }

    if ($params{query_params}) {
        $self->error("query_params must be a hashref")
            unless ref($params{query_params}) eq 'HASH';
    }

    $VALID_METHOD{$params{method}} or
        $self->error("Invalid value for parameter $params{method}");

    $self->error("Missing value for parameter URI")
        unless defined $params{uri};

    # End param checking


    my $joined_uri = $self->_assemble_uri(
       $params{uri}, $params{query_params}, $params{template_params});
           # It's ok if query_params and/or template_params are nonexistent

    $self->_set__response(undef);

    my $header = HTTP::Headers->new();
    $header->header(%{$params{head_params}})
        if $params{head_params};
    $header->header('Content-Type' => 'application/json')
        if $params{body_params};
    $header->header('Content-Type' => $params{content_type})
        if $params{content_type};

    my $req = HTTP::Request->new(
        $params{method},
        $joined_uri,
        $header
    );

    if ($params{body_params}) {
        $CANONICAL ? $req->content(JSON->new->utf8->canonical->encode($params{body_params}))
                   : $req->content(encode_json($params{body_params}));
    }

    if ($params{raw_body}) {
        $req->content($params{raw_body});
    }

    my $agent = $self->_get_agent();

    my $res;
    if ($self->debug) {
        use Data::Dumper;
        local $Data::Dumper::Sortkeys = sub {
            return [
                grep {$_ !~ /x-auth-token|x-subject-token|x-vault-token/} keys %{$_[0]}
            ];
        } if $self->debug->{trim_tokens};

        warn "*** LWP DEFAULT HEADERS: ". Dumper($agent->default_headers);
        warn "*** REQUEST: " . Dumper($req);

        $res = $agent->request($req);
        warn "*** RESPONSE: " . Dumper($res);
    } else {
        $res = $agent->request($req);
    }

    $self->_set__response($res);

    if ($res->is_success) {
        # This is a bad hack, but some Compute calls return non-json response
        # bodies and decode_json will throw an exception on them.
        # Alternatively, could use a JSON::allow_ method all the time, but I
        # prefer to have validation when actual JSON is returned
        if ($res->decoded_content) {
            return decode_json $res->decoded_content
                if substr($res->decoded_content, 0, 1) =~ /[\{\[]/;
            return $res->decoded_content;
        }

        # request succeeded, but response had no content
        return 1;
    }    

    # request failed
    return 0;
}

=item C<METHOD Aliases>

$client->METHOD(params) will ship the METHOD as method=>$method to the request

=cut
sub GET {
    my ($self, %params) = @_;   
    $params{method} = 'GET';
    return $self->request(%params);
}
sub POST {
    my ($self, %params) = @_;
    $params{method} = 'POST';
    return $self->request(%params);
}
sub LIST {
    my ($self, %params) = @_;
    $params{method} = 'LIST';
    return $self->request(%params);
}
sub DELETE {
    my ($self, %params) = @_;
    $params{method} = 'DELETE';
    return $self->request(%params);
}
sub PATCH {
    my ($self, %params) = @_;
    $params{method} = 'PATCH';
    return $self->request(%params);
}


=item C<thin_request>

Send a request directly to a LWP::UserAgent request method.  These arguments of the
requst may be in the form of key=>value, or multiples of k1=>v1, k2=>v2.  Complex
structures are not supported.

Usage:

  # For GET/DELETE supply each k=>v pair as a new array element
  $client->thin_request('GET', $URI, key1=> val1, key2 => val2);

  # For POST/PUT if you wrap the k=>v pairs into a structure they will be sent as form data
  $client->thin_request('PUT', $URI, {key1 => val1, key2 => val2});

Example:

  my $res = $client->thin_request('POST', "public/auth", { user => $user, pass => $pass });

=cut
sub thin_request {
    my ($self, $method, $uri, $query_params, @data) = @_;

    my $agent = $self->_get_agent();

    die("invalid method") unless $VALID_METHOD{$method};

    # Don't support LIST
    if ($method eq 'LIST') {
        __PACKAGE__->error("thin_request does not support LIST");
    }

    # lc for function call
    $method = lc($method);

    # POST will require a structure
    if ($method eq 'post' && !@data) {
        @data = [];
    }

    my $joined_uri = $self->_assemble_uri($uri,$query_params);

    my $res = $agent->$method($joined_uri, @data);

    $self->_set__response($res);

    if ($res->is_success) {
        if (defined $res->decoded_content) {
            if ($res->header("Content-Type") =~ /^application\/json\b/i) {
                my $json = eval {return decode_json $res->decoded_content} || return 0;
                return $json;
            } else {
                return $res->decoded_content;
            }
        }

        # request succeeded, but response had no content
        return 1;
    }    
    # request failed
    return 0;
}

=item C<is_success>

Shortcut to the whether the last response succeeded

=cut

sub is_success {
    my ($self) = @_;
    return $self->_response->is_success
        if defined $self->_response;
    return undef;
}

=item C<response_code>

Returns the response code of the last request.

=cut

sub response_code {
    my ($self) = @_;
    return $self->_response->code
        if defined $self->_response;
    return undef;
}


=item C<response_header>

    my $ctype = $client->response_header('Content-Type');

Returns the value of a selected response header of the last request.

=cut

sub response_header {
    my ($self, $desired_header) = @_;
    return $self->_response->header($desired_header)
        if defined $self->_response;
    return undef;
}


=item C<response_body>

Returns a string of the response body of the last request.

=cut

sub response_body {
    my ($self) = @_;
    return $self->_response->decoded_content
        if defined $self->_response;
    return undef;
}


=item C<debug>

Dump information on every request(). Set to undef, {}, or a hashref of
configuration flags.

=over 12

=item C<undef>

The default level: don't dump anything.

=item C<{}>

Dump the LWP object's default header object, request object, and response
object.

=item C<{trim_tokens => 0}>

Whether to trim tokens.

=back

=cut

has debug => (
    is => 'rw',
    default => sub { undef }
);

=back

=head2 PRIVATE METHODS

The following private methods are documented in case a subclass should need to
override them.

=over 12

=cut

# If a user wants to use a new root path, safest route is a new obj
has _uri_host => (
    is       => 'ro',
    required => 1,
    init_arg => 'uri_host',
    isa => sub {
        my $uri = $_[0];
        __PACKAGE__->error("Invalid value for parameter $uri; must specify http(s)://")
            unless $uri =~ qr{^https?://\S*};
    }
);

has _require_https => (
    is       => 'ro',
    init_arg => 'require_https',
    isa => sub {
        my $option = $_[0];
        __PACKAGE__->error("Invalid value for parameter require_https: $option;"
                           . " Must be either 0 or 1.")
            unless $option =~ /^[01]$/;
    },
    default => 0
);

sub BUILD {
    my ($self) = @_;
    __PACKAGE__->error("Invalid value for uri_host: $self->uri_host; "
                       . " require_https specified but not a https uri")
        if $self->_require_https && !($self->_uri_host =~ /^https/);
}

# _agent_options($options_hashref)
# Hashref containing the constructor options for the user agent.
has _agent_options => (
    is       => 'ro',
    init_arg => 'agent_options',
    default  => sub {
        return { agent => __PACKAGE__ . "/$VERSION" };
    },
    trigger  => sub {
        my ($self, $options) = @_;
        return if defined $options->{'agent'};

        $options->{agent} = __PACKAGE__ . "/$VERSION";
        return $options;
    }
);

# _response stores the HTTP::Response object from the most recent request
has _response => (is => 'rwp');


=item C<_get_agent>

Returns a new user agent object for use in requests with this client.
C<_get_agent> uses C<_agent_options> to get the constructor options for the
agent.

=cut

sub _get_agent {
    my ($self) = @_;

    my %options = %{$self->_agent_options || {}};

    my $headers = HTTP::Headers->new(Accept => 'application/json');
    
    $headers->header(%{$self->head_params_default})
        if %{$self->head_params_default};

    $options{default_headers} = $headers;

    $options{ssl_opts} = $self->ssl_opts if $self->ssl_opts;

    $options{cookie_jar} = $self->_get_cookie_jar() if $self->cookie_jar;

    $options{env_proxy} = 1;

    return LWP::UserAgent->new(%options);
}

sub _get_cookie_jar {
    my ($self) = @_;

    if($self->cookie_jar eq 1) {
        $self->{_cookie_jar} ||= HTTP::Cookies->new();
    } else {
        $self->{_cookie_jar} ||= HTTP::Cookies->new(file => $self->cookie_jar, autosave => 1, ignore_discard => 1);
    }
}

# _assemble_uri($uri_arrayref_or_string, $query_params_hashref, $template_params_hashref)
# Joins the base uri, uri_host, with the desired path
sub _assemble_uri {
    my ($self, $path, $query_params, $template_params) = @_;

    if (ref $path) {
        $self->error("Invalid value for parameter $path; must be a string");
    }

    if (defined $query_params) {
        $self->error("Invalid value for parameter $query_params; must be a HASH or ARRAY ref")
            unless (ref($query_params) eq 'HASH' or ref($query_params) eq 'ARRAY');
    }

    my $uri;
    if ($path eq '/') {
        # Remove trailing / from base uri if joining to a path of /
        my $uri_host = $self->_uri_host;

        $uri_host = $1
            if $uri_host =~ qr{(\S*)/$};

        $uri = $uri_host . '/';

    } elsif ($path) {
        # Remove trailing / from base uri and beginning / from path
        # so as not to construct a uri with // in the path

        my $uri_host = $self->_uri_host;

        $uri_host = $1
            if $uri_host =~ qr{(\S*)/$};

        $path = $1
            if $path =~ qr{^/(\S*)};

        $uri = $uri_host . '/' . $path;

    } else {
        # No path to append to uri_host, so don't modify uri_host in case user
        # wanted trailing slash
        $uri = $self->_uri_host;
    }

    $uri = $self->_interpolate_uri($uri, $template_params)
        if defined $template_params;

    $uri .= '?' . URI::Query->new($query_params)->stringify
        if defined $query_params;

    $self->error("Invalid value $uri; does not form a valid uri")
        unless(is_http_uri($uri) or is_https_uri($uri));

    return $uri;
}


# _interpolate_uri($uri_string, $template_params_hashref)
# Interpolates named values into the uri, escaping each
sub _interpolate_uri {
    my ($self, $uri, $template_params) = @_;

    $self->error("Invalid value for parameter $template_params: "
        . "interpolated values must be supplied in a hashref\n")
        unless ref($template_params) eq 'HASH';

    my %escaped_tparams;
    foreach my $key (keys %$template_params) {
        $escaped_tparams{$key} = uri_escape $template_params->{$key};
    }

    $uri = named_sprintf($uri, %escaped_tparams);

    return $uri;
}

# error handling
sub error {
    my ($self, $error) = @_;

    croak($error);
}

=back

=cut

1;
