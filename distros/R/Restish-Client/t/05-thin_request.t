use strict;
use warnings;

use Test::More;
use Test::Exception;
use HTTP::Request;
use HTTP::Response;
use URI;

use Test::Mock::LWP::Dispatch;

use Restish::Client;

# Each request is recorded here so its method, uri, headers and body can be
# inspected after the call
my $last_req;

# Response returned by the mock; tests change these as needed
my ($code, $content_type, $body);

$mock_ua->map(qr{^https://api\.example\.com/}, sub {
    $last_req = shift;
    my $h = HTTP::Headers->new;
    $h->header('Content-Type' => $content_type) if defined $content_type;
    return HTTP::Response->new($code, 'msg', $h, $body);
});

sub respond { ($code, $content_type, $body) = @_ }

# Decode a form-urlencoded request body into a hashref
sub form_of {
    my $u = URI->new('http:');
    $u->query($_[0]->content);
    return { $u->query_form };
}

my $client = Restish::Client->new(uri_host => 'https://api.example.com/');

# POST with form data, the form used in production
{
    respond(200, 'application/json', '{"token":"abc"}');

    my $res = $client->thin_request('POST', "public/auth", undef,
        { user => 'bob', pass => 's3cret' });

    is( $last_req->method, 'POST', 'POST form: method' );
    is( $last_req->uri, 'https://api.example.com/public/auth',
        'POST form: uri has no query string' );
    is( $last_req->header('Content-Type'), 'application/x-www-form-urlencoded',
        'POST form: form-urlencoded content type' );
    is_deeply( form_of($last_req), { user => 'bob', pass => 's3cret' },
        'POST form: fields sent in the body' );
    is( $last_req->header('Accept'), 'application/json',
        'POST form: default Accept header sent' );
    is_deeply( $res, { token => 'abc' }, 'POST form: JSON response decoded' );
}

{
    respond(200, 'application/json', '{"ok":1}');

    my $res = $client->thin_request('POST', 'edit_serverinfo', undef,
        { server => 'web1', key => 'os', value => 'linux' });

    is( $last_req->uri, 'https://api.example.com/edit_serverinfo',
        'POST form: uri' );
    is_deeply( form_of($last_req), { server => 'web1', key => 'os', value => 'linux' },
        'POST form: three fields sent in the body' );
    is_deeply( $res, { ok => 1 }, 'POST form: JSON response decoded' );
}

{
    respond(200, 'text/plain', 'test login');

    my $res = $client->thin_request('POST', "echo", undef, { data => "test login" });

    is_deeply( form_of($last_req), { data => 'test login' },
        'POST form: value with a space is encoded' );
    is( $res, 'test login', 'POST form: non-JSON response returned as text' );
}

{
    respond(200, 'application/json; charset=utf-8', '{"cleared":true}');

    my $res = $client->thin_request('POST', 'clear_sssd_cache', undef, { server => 'web1' });

    ok( $res->{cleared}, 'POST form: JSON with charset parameter decoded' );
}

# Failure and edge cases
{
    respond(403, 'application/json', '{"error":"denied"}');

    my $res = $client->thin_request('POST', "public/auth", undef,
        { user => 'bob', pass => 'wrong' });

    is( $res, 0, 'Failed request returns 0' );
    is( $client->response_code, 403, 'Failed request response code' );
    is( $client->response_body, '{"error":"denied"}', 'Failed request response body' );
}

{
    respond(200, 'application/json', 'not json');

    is( $client->thin_request('POST', 'echo', undef, { data => 1 }), 0,
        'Invalid JSON with a JSON content type returns 0' );
}

{
    respond(200, undef, '');

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $res = $client->thin_request('POST', 'echo', undef);

    is( $res, '', 'Empty successful response returns the empty body' );
    is( scalar @warnings, 0, 'No warnings when the response has no Content-Type' );
    is( $last_req->header('Content-Length'), 0, 'POST without data sends Content-Length 0' );
}

# Query parameters and headers
{
    respond(200, 'application/json', '[1,2]');

    my $res = $client->thin_request('GET', 'servers', { status => 'active' });

    is( $last_req->method, 'GET', 'GET: method' );
    is( $last_req->uri, 'https://api.example.com/servers?status=active',
        'GET: query params in uri' );
    is_deeply( $res, [1, 2], 'GET: JSON array response decoded' );
}

{
    respond(200, 'text/plain', 'ok');

    $client->thin_request('GET', 'servers', undef, 'X-Request-Id' => 'abc123');

    is( $last_req->header('X-Request-Id'), 'abc123', 'GET: extra args sent as headers' );
}

{
    respond(200, 'text/plain', 'ok');

    $client->thin_request('PUT', 'servers/web1', undef, { status => 'down' });

    is( $last_req->method, 'PUT', 'PUT: method' );
    is_deeply( form_of($last_req), { status => 'down' }, 'PUT: form fields sent in the body' );
}

# Invalid methods
dies_ok { $client->thin_request('LIST', 'servers') } 'LIST is not supported';
dies_ok { $client->thin_request('FOO', 'servers') } 'Unknown method dies';

done_testing();
