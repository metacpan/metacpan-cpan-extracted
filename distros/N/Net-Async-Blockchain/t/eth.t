#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Fatal;

use IO::Async::Loop;
use IO::Async::Test;
use Ryu::Async;
use Future::AsyncAwait;

use Net::Async::Blockchain::ETH;

my $mock_ws_client = Test::MockModule->new('Net::Async::Blockchain::Client::Websocket');

my $loop = IO::Async::Loop->new();
testing_loop($loop);

subtest "subscribe _ wrong subscription type" => sub {

    $loop->add(my $blockchain_eth = Net::Async::Blockchain::ETH->new());
    like(
        exception { $blockchain_eth->subscribe('dummy')->get },
        qr/Invalid or not implemented subscription/,
        'expecting to die due to wrong subscription type'
    );
};

subtest "subscribe" => sub {
    my $ryu = Ryu::Async->new;
    $loop->add($ryu);

    my $source = $ryu->source;

    $mock_ws_client->mock(
        eth_subscribe => async sub {
            return $source;
        },
    );

    my $blockchain_code   = 'Ethereum';
    my $subscription_type = 'blocks';
    my $message           = {
        params => {
            subscription => '1',
            result       => {
                number => '0x001',
            },
        },
    };

    $loop->add(
        my $blockchain_eth = Net::Async::Blockchain::ETH->new(
            subscription_url => "tcp://127.0.0.1:123",
            blockchain_code  => $blockchain_code
        ));

    my $eth_subscribe = $blockchain_eth->subscribe($subscription_type)->get;
    is ref $eth_subscribe, 'Ryu::Source', 'correct reference for Ryu Source';

    my $expected_message = {
        blockchain_code   => $blockchain_code,
        subscription_type => $subscription_type,
        message           => $message,
    };

    my @messages = ({
            result => '1',    # the subscription id
        },
        {
            params => {
                subscription => '2'    # wrong subscription id (skip)
            }
        },
        $message,
    );

    $eth_subscribe->take(1)->each(
        sub {
            my $emitted_message = shift;
            is_deeply $emitted_message, $expected_message, "Correct emitted message";
        })->retain;

    $source->emit($_) for @messages;

    $mock_ws_client->unmock_all();
};

done_testing;
