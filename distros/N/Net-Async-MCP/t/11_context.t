use strict;
use warnings;
use Test2::V0;

use Net::Async::MCP::Transport::InProcess;

# What the in-process transport hands handle() as its second argument, which is
# the one thing about this transport that depends on what is installed. MCP is
# a recommendation of this distribution and not a requirement, so this file
# runs either way and asserts the whole rule rather than the half of it that
# happens to be reachable here: a fresh MCP::Server::Context per call where
# that class can be loaded, and no second argument at all where it cannot.
#
# Both halves matter. MCP::Server >= 0.10 calls progress_token, has_scope and
# insufficient_scope straight on the context for nearly every request past
# initialize and ping, so a real server has to get a real context and nothing
# that merely looks like one. And a transport that cannot even be loaded
# without MCP is not the optional dependency this distribution claims to have,
# which is what took t/00_load.t and t/40_errors.t down on a smoker.
my $HAS_CONTEXT = eval { require MCP::Server::Context; 1 } || 0;

# Anything with a handle() method is a server to this transport, which is
# exactly why the context may be absent: without MCP no other kind exists. This
# one records what it was called with rather than what it was asked.
{
  package Test::RecordingServer;
  sub new { bless { calls => [] }, shift }
  sub handle {
    my ( $self, $request, @context ) = @_;
    push @{ $self->{calls} }, \@context;
    return undef unless defined $request->{id};
    return { jsonrpc => '2.0', id => $request->{id}, result => {} };
  }
  sub calls { $_[0]->{calls} }
}

my $server = Test::RecordingServer->new;
my $transport = Net::Async::MCP::Transport::InProcess->new(server => $server);

ok($transport->send_request('ping')->is_done, 'a request reaches the server');
ok($transport->send_notification('notifications/initialized')->is_done,
  'and so does a notification');

my ( $request_context, $notification_context ) = @{ $server->calls };
is(scalar @{ $server->calls }, 2, 'both arrived');

if ($HAS_CONTEXT) {
  is(scalar @$request_context, 1,
    'a request carries one argument past the request itself');
  is(ref $request_context->[0], 'MCP::Server::Context',
    'and it is a context, not a hashref standing in for one');

  is(scalar @$notification_context, 1, 'a notification carries one too');
  is(ref $notification_context->[0], 'MCP::Server::Context',
    'and it is a context as well');

  # Per request, not per transport: a context accumulates request state, so one
  # shared between calls would carry the last request's into the next.
  ok($request_context->[0] != $notification_context->[0],
    'a fresh context for every call');
}
else {
  is(scalar @$request_context, 0,
    'without MCP a request carries nothing past the request itself');
  is(scalar @$notification_context, 0,
    'and neither does a notification');
}

done_testing;
