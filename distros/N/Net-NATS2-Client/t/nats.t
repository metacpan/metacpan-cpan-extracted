use strict;
use warnings;

use Test::More;
use Net::NATS2::Client;

my $client = Net::NATS2::Client->new(uri => 'nats://nats:4222', socket_args => {Timeout=>1});
for (1..2) {
    last if $client->connect;
    sleep 1;
}

plan skip_all => 'NATS is unavailable' unless $client->connection;
ok($client->connection, 'connects to NATS');
ok($client->ping(1),    'receives PONG from NATS');

my $message;
$client->subscribe(
    'compose.test',
    sub {
        ($message) = @_;
    }
);

ok($client->publish('compose.test', 'hello'), 'publishes a message');

for (1 .. 5) {
    $client->wait_for_op(1);
    last if $message;
}

is($message->data, 'hello', 'receives the published message');

my $header_message;
my $headers = "NATS/1.0\r\nX-Trace-ID: 42\r\n\r\n";
$client->subscribe(
    'compose.headers',
    sub {
        ($header_message) = @_;
    }
);

ok($client->hpublish('compose.headers', $headers, 'hello with headers'), 'publishes a message with headers',);

for (1 .. 5) {
    $client->wait_for_op(1);
    last if $header_message;
}

is($header_message->headers, $headers,             'receives raw NATS headers');
is($header_message->data,    'hello with headers', 'receives header message payload');
$client->close;

done_testing;
