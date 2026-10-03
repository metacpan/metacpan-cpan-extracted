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

our $VERSION = '1.10';

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

has head_params_default => (
    is      => 'rw',
    default => sub { {} },
    isa     => sub { 
            __PACKAGE__->error("Invalid parameter $_[0]; supply a hashref")
                unless ref $_[0] eq 'HASH'
           }
);

has ssl_opts => (
    is      => 'rw',
    default => sub { {} },
    isa     => sub { 
            __PACKAGE__->error("Invalid parameter $_[0]; supply a hashref")
                unless ref $_[0] eq 'HASH'
           }
);

has cookie_jar => (
    is      => 'rw',
    default => undef,
);

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
sub PUT {
    my ($self, %params) = @_;
    $params{method} = 'PUT';
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

sub thin_request {
    my ($self, $method, $uri, $query_params, @lwp_args) = @_;

    $self->error("Invalid method for thin_request: $method")
        unless $VALID_METHOD{$method} && $method ne 'LIST';

    my $lwp_method = lc $method;
    my $res = $self->_get_agent->$lwp_method(
        $self->_assemble_uri($uri, $query_params), @lwp_args);

    $self->_set__response($res);

    # request failed
    return 0 unless $res->is_success;

    my $content = $res->decoded_content;

    # request succeeded, but content could not be decoded
    return 1 unless defined $content;

    if (($res->header('Content-Type') || '') =~ m{^application/json\b}i) {
        return eval { decode_json $content } || 0;
    }

    return $content;
}

sub is_success {
    my ($self) = @_;
    return $self->_response->is_success
        if defined $self->_response;
    return undef;
}

sub response_code {
    my ($self) = @_;
    return $self->_response->code
        if defined $self->_response;
    return undef;
}

sub response_header {
    my ($self, $desired_header) = @_;
    return $self->_response->header($desired_header)
        if defined $self->_response;
    return undef;
}

sub response_body {
    my ($self) = @_;
    return $self->_response->decoded_content
        if defined $self->_response;
    return undef;
}

has debug => (
    is => 'rw',
    default => sub { undef }
);

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

# _get_agent()
# Returns a new LWP::UserAgent built from the client attributes. Documented
# for subclasses under SUBCLASSING.
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

1;

__END__

=pod

=encoding utf8

=head1 NAME

Restish::Client - A lightweight client for JSON REST APIs

=head1 VERSION

Version 1.10

=head1 SYNOPSIS

    use Restish::Client;

    my $client = Restish::Client->new(
        uri_host            => 'https://api.example.com/v1/',
        head_params_default => { Authorization => "Bearer $token" },
    );

    # GET /v1/users?status=active
    my $users = $client->GET(
        uri          => 'users',
        query_params => { status => 'active' },
    );

    # POST a JSON body
    my $user = $client->POST(
        uri         => 'users',
        body_params => { name => 'Alice', email => 'alice@example.com' },
    );

    # DELETE /v1/users/42, with the id escaped into the path
    $client->DELETE(
        uri             => 'users/%(id)s',
        template_params => { id => $user->{id} },
    );

    die sprintf "Request failed (%s): %s\n",
        $client->response_code, $client->response_body
        unless $client->is_success;

=head1 DESCRIPTION

B<Restish::Client> wraps L<LWP::UserAgent> for APIs that speak JSON over HTTP.
Give it a base URL once, then make requests with relative paths. Request
bodies are encoded as JSON, JSON responses are decoded into Perl data, and the
last response is kept so you can inspect its status, headers and body.

=over 4

=item * Path templates with automatic escaping: C<users/%(id)s>

=item * Query strings built from a hashref

=item * Default headers sent with every request

=item * Optional cookie jar, in memory or saved to disk

=item * Form-encoded requests through L</thin_request>

=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Restish::Client->new(%options);

=over 4

=item C<uri_host> I<(required)>

Base URL for every request. Must start with C<http://> or C<https://>.
It cannot be changed later; create a new client for a different host.

=item C<head_params_default>

Hashref of headers to send with every request. See L</head_params_default>.

=item C<ssl_opts>

Hashref of SSL options for the user agent. See L</ssl_opts>.

=item C<cookie_jar>

C<1> to keep cookies in memory, or a file path to save them. See L</cookie_jar>.

=item C<agent_options>

Hashref of extra options for L<LWP::UserAgent/new>, such as C<timeout>. The
C<agent> string defaults to C<Restish::Client/VERSION>. The client sets
C<default_headers>, C<ssl_opts> and C<env_proxy> itself, so use its own
options for those.

=item C<require_https>

If C<1>, C<new> dies unless C<uri_host> is an C<https://> URL. Defaults to C<0>.

=item C<debug>

Print each request and response to STDERR. See L</debug>.

=back

A client using a Vault token and a client certificate:

    my $client = Restish::Client->new(
        uri_host            => 'https://vault.example.com/',
        head_params_default => { 'X-Vault-Token' => $token },
        require_https       => 1,
        agent_options       => { timeout => 10 },
        ssl_opts            => {
            SSL_cert_file => '/etc/ssl/certs/client.pem',
            SSL_key_file  => '/etc/ssl/private/client.key',
        },
    );

Proxy settings are always read from the environment (C<https_proxy>,
C<no_proxy> and so on).

=head1 MAKING REQUESTS

=head2 request

    my $data = $client->request(
        method          => 'POST',
        uri             => 'users/%(id)s/keys',
        template_params => { id => 42 },
        query_params    => { notify => 1 },
        body_params     => { key => $public_key },
        head_params     => { 'X-Request-Id' => $request_id },
    );

Send a request and return the response data.

=over 4

=item C<method> I<(required)>

C<GET>, C<POST>, C<PUT>, C<PATCH>, C<DELETE> or C<LIST>.

=item C<uri> I<(required)>

Path relative to C<uri_host>. The leading C</> is optional. The path is used
as given, so put any values that need escaping in C<template_params>.

=item C<template_params>

Hashref of values for the C<%(name)s> placeholders in C<uri>. Each value is
URI-escaped before it is inserted.

=item C<query_params>

Hashref of query string parameters. Keys and values are escaped.

=item C<body_params>

Data to send as a JSON body. Sets C<Content-Type: application/json>.

=item C<raw_body>

A body to send unchanged, such as file contents. Set C<content_type> with it.

=item C<content_type>

Value for the C<Content-Type> header.

=item C<head_params>

Hashref of headers for this request only. They override any header of the
same name in L</head_params_default>.

=back

An unknown argument name is fatal, so a typo such as C<query_param> fails
loudly instead of sending an unfiltered request.

B<Returns:>

=over 4

=item * the decoded data, if the body starts with C<{> or C<[>

=item * the body as a string, if it is anything else

=item * C<1>, if the body is empty or false

=item * C<0>, if the status is not 2xx (including connection errors, which
LWP reports as status 500)

=back

Invalid JSON in a successful response is fatal. Because a successful request
can return a false value, check L</is_success> when you need to be certain.

Uploading a file:

    $client->POST(
        uri          => 'uploads',
        query_params => { filename => 'report.pdf' },
        raw_body     => $pdf_data,
        content_type => 'application/pdf',
    );

=head2 GET, POST, PUT, PATCH, DELETE, LIST

    my $user = $client->GET( uri => 'users/42' );

    $client->PUT(
        uri         => 'users/42',
        body_params => { name => 'Bob' },
    );

Shortcuts for L</request> with C<method> already set. They take the same
arguments. C<LIST> is a non-standard method used by some APIs, such as
HashiCorp Vault.

=head2 thin_request

    my $res = $client->thin_request($method, $uri, \%query, @lwp_args);

Send a request through the matching L<LWP::UserAgent> method (C<get>, C<post>,
C<put>, C<patch> or C<delete>). Use it for endpoints that take form-encoded
bodies instead of JSON.

=over 4

=item C<$method>

C<GET>, C<POST>, C<PUT>, C<PATCH> or C<DELETE>. C<LIST> is not supported.

=item C<$uri>

Path relative to C<uri_host>, as for L</request>.

=item C<\%query>

Hashref (or arrayref of pairs) for the query string, or C<undef> for none.
B<This argument is positional>: pass C<undef> when you have form data but
no query parameters.

=item C<@lwp_args>

Passed unchanged to LWP::UserAgent. For C<POST>, C<PUT> and C<PATCH>, an
optional hashref of form fields followed by any header pairs. For C<GET> and
C<DELETE>, header pairs only; these cannot send a body.

=back

B<Returns> the decoded data if the response has a JSON C<Content-Type>,
otherwise the body as a string. Returns C<0> if the request failed or the JSON
could not be decoded.

    # POST form fields
    my $res = $client->thin_request('POST', 'public/auth', undef,
        { user => $user, pass => $pass });

    # GET /servers?status=active
    my $servers = $client->thin_request('GET', 'servers',
        { status => 'active' });

    # GET with an extra header
    my $res = $client->thin_request('GET', 'servers', undef,
        'X-Request-Id' => $id);

    # PUT /servers/web1?notify=1 with form fields
    $client->thin_request('PUT', 'servers/web1', { notify => 1 },
        { status => 'down' });

=head1 INSPECTING THE RESPONSE

The client keeps the response from the most recent request. Each method
below returns C<undef> until a request has been made.

=head2 is_success

    if ($client->is_success) { ... }

True if the last response had a 2xx status.

=head2 response_code

    my $status = $client->response_code;    # e.g. 404

The HTTP status code of the last response.

=head2 response_header

    my $type = $client->response_header('Content-Type');

The value of one header from the last response.

=head2 response_body

    warn "Error: ", $client->response_body unless $client->is_success;

The body of the last response as a decoded string. Useful for error details,
since a failed L</request> returns only C<0>.

=head1 ATTRIBUTES

Each attribute can be passed to L</new> or changed later through its
accessor. A change applies from the next request on.

=head2 head_params_default

    $client->head_params_default({ 'X-Vault-Token' => $token });

Hashref of headers sent with every request. Setting it replaces the whole
set. C<Accept: application/json> is also sent, unless this hashref sets
C<Accept> itself.

=head2 ssl_opts

    $client->ssl_opts({ SSL_ca_file => '/etc/ssl/certs/internal-ca.pem' });

Hashref passed to L<LWP::UserAgent/ssl_opts>, such as a CA file or a client
certificate.

=head2 cookie_jar

    $client->cookie_jar(1);                        # in memory
    $client->cookie_jar('/var/tmp/cookies.txt');   # saved to a file

Keep cookies between requests. With a file path, cookies (including session
cookies) are loaded from and saved to that file. The jar is created on the
first request, so set this before making any.

=head2 debug

    $client->debug({});                      # print everything
    $client->debug({ trim_tokens => 1 });    # leave tokens out
    $client->debug(undef);                   # off (the default)

When set to a hashref, L</request> prints the agent's default headers, the
request and the response to STDERR. With C<trim_tokens>, the
C<X-Auth-Token>, C<X-Subject-Token> and C<X-Vault-Token> headers are left out.
L</thin_request> prints nothing.

=head1 ERRORS

Invalid arguments are fatal: a missing C<uri_host> or C<uri>, an unknown
method or argument name, a non-hashref where a hashref is expected, or a path
that does not form a valid URL. The client throws these with L<Carp/croak>.

An HTTP error is I<not> fatal. L</request> and L</thin_request> return C<0>,
and the response methods tell you what went wrong.

=head1 SUBCLASSING

Restish::Client is a L<Moo> class, so subclasses can use C<extends> and
method modifiers.

=head2 error

    sub error {
        my ($self, $message) = @_;
        My::Exception->throw($message);
    }

Called with the message for each error raised while making a request. The
default croaks. Errors from constructor and attribute validation always croak.

=head2 _get_agent

    package My::Client;
    use Moo;
    extends 'Restish::Client';

    around _get_agent => sub {
        my ($orig, $self) = @_;
        my $ua = $self->$orig;
        $ua->agent('My::Client/1.0');
        return $ua;
    };

Returns the L<LWP::UserAgent> for a request. A new agent is built for each
request from the client's attributes. Wrap it to add handlers or change
settings.

=head1 TESTING

Set C<$Restish::Client::CANONICAL> to C<1> to encode C<body_params> with
sorted keys, so request bodies can be compared as strings in tests.

=head1 SEE ALSO

L<LWP::UserAgent>, L<HTTP::Request::Common>, L<Text::Sprintf::Named>, L<Moo>

=head1 BUGS

Please report bugs at
L<https://github.com/thend20/perl-restish-client/issues>.

=head1 AUTHOR

Tim H E<lt>thend20@pair.comE<gt>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 3, as published by
the Free Software Foundation. See the F<LICENSE> file distributed with it, or
L<https://www.gnu.org/licenses/gpl-3.0.html>.

=cut
