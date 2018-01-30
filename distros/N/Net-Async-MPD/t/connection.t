use strict;
use warnings;

# use Log::Any::Adapter;
# Log::Any::Adapter->set( 'Stderr', log_level => 'trace' );

use lib 't/lib';
use Test::More;
use Test::Server::MPD;
use Net::Async::MPD;
use Try::Tiny;
use IO::Async::Loop;
use Scope::Guard qw( scope_guard );
use Net::EmptyPort qw( empty_port );
use IO::Async::Timer::Periodic;

my $server;
sub start_server {
  $server->stop if $server and $server->is_running;

  $server = Test::Server::MPD->new(@_);

  my $start = try { $server->start } catch { $_ };
  plan skip_all => 'Could not start test MPD server' if $start =~ /not/;

  diag 'Started MPD server on port ' . $server->port;

  return $server;
}

start_server(
  profiles => {
    password => [qw( read add control admin )],
  },
);

{
  my $client = Net::Async::MPD->new(
    port => $server->port,
    auto_connect => 1,
  );
  my $future = $client->send('status');
  $client->catch( sub { ok 1, 'Error triggers error event' });

  try { $future->get }
  catch { like $_, qr/have permission/i, 'Caught forbidden command' };

  $client = Net::Async::MPD->new(
    port => $server->port,
    password => 'password',
    auto_connect => 1,
  );

  ok my $status = $client->get( 'status' ), 'Blocking call to status';
  is ref $status, 'HASH', 'Received status as hash reference';
}

start_server();

my $guard = scope_guard sub {
  $server->stop;
  diag 'Stopped Test MPD server';
};

{
  my $client = Net::Async::MPD->new( port => $server->port );

  try { $client->get( 'ping' ) }
  catch {
    like $_, qr/No connection/i, 'Die if sending a command without connection'
  };

  ok $client->connect, 'Established connection to server';
  ok $client->connect, 'Connect is idempotent';

  try { $client->send }
  catch { like $_, qr/need commands/i, 'Cannot send with no arguments' };

  my $future = $client->send( 'status', sub {
    ok 1, 'Status received';
    my $status = shift;
    is ref $status, 'HASH', 'Received result as hash';
  });
  $future->get;

  $client->send({ list => 1 }, [ 'stats', 'status' ],
    sub {
      ok 1, 'Sent a command list';
      is scalar @_, 2, 'Received multiple results from list';

      my ($stats, $status) = @_;
      is ref $stats, 'HASH', 'Received results from each command';
    }
  );

  $client->send({ list => 0 }, [ 'stats', 'status' ],
    sub {
      is scalar @_, 1, 'Received a single result from list';

      my ($combined) = @_;
      is ref $combined, 'HASH', 'Received results from each command';
    }
  );

  $client->send( { parser => sub { ok 1, 'Custom parser' } }, 'ping' )->get;
}

{
  my $catcher = Net::Async::MPD->new(
    port => $server->port,
    auto_connect => 1,
  );

  # We need another client to trigger the events
  my $thrower = Net::Async::MPD->new(
    port => $server->port,
    auto_connect => 1,
  );

  is $catcher->noidle, undef, 'noidle does nothing if not idling';

  my $timer = IO::Async::Timer::Periodic->new(
    first_interval => 1,
    interval => 1,
    on_tick => sub { $thrower->send( 'clear' ) },
  );
  IO::Async::Loop->new->add($timer);
  $timer->start;

  $catcher->on( playlist => sub {
    ok 1, 'Caught mixer event';

    $catcher->noidle;
    $catcher->noidle;

    ok 1, 'Calling noidle more than once is not a problem';

    $timer->stop;
  });

  $catcher->idle->get;
}

$server->stop;
{
  try {
    Net::Async::MPD->new(
      port => empty_port(),
      auto_connect => 1,
    );
  }
  catch {
    like $_, qr/MPD connect failed/i, 'Cannot connect to a non-extant MPD server';
  };
}

done_testing();
