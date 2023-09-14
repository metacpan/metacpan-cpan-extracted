#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::TCP;

use IO::Async::Loop;
use IO::Async::Test;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(:all);

use Net::Async::Blockchain::BTC;

my $loop = IO::Async::Loop->new();
testing_loop($loop);

subtest "subscribe _ wrong subscription type" => sub {

    $loop->add(my $blockchain_btc = Net::Async::Blockchain::BTC->new());
    like(
        exception { $blockchain_btc->subscribe('dummy')->get },
        qr/Invalid or not implemented subscription/,
        'expecting to die due to wrong subscription type'
    );
};

subtest "subscribe" => sub {

    # ZMQ server
    my $block_hash       = '00000000a4bceeac7fd4a65e71447724e5e67e9d8d0d5a7e6906776eaa35e834';
    my $block_hash_bytes = pack('H*', $block_hash);
    my @msg              = ('hashblock', $block_hash_bytes);
    my $zmq_server       = Test::TCP->new(
        code => sub {
            my $port = shift;
            my $ctxt = zmq_init();
            my $sock = zmq_socket($ctxt, ZMQ_PUB);

            zmq_bind($sock, "tcp://127.0.0.1:$port");
            sleep 2;
            for (@msg) {
                zmq_sendmsg($sock, zmq_msg_init_data($_), ZMQ_SNDMORE);
            }
            zmq_sendmsg($sock, zmq_msg_init_data("last"), 0);
            exit 0;
        });

    my $port              = $zmq_server->port;
    my $ctxt              = zmq_init();
    my $sock              = zmq_socket($ctxt, ZMQ_SUB);
    my $blockchain_code   = 'Bitcoin';
    my $subscription_type = 'blocks';

    $loop->add(
        my $blockchain_btc = Net::Async::Blockchain::BTC->new(
            subscription_url => "tcp://127.0.0.1:$port",
            blockchain_code  => $blockchain_code
        ));

    my $btc_subscribe = $blockchain_btc->subscribe($subscription_type)->get;
    is ref $btc_subscribe, 'Ryu::Source', 'correct reference for Ryu Source';

    my $expected_message = {
        blockchain_code   => $blockchain_code,
        subscription_type => $subscription_type,
        message           => $block_hash,
    };

    $btc_subscribe->take(1)->each(
        sub {
            my $emitted_message = shift;
            is_deeply $emitted_message, $expected_message, "Correct emitted message";
        })->get;
};

done_testing;
