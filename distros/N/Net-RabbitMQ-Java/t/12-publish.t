use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 13;

Net::RabbitMQ::Java->init;

my $factory = Net::RabbitMQ::Java::Client::ConnectionFactory->new;
isa_ok($factory, 'Net::RabbitMQ::Java::Client::ConnectionFactory');

$factory->setUsername('guest');
$factory->setPassword('guest');
$factory->setHost($ENV{'MQHOST'} || "dev.rabbitmq.com");
$factory->setPort($ENV{'MQPORT'} || 5672);

ok(my $conn = eval { $factory->newConnection })
    or diag($@->printStackTrace);
isa_ok($conn, 'Net::RabbitMQ::Java::Client::impl::AMQConnection');

my $channel = $conn->createChannel;
isa_ok($channel, 'Net::RabbitMQ::Java::Client::impl::ChannelN');

ok(my $queueDeclare_res = eval {
    $channel->queueDeclare(
        'n-r-j-test-queue',
        1, #durable
        0, #exclusive
        0, #auto-delete
        {}
    );
}) or diag $@;
isa_ok($queueDeclare_res, 'Net::RabbitMQ::Java::Client::impl::AMQImpl::Queue::DeclareOk');

my $queue_name = $queueDeclare_res->getQueue;

ok(my $queueBind_res = eval {
    $channel->queueBind(
        $queue_name,
        'n-r-j-test',
        "n-r-k-test-routing-key"
    );
}) or diag $@;
isa_ok($queueBind_res, 'Net::RabbitMQ::Java::Client::impl::AMQImpl::Queue::BindOk');

my $confirmed = 0;
my $cb = $channel->setConfirmListener(sub { $confirmed = 1 });

isa_ok($cb, 'Net::RabbitMQ::Java::Helper::CallbackCaller');

ok(my $confirmSelect_res = eval { $channel->confirmSelect }) or diag $@;
isa_ok($confirmSelect_res, 'Net::RabbitMQ::Java::Client::impl::AMQImpl::Confirm::SelectOk');

ok(eval {
    $channel->basicPublish(
        'n-r-j-test',
        "n-r-k-test-routing-key",
        {
            contentType => 'text/plain',
            contentEncoding => 'none',
            correlationId => 123,
            replyTo => 'somequeue',
            expiration => 'later',
            messageId => 'ABC',
            type => 'notmytype',
            userId => 'guest',
            appId => 'idd',
            deliveryMode => 1,
            priority => 2,
            timestamp => 1271857990,
        },
        "My Test Payload"
    );
    1;
}) or diag $@;

$cb->process while !$confirmed;
ok($confirmed);

$channel->close;
$conn->close;

1;
