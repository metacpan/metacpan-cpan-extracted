use strict;
use warnings;

use Net::RabbitMQ::Java;
use Test::More tests => 17;

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

my $cb = $channel->setReturnListener(sub {
    my ($replyCode, $replyText, $exchange, $routingKey, $properties, $body) = @_;
    is($body, 'unroutable message');
});

isa_ok($cb, 'Net::RabbitMQ::Java::Helper::CallbackCaller');

ok(my $txSelect_res = eval { $channel->txSelect }) or diag $@;
isa_ok($txSelect_res, 'Net::RabbitMQ::Java::Client::impl::AMQImpl::Tx::SelectOk');

for (1..3) {
    ok(eval {
        $channel->basicPublish(
            'n-r-j-test',
            'non-existent-routing-key',
            1, #mandatory
            1, #immediate
            undef,
            "unroutable message"
        );
        1;
    }) or diag $@;
}

ok(my $txCommit_res = eval { $channel->txCommit }) or diag $@;
isa_ok($txCommit_res, 'Net::RabbitMQ::Java::Client::impl::AMQImpl::Tx::CommitOk');

$cb->process;

$channel->close;
$conn->close;

1;
