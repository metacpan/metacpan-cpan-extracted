#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent;
use Net::HTTP2::Client::AnyEvent;

my $cv = AnyEvent->condvar();

my $h2 = Net::HTTP2::Client::AnyEvent->new("perl.org");

$h2->request("GET", "/")->then(
    sub {
        my ($resp) = shift;
        print $resp->content();
    },
)->finally($cv);

$cv->recv();
