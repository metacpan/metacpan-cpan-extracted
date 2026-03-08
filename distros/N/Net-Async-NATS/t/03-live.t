use strict;
use warnings;
use Test2::V0;

use IO::Async::Loop;
use Net::Async::NATS;

# Live test — requires a running NATS server
# Run with: TEST_NATS_HOST=localhost prove -lv t/03-live.t

my $host = $ENV{TEST_NATS_HOST} or do {
    skip_all 'Set TEST_NATS_HOST to run live tests';
};
my $port = $ENV{TEST_NATS_PORT} || 4222;

my $loop = IO::Async::Loop->new;
my $nats = Net::Async::NATS->new(
    host => $host,
    port => $port,
    name => 'net-async-nats-test',
);
$loop->add($nats);

# Connect
my $info = $loop->await( $nats->connect );
ok $nats->is_connected, 'connected to NATS';
ok $info->{server_id}, 'got server_id: ' . ($info->{server_id} // '?');
note "NATS version: $info->{version}";

# Ping
$loop->await( $nats->ping );
pass 'ping/pong ok';

# Pub/Sub
{
    my @received;
    my $sub = $loop->await( $nats->subscribe('test.nats.perl.>', sub {
        my ($subject, $payload, $reply_to) = @_;
        push @received, { subject => $subject, payload => $payload };
    }) );

    ok $sub->sid, 'subscribed with sid=' . $sub->sid;

    # Give the subscription time to register on the server
    $loop->await( $nats->ping );

    $loop->await( $nats->publish('test.nats.perl.hello', 'world') );
    $loop->await( $nats->publish('test.nats.perl.foo.bar', 'baz') );

    # Flush: another ping/pong round trip ensures messages are delivered
    $loop->await( $nats->ping );

    is scalar @received, 2, 'received 2 messages';
    is $received[0]{subject}, 'test.nats.perl.hello', 'first subject';
    is $received[0]{payload}, 'world', 'first payload';
    is $received[1]{subject}, 'test.nats.perl.foo.bar', 'second subject';
    is $received[1]{payload}, 'baz', 'second payload';

    $loop->await( $nats->unsubscribe($sub) );
}

# Request/Reply
{
    # Set up a responder
    my $responder = $loop->await( $nats->subscribe('test.nats.perl.echo', sub {
        my ($subject, $payload, $reply_to) = @_;
        if ($reply_to) {
            $loop->await( $nats->publish($reply_to, "echo:$payload") );
        }
    }) );

    $loop->await( $nats->ping );

    my ($reply) = $loop->await( $nats->request('test.nats.perl.echo', 'hello', timeout => 5) );
    is $reply, 'echo:hello', 'request/reply works';

    $loop->await( $nats->unsubscribe($responder) );
}

# Disconnect
$loop->await( $nats->disconnect );
ok !$nats->is_connected, 'disconnected';

done_testing;
