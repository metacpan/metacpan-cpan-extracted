use strict;
use warnings;
use Test2::V0;

use MIME::Base64 qw( decode_base64 );
use Encode qw( decode is_utf8 );
use Future;
use JSON::MaybeXS;

use Net::Async::MCP;
use Net::Async::MCP::Transport::HTTP;

# HTTP::Message reaches this distribution only through Net::Async::HTTP, which
# is a recommendation and not a requirement: without it there is no usable HTTP
# transport, so there is nothing here to test either.
skip_all 'HTTP::Message is required for the HTTP transport tests'
  unless eval { require HTTP::Response; require HTTP::Request; 1 };

# The suite has no MCP server to talk to over HTTP, so these tests drive the
# response handling directly: turning an HTTP response into a Future is where
# the transport makes its decisions, and getting them wrong turns a real
# JSON-RPC error into a misleading transport error.

my $transport = Net::Async::MCP::Transport::HTTP->new(
  url => 'http://mcp.invalid/mcp',
);

sub response {
  my ( $code, $content_type, $body ) = @_;
  return HTTP::Response->new($code, undef,
    [ defined $content_type ? ( 'Content-Type' => $content_type ) : () ], $body);
}

# The HTTP transport holds no connection between requests
{
  ok($transport->is_alive, 'HTTP transport is always alive');
}

# Every POST mirrors the request metadata into headers so an intermediary can
# route without parsing the body. MCP::Server::Transport::HTTP::_check_headers
# compares them against the body and answers -32020 for anything missing or
# diverging, so a wrong value here does not degrade the client, it fails every
# single request.

sub headers {
  my ( $method, $params, @options ) = @_;
  return { $transport->_standard_headers($method, $params, @options) };
}

# The header value the server compares is what comes back out of the sentinel
sub decoded_name {
  my ( $value ) = @_;
  return $value unless $value =~ /^=\?base64\?(.*)\?=$/s;
  return decode('UTF-8', decode_base64($1));
}

{
  my $params = {
    name      => 'get_weather',
    arguments => { city => 'Berlin' },
    _meta     => { 'io.modelcontextprotocol/protocolVersion' => '2026-07-28' },
  };
  my $h = headers('tools/call', $params);

  is($h->{'Content-Type'}, 'application/json', 'the JSON content type survives');
  is($h->{'Accept'}, 'application/json, text/event-stream',
    'both response types are still accepted');
  is($h->{'MCP-Protocol-Version'},
    $params->{_meta}{'io.modelcontextprotocol/protocolVersion'},
    'MCP-Protocol-Version comes from the body _meta, so it cannot diverge');
  is($h->{'Mcp-Method'}, 'tools/call', 'Mcp-Method is the method being called');
  is($h->{'Mcp-Name'}, $params->{name}, 'Mcp-Name is the tool name from the body');
}

# The name lives under a different key per method, and the server compares
# against exactly that key
{
  my $prompt = headers('prompts/get', { name => 'greeting' });
  is($prompt->{'Mcp-Name'}, 'greeting', 'prompts/get takes Mcp-Name from params.name');

  my $resource = headers('resources/read', { uri => 'file:///etc/hosts' });
  is($resource->{'Mcp-Name'}, 'file:///etc/hosts',
    'resources/read takes Mcp-Name from params.uri');
}

# A method without a name parameter gets no Mcp-Name at all - an empty one
# would claim the body said something it did not
{
  my $h = headers('tools/list', {
    _meta => { 'io.modelcontextprotocol/protocolVersion' => '2026-07-28' },
  });
  is($h->{'Mcp-Method'}, 'tools/list', 'Mcp-Method is set for a listing method too');
  ok(!exists $h->{'Mcp-Name'}, 'no Mcp-Name for a method without a name parameter');
}

# Header values are bytes, so anything outside printable ASCII travels base64
# encoded in a sentinel the server knows how to undo
{
  my $name = "Wetter-\x{00dc}bersicht";
  my $h = headers('tools/call', { name => $name });
  is($h->{'Mcp-Name'}, '=?base64?V2V0dGVyLcOcYmVyc2ljaHQ=?=',
    'a non-ASCII tool name is base64 encoded as UTF-8 bytes');
  is(decoded_name($h->{'Mcp-Name'}), $name,
    'and the server decodes it back to the name in the body');
}

{
  my $name = "grep\tfiles";
  my $h = headers('tools/call', { name => $name });
  is($h->{'Mcp-Name'}, '=?base64?Z3JlcAlmaWxlcw==?=',
    'a control character outside [\x20-\x7e] is base64 encoded as well');
  is(decoded_name($h->{'Mcp-Name'}), $name,
    'and decodes back to the name in the body');
}

# A name that already looks like the sentinel has to be encoded too, or the
# server would decode a name the body never contained
{
  my $name = '=?base64?Zm9v?=';
  my $h = headers('tools/call', { name => $name });
  is($h->{'Mcp-Name'}, '=?base64?PT9iYXNlNjQ/Wm05dj89?=',
    'a name shaped like the sentinel is encoded rather than passed through');
  is(decoded_name($h->{'Mcp-Name'}), $name,
    'and decodes back to the literal name, not to its inner value');
}

# send_notification stays public transport API, but this distribution calls it
# nowhere any more: the handshake lost its initialized step, and the Streamable
# HTTP binding of this revision defines no client-to-server notification at all
# (notifications/cancelled, used here as the shape a caller would send, lives
# on stdio). _standard_headers still has to build headers for whatever a caller
# passes, and a notification body carries no _meta, so there is no protocol
# version to mirror - inventing one would be worse than sending none
{
  my $h = headers('notifications/cancelled', { requestId => 7 });
  is($h->{'Mcp-Method'}, 'notifications/cancelled',
    'a notification names its method like any other POST');
  ok(!exists $h->{'MCP-Protocol-Version'},
    'no MCP-Protocol-Version header for a notification body without _meta');

  my $bare = headers('notifications/cancelled', undef);
  is($bare->{'Mcp-Method'}, 'notifications/cancelled',
    'and still does so when called without params at all');
  ok(!exists $bare->{'MCP-Protocol-Version'},
    'no MCP-Protocol-Version header without params to take it from');

  my $no_meta = headers('tools/list', {});
  ok(!exists $no_meta->{'MCP-Protocol-Version'},
    'nor with params that carry no _meta');
  is($no_meta->{'Mcp-Method'}, 'tools/list', 'while Mcp-Method is there either way');
}

# Tool arguments annotated with x-mcp-header travel as Mcp-Param-{Name}. The
# client resolves which ones and what they say; this transport only puts them
# on the wire, through the same sentinel encoding as Mcp-Name, since
# MCP::Server::Transport::HTTP::_check_params decodes both the same way.
{
  my $h = headers('tools/call',
    { name => 'deploy', arguments => { region => 'europe-west1' } },
    header_params => [ { name => 'Region', value => 'europe-west1' } ]);
  is($h->{'Mcp-Param-Region'}, 'europe-west1',
    'an annotated argument becomes Mcp-Param-{Name}');

  my $encoded = headers('tools/call',
    { name => 'deploy', arguments => { region => "Gr\x{00fc}n" } },
    header_params => [ { name => 'Region', value => "Gr\x{00fc}n" } ]);
  is($encoded->{'Mcp-Param-Region'}, '=?base64?R3LDvG4=?=',
    'a param value outside printable ASCII is base64 encoded like a tool name');
  is(decoded_name($encoded->{'Mcp-Param-Region'}), "Gr\x{00fc}n",
    'and the server decodes it back to the value in the body');

  ok(!exists headers('tools/call', { name => 'deploy' })->{'Mcp-Param-Region'},
    'no Mcp-Param header without the client asking for one');
}

# A caller's own headers are the only way an Authorization reaches the server:
# no part of the protocol describes one, so without them a remote MCP server
# behind OAuth cannot be talked to at all.
{
  my $auth = Net::Async::MCP::Transport::HTTP->new(
    url     => 'http://mcp.invalid/mcp',
    headers => {
      Authorization => 'Bearer t0ken',
      'X-Trace-Id'  => 'abc123',
    },
  );

  my $h = { $auth->_standard_headers('tools/list', {
    _meta => { 'io.modelcontextprotocol/protocolVersion' => '2026-07-28' },
  }) };

  is($h->{'Authorization'}, 'Bearer t0ken', 'a configured Authorization is sent');
  is($h->{'X-Trace-Id'}, 'abc123', 'as is any other header the caller configured');
  is($h->{'Mcp-Method'}, 'tools/list',
    'next to, not instead of, the headers derived from the body');
}

# The derived headers are the ones the server compares against the body, and it
# answers -32020 for any that diverges, so a caller must not be able to reach
# them. Ordering the caller's first is not enough on its own: HTTP::Headers
# keeps a field given twice as two values of one header rather than letting the
# later win, so a colliding header would still travel to the server.
{
  my $hostile = Net::Async::MCP::Transport::HTTP->new(
    url     => 'http://mcp.invalid/mcp',
    headers => {
      'Mcp-Method'           => 'tools/list',
      'mcp-protocol-version' => '1999-01-01',
      'Mcp-Name'             => 'other_tool',
      'Mcp-Param-Region'     => 'us-east1',
      'Authorization'        => 'Bearer t0ken',
    },
  );

  my @headers = $hostile->_standard_headers('tools/call',
    {
      name  => 'deploy',
      _meta => { 'io.modelcontextprotocol/protocolVersion' => '2026-07-28' },
    },
    header_params => [ { name => 'Region', value => 'europe-west1' } ]);

  # What the server gets to see, rather than the list this client passes around
  my $req = HTTP::Request->new(POST => 'http://mcp.invalid/mcp', [@headers], '');

  is($req->header('Mcp-Method'), 'tools/call',
    'the method header stays the method being called');
  is($req->header('MCP-Protocol-Version'), '2026-07-28',
    'the protocol version stays the one in the body _meta');
  is($req->header('Mcp-Name'), 'deploy', 'the name stays the one in the body');
  is($req->header('Mcp-Param-Region'), 'europe-west1',
    'an annotated argument keeps the value the client resolved for it');
  is($req->header('Authorization'), 'Bearer t0ken',
    'while a header the protocol derives nothing for is passed through untouched');

  my %count;
  for (my $i = 0; $i < @headers; $i += 2) { $count{ lc $headers[$i] }++ }
  is($count{'mcp-method'}, 1,
    'a colliding caller header is dropped, not sent as a second value');
  is($count{'mcp-protocol-version'}, 1, 'and its case does not get it past the filter');
  is($count{'mcp-param-region'}, 1, 'nor does an annotated argument name');
}

ok($transport->mirrors_header_params,
  'the HTTP transport is the one that mirrors header params');

# From here the whole path is under test, from the arguments a caller passes to
# the headers that would go on the wire: a wrong or missing Mcp-Param header is
# not a cosmetic defect, the server answers -32020 and the call never runs.
{
  package Test::CapturingHTTP;

  sub new {
    my ( $class, %args ) = @_;
    return bless { requests => [], responder => $args{responder} }, $class;
  }

  sub do_request {
    my ( $self, %args ) = @_;
    push @{ $self->{requests} }, $args{request};

    my $response = $self->{responder}->($args{request});

    # Net::Async::HTTP hands the header over as soon as it has it and takes
    # the callback for the body in return, calling it once more with nothing
    # at the end of the body, where whatever it returns becomes the result of
    # the Future. A redirect it consumes itself and never passes on.
    my $on_header = $args{on_header};
    return Future->done($response) if !$on_header || $response->is_redirect;

    my $header = $response->clone;
    $header->content('');
    my $on_chunk = $on_header->($header);
    $on_chunk->($response->content) if length $response->content;
    return Future->done($on_chunk->());
  }

  sub requests { @{ $_[0]{requests} } }
}

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1);

# One tool with an argument per shape the server compares differently, plus one
# argument that is not annotated at all and must stay out of the headers
my $TOOL = {
  name        => 'deploy',
  description => 'Deploy a service',
  inputSchema => {
    type       => 'object',
    properties => {
      service  => { type => 'string' },
      region   => { type => 'string',  'x-mcp-header' => 'Region' },
      dry_run  => { type => 'boolean', 'x-mcp-header' => 'Dry-Run' },
      replicas => { type => 'integer', 'x-mcp-header' => 'Replicas' },
      options  => {
        type       => 'object',
        properties => {
          label => { type => 'string', 'x-mcp-header' => 'Label' },
        },
      },
    },
  },
};

# A client whose transport answers out of this file instead of the network. The
# transport builds its Net::Async::HTTP when it joins a loop, so handing it one
# up front keeps the test off both.
sub client {
  my ( $responder ) = @_;

  my $http = Test::CapturingHTTP->new(responder => $responder);
  my $t = Net::Async::MCP::Transport::HTTP->new(url => 'http://mcp.invalid/mcp');
  $t->{http} = $http;

  my $mcp = Net::Async::MCP->new(url => 'http://mcp.invalid/mcp');
  $mcp->{transport} = $t;

  return ( $mcp, $http );
}

sub serve_tool {
  my ( $request ) = @_;
  my $data = $json->decode($request->content);

  my $result = $data->{method} eq 'tools/list'
    ? { tools => [$TOOL] }
    : { content => [ { type => 'text', text => 'deployed' } ], isError => JSON::MaybeXS::false };

  return response(200, 'application/json',
    $json->encode({ jsonrpc => '2.0', id => $data->{id}, result => $result }));
}

sub sent_methods {
  my ( $http ) = @_;
  return [ map { $json->decode($_->content)->{method} } $http->requests ];
}

{
  my ( $mcp, $http ) = client(\&serve_tool);

  # \0 is what a caller writes for a JSON false, and it is a *reference*, so
  # anything that asks it for its truth directly gets "true" - a header saying
  # true while the body says false, which the server answers with -32020.
  my $f = $mcp->call_tool('deploy', {
    service  => 'api',
    region   => 'europe-west1',
    dry_run  => \0,
    replicas => 3,
    options  => { label => "Gr\x{00fc}n" },
  });
  ok($f->is_done, 'the call goes through') or diag $f->failure;

  is(sent_methods($http), ['tools/list', 'tools/call'],
    'a tool with no known schema is looked up once before it is called');

  my ( $call ) = ($http->requests)[1];
  is($call->header('Mcp-Param-Region'), 'europe-west1',
    'a string argument is mirrored as it stands');
  is($call->header('Mcp-Param-Dry-Run'), 'false',
    'a \0 boolean is mirrored as false, not as the true reference it is');
  is($call->header('Mcp-Param-Replicas'), '3', 'an integer is mirrored as its number');
  is(decoded_name($call->header('Mcp-Param-Label')), "Gr\x{00fc}n",
    'a nested argument is found through its properties path');
  is($call->header('Mcp-Param-Service'), undef,
    'an argument without x-mcp-header gets no header');
}

# The other two spellings of a boolean, and an argument the caller did not pass
{
  my ( $mcp, $http ) = client(\&serve_tool);
  $mcp->call_tool('deploy', { dry_run => \1 })->get;
  my ( $call ) = ($http->requests)[1];
  is($call->header('Mcp-Param-Dry-Run'), 'true', 'a \1 boolean is mirrored as true');
  is($call->header('Mcp-Param-Region'), undef,
    'an argument the call did not pass gets no header, which the server would reject');
}

{
  my ( $mcp, $http ) = client(\&serve_tool);
  $mcp->call_tool('deploy', { dry_run => JSON::MaybeXS::false })->get;
  my ( $call ) = ($http->requests)[1];
  is($call->header('Mcp-Param-Dry-Run'), 'false',
    'a JSON::PP::Boolean false is mirrored as false too');
}

# The schemas are cached, so a second call to the same tool asks for nothing
{
  my ( $mcp, $http ) = client(\&serve_tool);
  $mcp->call_tool('deploy', { region => 'eu' })->get;
  $mcp->call_tool('deploy', { region => 'us' })->get;
  is(sent_methods($http), ['tools/list', 'tools/call', 'tools/call'],
    'the tool list is fetched once, not per call');
}

# A tools/list that fails must not take the call with it: most tools have no
# annotated argument at all and would become uncallable over an unrelated
# error. The call goes out bare and the server decides.
{
  my ( $mcp, $http ) = client(sub {
    my ( $request ) = @_;
    my $data = $json->decode($request->content);
    return HTTP::Response->new(500, 'Internal Server Error', [], '')
      if $data->{method} eq 'tools/list';
    return serve_tool($request);
  });

  my $f = $mcp->call_tool('deploy', { region => 'europe-west1' });
  ok($f->is_done, 'the call survives a failed tool list') or diag $f->failure;
  is(sent_methods($http), ['tools/list', 'tools/call'], 'and is still sent');
  is(($http->requests)[1]->header('Mcp-Param-Region'), undef,
    'without headers it could not resolve');
}

# MCP::Server renders a rejected _meta as -32602 with HTTP 400. Reporting the
# status line instead would throw away the only useful part of the answer.
{
  my $f = $transport->_handle_response(response(400, 'application/json',
    '{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Missing protocol version"}}'));
  is($f->failure, 'MCP error -32602: Missing protocol version',
    'HTTP 400 with a JSON-RPC error body surfaces the JSON-RPC error');
}

# MCP::Server answers an unknown method - subscriptions/listen on a server
# without notification support, for one - with -32601 and HTTP 404. The status
# alone would say nothing about which method the server refused.
{
  my $f = $transport->_handle_response(response(404, 'application/json',
    '{"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method \'subscriptions/listen\' not found"}}'));
  is($f->failure, "MCP error -32601: Method 'subscriptions/listen' not found",
    'HTTP 404 with a JSON-RPC error body surfaces the JSON-RPC error');
}

# A bare 404 is nothing but a 404. The current revision has no protocol
# sessions, so there is no expired session left to blame it on and the honest
# report is the status line.
{
  my $f = $transport->_handle_response(response(404, 'text/plain', 'Not Found'));
  like($f->failure, qr/^MCP HTTP error: 404/,
    'bare HTTP 404 falls back to the HTTP status line');
}

# A JSON body with a plain string "error" is not a JSON-RPC error. MCP::Server
# answers a bad method with exactly that shape, and a gateway in between may
# invent another one, so it must not be read as a JSON-RPC error object.
{
  my $f = $transport->_handle_response(response(405, 'application/json',
    '{"error":"Method not allowed"}'));
  like($f->failure, qr/^MCP HTTP error: 405/,
    'a non-JSON-RPC error body falls back to the HTTP status line');
}

# Any other non-2xx without a JSON-RPC body keeps the old HTTP-level report
{
  my $f = $transport->_handle_response(
    HTTP::Response->new(502, 'Bad Gateway', [ 'Content-Type' => 'text/html' ], '<html>nope</html>'));
  like($f->failure, qr/^MCP HTTP error: 502/,
    'non-2xx without a JSON-RPC body falls back to the HTTP status line');
}

# The body reaches the JSON decoder as UTF-8 bytes. decoded_content would hand
# back characters, and decoding those again as UTF-8 mangles or dies on
# anything outside ASCII.
{
  my $f = $transport->_handle_response(response(200, 'application/json; charset=utf-8',
    qq({"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"Gr\xc3\xbc\xc3\x9fe"}]}})));
  ok($f->is_done, 'utf-8 JSON body parses') or diag $f->failure;
  is($f->is_done && $f->get->{content}[0]{text}, "Gr\x{00fc}\x{00df}e",
    'utf-8 JSON body is decoded exactly once');
}

# Same for SSE, where decoded_content does apply a charset (text/*) and the
# double decoding actually fails
{
  my $body = "event: message\n"
    . qq(data: {"jsonrpc":"2.0","id":1,"result":{"text":"Gr\xc3\xbc\xc3\x9fe"}}\n\n);
  my $f = $transport->_handle_response(response(200, 'text/event-stream', $body));
  ok($f->is_done, 'utf-8 SSE body parses') or diag $f->failure;
  is($f->is_done && $f->get->{text}, "Gr\x{00fc}\x{00df}e",
    'utf-8 SSE body is decoded exactly once');
}

# A successful JSON response still reports a JSON-RPC error as one
{
  my $f = $transport->_handle_response(response(200, 'application/json',
    '{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Unknown tool"}}'));
  is($f->failure, 'MCP error -32602: Unknown tool', 'JSON-RPC error in a 200 response');
}

# An "error" that is not a JSON-RPC error object must not be read as one. This
# is not a hypothetical shape: MCP::Server::Transport::HTTP renders its own
# refusals as {error => 'Method not allowed'} and {error => 'Invalid JSON'},
# and a gateway in between may put its own body in front of a 200. Reaching
# into a string as if it were a hash throws, which no caller of a Future-
# returning method expects, so the test has to survive the die to report on it.
{
  my $f;
  ok(lives {
    $f = $transport->_handle_response(response(200, 'application/json',
      '{"error":"Method not allowed"}'));
  }, 'a 200 whose error is a string does not die') or note $@;

  ok($f && $f->is_failed, 'it fails the Future instead');
  like($f->failure, qr/Method not allowed/,
    'and the failure quotes what the body actually said');
}

{
  my $body = "event: message\n"
    . qq(data: {"jsonrpc":"2.0","id":1,"error":"Method not allowed"}\n\n);
  my $f;
  ok(lives { $f = $transport->_handle_response(response(200, 'text/event-stream', $body)) },
    'the same body in an SSE event does not die either') or note $@;

  ok($f && $f->is_failed, 'it fails the Future instead');
  like($f->failure, qr/Method not allowed/,
    'and the failure quotes what the event actually said');
}

# A JSON-RPC error object without a message is still a JSON-RPC error: the code
# is the part the caller acts on, and interpolating an undef message would warn
{
  my $f = $transport->_handle_response(response(200, 'application/json',
    '{"jsonrpc":"2.0","id":1,"error":{"code":-32603}}'));
  is($f->failure, 'MCP error -32603: (no message)',
    'a message-less JSON-RPC error reports its code without warning');
}

# A notification has no answer this client reads, so the status is all there is
# to judge. Treating every completed POST as a success hid a rejection: the
# client reported the notification as sent while the server had refused it.
{
  my $f = $transport->_handle_notification_response(
    HTTP::Response->new(202, 'Accepted', [], ''));
  ok($f->is_done, '202 Accepted with no body is a delivered notification')
    or diag $f->failure;
}

{
  my $f = $transport->_handle_notification_response(response(400, 'application/json',
    '{"jsonrpc":"2.0","id":null,"error":{"code":-32602,"message":"Missing protocol version"}}'));
  is($f->failure, 'MCP error -32602: Missing protocol version',
    'a JSON-RPC error body wins over the status here too');
}

{
  my $f = $transport->_handle_notification_response(
    HTTP::Response->new(500, 'Internal Server Error', [ 'Content-Type' => 'text/html' ], '<html>nope</html>'));
  like($f->failure, qr/^MCP HTTP error: 500/,
    'a non-2xx without a usable body fails with the HTTP status line');
}

# A server may send notifications on the response stream of a request long
# before the response itself - the notifications/progress of a running
# tools/call above all - and they are worth nothing once the call has
# finished, so the stream has to be read as it arrives rather than in one
# piece at the end. What Net::Async::HTTP feeds a body to is the callback
# _sse_reader returns, so feeding it by hand is the whole stream, and where
# one chunk ends and the next begins is the point of most of what follows.

sub sse_reader {
  my ( $notifications ) = @_;

  my $t = Net::Async::MCP::Transport::HTTP->new(
    url             => 'http://mcp.invalid/mcp',
    on_notification => sub { push @$notifications, $_[1] },
  );

  return $t->_sse_reader;
}

sub sse_event {
  my ( $payload ) = @_;
  return "data: $payload\n\n";
}

my $PROGRESS = '{"jsonrpc":"2.0","method":"notifications/progress",'
  . '"params":{"progressToken":"t","progress":1,"total":3}}';
my $MESSAGE = '{"jsonrpc":"2.0","method":"notifications/message",'
  . '"params":{"level":"info","data":"halfway"}}';
my $RESULT = '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"done"}]}}';

{
  my @got;
  my $read = sse_reader(\@got);

  $read->("event: message\n" . sse_event($PROGRESS));
  is(scalar @got, 1,
    'a notification reaches the handler as soon as its event is complete');
  is($got[0]{method}, 'notifications/progress',
    'and arrives as the decoded notification the server sent');
  is($got[0]{params}{progress}, 1, 'with the params it carried');

  $read->(sse_event($MESSAGE));
  is([ map { $_->{method} } @got ],
    [ 'notifications/progress', 'notifications/message' ],
    'the next one follows it, in the order the server sent them');

  $read->(sse_event($RESULT));
  is(scalar @got, 2, 'while the response is no notification and is not handed over');

  my $f = $read->();
  ok($f->is_done, 'the finished stream resolves with the response it carried')
    or diag $f->failure;
  is($f->get->{content}[0]{text}, 'done', 'and the caller gets the result of it');
}

# The network decides where a chunk ends, not the server: every boundary at
# once is the strongest form of the test, and any of them losing a byte turns
# a delivered notification into a decode that quietly fails
{
  my @got;
  my $read = sse_reader(\@got);

  $read->($_) for split //, sse_event($PROGRESS) . sse_event($RESULT);

  is(scalar @got, 1, 'an event torn into single bytes is put back together');
  is($got[0]{params}{total}, 3, 'with everything that was in it');

  my $f = $read->();
  ok($f->is_done, 'and so is the response behind it') or diag $f->failure;
  is($f->get->{content}[0]{text}, 'done', 'with the result it carried');
}

# A server holds an idle stream open with comment lines, which are no events
# at all, and may name fields this client has no use for. All of it over the
# CRLF line endings an HTTP server writes rather than the bare LF a string
# literal in a test does.
{
  my @got;
  my $read = sse_reader(\@got);

  $read->(": keep-alive\r\n\r\n");
  is(scalar @got, 0, 'a keep-alive comment is not delivered as a notification');

  # A CRLF blank line has to end its event where it stands: an event that only
  # ends when the stream does is a notification delivered too late to be worth
  # anything, and the next event's data lines join onto it into one document
  # that decodes as nothing at all
  $read->("event: message\r\ndata: $PROGRESS\r\n\r\n");
  is(scalar @got, 1, 'while a CRLF blank line ends its event there and then');

  $read->("id: 42\r\n: another keep-alive\r\n");
  $read->("data: $RESULT\r\n\r\n");

  is(scalar @got, 1, 'and a field this client has no use for changes nothing');

  my $f = $read->();
  ok($f->is_done, 'and nothing about it stops the response from arriving')
    or diag $f->failure;
  is($f->get->{content}[0]{text}, 'done',
    'which reads as it stands, CRLF line endings and all');
}

# The data lines of one event are one document, joined by newlines: a server
# pretty-printing its JSON sends exactly this
{
  my @got;
  my $read = sse_reader(\@got);

  $read->(qq(data: {"jsonrpc":"2.0","id":1,\ndata:  "result":{"text":"joined"}}\n\n));

  my $f = $read->();
  ok($f->is_done, 'the data lines of one event are joined into one document')
    or diag $f->failure;
  is($f->get->{text}, 'joined', 'and read as the one thing they are');
}

# A chunk ends between two bytes of a character as readily as between two
# lines. Buffering characters instead of bytes would cut the multi-byte
# sequence in half and lose the event to a decode that fails silently.
{
  my @got;
  my $read = sse_reader(\@got);

  my $event = sse_event('{"jsonrpc":"2.0","method":"notifications/message",'
    . qq("params":{"level":"info","data":"Gr\xc3\xbc\xc3\x9fe"}}));
  my $cut = index($event, "\xc3\xbc") + 1;

  $read->(substr($event, 0, $cut));
  is(scalar @got, 0, 'nothing is delivered from half an event');

  $read->(substr($event, $cut));
  is(scalar @got, 1, 'an event cut inside a multi-byte character survives it');
  is($got[0]{params}{data}, "Gr\x{00fc}\x{00df}e",
    'and its text is decoded exactly once');
}

# Net::Async::HTTP hands over bytes, which is what the JSON decoder wants.
# Characters would be read as UTF-8 a second time, and since a failed decode
# is how a stream tolerates an event it cannot use, every non-ASCII event
# would go missing without a word.
{
  my @got;
  my $read = sse_reader(\@got);

  my $event = decode('UTF-8',
    sse_event('{"jsonrpc":"2.0","method":"notifications/message",'
      . qq("params":{"level":"info","data":"Gr\xc3\xbc\xc3\x9fe"}})));
  ok(is_utf8($event), 'the chunk really is characters rather than bytes');

  $read->($event);
  is(scalar @got, 1, 'a chunk of characters is encoded back to bytes');
  is($got[0]{params}{data}, "Gr\x{00fc}\x{00df}e", 'rather than lost to the decoder');
}

# A stream that ends without a response answered nothing, whatever else it
# said on the way. (A subscriptions/listen looks exactly like this and is not
# served by this at all - it needs a Future that never expects a response.)
{
  my @got;
  my $read = sse_reader(\@got);

  $read->(sse_event($PROGRESS));
  my $f = $read->();

  is($f->failure, 'MCP HTTP no JSON-RPC response in SSE stream',
    'a stream that only ever notified never answered the request');
  is(scalar @got, 1, 'though what it did send was delivered all the same');
}

# Nothing has to be listening. A server sends its notifications whether or not
# this client asked for them, and one nobody wants is dropped rather than
# turned into an error on a request that is otherwise going fine.
{
  my $read = $transport->_sse_reader;
  my $f;

  ok(lives {
    $read->(sse_event($PROGRESS));
    $f = $read->();
  }, 'a notification with no handler for it is dropped') or note $@;

  is($f->failure, 'MCP HTTP no JSON-RPC response in SSE stream',
    'and changes nothing about what the stream did or did not answer');
}

# The reader only ever sees what Net::Async::HTTP gives it, so the wiring in
# between - which body is read as it arrives and which is read whole - is its
# own thing to get wrong.
{
  package Test::StreamingHTTP;

  sub new {
    my ( $class, %args ) = @_;
    return bless { %args }, $class;
  }

  sub do_request {
    my ( $self, %args ) = @_;

    # A redirect is consumed by Net::Async::HTTP itself: it does not follow
    # one for a POST, and the body reader never sees it
    return Future->done($self->{response}) if $self->{response};

    my $on_chunk = $args{on_header}->($self->{header});
    $on_chunk->($_) for @{ $self->{chunks} };
    return Future->done($on_chunk->());
  }
}

sub streaming_transport {
  my ( $notifications, %args ) = @_;

  my $t = Net::Async::MCP::Transport::HTTP->new(
    url             => 'http://mcp.invalid/mcp',
    on_notification => sub { push @$notifications, $_[1] },
  );
  $t->{http} = Test::StreamingHTTP->new(%args);

  return $t;
}

{
  my @got;
  my $t = streaming_transport(\@got,
    header => HTTP::Response->new(200, 'OK',
      [ 'Content-Type' => 'text/event-stream' ], ''),
    chunks => [
      "data: $PROGRESS\n",
      "\ndata: " . substr($RESULT, 0, 20),
      substr($RESULT, 20) . "\n\n",
    ],
  );

  my $f = $t->send_request('tools/call', { name => 'slow' });
  ok($f->is_done, 'a request answered with an event stream resolves with its response')
    or diag $f->failure;
  is($f->get->{content}[0]{text}, 'done', 'and hands the caller the result');
  is([ map { $_->{method} } @got ], ['notifications/progress'],
    'while the notification that came first reached the handler');
}

# The content type decides how a body is read, not the fact that it is read
# through a callback: a JSON answer says nothing until it is complete and is
# still judged whole, chunked or not.
{
  my @got;
  my $t = streaming_transport(\@got,
    header => HTTP::Response->new(200, 'OK',
      [ 'Content-Type' => 'application/json' ], ''),
    chunks => [ substr($RESULT, 0, 30), substr($RESULT, 30) ],
  );

  my $f = $t->send_request('tools/call', { name => 'quick' });
  ok($f->is_done, 'a JSON body split across chunks is put back together')
    or diag $f->failure;
  is($f->get->{content}[0]{text}, 'done', 'and read as the whole response it is');
  is(scalar @got, 0, 'with nothing to deliver on the way');
}

{
  my @got;
  my $t = streaming_transport(\@got,
    header => HTTP::Response->new(404, 'Not Found',
      [ 'Content-Type' => 'application/json' ], ''),
    chunks => [ '{"jsonrpc":"2.0","id":1,"error":{"code":-32601,',
      '"message":"Method not found"}}' ],
  );

  my $f = $t->send_request('tools/call', { name => 'nope' });
  is($f->failure, 'MCP error -32601: Method not found',
    'and a JSON-RPC error still wins over the status it came with');
}

# Net::Async::HTTP resolves with the response object rather than with anything
# a body reader returned when it consumed the body itself, which is what a
# redirected endpoint looks like from here
{
  my @got;
  my $t = streaming_transport(\@got,
    response => HTTP::Response->new(302, 'Found',
      [ Location => 'http://elsewhere.invalid/mcp' ], ''),
  );

  my $f = $t->send_request('tools/list', {});
  like($f->failure, qr/^MCP HTTP error: 302/,
    'a redirect that never reached the body reader is reported as the failure it is');
}

# What answers a request is its response, and the end of the body it arrived in
# is a different moment: nothing in the Streamable HTTP binding obliges a
# server to close the stream behind it, and a caller kept waiting for that
# waits until the stall timeout gives up on a stream that has nothing left to
# say. The mocks above feed a body and end it in the same call, which cannot
# tell the two moments apart, so this one keeps the stream open.
{
  package Test::OpenStreamHTTP;

  sub new { return bless { streams => [] }, shift }

  sub do_request {
    my ( $self, %args ) = @_;

    my $stream = {
      chunk => $args{on_header}->(HTTP::Response->new(200, 'OK',
        [ 'Content-Type' => 'text/event-stream' ], '')),
      future => Future->new,
    };
    push @{ $self->{streams} }, $stream;

    return $stream->{future};
  }

  sub stream { return $_[0]{streams}[-1] }
  sub feed   { $_[0]->stream->{chunk}->($_[1]); return $_[0] }
  sub finish {
    my ( $self ) = @_;
    my $stream = $self->stream;
    $stream->{future}->done($stream->{chunk}->()) unless $stream->{future}->is_ready;
    return $self;
  }
}

{
  my @got;
  my $t = Net::Async::MCP::Transport::HTTP->new(
    url             => 'http://mcp.invalid/mcp',
    on_notification => sub { push @got, $_[1] },
  );
  my $http = Test::OpenStreamHTTP->new;
  $t->{http} = $http;

  my $f = $t->send_request('tools/call', { name => 'slow' });

  $http->feed(sse_event($PROGRESS));
  ok(!$f->is_ready, 'the notifications before a response do not answer the request');

  $http->feed(sse_event($RESULT));
  ok($f->is_done, 'while its response answers it the moment it lands')
    or diag $f->failure;
  is($f->get->{content}[0]{text}, 'done', 'with the result the response carried');

  ok(!$http->stream->{future}->is_ready,
    'and a server that holds the stream open afterwards holds nobody up');

  $http->feed(sse_event($MESSAGE));
  is([ map { $_->{method} } @got ],
    [ 'notifications/progress', 'notifications/message' ],
    'what it still sends is delivered as the notification it is');

  $http->finish;
  ok($f->is_done, 'and the end of the stream changes nothing about the answer');
  is($f->get->{content}[0]{text}, 'done', 'which is still the one it gave');

  # The caller holds the answer rather than the exchange now, so the transport
  # is what holds the exchange - and what has to let go of it again, or every
  # request ever made stays on it.
  is($t->{pending}, {}, 'and the finished request is off the transport');
}

# Net::Async::HTTP applies no timeout unless it is given one, so a server that
# accepts a POST and then goes quiet holds the caller forever. Only the stall
# timeout has a default: it fires when nothing at all arrives any more, where a
# wall-clock timeout would also cut off a tools/call that is legitimately slow.
# These tests need a loop, since the transport builds its client when it joins
# one, but no server: nothing is sent.
subtest 'timeouts reach the HTTP client' => sub {
  skip_all 'Net::Async::HTTP is required for the timeout tests'
    unless eval { require Net::Async::HTTP; 1 };

  require IO::Async::Loop;
  my $loop = IO::Async::Loop->new;

  # Net::Async::HTTP exposes neither value, and what has to be right is what
  # the object it makes its requests with was configured with.
  my $default = Net::Async::MCP::Transport::HTTP->new(url => 'http://mcp.invalid/mcp');
  $loop->add($default);
  is($default->{http}{stall_timeout}, 60, 'a 60 second stall timeout is the default');
  is($default->{http}{timeout}, undef,
    'and no wall-clock timeout, which would break a legitimately slow tool call');

  my $configured = Net::Async::MCP::Transport::HTTP->new(
    url           => 'http://mcp.invalid/mcp',
    timeout       => 30,
    stall_timeout => 5,
  );
  $loop->add($configured);
  is($configured->{http}{timeout}, 30, 'a configured timeout is passed on');
  is($configured->{http}{stall_timeout}, 5,
    'and a configured stall timeout replaces the default');

  # Net::Async::HTTP::Connection builds a stall timer only for a true value, so
  # 0 is how the stall timeout is switched off - unlike timeout, where 0 is a
  # limit of zero seconds that would fail every request.
  my $off = Net::Async::MCP::Transport::HTTP->new(
    url           => 'http://mcp.invalid/mcp',
    stall_timeout => 0,
  );
  $loop->add($off);
  ok(!$off->{http}{stall_timeout}, 'a stall timeout of 0 switches it off');

  $configured->configure(stall_timeout => 90);
  is($configured->{http}{stall_timeout}, 90,
    'configuring one after the client exists reaches it');

  $loop->remove($_) for $default, $configured, $off;
};

# The transport is built by the client, so anything a caller cannot hand to the
# client cannot reach it at all - which is what kept an Authorization out.
subtest 'the client passes the HTTP options through' => sub {
  skip_all 'Net::Async::HTTP is required for the pass-through tests'
    unless eval { require Net::Async::HTTP; 1 };

  require IO::Async::Loop;
  my $loop = IO::Async::Loop->new;

  my $mcp = Net::Async::MCP->new(
    url     => 'http://mcp.invalid/mcp',
    headers => { Authorization => 'Bearer t0ken' },
    timeout => 30,
  );
  $loop->add($mcp);

  is($mcp->headers, { Authorization => 'Bearer t0ken' }, 'the client reports its headers');
  is($mcp->timeout, 30, 'and its timeout');
  is($mcp->stall_timeout, undef, 'and reports nothing where nothing was configured');

  my $t = $mcp->{transport};
  is($t->{headers}, { Authorization => 'Bearer t0ken' }, 'the transport was given the headers');
  is($t->{http}{timeout}, 30, 'and the timeout reached Net::Async::HTTP');
  is($t->{http}{stall_timeout}, 60,
    'while an unset stall timeout leaves the transport default standing rather than off');

  # A bearer token is rotated while the client is up, long after the transport
  # was built, so a configure that only reached the client would be lost.
  $mcp->configure(headers => { Authorization => 'Bearer fresh' });
  is($t->{headers}, { Authorization => 'Bearer fresh' },
    'a later configure reaches the transport that already exists');
  is({ $t->_standard_headers('tools/list', {}) }->{'Authorization'}, 'Bearer fresh',
    'so the next request carries the new token');

  $loop->remove($mcp);
};

done_testing;
