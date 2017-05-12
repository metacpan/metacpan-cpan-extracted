#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use PubNub::PubSub;
use Data::Dumper;

my $pubnub = PubNub::PubSub->new(
    sub_key => $ENV{PUBNUB_SUB_KEY} || 'sub-c-22665af4-6988-11e4-8cf9-02ee2ddab7fe',
);

$pubnub->subscribe_multi(
    channels => [qw(sandbox foo bar)],
    callback => { sandbox => sub {
                       my (@messages) = @_;
                       foreach (@messages) {
                           my ($msgs, $timetoken, $channel) = @$_;
                           print "# Got message on $channel, timetoken $timetoken\n";
                           print Dumper($msgs);
                      }
                      return 1; # 1 to continue, 0 to stop
                   },
                   on_connect => sub { print "# got connect message!\n"; 1 },
                   _default => sub { print "# not from sandbox\n"; 1 },
               },
);

1;
