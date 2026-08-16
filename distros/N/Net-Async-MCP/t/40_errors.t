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
  is($failure[0], 'MCP server process has exited',
    'a transport-level failure keeps its message');
  is(scalar @failure, 1, 'and carries no category');

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
