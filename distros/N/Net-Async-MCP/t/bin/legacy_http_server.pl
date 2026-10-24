#!/usr/bin/env perl
# A legacy Streamable HTTP MCP server for the tests, shaped after the
# TypeScript SDK's: sessions, the initialize handshake of 2025-03-26 ..
# 2025-11-25, and nothing of the modern revision. It listens on a free port of
# 127.0.0.1 and prints that port as its first line on stdout. Configured
# through the environment:
#
#   LEGACY_HTTP_VERSIONS  comma-separated revisions it accepts, newest first
#   LEGACY_HTTP_PREINIT   how a request before initialize is refused: sdk
#                         (400 with a JSON-RPC -32000 body, the default),
#                         empty (400, no body), modern (400 with a -32022
#                         body naming only 2027-01-01)
#   LEGACY_HTTP_SESSION   0 to assign no session id
#   LEGACY_HTTP_DELETE    the status a DELETE is answered with (default 200)
#   LEGACY_HTTP_PARENT    the pid of the test; the server exits once it is no
#                         longer its parent (default: the parent it starts with)
#
# Control endpoints for the tests: GET /control/log answers every MCP request
# received so far - HTTP method, the headers that matter, the body - and POST
# /control/expire ends every session, so the next request in one gets 404;
# with ?sticky=N the next N sessions started are also ended as soon as their
# notifications/initialized arrives.
use Mojolicious::Lite -signatures;
use Mojo::IOLoop;
use Mojo::JSON qw( decode_json encode_json );
use Mojo::Server::Daemon;

my @versions = split /,/, $ENV{LEGACY_HTTP_VERSIONS}
  // '2025-11-25,2025-06-18,2025-03-26';
my $preinit     = $ENV{LEGACY_HTTP_PREINIT} // 'sdk';
my $use_session = $ENV{LEGACY_HTTP_SESSION} // 1;
my $delete      = $ENV{LEGACY_HTTP_DELETE} // 200;

my ( @log, %sessions, $sticky, %asked, $next_session );
# Without sessions there is one connection state, kept under the empty key.
my $SESSIONLESS = '';

sub rpc_error ($c, $status, $id, $code, $message, $data = undef) {
  return $c->render(status => $status, json => {
    jsonrpc => '2.0',
    id      => $id,
    error   => { code => $code, message => $message, defined $data ? ( data => $data ) : () },
  });
}

sub result ($c, $id, $result) {
  return $c->render(json => { jsonrpc => '2.0', id => $id, result => $result });
}

sub text ($text) { return { content => [ { type => 'text', text => $text } ] } }

sub log_request ($c, $body) {
  my $h = $c->req->headers;
  push @log, {
    method  => $c->req->method,
    headers => { map { defined $h->header($_) ? ( $_ => $h->header($_) ) : () }
      qw( Mcp-Session-Id MCP-Protocol-Version Mcp-Method Mcp-Name Authorization Accept ) },
    body    => $body,
  };
}

# An answer on an event stream that first asks the client something, waits for
# the client's answer to arrive by POST, and then answers with what came back.
# Written with write, a body that ends with the connection, and not with
# write_chunk: Mojolicious sends the CRLF that ends a chunk only in front of the
# next one, and Net::Async::HTTP hands a chunk over only once that CRLF is in,
# so the question would sit unread until the answer it waits for arrived.
sub ask_then_answer ($c, $id, $method, $make_result) {
  $c->res->headers->content_type('text/event-stream');
  $c->inactivity_timeout(30);
  my $ask = "ask-$id";
  $asked{$ask} = sub ($answer) {
    $c->write('data: ' . encode_json({ jsonrpc => '2.0', method => 'notifications/message',
      params => { level => 'info', data => 'asked' } }) . "\n\n");
    $c->write('data: ' . encode_json({ jsonrpc => '2.0', id => $id,
      result => $make_result->($answer) }) . "\n\n", sub ($c, @) { $c->finish });
  };
  $c->write('data: ' . encode_json({ jsonrpc => '2.0', id => $ask, method => $method,
    params => {} }) . "\n\n");
}

post '/control/expire' => sub ($c) {
  $_->{expired} = 1 for values %sessions;
  $sticky = $c->param('sticky');
  $c->render(json => { ok => 1 });
};

get '/control/log' => sub ($c) { $c->render(json => \@log) };

del '/mcp' => sub ($c) {
  log_request($c, undef);
  delete $sessions{ $c->req->headers->header('Mcp-Session-Id') // '' };
  $c->rendered($delete);
};

post '/mcp' => sub ($c) {
  my $message = eval { decode_json($c->req->body) } // {};
  log_request($c, $message);

  my ( $id, $method ) = @{$message}{qw( id method )};
  my $sid = $c->req->headers->header('Mcp-Session-Id');

  if (( $method // '' ) eq 'initialize') {
    return rpc_error($c, 400, $id, -32600, 'Invalid Request: initialize inside a session')
      if defined $sid;
    my $asked = $message->{params}{protocolVersion} // '';
    my ($agreed) = grep { $_ eq $asked } @versions;
    $agreed //= $versions[0];
    my $session = $use_session ? 'session-' . ++$next_session : $SESSIONLESS;
    $sessions{$session} = { version => $agreed };
    $c->res->headers->header('Mcp-Session-Id' => $session) if $use_session;
    return result($c, $id, {
      protocolVersion => $agreed,
      capabilities    => { tools => {} },
      serverInfo      => { name => 'LegacyHTTPServer', version => '1.0' },
    });
  }

  my $state;
  if ($use_session) {
    unless (defined $sid) {
      return $c->rendered(400) if $preinit eq 'empty';
      return rpc_error($c, 400, $id, -32022, 'Unsupported protocol version',
        { supported => ['2027-01-01'], requested => 'whatever' }) if $preinit eq 'modern';
      return rpc_error($c, 400, undef, -32000, 'Bad Request: Server not initialized');
    }
    $state = $sessions{$sid};
    return rpc_error($c, 404, undef, -32001, 'Session not found')
      if !$state || $state->{expired};
  }
  else {
    $state = $sessions{$SESSIONLESS}
      or return rpc_error($c, 400, undef, -32000, 'Bad Request: Server not initialized');
  }

  # Inside a session everything has to be legacy: the routing headers of the
  # modern revision do not belong here.
  return rpc_error($c, 400, $id, -32000, 'Bad Request: Mcp-Method is not a legacy header')
    if defined $c->req->headers->header('Mcp-Method');

  my $version = $c->req->headers->header('MCP-Protocol-Version') // '';
  return rpc_error($c, 400, $id, -32000, "Bad Request: MCP-Protocol-Version '$version' "
    . "is not the negotiated $state->{version}")
    unless $version eq $state->{version};

  # A response to a request this server asked on a stream.
  if (!defined $method) {
    my $answer = delete $asked{ $id // '' };
    $answer->($message) if $answer;
    return $c->rendered(202);
  }

  if ($method eq 'notifications/initialized') {
    $state->{initialized} = 1;
    if ($sticky) {
      $state->{expired} = 1;
      $sticky--;
    }
    return $c->rendered(202);
  }
  return $c->rendered(202) unless defined $id;

  return rpc_error($c, 400, $id, -32000, 'Bad Request: notifications/initialized missing')
    unless $state->{initialized};

  if ($method eq 'tools/list') {
    return result($c, $id, { tools => [ map { {
      name => $_, description => "The $_ tool", inputSchema => { type => 'object' },
    } } qw( echo roots slow ) ] });
  }
  if ($method eq 'tools/call') {
    my $tool = $message->{params}{name} // '';
    my $args = $message->{params}{arguments} // {};
    return ask_then_answer($c, $id, 'ping', sub ($answer) {
      text('Echo: ' . ( $args->{message} // '' ) . ' (ping ' . encode_json($answer->{result} // $answer->{error}) . ')');
    }) if $tool eq 'echo';
    return ask_then_answer($c, $id, 'roots/list', sub ($answer) {
      text(encode_json($answer->{error} // $answer->{result}));
    }) if $tool eq 'roots';
    if ($tool eq 'slow') {
      $c->res->headers->content_type('text/event-stream');
      $c->inactivity_timeout(30);
      return $c->write(": waiting\n\n");
    }
    return rpc_error($c, 200, $id, -32602, "Unknown tool '$tool'");
  }

  return rpc_error($c, 200, $id, -32601, "Method not found: $method");
};

my $daemon = Mojo::Server::Daemon->new(
  app    => app,
  listen => ['http://127.0.0.1'],
  silent => 1,
);
app->log->level('fatal');
$daemon->start;
$| = 1;
print $daemon->ports->[0], "\n";

# The test that started this server stops it, and kills it in an END block -
# which a test killed by a signal or a timeout never runs. Unlike the stdio
# servers, which end with the stdin their parent held, nothing here notices
# the parent going, so the server checks: once it has been handed to another
# parent, the test is gone and nobody will ever ask it anything again. The
# test names itself in LEGACY_HTTP_PARENT because a test killed while this
# server was still compiling has already handed it on before any getppid here
# could see the original.
my $parent = $ENV{LEGACY_HTTP_PARENT} // getppid;
Mojo::IOLoop->recurring(0.5 => sub { exit 0 if getppid != $parent });

Mojo::IOLoop->start;
