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
    eval { require IO::Async::Loop; 1 } or skip "IO::Async isn’t available: $@", $ClientTest::TEST_COUNT;

    require Net::Curl::Promiser::IOAsync;

    local $SIG{'ALRM'} = 60;

    local $SIG{'CHLD'} = sub {
        my $pid = waitpid -1, 1;
        die "Subprocess $pid ended prematurely!";
    };

    my $server = MyServer->new();

    my $port = $server->port();

    my $loop = IO::Async::Loop->new();

    my $promiser = Net::Curl::Promiser::IOAsync->new($loop);

    ClientTest::run($promiser, $port)->finally(sub { $loop->stop() });

    $loop->run();
}

done_testing();
