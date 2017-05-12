#!perl
use strict;
use warnings;
use lib 't/lib';
use Stomp_LogCalls;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Net::Stomp::Producer;
use Data::Printer;
use Test::Warn;

my $p=Net::Stomp::Producer->new({
    connection_builder => sub { return Stomp_LogCalls->new(@_) },
    servers => [ {
        hostname => 'test-host', port => 9999,
    } ],
    connect_retry_delay=>0.1,
    sending_method => 'with_receipt',
});

@Stomp_LogCalls::calls=();
$Stomp_LogCalls::returns{send_with_receipt}=[0,1];
warnings_like
    { $p->send('somewhere',{},'{"a":"message"}') }
    [{ carped => qr{\bcall to send_with_receipt failed\b}i}],
    'warned of failured and reconnect'
;


cmp_deeply(
    \@Stomp_LogCalls::calls,
    [
        [
            'new',
            'Stomp_LogCalls',
            ignore(),
        ],
        [
            'connect',
            ignore(),
            ignore(),
        ],
        [
            'send_with_receipt',
            ignore(),
            {
                body  => '{"a":"message"}',
                destination => '/somewhere',
            },
        ],
        [
            'new',
            'Stomp_LogCalls',
            ignore(),
        ],
        [
            'connect',
            ignore(),
            ignore(),
        ],
        [
            'send_with_receipt',
            ignore(),
            {
                body  => '{"a":"message"}',
                destination => '/somewhere',
            },
        ],
    ],
    'connected, sent, reconnected, resent'
) or note p @Stomp_LogCalls::calls;

done_testing;
