# $Id$

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use HTTP::Request;
use HTTP::Response;
use JSON;

# use this until _get_agent behavior is worked out
# and we can subclass it. once that's done, switch
# to using Test::LWP::UserAgent as it avoids bugs that
# can occur when MockObject overrides ISA
use Test::Mock::LWP::Dispatch;

use Restish::Client;

# uri as string
{
$mock_ua->map(
    'https://ident.os.example.com/v3/string_path',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
    method      => 'GET',
    uri         => '/v3/string_path',
    );

ok($res, 'Received resource from request');

is( $client->response_code,
    '200',
    'String URI' );
}

# uri_host with interpolation
{
$mock_ua->map(
    'https://compute.os.example.com/v2/cde381ab/bl%20ah',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://compute.os.example.com/v2/%(tenant_id)s/%(other)s');

my $res = $client->request(
    method          => 'GET',
    uri             => '',
    template_params => { tenant_id => 'cde381ab', other => 'bl ah' }
    );

ok($res, 'Received resource from request; uri_host with interpolation');

is( $client->response_code,
    '200',
    'uri_host with interpolation' );
}

# uri_host with invalid interpolation type
{
$mock_ua->map(
    'https://compute.os.example.com/v2/cde381ab/bl%20ah',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://compute.os.example.com/v2/%(tenant_id)s/%(other)s');

throws_ok( sub { $client->request(
        method          => 'GET',
        uri             => '',
        template_params => [ tenant_id => 'cde381ab', other => 'bl ah' ])
    },
    qr/hashref/,
    'invalid interpolation type'
);
}

# uri_host with malformed interpolation
{
$mock_ua->map(
    'https://compute.os.example.com/v2/cde381ab/bl%20ah',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://compute.os.example.com/v2/%(tenant_id)s/%(other)');

throws_ok( sub { $client->request(
        method          => 'GET',
        uri             => '',
        template_params => { tenant_id => 'cde381ab', other => 'bl ah' })
    },
    qr/does not form a valid uri/,
    'malformed interpolation yields invalid uri'
);
}

# uri as string, with interpolation
{
$mock_ua->map(
    'https://compute.os.example.com/v2/cde381ab/bl%20ah',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://compute.os.example.com/v2');

my $res = $client->request(
    method          => 'GET',
    uri             => '/%(tenant_id)s/%(other)s',
    template_params => { tenant_id => 'cde381ab', other => 'bl ah' }
    );

ok($res, 'Received resource from request; string uri with interpolation');

is( $client->response_code,
    '200',
    'String uri with interpolation' );
}

# joined uri is invalid uri
{
$mock_ua->map(
    'https://ident.os.example.com/v3/string_path',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

throws_ok( sub { $client->request(
    method      => 'GET',
    uri         => 'eeeee/\e')},
    qr/does not form a valid uri/,
    'joined uri is an invalid uri' );
}

# uri must be scalar
{
$mock_ua->map(
    'https://ident.os.example.com/v3/string_path',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

throws_ok( sub {
             $client->request(
             method      => 'GET',
             uri         => { path => '/v3/string_path' })},
             qr/Invalid/,
             'must be a string');
}

# test merging uri slashes
{
$mock_ua->map(
    'https://ident.os.example.com/v3/slash',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com/');

my $res = $client->request(
            method      => 'GET',
            uri         => '/v3/slash' 
);

is( $client->response_code,
    200,
    'test merging uri slashes' );
}

# test merging uri with no slashes
{
$mock_ua->map(
    'https://ident.os.example.com/v3/noslash',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
            method      => 'GET',
            uri         => 'v3/noslash' 
);

is( $client->response_code,
    200,
    'test merging no slashes' );
}

# test merging uri that is only a slash with uri_host ending in slash
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com/v3/');

# mock_ua will match with or without /, so just check method return val
is( $client->_assemble_uri('/'),
    'https://ident.os.example.com/v3/',
    'test merging uri that is only a slash with uri_host ending in slash' );
}

done_testing();
