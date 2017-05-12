use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 5;

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

my $cb = $conn->addShutdownListener(sub {});
isa_ok($cb, 'Net::RabbitMQ::Java::Helper::CallbackCaller');


ok(eval { $conn->removeShutdownListener($cb->getListener); 1 })
    or diag $@;

$conn->close;

1;
