#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::Slack;

use Log::Any::Adapter qw(Stdout), log_level => 'debug';

my $loop = IO::Async::Loop->new;

$loop->add(
    my $slack = Net::Async::Slack->new(
        client_id => '159837476818.159130832832',
    )
);

$slack->oauth_request(sub {
    warn "here: @_";
    Future->done
},
    redirect_uri => 'https://localhost/slack-rtm/oauth',
)->get;
