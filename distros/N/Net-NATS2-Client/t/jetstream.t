use strict;
use warnings;

use Test::More;
use Net::NATS2::Client;
use Net::NATS2::JetStream;

my $client = Net::NATS2::Client->new(uri => 'nats://nats:4222', socket_args => {Timeout=>1});
for (1..2) {
    last if $client->connect;
    sleep 1;
}
plan skip_all => 'NATS is unavailable' unless $client->connection;
ok($client->connection, 'connects to NATS');

my $js = Net::NATS2::JetStream->new(client => $client, timeout => 1);
ok($js->api_info, 'retrieves JetStream account information');

my $stream = $js->add_stream({name => 'ORDERS', subjects => ['orders'], storage => 'memory',});
is($stream->{config}{name}, 'ORDERS', 'creates a stream');

my $ack = $js->publish('orders', 'created');
is($ack->{stream}, 'ORDERS', 'publishes to JetStream');
is($ack->{seq},    1,        'receives the publish sequence');

my $consumer = $js->add_consumer('ORDERS', {durable_name => 'WORKER', ack_policy => 'explicit',});
is($consumer->{config}{durable_name}, 'WORKER', 'creates a durable pull consumer');

my $message = $js->next_message('ORDERS', 'WORKER');
is($message->data, 'created', 'fetches the next pull-consumer message');
ok($js->ack($message), 'acknowledges a pull-consumer message');

$js->publish('orders', 'retry');
$message = $js->next_message('ORDERS', 'WORKER');
is($message->data, 'retry', 'fetches another pull-consumer message');
ok($js->nak($message), 'negatively acknowledges a message');
$message = $js->next_message('ORDERS', 'WORKER');
is($message->data, 'retry', 'redelivers a negatively acknowledged message');
ok($js->term($message), 'terminates a message');

$js->publish('orders', 'batch one');
$js->publish('orders', 'batch two');
my $messages = $js->fetch('ORDERS', 'WORKER', 2);
is_deeply([map { $_->data } @$messages], ['batch one', 'batch two'], 'fetches a batch from a pull consumer');
ok($js->ack($_), 'acknowledges a fetched message') for @$messages;

my $info = $js->stream_info('ORDERS');
is($info->{state}{messages}, 4, 'stream reports the published messages');

my $list = $js->stream_list;
is($list->{total}, 1, 'lists streams');

ok($js->purge_stream('ORDERS')->{success}, 'purges a stream');
is($js->stream_info('ORDERS')->{state}{messages}, 0, 'purge removes messages');
ok($js->delete_stream('ORDERS')->{success}, 'deletes a stream');

$client->close;

done_testing;
