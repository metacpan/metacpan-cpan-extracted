#!/usr/bin/env perl

use strict;
use warnings;
no indirect;

use IO::Async::Loop;
use Data::Dumper;

use Net::Async::Blockchain::BTC;
use Net::Async::Blockchain::ETH;

my $loop = IO::Async::Loop->new;

$loop->add(
    my $eth_client = Net::Async::Blockchain::ETH->new(
        subscription_url => "ws://127.0.0.1:8546",
        blockchain_code  => 'Ethereum',
    ));
$loop->add(
    my $btc_client = Net::Async::Blockchain::BTC->new(
        subscription_url => "tcp://127.0.0.1:28332",
        blockchain_code  => 'Bitcoin',
    ));

$btc_client->subscribe("blocks")->merge($eth_client->subscribe("blocks"))->each(sub { print Dumper shift })->get;
