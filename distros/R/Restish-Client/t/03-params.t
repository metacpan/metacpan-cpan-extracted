# $Id$

use strict;
use warnings;

use Test::More tests => 7;
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
my $NOC_VERSION = $Restish::Client::VERSION;

# Enable canonical JSON encoding for deterministic testing
$Restish::Client::CANONICAL = 1;

# URI Params
{
$mock_ua->map(
    'https://ident.os.example.com/v3/test?param1=value1&param2=value2',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
    method     => 'GET',
    uri => '/v3/test',
    query_params => { param1 => 'value1', param2 => 'value2' }
    );

ok($res, 'Received resource from URI-param GET request');

is_deeply( $res,
           decode_json('{"test":"ok"}'),
           'URI params' );
}

# Invalid URI Params
{
$mock_ua->map(
    'https://ident.os.example.com/v3/test?param1=value1&param2=value2',
    HTTP::Response->new(200, 'OK', HTTP::Headers->new, '{"test":"ok"}'));

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

throws_ok(
    sub {
        $client->request(
            method       => 'POST',
            uri          => '/v3/test',
            query_params => [ 'param1', 'value1', 'param2', 'value2' ]
        )
    },
    qr/must be a hashref/,
    'Invalid URI params');
}

# Head Params
{
$mock_ua->map(
    'https://ident.os.example.com/v3/test/headparams',
    sub {
        my $req = shift;
        return 0 unless $req->header('param1') eq 'value1'
            and $req->header('param2') eq 'value2';
        return HTTP::Response->new(200, 'OK',
            HTTP::Headers->new, '{"test":"ok"}');
    });

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
    method      => 'POST',
    uri         => '/v3/test/headparams',
    head_params => { param1 => 'value1', param2 => 'value2' }
    );

ok($res, 'Received resource from head parameter POST request');

is_deeply( $res,
           decode_json('{"test":"ok"}'),
           'Head params' );
}

# Body params
{
$mock_ua->map(
    'https://ident.os.example.com/v3/test/bodyparams',
    sub {
        my $req = shift;
        die "Incorrect content type" unless $req->header('Content-Type') eq 'application/json';
        die "Incorrect body params" unless $req->content eq
            '{"bparam1":"bvalue1","bparam2":"bvalue2"}';
        return HTTP::Response->new(200, 'OK',
            HTTP::Headers->new, '{"test":"ok"}');
    });

my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

my $res = $client->request(
    method      => 'POST',
    uri         => '/v3/test/bodyparams',
    body_params => { bparam1 => 'bvalue1', bparam2 => 'bvalue2' }
    );

ok($res, 'Received resource from body parameter POST request');

is_deeply( $res,
           decode_json('{"test":"ok"}'),
           'Body params' );
}

done_testing();
