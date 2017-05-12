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

my $cb = $conn->addShutdownListener(sub {
    my ($shutdownSignalException) = @_;
    isa_ok($shutdownSignalException, 'Net::RabbitMQ::Java::Client::ShutdownSignalException');
    like(
        $shutdownSignalException->getReason->getMethod->getReplyText,
        qr/NOT_FOUND/,
        'shutdown reason'
        );
    ok(1, 'connection shutdown');
});
isa_ok($cb, 'Net::RabbitMQ::Java::Helper::CallbackCaller');

my $cb1 = $channel->addShutdownListener(sub {
    my ($shutdownSignalException) = @_;
    isa_ok($shutdownSignalException, 'Net::RabbitMQ::Java::Client::ShutdownSignalException');
    like(
        $shutdownSignalException->getReason->getMethod->getReplyText,
        qr/NOT_FOUND/,
        'shutdown reason'
        );
    ok(1, 'channel shutdown');
});
isa_ok($cb, 'Net::RabbitMQ::Java::Helper::CallbackCaller');

my $cb2 = $channel->addShutdownListener(sub {
    ok(1, 'second channel shutdown callback');
});
isa_ok($cb2, 'Net::RabbitMQ::Java::Helper::CallbackCaller');

ok(my $txSelect_res = eval { $channel->txSelect }) or diag $@;
isa_ok($txSelect_res, 'Net::RabbitMQ::Java::Client::impl::AMQImpl::Tx::SelectOk');

for (1..3) {
    ok(eval {
        $channel->basicPublish(
            'non-existent-exchange',
            'non-existent-routing-key',
            1, #mandatory
            1, #immediate
            undef,
            "unroutable message"
        );
        1;
    }, 'basicPublish') or diag $@;
}

my $txCommit_res = eval { $channel->txCommit };
isa_ok($@, 'Net::RabbitMQ::Java::java::io::IOException', 'commit failure');

Net::RabbitMQ::Java->processCallbacks;

1;
