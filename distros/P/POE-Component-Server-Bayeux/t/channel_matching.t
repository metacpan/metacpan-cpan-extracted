#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    use_ok('POE::Component::Server::Bayeux::Utilities');
}

use POE::Component::Server::Bayeux::Utilities qw(channel_match);

my @comparisons = (qw(
    /chat/demo       /chat/demo   1
    /chat/demo/sub   /chat/demo   0
    /chat/demo       /chat/*      1
    /chat/demo/sub   /chat/*      0
    /chat/demo/sub   /chat/**     1
    /chat            /chat/*      0
    /chat            /*           1
    /chat/demo       /*           0
    /private/demo    /chat/demo   0
    /private/demo    /*/demo      0
));

while (my ($channel, $subscription, $expected) = splice @comparisons, 0, 3, ()) {
    my $result = channel_match($channel, $subscription);
    is($result, $expected, "Channel $channel matches subscription $subscription");
}
