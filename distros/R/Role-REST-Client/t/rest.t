use Test::More;
use Test::Deep;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Request;
use utf8;

{
	package RESTExample;

	use Moo;
	with 'Role::REST::Client';

	sub bar {
		my ($self) = @_;
		return $self->post('/foo/bar/baz', {foo => 'bar'});
        }

        sub baz {
		my ($self) = @_;
		return $self->post('/foo/bar/baz', {foo => 'bar', bar => 'baz' });
        }
}
{
  package UAClass;

  use Moo;
  use JSON;
  use Test::More;
  has 'timeout' => ( is => 'ro');
  sub request {
    my ( $self, $method, $uri, $opts ) = @_;
    ok(!ref($opts->{'content'}), 'content key must be a scalar value due content-type');
    if ( lc $method eq 'post' ) {
      like($opts->{'content'}, qr{foo\=bar}, 'no serialization should happen');
    }
    my $req = HTTP::Request->new($method => $uri);
    my $json = encode_json({ error => 'Resource not found' });
    my $headers = HTTP::Headers->new('Content-Type' => 'application/json');
    my $res = HTTP::Response->new(404, 'Not Found', $headers, $json);
    $res->request($req);
    return $res;
  }
}

my $ua = UAClass->new(timeout => 5);
my $persistent_headers = { 'Accept' => 'application/json' };
my %testdata = (
	server => 'http://localhost:3000',
	type => 'application/x-www-form-urlencoded',
	user_agent => $ua,
        persistent_headers => $persistent_headers,
);
{
    ok(my $client = RESTExample->new({
	        server => 'http://localhost:3000',
	        type => 'application/json',
        }), 'New object');
    is($client->has_no_headers, 1, 'client has no headers');
    #is_deeply($client->httpheaders, {}, 'client has no headers');
    $client->set_persistent_header('X-Test' => 'foo' );
    is_deeply($client->httpheaders, { 'X-Test' => 'foo' },
        'should have at least persistent_headers');

}
ok(my $obj = RESTExample->new(%testdata), 'New object');
isa_ok($obj, 'RESTExample');

for my $item (qw/post get put delete _call httpheaders/) {
    ok($obj->can($item), "Role method $item exists");
}

is_deeply($obj->httpheaders, $persistent_headers, 'headers should include persistent ones since first request');
ok(my $res = $obj->bar, 'got a response object');
is_deeply($obj->httpheaders, $persistent_headers, 'after first request, it contains persistent ones');
isa_ok($res, 'Role::REST::Client::Response');
isa_ok($res->response, 'HTTP::Response');
is($res->code, 404, 'Resource not found');

$obj->set_header('X-Foo', 'foo');
is_deeply($obj->httpheaders, {
  %$persistent_headers,
  'X-Foo', 'foo',
});

$obj->reset_headers;
is_deeply($obj->httpheaders, $persistent_headers,
  'should have at least persistent_headers');

ok(!exists($obj->persistent_headers->{'X-Foo'}));
ok($res = $obj->bar, 'got a response obj');
ok(!exists($obj->persistent_headers->{'content-length'}));
ok($res = $obj->baz, 'got a response obj');
ok(!exists($obj->persistent_headers->{'content-length'}));

$obj->clear_all_headers;
is_deeply($obj->httpheaders, {}, 'All headers are cleared, even the persistent ones');

my $newheaders = { 'X-Foo' => 'foo', 'Accept' => 'application/yaml' };
ok($obj = RESTExample->new({ %testdata, httpheaders => $newheaders }));
is_deeply($obj->httpheaders, {
  %$persistent_headers,
  %$newheaders,
}, 'merge httpheaders with persistent_headers');
ok($res = $obj->bar, 'got a response object');
is_deeply($obj->httpheaders, $persistent_headers,
  'after first request, it contains persistent ones');

ok($res = $obj->get('/getendpoint', { param => 'büz' }));
like($res->response->request->uri, qr{param=b%C3%BCz});

done_testing;
