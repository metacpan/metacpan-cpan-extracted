use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 12;

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

my $consumer = Net::RabbitMQ::Java::Client::QueueingConsumer->new($channel);
isa_ok($consumer, 'Net::RabbitMQ::Java::Client::QueueingConsumer');

ok(my $basicConsume_res = eval {
    $channel->basicConsume(
        'n-r-j-test-queue',
        0,  #auto-ack
        'ctag',  # consumer-tag
        $consumer
    );
}) or diag $@;
is($basicConsume_res, 'ctag');

my $delivery = $consumer->nextDelivery;
isa_ok($delivery, 'Net::RabbitMQ::Java::Client::QueueingConsumer::Delivery');

is($delivery->getBody, 'My Test Payload');

my $props = $delivery->getProperties;
isa_ok($props, 'Net::RabbitMQ::Java::Client::AMQP::BasicProperties');

is($props->getType, 'notmytype');
is($props->getReplyTo, 'somequeue');

$channel->close;
$conn->close;

1;
