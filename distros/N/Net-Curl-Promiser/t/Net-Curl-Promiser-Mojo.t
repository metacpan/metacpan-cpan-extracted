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
    eval { require Mojo::IOLoop; 1 } or skip "Mojo::IOLoop isn’t available: $@", $ClientTest::TEST_COUNT;

    require Net::Curl::Promiser::Mojo;

    local $SIG{'ALRM'} = 60;

    local $SIG{'CHLD'} = sub {
        my $pid = waitpid -1, 1;
        die "Subprocess $pid ended prematurely!";
    };

    my $server = MyServer->new();

    my $port = $server->port();

    my $promiser = Net::Curl::Promiser::Mojo->new();

    my $promise = ClientTest::run($promiser, $port)->then( sub { print "big resolve\n" }, sub { $@ = shift; warn } );

    my $pr2 = $promise->finally( sub { Mojo::IOLoop->stop() } );

    Mojo::IOLoop->start();
}

done_testing();
