use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 7;

Net::RabbitMQ::Java->init;

my $factory = Net::RabbitMQ::Java::Client::ConnectionFactory->new;
isa_ok($factory, 'Net::RabbitMQ::Java::Client::ConnectionFactory');

$factory->setUsername('guest');
$factory->setPassword('guest');
$factory->setHost($ENV{'MQHOST'} || "dev.rabbitmq.com");
$factory->setPort($ENV{'MQPORT'} || 5672);

{
    ok(my $conn = eval { $factory->newConnection })
        or diag($@->printStackTrace);
    isa_ok($conn, 'Net::RabbitMQ::Java::Client::impl::AMQConnection');
    
    my $channel = $conn->createChannel;
    isa_ok($channel, 'Net::RabbitMQ::Java::Client::impl::ChannelN');
    
    my $cb1 = $conn->addShutdownListener(sub {});
    isa_ok($cb1, 'Net::RabbitMQ::Java::Helper::CallbackCaller');

    my $cb2 = $channel->addShutdownListener(sub {});
    isa_ok($cb2, 'Net::RabbitMQ::Java::Helper::CallbackCaller');
}

# $conn and $channel went out of scope.

ok(eval { Net::RabbitMQ::Java->processCallbacks; 1 });

1;
