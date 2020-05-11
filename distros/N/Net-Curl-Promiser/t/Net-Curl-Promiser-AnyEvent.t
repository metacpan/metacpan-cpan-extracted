#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use Net::Curl::Easy;

use FindBin;
use lib "$FindBin::Bin/lib";

use MyServer;
use ClientTest;

plan tests => $ClientTest::TEST_COUNT;

SKIP: {
    eval { require AnyEvent::Loop; 1 } or skip "AnyEvent isn’t available: $@", $ClientTest::TEST_COUNT;

    diag "Using AnyEvent $AnyEvent::VERSION; backend: " . AnyEvent::detect();

    require Net::Curl::Promiser::AnyEvent;

    my $server = MyServer->new();

    my $port = $server->port();

    my $promiser = Net::Curl::Promiser::AnyEvent->new();

    my $cv = AnyEvent->condvar();

    ClientTest::run($promiser, $port)->finally($cv);

    $cv->recv();

    $server->finish();
}

done_testing();
