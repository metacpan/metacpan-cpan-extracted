#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::Slack;

use Log::Any::Adapter qw(Stdout), log_level => 'debug';

use Getopt::Long;

GetOptions(
    'host=s' => \my $host,
    'client_id=s' => \my $client_id,
);

my $loop = IO::Async::Loop->new;

$loop->add(
    my $slack = Net::Async::Slack->new(
        slack_host => $host,
        client_id => $client_id,
    )
);

$slack->oauth_request(sub {
    warn "here: @_";
    Future->done
},
    redirect_uri => 'https://localhost/slack-rtm/oauth',
)->get;
