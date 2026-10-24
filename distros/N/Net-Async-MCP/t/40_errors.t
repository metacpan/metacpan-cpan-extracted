use strict;
use warnings;
use Test2::V0;

use IO::Async::Loop;

use Net::Async::MCP::Transport::HTTP;
use Net::Async::MCP::Transport::InProcess;
use Net::Async::MCP::Transport::Stdio;

# What a server error fails a Future with. The message is the whole report a
# caller used to get, and a code is not recoverable from it: -32601 and -32602
# read the same to a regex that does not already know the wording, and
# error->{data} never appears in it at all. So every transport fails a JSON-RPC
# error the way Future's ( $message, $category, @details ) convention asks for
# it - ( $message, mcp => $error ) - which leaves the scalar context of
# ->failure byte-identical to what it was and hands the list context the raw
# error object.
#
# Two things are asserted per transport, and both of them matter: that the
# message did not move, since every existing caller reads it, and that the
# error object arrives with its code and its data, since a caller that has to
# renegotiate a protocol version reads error->{data}{supported} and nothing
# else will do. The third is that a failure which is not a JSON-RPC error
# carries no category: if it did, the category would say nothing.

# The renegotiation case, verbatim: an MCP server refusing a protocol version
# answers -32602 and names the versions it does speak in error->{data}.
my %PROTOCOL_ERROR = (
  code    => -32602,
  message => 'Unsupported protocol version',
  data    => { supported => [ '2026-07-28', '2025-06-18' ] },
);

my $PROTOCOL_MESSAGE = 'MCP error -32602: Unsupported protocol version';

# InProcess. A stub server rather than a real MCP::Server: what is under test
# is how a JSON-RPC error response is turned into a failure, and a stub is the
# only way to get exactly the error object the assertions name.
{
  package Test::ErrorServer;
  sub new { bless {}, shift }
  sub handle {
    my ( $self, $request ) = @_;
    return undef unless defined $request->{id};
    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      error   => { %PROTOCOL_ERROR },
    };
  }
}

# Answers a request with nothing at all, which is not a JSON-RPC error but a
# transport-level complaint about the server.
{
  package Test::SilentServer;
  sub new { bless {}, shift }
  sub handle { return undef }
}

{
  my $transport = Net::Async::MCP::Transport::InProcess->new(
    server => Test::ErrorServer->new,
  );

  my $f = $transport->send_request('server/discover');
  ok($f->is_failed, 'in-process server error fails the future');

  my $message = $f->failure;
  is($message, $PROTOCOL_MESSAGE, 'the message is unchanged in scalar context');

  my ( undef, $category, $error ) = $f->failure;
  is($category, 'mcp', 'a JSON-RPC error is categorised as mcp');
  is($error->{code}, -32602, 'the raw error object carries the code');
  is($error->{data}{supported}, [ '2026-07-28', '2025-06-18' ],
    'and the data a caller has to renegotiate from');
  is($error, { %PROTOCOL_ERROR }, 'the error object is the one the server sent');
}

{
  my $transport = Net::Async::MCP::Transport::InProcess->new(
    server => Test::SilentServer->new,
  );

  my $f = $transport->send_request('server/discover');
  my @failure = $f->failure;
  is($failure[0], 'No response from MCP server',
    'a transport-level failure keeps its message');
  is(scalar @failure, 1,
    'and carries no category, so mcp means a server error and nothing else');
}

# InProcess, a server object answering in shapes JSON-RPC does not have.
# MCP::Server itself always renders an error object with a code, but this
# transport takes any object with a handle() method - a subclass, a wrapper, a
# Mojo::Promise resolving to whatever it was given - so its answer is read with
# the same care as one off the wire: an "error" that is no error object must
# neither be reached into, which dies in the caller's face, nor be read as
# success. Each request names the shape it wants back as its method.
{
  package Test::ForeignErrorServer;
  my %answer = (
    string         => { error => 'nope' },
    array          => { error => [ 'nope', 1 ] },
    number         => { error => 42 },
    zero           => { error => 0 },
    no_code        => { error => { message => 'nope' } },
    null_alone     => { error => undef },
    null_on_result => { error => undef, result => { ok => 1 } },
  );
  sub new { bless {}, shift }
  sub handle {
    my ( $self, $request ) = @_;
    return {
      jsonrpc => '2.0',
      id      => $request->{id},
      %{ $answer{ $request->{method} } },
    };
  }
}

{
  my $transport = Net::Async::MCP::Transport::InProcess->new(
    server => Test::ForeignErrorServer->new,
  );

  # The eval turns a die inside send_request into a failed assertion rather
  # than the end of the test file.
  my $answer = sub {
    my ( $shape ) = @_;
    my $f = eval { $transport->send_request($shape) };
    ok($f, 'an answer of shape '.$shape.' does not die') or diag $@;
    return $f // Future->done;
  };

  for my $case (
    [ string  => 'MCP in-process error response: nope',              'a string error' ],
    [ array   => 'MCP in-process error response: ["nope",1]',        'an array error' ],
    [ number  => 'MCP in-process error response: 42',                'a number error' ],
    [ zero    => 'MCP in-process error response: 0',                 'a false number error' ],
    [ no_code => 'MCP in-process error response: {"message":"nope"}', 'an error object without a code' ],
  ) {
    my ( $shape, $message, $what ) = @$case;
    my $f = $answer->($shape);
    ok($f->is_failed, 'in process, '.$what.' fails the request');
    my @failure = $f->is_failed ? $f->failure : ();
    is($failure[0], $message, $what.' fails with the text it carries');
    is(scalar @failure, 1,
      $what.' carries no category, having no error object to hand over');
  }

  {
    my $f = $answer->('null_alone');
    ok($f->is_failed, 'in process, a null error without a result fails the request');
    my @failure = $f->is_failed ? $f->failure : ();
    is($failure[0], 'MCP in-process invalid response: a null error and no result',
      'saying what was missing');
    is(scalar @failure, 1, 'and carries no category');
  }

  {
    my $f = $answer->('null_on_result');
    ok($f->is_done, 'in process, a null error next to a result is a success');
    is($f->is_done ? $f->result : undef, { ok => 1 }, 'with that result');
  }
}

# Stdio. The response has to come off the wire for this to prove anything, so
# the subprocess is a JSON-RPC server of three lines that answers every request
# with the same error.
{
  my $loop = IO::Async::Loop->new;

  my $transport = Net::Async::MCP::Transport::Stdio->new(
    command => [
      $^X, '-MJSON::MaybeXS', '-e', q{
        my $json = JSON::MaybeXS->new(utf8 => 1);
        $| = 1;
        while (defined(my $line = <STDIN>)) {
          chomp $line;
          next if $line eq '';
          my $message = $json->decode($line);
          next unless defined $message->{id};
          print $json->encode({
            jsonrpc => '2.0',
            id      => $message->{id},
            error   => {
              code    => -32602,
              message => 'Unsupported protocol version',
              data    => { supported => [ '2026-07-28', '2025-06-18' ] },
            },
          }), "\n";
        }
      },
    ],
  );
  $loop->add($transport);

  my $f = $transport->send_request('server/discover');
  $f->await;
  ok($f->is_failed, 'a JSON-RPC error read from stdout fails the future');

  my $message = $f->failure;
  is($message, $PROTOCOL_MESSAGE, 'the message is unchanged in scalar context');

  my ( undef, $category, $error ) = $f->failure;
  is($category, 'mcp', 'a JSON-RPC error is categorised as mcp');
  is($error->{code}, -32602, 'the raw error object carries the code');
  is($error->{data}{supported}, [ '2026-07-28', '2025-06-18' ],
    'and the data a caller has to renegotiate from');

  $transport->close->get;

  # A dead subprocess is this transport's own failure, not the server's.
  my @failure = $transport->send_request('ping')->failure;
  is($failure[0], 'MCP server process exited (code 0)',
    'a transport-level failure says how the process ended');
  is(scalar @failure, 1, 'and carries no category');

  $loop->remove($transport);
}

# Stdio, a server that answers in shapes JSON-RPC does not have. The subprocess
# is whatever the host was told to run, so what it writes is foreign input: an
# "error" that is no error object must neither be reached into - which dies
# inside the read callback, takes the loop down with it and leaves the request
# pending forever - nor be read as success. Each request names the shape it
# wants back as its method, so one subprocess serves every case, and the last
# request proves the transport still answers after all of them.
{
  my $loop = IO::Async::Loop->new;

  my $transport = Net::Async::MCP::Transport::Stdio->new(
    command => [
      $^X, '-MJSON::MaybeXS', '-e', q{
        my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
        my %answer = (
          string         => { error => 'nope' },
          array          => { error => [ 'nope', 1 ] },
          number         => { error => 42 },
          zero           => { error => 0 },
          no_code        => { error => { message => 'nope' } },
          null_alone     => { error => undef },
          null_on_result => { error => undef, result => { ok => 1 } },
          proper         => { result => { ok => 1 } },
        );
        $| = 1;
        while (defined(my $line = <STDIN>)) {
          chomp $line;
          next if $line eq '';
          my $message = $json->decode($line);
          next unless defined $message->{id};
          print $json->encode({
            jsonrpc => '2.0',
            id      => $message->{id},
            %{ $answer{ $message->{method} } },
          }), "\n";
        }
      },
    ],
  );
  $loop->add($transport);

  # The await sits in an eval so that a read callback dying in the loop shows
  # up as a failed assertion here rather than as the end of the test file.
  my $answer = sub {
    my ( $shape ) = @_;
    my $f = $transport->send_request($shape);
    my $survived = eval { $f->await; 1 };
    ok($survived, 'the loop survives an answer of shape '.$shape)
      or diag $@;
    return $f;
  };

  for my $case (
    [ string  => 'MCP stdio error response: nope',              'a string error' ],
    [ array   => 'MCP stdio error response: ["nope",1]',        'an array error' ],
    [ number  => 'MCP stdio error response: 42',                'a number error' ],
    [ zero    => 'MCP stdio error response: 0',                 'a false number error' ],
    [ no_code => 'MCP stdio error response: {"message":"nope"}', 'an error object without a code' ],
  ) {
    my ( $shape, $message, $what ) = @$case;
    my $f = $answer->($shape);
    ok($f->is_failed, $what.' fails the request');
    my @failure = $f->is_failed ? $f->failure : ();
    is($failure[0], $message, $what.' fails with the text it carries');
    is(scalar @failure, 1,
      $what.' carries no category, having no error object to hand over');
  }

  # JSON-RPC 1.0 put "error": null next to every result, and some servers still
  # do: alongside a result it says nothing. On its own it answers nothing, and
  # reporting that as a success would hand the caller an undef it never asked
  # for.
  {
    my $f = $answer->('null_alone');
    ok($f->is_failed, 'a null error without a result fails the request');
    my @failure = $f->is_failed ? $f->failure : ();
    is($failure[0], 'MCP stdio invalid response: a null error and no result',
      'saying what was missing');
    is(scalar @failure, 1, 'and carries no category');
  }

  {
    my $f = $answer->('null_on_result');
    ok($f->is_done, 'a null error next to a result is a success');
    is($f->is_done ? $f->result : undef, { ok => 1 }, 'with that result');
  }

  {
    my $f = $answer->('proper');
    ok($f->is_done, 'the transport still answers after every foreign shape');
    is($f->is_done ? $f->result : undef, { ok => 1 }, 'with the result sent');
  }

  $transport->close->get;
  $loop->remove($transport);
}

sub response {
  my ( $code, $content_type, $content ) = @_;
  return HTTP::Response->new($code, undef,
    [ 'Content-Type' => $content_type ], $content);
}

# HTTP. HTTP::Message reaches this distribution only through Net::Async::HTTP,
# which is a recommendation and not a requirement, so the responses these tests
# are built from may not be constructible. Only this section depends on it -
# the two transports above are testable either way, which is why the skip sits
# here and not on the whole file.
subtest 'HTTP transport' => sub {
  skip_all 'HTTP::Message is required for the HTTP transport tests'
    unless eval { require HTTP::Response; 1 };

  my $transport = Net::Async::MCP::Transport::HTTP->new(
    url => 'http://mcp.invalid/mcp',
  );

  my $body = '{"jsonrpc":"2.0","id":1,"error":{"code":-32602,'
    . '"message":"Unsupported protocol version",'
    . '"data":{"supported":["2026-07-28","2025-06-18"]}}}';

  # An MCP server renders a rejected _meta with HTTP 400, so the JSON body of a
  # non-2xx response is where a renegotiable error actually shows up.
  {
    my $f = $transport->_handle_response(response(400, 'application/json', $body));

    my $message = $f->failure;
    is($message, $PROTOCOL_MESSAGE, 'the message is unchanged in scalar context');

    my ( undef, $category, $error ) = $f->failure;
    is($category, 'mcp', 'a JSON-RPC error is categorised as mcp');
    is($error->{code}, -32602, 'the raw error object carries the code');
    is($error->{data}{supported}, [ '2026-07-28', '2025-06-18' ],
      'and the data a caller has to renegotiate from');
  }

  # The same error arriving on an event stream instead. It travels a different
  # code path to the same failure, and a caller cannot tell from the outside
  # which one answered it.
  {
    my $f = $transport->_handle_response(
      response(200, 'text/event-stream', "data: $body\n\n"));

    my $message = $f->failure;
    is($message, $PROTOCOL_MESSAGE, 'an SSE error keeps the same message');

    my ( undef, $category, $error ) = $f->failure;
    is($category, 'mcp', 'and is categorised as mcp too');
    is($error->{data}{supported}, [ '2026-07-28', '2025-06-18' ],
      'with the same data behind it');
  }

  # A notification is answered with a status and no body this client reads, but
  # a server that refuses one still refuses it as JSON-RPC.
  {
    my $f = $transport->_handle_notification_response(
      response(400, 'application/json', $body));

    my $message = $f->failure;
    is($message, $PROTOCOL_MESSAGE, 'a refused notification keeps the same message');

    my ( undef, $category, $error ) = $f->failure;
    is($category, 'mcp', 'and is categorised as mcp as well');
    is($error->{code}, -32602, 'carrying the error object the body held');
  }

  # A status line is not a JSON-RPC error, and neither is a JSON body whose
  # "error" is a bare string - the shape MCP::Server's own HTTP transport
  # renders its refusals in. Both keep their message and stay uncategorised.
  {
    my @failure = $transport->_handle_response(
      response(404, 'text/plain', 'Not Found'))->failure;
    like($failure[0], qr/^MCP HTTP error: 404/, 'an HTTP failure keeps its message');
    is(scalar @failure, 1, 'and carries no category');
  }

  {
    my @failure = $transport->_handle_response(
      response(200, 'application/json', '{"error":"Method not allowed"}'))->failure;
    like($failure[0], qr/^MCP HTTP error response: Method not allowed/,
      'a foreign error shape keeps its message');
    is(scalar @failure, 1,
      'and carries no category, having no error object to hand over');
  }

  # "error": null reads the same over HTTP as over stdio, in a JSON body and on
  # an event stream alike: next to a result it is the JSON-RPC 1.0 habit and
  # says nothing, on its own it answers nothing, and an undef handed out as
  # the result would be a success the server never reported.
  for my $case (
    [ 'a JSON body',      'application/json',  sub { $_[0] } ],
    [ 'an event stream',  'text/event-stream', sub { "data: $_[0]\n\n" } ],
  ) {
    my ( $where, $content_type, $wrap ) = @$case;

    {
      my $f = $transport->_handle_response(response(200, $content_type,
        $wrap->('{"jsonrpc":"2.0","id":1,"error":null}')));
      ok($f->is_failed, 'in '.$where.', a null error without a result fails the request');
      my @failure = $f->is_failed ? $f->failure : ();
      is($failure[0], 'MCP HTTP invalid response: a null error and no result',
        'saying what was missing');
      is(scalar @failure, 1, 'and carries no category');
    }

    {
      my $f = $transport->_handle_response(response(200, $content_type,
        $wrap->('{"jsonrpc":"2.0","id":1,"error":null,"result":{"ok":1}}')));
      ok($f->is_done, 'in '.$where.', a null error next to a result is a success');
      is($f->is_done ? $f->result : undef, { ok => 1 }, 'with that result');
    }
  }

  # A non-2xx whose body holds no JSON-RPC error must still fall back to the
  # status line. The lookup answers with a list now, and an empty body is where
  # an "undef" left over from the scalar days would become a one-element list
  # and fail the request with an undefined message.
  {
    my @failure = $transport->_handle_response(
      response(500, 'application/json', ''))->failure;
    like($failure[0], qr/^MCP HTTP error: 500/,
      'a non-2xx with an empty body falls back to the status line');
    is(scalar @failure, 1, 'and carries no category');
  }
};

done_testing;
