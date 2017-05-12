#!/usr/bin/env perl

use strict;

use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use HTTP::Request;
use Mock::Apache;
use Apache::Constants qw(:common :http);
use Readonly;

# set to 0 (no debug), 1 (methods traced), 2 (methods and callers traced)
Readonly our $DEBUG_LEVEL   => 0;

Readonly our $TEST_HOST     => 'example.com';
Readonly our $TEST_URI      => 'xyzzy/index.html';

Readonly our $TEST_CONTENT  => "hello mock apache\n";
Readonly our $CONTENT_TYPE  => 'text/plain';

diag "testing simple request handling";

my $start_time = time;

my $http_request = HTTP::Request->new('GET' => "http://$TEST_HOST/$TEST_URI");

my $mock_apache  = Mock::Apache->setup_server(server_hostname => $TEST_HOST, DEBUG => $DEBUG_LEVEL);
my $mock_client = $mock_apache->mock_client();
my $request     = $mock_client->new_request($http_request);

my $server = $request->server;
is($server, $Apache::server, '$r->server gives mock server object');
is($server->server_hostname, $TEST_HOST,              '$s->server_hostname');
is($server->server_admin,    "webmaster\@$TEST_HOST", '$s->server_admin');

is($request->uri, $TEST_URI, '$r->uri');

cmp_ok($request->request_time, '>=', $start_time, 'request time is sane (lower bound)');
cmp_ok($request->request_time, '<=', time,        'request time is sane (upper bound)');

my $response = $mock_apache->execute_handler(\&handler, $request);

my $resp_headers = $response->headers;

is($response->code, HTTP_OK,                             'response status code');
is($resp_headers->content_type,   $CONTENT_TYPE,         'response content-type header');
is($resp_headers->content_length, length($TEST_CONTENT), 'response content-length header');
is($response->content,            $TEST_CONTENT,         'response content');

done_testing();


sub handler {
    my $r = shift;

    $r->content_type($CONTENT_TYPE);
    print $TEST_CONTENT;
    return OK;
}
