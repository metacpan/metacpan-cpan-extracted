#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use PubNub::PubSub;
use Data::Dumper;

my $pubnub = PubNub::PubSub->new(
    sub_key => $ENV{PUBNUB_SUB_KEY} || 'sub-c-a66b65f2-2d96-11e4-875c-02ee2ddab7fe',
    channel => $ENV{PUBNUB_CHANNEL} || 'sandbox',
);

my $history = $pubnub->history({
    count => 5,
    reverse => "true",
});
while (1) {
    print Dumper(\$history);
    last unless @{$history->[0]}; # no messages
    sleep 1;
    $history = $pubnub->history({
        count => 5,
        reverse => "true",
        start => $history->[2]
    });
}

1;