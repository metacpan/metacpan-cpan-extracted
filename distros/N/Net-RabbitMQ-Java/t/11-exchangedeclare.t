use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 6;

Net::RabbitMQ::Java->init;

my $factory = Net::RabbitMQ::Java::Client::ConnectionFactory->new;
isa_ok($factory, 'Net::RabbitMQ::Java::Client::ConnectionFactory');

$factory->setUsername('guest');
$factory->setPassword('guest');
$factory->setVirtualHost('/');
$factory->setHost($ENV{'MQHOST'} || "dev.rabbitmq.com");
$factory->setPort($ENV{'MQPORT'} || 5672);

ok(my $conn = eval { $factory->newConnection })
    or diag($@->printStackTrace);
isa_ok($conn, 'Net::RabbitMQ::Java::Client::impl::AMQConnection');

my $channel = $conn->createChannel;
isa_ok($channel, 'Net::RabbitMQ::Java::Client::impl::ChannelN');

ok(my $declare_res = eval {
    $channel->exchangeDeclare(
        'n-r-j-test',
        "direct",
        1, # durable
        0, # auto-delete
        undef
    );
}) or diag $@;
isa_ok($declare_res, 'Net::RabbitMQ::Java::Client::impl::AMQImpl::Exchange::DeclareOk');

1;
