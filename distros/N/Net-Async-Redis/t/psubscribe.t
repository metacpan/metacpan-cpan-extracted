use strict;
use warnings;

use Test::More;
use IO::Async::Test;

use Net::Async::Redis;
use IO::Async::Loop;

plan skip_all => 'set NET_ASYNC_REDIS_HOST env var to test' unless exists $ENV{NET_ASYNC_REDIS_HOST};

my $loop = IO::Async::Loop->new;
testing_loop($loop);

$loop->add(my $publisher = Net::Async::Redis->new);
$loop->add(my $subscriber = Net::Async::Redis->new);
Future->needs_all(
    $publisher->connect(
        host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
    ),
    $subscriber->connect(
        host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
    )
)->get;

my $s = $subscriber->psubscribe('testprefix::*')->get;
{
    ok($s, "Got subscription");

    is($s->redis,   $subscriber,     '$s->redis');
    is($s->channel, 'testprefix::*', '$s->channel');
}

my @messages;
$s->events->each(sub {
    my ( $message ) = @_;
    push @messages, $message;
});

$publisher->publish('testprefix::123', 'the message')->get;

wait_for { @messages > 0 };

{
    ok(my $msg = shift @messages, "Got a message");

    is($msg->redis,        $subscriber,       '$msg->redis');
    is($msg->subscription, $s,                '$msg->subscription');
    is($msg->channel,      'testprefix::123', '$msg->channel');
    is($msg->type,         'pmessage',        '$msg->type');

    is($msg->payload,      'the message', '$msg->payload');
}

done_testing;
