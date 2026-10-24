use strict;
use warnings;
use Test2::V0;

use Cwd qw( abs_path );
use File::Basename qw( dirname );
use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::MCP;
use Net::Async::MCP::Transport::Stdio;
use Time::HiRes qw( time );

# The request timeout over stdio. A server that lives but never answers is the
# one case nothing else here ends: the process does not exit, so no exit fails
# the request, and without a limit the caller waits forever. None of this
# needs MCP - the servers are hand-rolled.
#
# A client that waits for an answer that never comes hangs rather than fails;
# the alarm turns that into a failure of this file.
alarm 60;

my $legacy_server = abs_path(dirname(__FILE__)) . '/bin/legacy_mcp_server.pl';

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
my $loop = IO::Async::Loop->new;

# Alive, reading, and silent: it answers test/transcript with every line it
# has received so far and nothing else, so what reached it is assertable while
# every other request is left without an answer.
my @silent_server = ( $^X, '-MJSON::MaybeXS', '-e', q{
  my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
  my @seen;
  $| = 1;
  while (defined(my $line = <STDIN>)) {
    chomp $line;
    next if $line eq '';
    push @seen, $line;
    my $message = $json->decode($line);
    next unless ( $message->{method} // '' ) eq 'test/transcript';
    print $json->encode({
      jsonrpc => '2.0',
      id      => $message->{id},
      result  => { seen => [ @seen ] },
    }), "\n";
  }
} );

sub transcript {
  my ( $transport ) = @_;
  my $seen = $transport->send_request('test/transcript')->get->{seen};
  return [ map { $json->decode($_) } @$seen ];
}

sub wait_for { $loop->delay_future(after => $_[0])->get }

# The transport on its own: the request fails in finite time, in category
# timeout, and the server hears about it the way it hears about a cancel.
{
  my $transport = Net::Async::MCP::Transport::Stdio->new(
    command => \@silent_server,
    timeout => 0.5,
  );
  $loop->add($transport);

  my $started = time;
  my $f = $transport->send_request('tools/call', { name => 'never' });
  my ( $message, $category ) = $f->followed_by(sub { Future->done( $_[0] ) })
    ->get->failure;
  my $took = time - $started;

  is($category, 'timeout', 'an unanswered request fails in category timeout');
  is($message, 'MCP stdio request tools/call timed out after 0.5s',
    'with a message naming the method and the limit');
  ok($took >= 0.4 && $took < 5, 'after the timeout, not before and not forever')
    or note "took ${took}s";
  is(scalar keys %{ $transport->{pending} }, 0, 'and its pending entry is gone');

  my $seen = transcript($transport);
  is([ map { $_->{method} } @$seen ],
    [ 'tools/call', 'notifications/cancelled', 'test/transcript' ],
    'the server is sent notifications/cancelled');
  is($seen->[1]{params}{requestId}, $seen->[0]{id},
    'naming the request that timed out');
  ok(!exists $seen->[1]{id}, 'as a notification, carrying no id of its own');
  like($seen->[1]{params}{reason}, qr/timed out/, 'with a reason saying why');

  # A request answered in time stops its timer: nothing is cancelled once the
  # limit has passed, which would otherwise leave a stray notification behind
  # every successful call.
  my $before = scalar @{ transcript($transport) };
  wait_for(0.8);
  my $after = transcript($transport);
  is(scalar @$after, $before + 1, 'an answered request sends nothing when its limit passes');

  # Configured later, it applies to the requests sent after.
  $transport->configure(timeout => 0.2);
  $started = time;
  my $later = $transport->send_request('tools/call', { name => 'never' });
  is(( $later->followed_by(sub { Future->done( $_[0] ) })->get->failure )[1],
    'timeout', 'a timeout configured later applies to the next request');
  ok(time - $started < 0.45, 'with the new limit') or note time - $started;

  $transport->close->get;
  $loop->remove($transport);
}

# Without a timeout nothing changes: the request waits for as long as the
# server lives, and the exit is what ends it.
{
  my $transport = Net::Async::MCP::Transport::Stdio->new(
    command => \@silent_server,
  );
  $loop->add($transport);

  my $f = $transport->send_request('tools/call', { name => 'never' });
  wait_for(1);
  ok(!$f->is_ready, 'without a timeout an unanswered request keeps waiting');
  is(scalar keys %{ $transport->{pending} }, 1, 'and stays pending');
  is([ map { $_->{method} } @{ transcript($transport) } ],
    [ 'tools/call', 'test/transcript' ], 'and nothing is cancelled');

  $transport->close->get;
  like(scalar $f->failure, qr/^MCP server process exited/,
    'until the process exits');
  is(( $f->failure )[1], undef, 'which fails it without a category, as before');
  $loop->remove($transport);
}

# The client hands timeout to the stdio transport, which before took it for
# HTTP only - and leaves it alone where the caller never named it.
{
  my $mcp = Net::Async::MCP->new(command => \@silent_server, timeout => 0.5);
  $loop->add($mcp);
  is($mcp->{transport}{timeout}, 0.5, 'the client passes timeout to the stdio transport');
  $mcp->configure(timeout => 2);
  is($mcp->{transport}{timeout}, 2, 'and a later configure reaches it too');
  $mcp->{transport}->close->get;
  $loop->remove($mcp);

  my $plain = Net::Async::MCP->new(command => \@silent_server);
  $loop->add($plain);
  ok(!exists $plain->{transport}{timeout}, 'an unnamed timeout is not passed at all');
  $plain->{transport}->close->get;
  $loop->remove($plain);
}

# Through the client, the request timeout bounds the whole handshake: the
# probe runs out of it and is taken for a legacy server's silence, and the
# initialize that follows runs out of it too. So initialize fails in finite
# time, in category timeout, and both requests are cancelled at the server.
{
  my $mcp = Net::Async::MCP->new(
    command          => \@silent_server,
    timeout          => 0.5,
    discover_timeout => 30,
  );
  $loop->add($mcp);

  my $started = time;
  my $f = $mcp->initialize->followed_by(sub { Future->done( $_[0] ) })->get;
  ok($f->is_failed, 'initialize against a silent server fails');
  is(( $f->failure )[1], 'timeout', 'in category timeout');
  ok(time - $started < 5, 'long before discover_timeout');

  is([ map { $_->{method} } @{ transcript($mcp->{transport}) } ],
    [ 'server/discover', 'notifications/cancelled', 'initialize',
      'notifications/cancelled', 'test/transcript' ],
    'the probe and the initialize are each cancelled at the server');

  $mcp->{transport}->close->get;
  $loop->remove($mcp);
}

# The probe and the request timeout do not collide: a legacy server that
# leaves server/discover unanswered is still found legacy when the request
# timeout is the shorter limit, rather than failing the handshake.
{
  my $mcp = Net::Async::MCP->new(
    command          => [ $^X, $legacy_server ],
    env              => { LEGACY_MCP_DISCOVER => 'silent' },
    timeout          => 0.5,
    discover_timeout => 30,
  );
  $loop->add($mcp);

  my $started = time;
  ok(lives { $mcp->initialize->get }, 'a probe running out of timeout falls back')
    or note $@;
  ok($mcp->is_legacy, 'to the legacy handshake');
  ok(time - $started < 5, 'after timeout rather than discover_timeout');
  ok(lives { $mcp->list_tools->get }, 'and the connection keeps working') or note $@;

  $mcp->shutdown->get;
  $loop->remove($mcp);
}

done_testing;
