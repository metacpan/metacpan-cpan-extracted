#!/usr/bin/env perl

use strict;
use warnings;
no indirect;

use IO::Async::Loop;
use Data::Dumper;

use Net::Async::Blockchain::BTC;

my $loop = IO::Async::Loop->new;

$loop->add(
    my $btc_client = Net::Async::Blockchain::BTC->new(
        subscription_url => 'tcp://127.0.0.1:28332',
        # Timeout time for connection (seconds)
        subscription_timeout => 100,
        # Timeout time for received messages, this is applied when we have a bigger
        # duration interval between the messages (seconds).
        subscription_msg_timeout => 3600,
        blockchain_code          => 'Bitcoin',
    ));

$btc_client->subscribe("blocks")->each(sub { print Dumper shift->{hash} })->get;
