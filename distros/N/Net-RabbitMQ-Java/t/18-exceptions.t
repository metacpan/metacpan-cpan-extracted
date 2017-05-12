use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 2;

Net::RabbitMQ::Java->init;

my $factory = Net::RabbitMQ::Java::Client::ConnectionFactory->new;
isa_ok($factory, 'Net::RabbitMQ::Java::Client::ConnectionFactory');

$factory->setUsername('wrong-username');
$factory->setPassword('wrong-password');
$factory->setHost($ENV{'MQHOST'} || "dev.rabbitmq.com");
$factory->setPort($ENV{'MQPORT'} || 5672);

my $conn = eval { $factory->newConnection };
isa_ok($@, 'Net::RabbitMQ::Java::Client::PossibleAuthenticationFailureException');

1;
