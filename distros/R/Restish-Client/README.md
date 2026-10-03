# NAME

Restish::Client - A lightweight client for JSON REST APIs

# VERSION

Version 1.10

# SYNOPSIS

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

# DESCRIPTION

**Restish::Client** wraps [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) for APIs that speak JSON over HTTP.
Give it a base URL once, then make requests with relative paths. Request
bodies are encoded as JSON, JSON responses are decoded into Perl data, and the
last response is kept so you can inspect its status, headers and body.

- Path templates with automatic escaping: `users/%(id)s`
- Query strings built from a hashref
- Default headers sent with every request
- Optional cookie jar, in memory or saved to disk
- Form-encoded requests through ["thin\_request"](#thin_request)

# CONSTRUCTOR

## new

    my $client = Restish::Client->new(%options);

- `uri_host` _(required)_

    Base URL for every request. Must start with `http://` or `https://`.
    It cannot be changed later; create a new client for a different host.

- `head_params_default`

    Hashref of headers to send with every request. See ["head\_params\_default"](#head_params_default).

- `ssl_opts`

    Hashref of SSL options for the user agent. See ["ssl\_opts"](#ssl_opts).

- `cookie_jar`

    `1` to keep cookies in memory, or a file path to save them. See ["cookie\_jar"](#cookie_jar).

- `agent_options`

    Hashref of extra options for ["new" in LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent#new), such as `timeout`. The
    `agent` string defaults to `Restish::Client/VERSION`. The client sets
    `default_headers`, `ssl_opts` and `env_proxy` itself, so use its own
    options for those.

- `require_https`

    If `1`, `new` dies unless `uri_host` is an `https://` URL. Defaults to `0`.

- `debug`

    Print each request and response to STDERR. See ["debug"](#debug).

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

Proxy settings are always read from the environment (`https_proxy`,
`no_proxy` and so on).

# MAKING REQUESTS

## request

    my $data = $client->request(
        method          => 'POST',
        uri             => 'users/%(id)s/keys',
        template_params => { id => 42 },
        query_params    => { notify => 1 },
        body_params     => { key => $public_key },
        head_params     => { 'X-Request-Id' => $request_id },
    );

Send a request and return the response data.

- `method` _(required)_

    `GET`, `POST`, `PUT`, `PATCH`, `DELETE` or `LIST`.

- `uri` _(required)_

    Path relative to `uri_host`. The leading `/` is optional. The path is used
    as given, so put any values that need escaping in `template_params`.

- `template_params`

    Hashref of values for the `%(name)s` placeholders in `uri`. Each value is
    URI-escaped before it is inserted.

- `query_params`

    Hashref of query string parameters. Keys and values are escaped.

- `body_params`

    Data to send as a JSON body. Sets `Content-Type: application/json`.

- `raw_body`

    A body to send unchanged, such as file contents. Set `content_type` with it.

- `content_type`

    Value for the `Content-Type` header.

- `head_params`

    Hashref of headers for this request only. They override any header of the
    same name in ["head\_params\_default"](#head_params_default).

An unknown argument name is fatal, so a typo such as `query_param` fails
loudly instead of sending an unfiltered request.

**Returns:**

- the decoded data, if the body starts with `{` or `[`
- the body as a string, if it is anything else
- `1`, if the body is empty or false
- `0`, if the status is not 2xx (including connection errors, which
LWP reports as status 500)

Invalid JSON in a successful response is fatal. Because a successful request
can return a false value, check ["is\_success"](#is_success) when you need to be certain.

Uploading a file:

    $client->POST(
        uri          => 'uploads',
        query_params => { filename => 'report.pdf' },
        raw_body     => $pdf_data,
        content_type => 'application/pdf',
    );

## GET, POST, PUT, PATCH, DELETE, LIST

    my $user = $client->GET( uri => 'users/42' );

    $client->PUT(
        uri         => 'users/42',
        body_params => { name => 'Bob' },
    );

Shortcuts for ["request"](#request) with `method` already set. They take the same
arguments. `LIST` is a non-standard method used by some APIs, such as
HashiCorp Vault.

## thin\_request

    my $res = $client->thin_request($method, $uri, \%query, @lwp_args);

Send a request through the matching [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) method (`get`, `post`,
`put`, `patch` or `delete`). Use it for endpoints that take form-encoded
bodies instead of JSON.

- `$method`

    `GET`, `POST`, `PUT`, `PATCH` or `DELETE`. `LIST` is not supported.

- `$uri`

    Path relative to `uri_host`, as for ["request"](#request).

- `\%query`

    Hashref (or arrayref of pairs) for the query string, or `undef` for none.
    **This argument is positional**: pass `undef` when you have form data but
    no query parameters.

- `@lwp_args`

    Passed unchanged to LWP::UserAgent. For `POST`, `PUT` and `PATCH`, an
    optional hashref of form fields followed by any header pairs. For `GET` and
    `DELETE`, header pairs only; these cannot send a body.

**Returns** the decoded data if the response has a JSON `Content-Type`,
otherwise the body as a string. Returns `0` if the request failed or the JSON
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

# INSPECTING THE RESPONSE

The client keeps the response from the most recent request. Each method
below returns `undef` until a request has been made.

## is\_success

    if ($client->is_success) { ... }

True if the last response had a 2xx status.

## response\_code

    my $status = $client->response_code;    # e.g. 404

The HTTP status code of the last response.

## response\_header

    my $type = $client->response_header('Content-Type');

The value of one header from the last response.

## response\_body

    warn "Error: ", $client->response_body unless $client->is_success;

The body of the last response as a decoded string. Useful for error details,
since a failed ["request"](#request) returns only `0`.

# ATTRIBUTES

Each attribute can be passed to ["new"](#new) or changed later through its
accessor. A change applies from the next request on.

## head\_params\_default

    $client->head_params_default({ 'X-Vault-Token' => $token });

Hashref of headers sent with every request. Setting it replaces the whole
set. `Accept: application/json` is also sent, unless this hashref sets
`Accept` itself.

## ssl\_opts

    $client->ssl_opts({ SSL_ca_file => '/etc/ssl/certs/internal-ca.pem' });

Hashref passed to ["ssl\_opts" in LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent#ssl_opts), such as a CA file or a client
certificate.

## cookie\_jar

    $client->cookie_jar(1);                        # in memory
    $client->cookie_jar('/var/tmp/cookies.txt');   # saved to a file

Keep cookies between requests. With a file path, cookies (including session
cookies) are loaded from and saved to that file. The jar is created on the
first request, so set this before making any.

## debug

    $client->debug({});                      # print everything
    $client->debug({ trim_tokens => 1 });    # leave tokens out
    $client->debug(undef);                   # off (the default)

When set to a hashref, ["request"](#request) prints the agent's default headers, the
request and the response to STDERR. With `trim_tokens`, the
`X-Auth-Token`, `X-Subject-Token` and `X-Vault-Token` headers are left out.
["thin\_request"](#thin_request) prints nothing.

# ERRORS

Invalid arguments are fatal: a missing `uri_host` or `uri`, an unknown
method or argument name, a non-hashref where a hashref is expected, or a path
that does not form a valid URL. The client throws these with ["croak" in Carp](https://metacpan.org/pod/Carp#croak).

An HTTP error is _not_ fatal. ["request"](#request) and ["thin\_request"](#thin_request) return `0`,
and the response methods tell you what went wrong.

# SUBCLASSING

Restish::Client is a [Moo](https://metacpan.org/pod/Moo) class, so subclasses can use `extends` and
method modifiers.

## error

    sub error {
        my ($self, $message) = @_;
        My::Exception->throw($message);
    }

Called with the message for each error raised while making a request. The
default croaks. Errors from constructor and attribute validation always croak.

## \_get\_agent

    package My::Client;
    use Moo;
    extends 'Restish::Client';

    around _get_agent => sub {
        my ($orig, $self) = @_;
        my $ua = $self->$orig;
        $ua->agent('My::Client/1.0');
        return $ua;
    };

Returns the [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) for a request. A new agent is built for each
request from the client's attributes. Wrap it to add handlers or change
settings.

# TESTING

Set `$Restish::Client::CANONICAL` to `1` to encode `body_params` with
sorted keys, so request bodies can be compared as strings in tests.

# SEE ALSO

[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent), [HTTP::Request::Common](https://metacpan.org/pod/HTTP%3A%3ARequest%3A%3ACommon), [Text::Sprintf::Named](https://metacpan.org/pod/Text%3A%3ASprintf%3A%3ANamed), [Moo](https://metacpan.org/pod/Moo)

# BUGS

Please report bugs at
[https://github.com/thend20/perl-restish-client/issues](https://github.com/thend20/perl-restish-client/issues).

# AUTHOR

Tim H <thend20@pair.com>

# LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 3, as published by
the Free Software Foundation. See the `LICENSE` file distributed with it, or
[https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html).
