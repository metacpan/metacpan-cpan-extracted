use strict;
use warnings;
use Test2::V0;

use IO::Async::Loop;
use JSON::MaybeXS;
use Net::Async::MCP;
use Net::Async::MCP::Transport::Stdio;
use File::Basename qw( dirname );
use Scalar::Util qw( weaken );

my $server_script = dirname(__FILE__) . '/bin/test_mcp_server.pl';

# Create MCP client with Stdio transport
my $loop = IO::Async::Loop->new;
my $mcp = Net::Async::MCP->new(
  command => [ $^X, $server_script ],
);
$loop->add($mcp);

# Test initialize (current protocol: server/discover + _meta)
{
  my $result = $mcp->initialize->get;
  is($result->{_meta}{'io.modelcontextprotocol/serverInfo'}{name},
    'TestServer', 'server name in result._meta serverInfo');
  ok($result->{capabilities}, 'capabilities returned');
  is($mcp->server_info->{name}, 'TestServer', 'server_info accessor');
}

# Test ping
{
  my $ok = $mcp->ping->get;
  ok($ok, 'ping succeeds');
}

# Test list_tools
{
  my $tools = $mcp->list_tools->get;
  is(scalar @$tools, 2, 'two tools listed');

  my %by_name = map { $_->{name} => $_ } @$tools;
  ok($by_name{echo}, 'echo tool exists');
  ok($by_name{add}, 'add tool exists');
}

# Test call_tool - echo
{
  my $result = $mcp->call_tool('echo', { message => 'via stdio' })->get;
  ok(!$result->{isError}, 'echo not an error');
  is($result->{content}[0]{text}, 'Echo: via stdio', 'echo result correct');
}

# Test call_tool - add
{
  my $result = $mcp->call_tool('add', { a => 10, b => 20 })->get;
  ok(!$result->{isError}, 'add not an error');
  is($result->{content}[0]{text}, '30', 'add result correct');
}

# Test multiple rapid requests
{
  my @futures;
  for my $i (1..5) {
    push @futures, $mcp->call_tool('echo', { message => "msg$i" });
  }
  for my $i (1..5) {
    my $result = $futures[$i-1]->get;
    is($result->{content}[0]{text}, "Echo: msg$i", "rapid request $i correct");
  }
}

# Test shutdown
{
  my $ok = $mcp->shutdown->get;
  ok($ok, 'shutdown succeeds');
}

# ping is a transport-level liveness check, so once the subprocess is gone it
# must report that instead of claiming the server is still reachable.
{
  my $f = $mcp->ping;
  ok($f->failure, 'ping fails after the subprocess has exited');
  like($f->failure, qr/not alive/, 'failure names a dead transport');
}

# Cancellation. On stdio the only way to tell a server to stop is the
# notifications/cancelled notification, and the only handle a caller has on a
# request is the future send_request returned - so cancelling that future is
# what has to produce it. The Perl test server ignores notifications entirely,
# so what is asserted here is the wire content, not a server-side effect.
{
  my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

  # Records every line it is given and answers every request with the
  # transcript so far. That makes what reached the subprocess assertable from
  # a normal response, with no log file to poll and no sleeps to race.
  my $recorder = Net::Async::MCP::Transport::Stdio->new(
    command => [
      $^X, '-MJSON::MaybeXS', '-e', q{
        my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
        my @seen;
        $| = 1;
        while (defined(my $line = <STDIN>)) {
          chomp $line;
          next if $line eq '';
          push @seen, $line;
          my $message = $json->decode($line);
          next unless defined $message->{id};
          print $json->encode({
            jsonrpc => '2.0',
            id      => $message->{id},
            result  => { seen => [ @seen ] },
          }), "\n";
        }
      },
    ],
  );
  $loop->add($recorder);

  my $cancelled = $recorder->send_request('tools/call', { name => 'slow' });
  is(scalar keys %{ $recorder->{pending} }, 1, 'request is pending before cancellation');

  $cancelled->cancel;
  is(scalar keys %{ $recorder->{pending} }, 0, 'cancellation drops the pending entry');

  # The recorder does answer the cancelled request too; that response has to
  # land on nothing and must not be mistaken for the answer to this probe.
  my $seen = $recorder->send_request('ping')->get->{seen};
  is(scalar @$seen, 3, 'request, cancellation and probe reached the subprocess');

  my $note = $json->decode($seen->[1]);
  is($note->{jsonrpc}, '2.0', 'cancellation is JSON-RPC 2.0');
  is($note->{method}, 'notifications/cancelled', 'cancellation uses the notification method');
  ok(!exists $note->{id}, 'cancellation is a notification, carrying no id of its own');
  is($note->{params}{requestId}, $json->decode($seen->[0])->{id},
    'requestId names the request that was cancelled');

  # A request that already has its answer must send nothing when cancelled,
  # otherwise every completed call would leave a stray notification behind.
  my $answered = $recorder->send_request('ping');
  my $before = scalar @{ $answered->get->{seen} };
  $answered->cancel;
  ok($answered->is_done, 'an answered request stays done through ->cancel');
  my $after = $recorder->send_request('ping')->get->{seen};
  is(scalar @$after, $before + 1, 'cancelling a finished request sends nothing');

  # close marks the transport closed while the subprocess is still dying, so
  # a cancellation in that window must not write into the doomed pipe.
  my $in_flight = $recorder->send_request('tools/call', { name => 'doomed' });
  my $closing = $recorder->close;
  ok(!$in_flight->is_ready, 'request is still pending right after close');
  ok(lives { $in_flight->cancel }, 'cancelling on a closed transport does not die')
    or note $@;
  is(scalar keys %{ $recorder->{pending} }, 0,
    'cancellation on a closed transport still drops the pending entry');
  $closing->get;
}

# Retention. The stdout on_read and on_finish callbacks live on the process and
# its child streams, both of which the transport owns, so capturing the
# transport strongly in them closes a cycle no refcount breaks: the transport
# then outlives its own client, holding a subprocess's file handles open for as
# long as the program runs. Nothing about this is timing-dependent - every step
# below either blocks on a future or is synchronous - so a defined $probe here
# means a callback took a strong reference again, not a slow machine.
{
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
            result  => {},
          }), "\n";
        }
      },
    ],
  );
  $loop->add($transport);

  # A round trip, so the stdout read path has actually run and not just been
  # installed, and the process has a live child watch when close kills it.
  $transport->send_request('ping')->get;
  $transport->close->get;
  $loop->remove($transport);

  weaken(my $probe = $transport);
  undef $transport;
  is($probe, undef, 'transport is freed once closed, removed from the loop and dropped');
}

# Server-initiated notifications. A server writes notifications/progress and
# notifications/message on its own while a long running call is still in
# flight, so a line with no id has to reach the caller as it lands instead of
# being dropped for answering no request. The subprocess below writes all four
# lines before the one that answers, so the request's own future arriving is
# proof that everything ahead of it was read: nothing here sleeps or polls.
{
  my @notes;
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
            method  => 'notifications/progress',
            params  => { progressToken => 'tok', progress => 1 },
          }), "\n";
          # A request of the server's own, numbered from the server's counter
          # and so colliding with the client's pending id.
          print $json->encode({
            jsonrpc => '2.0',
            id      => $message->{id},
            method  => 'roots/list',
          }), "\n";
          # Neither a request nor a response nor a notification.
          print $json->encode({ jsonrpc => '2.0' }), "\n";
          print $json->encode({
            jsonrpc => '2.0',
            id      => $message->{id},
            result  => { answered => $message->{method} },
          }), "\n";
        }
      },
    ],
    on_notification => sub {
      my ( undef, $note ) = @_;
      push @notes, $note;
    },
  );
  $loop->add($transport);

  my $result = $transport->send_request('tools/call', { name => 'slow' })->get;
  ok(defined $result,
    'a server-initiated request sharing the id does not settle the pending request');
  is($result, { answered => 'tools/call' }, 'the response is what settles it');

  is(scalar @notes, 1, 'exactly the one notification line was delivered');
  is($notes[0]{method}, 'notifications/progress',
    'the notification arrives with the method the server sent');
  is($notes[0]{params}{progress}, 1, 'and with its params');

  # Net::Async::MCP hands its own on_notification down with configure, so a
  # handler set after construction has to take over from there.
  my @later;
  $transport->configure(on_notification => sub {
    my ( undef, $note ) = @_;
    push @later, $note;
  });
  $transport->send_request('ping')->get;
  is(scalar @later, 1, 'a handler set through configure receives notifications');
  is(scalar @notes, 1, 'and the handler it replaced receives no more');

  $transport->close->get;
  $loop->remove($transport);
}

# The same notification, but arriving where a caller of this distribution
# actually waits for it: on the client, through an on_notification given to
# Net::Async::MCP rather than to the transport. Nothing of the delivery is
# retested here - the block above owns that - only that a handler set on the
# client reaches the transport this client built at all, and that it is called
# with the client, which is the promise every event of this client makes and
# must not depend on which transport is underneath.
{
  my @notifying = (
    $^X, '-MJSON::MaybeXS', '-e', q{
      my $json = JSON::MaybeXS->new(utf8 => 1);
      $| = 1;
      while (defined(my $line = <STDIN>)) {
        chomp $line;
        next if $line eq '';
        my $message = $json->decode($line);
        next unless defined $message->{id};
        # Written before the response, so the request's own future arriving is
        # proof the notification was read: nothing here sleeps or polls.
        print $json->encode({
          jsonrpc => '2.0',
          method  => 'notifications/progress',
          params  => { progressToken => 'tok', progress => $message->{id} },
        }), "\n";
        print $json->encode({
          jsonrpc => '2.0',
          id      => $message->{id},
          result  => { content => [ { type => 'text', text => 'done' } ] },
        }), "\n";
      }
    },
  );

  my @seen;
  my $client = Net::Async::MCP->new(
    command         => [@notifying],
    on_notification => sub { push @seen, [@_] },
  );
  $loop->add($client);

  my $result = $client->call_tool('slow', {})->get;
  is($result->{content}[0]{text}, 'done', 'the call the notification belongs to returns');

  is(scalar @seen, 1, 'the notification written before that result reached the client');
  is($seen[0][0], exact_ref($client),
    'with the client as first argument, not the transport that read the line');
  is($seen[0][1]{method}, 'notifications/progress',
    'and the notification as it stood on the wire');

  # Set on a client that is already in a loop, and so long after the transport
  # was built: a caller that wants the progress of one long call sets a handler
  # right before making it.
  my @later;
  $client->configure(on_notification => sub { push @later, [@_] });
  $client->call_tool('slow', {})->get;

  is(scalar @later, 1, 'a handler configured on a running client gets the next one');
  is($later[0][0], exact_ref($client), 'with the client in front of it as well');
  is(scalar @seen, 1, 'and the handler it replaced receives no more');

  # What must not travel with it. The Stdio transport croaks on a configuration
  # key it does not know, so a client handing its whole transport-bound set
  # down would die here rather than quietly keep a header for a transport that
  # sends none.
  ok(lives { $client->configure(headers => { Authorization => 'Bearer t' }) },
    'an HTTP-only key configured on a stdio client does not reach the transport')
    or note $@;
  is($client->headers, { Authorization => 'Bearer t' },
    'the client keeps it all the same, for a transport that would take it');
  ok(!exists $client->{transport}{headers}, 'and the transport was never handed it');

  $client->shutdown->get;
  $loop->remove($client);
}

# A request a server answers with a notification has nothing to settle it.
# MCP::Server >= 0.15 serves subscriptions/listen over stdio too, and answers
# it with notifications/subscriptions/acknowledged - a notification, not a
# response - so the acknowledgement reaches on_notification while the request
# itself stays pending. The transport therefore refuses resolve_on_notification
# outright rather than let subscriptions_listen hang: it has no way of
# settling a request from a notification, and one that went out anyway would
# open a subscription on the server that nothing here could ever stop.
{
  my @notes;
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
          if (($message->{method} // '') eq 'subscriptions/listen') {
            print $json->encode({
              jsonrpc => '2.0',
              method  => 'notifications/subscriptions/acknowledged',
              params  => {
                _meta => { 'io.modelcontextprotocol/subscriptionId' => $message->{id} },
                notifications => { toolsListChanged => \1 },
              },
            }), "\n";
            next;
          }
          print $json->encode({
            jsonrpc => '2.0',
            id      => $message->{id},
            result  => {},
          }), "\n";
        }
      },
    ],
    on_notification => sub {
      my ( undef, $note ) = @_;
      push @notes, $note;
    },
  );
  $loop->add($transport);

  my $subscription = $transport->send_request('subscriptions/listen',
    { notifications => { toolsListChanged => 1 } });

  # The server answers by notification, so the request has nothing to settle
  # it. A follow-up round trip is what proves the acknowledgement was read:
  # its response arrives behind it on the one channel, and nothing here
  # sleeps or polls.
  $transport->send_request('ping')->get;

  ok(!$subscription->is_ready,
    'a request the server answers with a notification has nothing to settle it');
  is(scalar @notes, 1, 'the acknowledgement reached on_notification');
  is($notes[0]{method}, 'notifications/subscriptions/acknowledged',
    'as a notification, the way MCP::Server >= 0.15 answers over stdio');
  is($notes[0]{params}{_meta}{'io.modelcontextprotocol/subscriptionId'}, 1,
    'carrying the subscription id the server handed out');

  # What a caller of subscriptions_listen actually does, which is how the
  # transport is asked to settle a request from a notification. It cannot, so
  # the request fails on the spot rather than hang like the one above.
  my $refused = $transport->send_request('subscriptions/listen',
    { notifications => { toolsListChanged => 1 } },
    resolve_on_notification => 'notifications/subscriptions/acknowledged');

  is($refused->failure,
    'MCP subscriptions/listen is not usable over the stdio transport: the '
    . 'transport cannot settle a request from a notification '
    . '(resolve_on_notification)',
    'resolve_on_notification is refused loudly instead of ignored');
  is(scalar keys %{ $transport->{pending} }, 1,
    'the refused request is not sent and leaves nothing pending behind');

  # The one subscription request is still pending, with no response to come
  # and the process about to go away - settled by the close, which is the one
  # thing that can still settle it.
  $transport->close->get;
  ok($subscription->is_failed,
    'closing settles the request the server never answered');
  like($subscription->failure, qr/MCP server process exited/,
    'with the reason the answer is not coming');
  $loop->remove($transport);
}

# Retention on that path. The handler the client hands down is held by the
# transport, and the client holds the transport, so what reaches the transport
# must not hold the client: a strong reference there closes a cycle no refcount
# breaks, and the client - with the subprocess's file handles under it - would
# outlive every reference to it. Same question as the HTTP one in
# t/10_inprocess.t, asked on the path that now carries a handler too.
{
  my $client = Net::Async::MCP->new(
    command         => [ $^X, '-e', 'while (<STDIN>) {}' ],
    on_notification => sub { },
  );
  $loop->add($client);

  # Deliberately kept: the transport outliving this scope is what makes the
  # question sharp, since it is the transport that holds the handler.
  my $transport = $client->{transport};

  $client->shutdown->get;

  weaken( my $weak_client = $client );
  $loop->remove($client);
  undef $client;

  is($weak_client, undef,
    'a stdio client with an on_notification is freed once the loop lets go of it');
}

# A close and a request still running when the transport leaves the loop. The
# process is a child of the transport and goes out with it, which unwatches
# the child, so _on_finish never fires: the close future would wait for an
# exit nobody is watching for any more, and the request for an answer that
# cannot be read any more. Both are settled by the same hook, so both are
# exercised in one removal here. Nothing is timing-dependent: the loop does
# not run between the two sends and the remove, so neither the response nor
# on_finish can have arrived in the window either way.
{
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
            result  => {},
          }), "\n";
        }
      },
    ],
  );
  $loop->add($transport);

  # A round trip, so the process is up and has a live child watch for close to
  # take away again.
  $transport->send_request('ping')->get;

  my $unanswered = $transport->send_request('tools/call', { name => 'slow' });
  my $closing = $transport->close;
  ok(!$closing->is_ready, 'close is still pending while the process is dying');
  ok(!$unanswered->is_ready, 'and the request is still waiting for its answer');

  $loop->remove($transport);

  # Read out of the futures only once they are ready: Future::failure runs the
  # loop until the future is, so asking a still-orphaned one would hang here
  # rather than report the very thing this block is about.
  my $failure   = $closing->is_failed    ? scalar $closing->failure    : undef;
  my $abandoned = $unanswered->is_failed ? scalar $unanswered->failure : undef;

  ok($closing->is_ready, 'leaving the loop ends the close future instead of orphaning it');
  ok($closing->is_failed, 'it ends as a failure: nothing here observed the process exit');
  like($failure, qr/left the loop before it exited/,
    'the failure says why the exit will not be reported');

  ok($unanswered->is_ready, 'leaving the loop ends the pending request as well');
  ok($unanswered->is_failed, 'it too ends as a failure: its answer cannot arrive any more');
  like($abandoned, qr/left the loop before the request was answered/,
    'and names its own loss rather than the process exit');
  # Spelled out rather than left to isnt, which an absent failure would
  # satisfy on its own: what is asserted is that both arrived and that they
  # read differently, so unifying the two messages fails here too.
  ok(defined $abandoned && defined $failure && $abandoned ne $failure,
    'the two losses are told apart by their message');

  is(scalar keys %{ $transport->{pending} }, 0,
    'the pending table is emptied, so nothing is left for _on_finish to settle twice');
}

done_testing;
