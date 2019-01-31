use Mojo::Base -strict;
use Mojo::Redis;
use Test::More;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis               = Mojo::Redis->new($ENV{TEST_ONLINE});
my $channel             = "test:reconnect:$$";
my $expected_reconnects = 3;
my ($pubsub_id, @before_connect, @disconnect, @payloads, @reconnect);

note 'setup pubsub';
my $pubsub = $redis->pubsub;
$pubsub->reconnect_interval(0.3);

$pubsub->on(before_connect => sub { push @before_connect, $_[1] });
$pubsub->on(disconnect     => sub { push @disconnect,     $_[1] });
$pubsub->on(reconnect      => sub { push @reconnect,      $_[1] });
$pubsub->on(reconnect => sub { shift->notify($channel => 'reconnected') });

$pubsub->on(
  before_connect => sub {
    my ($pubsub, $conn) = @_;
    $conn->write_p(qw(CLIENT ID))->then(sub {
      $pubsub_id = shift;
      Mojo::IOLoop->timer(0.1 => sub { $pubsub->notify($channel => 'kill') });
    });
  }
);

note 'reconnect enabled';
$pubsub->listen($channel => \&gather);
$pubsub->listen("$channel:$_" => sub { }) for 1 .. 4;
Mojo::IOLoop->start;
is_deeply \@payloads, [qw(kill reconnected) x $expected_reconnects], 'got payloads';
is @before_connect, $expected_reconnects + 1, 'got before_connect events';
is @reconnect,  $expected_reconnects, 'got reconnect events';
is @disconnect, $expected_reconnects, 'got disconnect events';
isnt $before_connect[0], $before_connect[1], 'fresh connection';

note 'reconnect disabled';
(@before_connect, @disconnect, @reconnect) = ();
$pubsub->reconnect_interval(-1);
$pubsub->on(
  disconnect => sub {
    Mojo::IOLoop->timer(0.5 => sub { Mojo::IOLoop->stop });
  }
);
Mojo::IOLoop->timer(0.1 => sub { $pubsub->connection->disconnect });
Mojo::IOLoop->start;
is @before_connect + @reconnect, 0, 'got no before_connect or reconnect events';
is @disconnect, 1, 'got only disconnect event';

done_testing;

sub gather {
  my ($pubsub, $payload) = @_;
  note "---payload=($payload)";
  push @payloads, $payload;

  if ($payload eq 'kill') {
    $pubsub->db->client_p(KILL => ID => $pubsub_id);
  }
  elsif ($payload eq 'reconnected') {
    Mojo::IOLoop->stop if @disconnect == $expected_reconnects;
  }
}
