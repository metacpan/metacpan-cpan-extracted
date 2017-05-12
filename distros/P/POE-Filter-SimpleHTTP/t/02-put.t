use warnings;
use strict;

use Test::More('tests', 23);
use HTTP::Status(':constants');
use HTTP::Request;
use HTTP::Response;

BEGIN
{
    use_ok('POE::Filter::SimpleHTTP');
    use_ok('POE::Filter::SimpleHTTP::Regex');
    use_ok('POE::Filter::SimpleHTTP::Error');
}

$POE::Filter::SimpleHTTP::DEBUG = 0;

my $request = HTTP::Request->new();
$request->method('POST');
$request->uri('/index.html');
$request->user_agent('TEST/0.1');
$request->add_content($_) for qw|name=foo&value=123 bar=321&baz=yarg|;

my $response = HTTP::Response->new();
$response->code(+HTTP_OK);
$response->content_type('text/html');
$response->server('TESTSERVER/0.1');
$response->add_content($_) for qw|<html><body><p>H I</p></body></html>|;

my $filter = POE::Filter::SimpleHTTP->new();
isa_ok($filter, 'POE::Filter');
isa_ok($filter, 'Moose::Object');
isa_ok($filter, 'POE::Filter::SimpleHTTP');

$filter->method('POST');
is($filter->method(), 'POST', 'Filter accessor: method');

$filter->uri('/index.html');
is($filter->uri(), '/index.html', 'Filter accessor: uri');

$filter->useragent('TEST/0.1');
is($filter->useragent(), 'TEST/0.1', 'Filter accessor: useragent');

my $req1 = $filter->put([$request])->[0];
is_deeply($req1, $request, 'Passthrough of Request');

my $req2 = $filter->put([qw|name=foo&value=123 bar=321&baz=yarg|])->[0];
is($req2->method(), 'POST', 'Request post-put check 0/4');
is($req2->uri(), '/index.html', 'Request post-put check 1/4');
is($req2->user_agent(), 'TEST/0.1', 'Request post-put check 2/4');
is($req2->content(), 'name=foo&value=123bar=321&baz=yarg', 'Request post-put check 3/4');
is($req2->content_type(), 'text/plain', 'Request post-put check 4/4');

$filter->server('TESTSERVER/0.1');
is($filter->server(), 'TESTSERVER/0.1', 'Filter accessor: server');

$filter->mimetype('text/html');
is($filter->mimetype(), 'text/html', 'Filter accessor: mimetype');

$filter->mode(+PFSH_SERVER);
is($filter->mode(), +PFSH_SERVER, 'Filter access: mode');

my $rep1 = $filter->put([$response])->[0];
is_deeply($rep1, $response, 'Passthrough of Response');

my $rep2 = $filter->put([qw|<html><body><p>H I</p></body></html>|])->[0];
is($rep2->code(), +HTTP_OK, 'Response post-put check 0/3');
is($rep2->content_type(), 'text/html', 'Response post-put check 1/3');
is($rep2->content(), '<html><body><p>HI</p></body></html>', 'Response post-put check 2/3');
is($rep2->server(), 'TESTSERVER/0.1', 'Response post-put check 3/3');
