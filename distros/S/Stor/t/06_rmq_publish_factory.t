use strict;
use warnings;

use Test::More tests => 6;
use Mock::Quick;
use Test::Exception;

use_ok('RmqPublishFactory');

subtest 'undef uri' => sub {
    is(RmqPublishFactory->new->create(), undef);
};

subtest 'empty uri' => sub {
    is(RmqPublishFactory->new(uri => '')->create(), undef);
};

subtest 'no amqp uri' => sub {
    is(RmqPublishFactory->new(uri => 'http://test')->create(), undef);
};

my $rmq_mock = qclass(
    -with_new => 1,
    connect   => sub {
        my (undef, $host, $options) = @_;

        is($host, 'localhost', 'connect host');
        is_deeply($options, {password => 'guest', user => 'guest', vhost => 'stor', port => 5672}, 'connect options');
    },
    channel_open => sub {
        my (undef, $channel) = @_;

        is($channel, 1, 'channel');
    },
    exchange_declare => sub {
        my (undef, $channel, $exchange, $options) = @_;

        is($channel, 1, 'exchange_declare channel');
        is($exchange, 'stor', 'exchange_declare exchange');
    },
    publish => sub {
        my (undef, $channel, $routing_key, $msg, $options) = @_;

        is($channel, 1, 'publish channel');
        is($routing_key, 'sha', 'publish routing_key');
        is($msg, 'test', 'publish msg');
        is_deeply($options, {exchange => 'stor'}, 'publish options');
    },
);

subtest 'amqp default' => sub {
    my $factory = RmqPublishFactory->new(
        uri => 'amqp://guest:guest@localhost/stor',
        rmq => $rmq_mock->package->new(),
    );

    is($factory->exchange, 'stor', 'exchange');
    is($factory->routing_key, 'sha', 'routing_key');

    my $rmq_publish = $factory->create();
    is(ref $rmq_publish, 'CODE', 'create code');

    $rmq_publish->('test');

    done_testing(12);
};

subtest 'amqp override' => sub {
    my $factory = RmqPublishFactory->new(
        uri => 'amqp://guest:guest@localhost/vhost?exchange=other&routing_key=test',
        rmq => $rmq_mock->package->new(),
    );

    is($factory->exchange, 'other', 'exchange');
    is($factory->routing_key, 'test', 'routing_key');
};
