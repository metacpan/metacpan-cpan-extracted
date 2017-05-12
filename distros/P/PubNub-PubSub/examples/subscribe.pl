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

$pubnub->subscribe({
    callback => sub {
        my (@messages) = @_;
        foreach my $msg (@messages) {
            print "# Got message: $msg\n";
        }
        return 1; # 1 to continue, 0 to stop
    }
});

1;