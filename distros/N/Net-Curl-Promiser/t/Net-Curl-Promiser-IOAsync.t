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

    diag "Using IO::Async::Loop $IO::Async::Loop::VERSION";

    # This ensures that tests aren’t subject to potential bugs
    # in non-core event loop backends.
    no warnings 'once';
    local $IO::Async::Loop::LOOP = 'Select';

    require Net::Curl::Promiser::IOAsync;

    my $server = MyServer->new();

    my $port = $server->port();

    my $loop = IO::Async::Loop->new();

    my $version = eval { $loop->VERSION() } || '(unknown version)';

    diag "Using loop class " . ref($loop) . " $version";

    my $promiser = Net::Curl::Promiser::IOAsync->new($loop);

    ClientTest::run($promiser, $port)->finally(sub { $loop->stop() });

    $loop->run();

    $server->finish();
}

done_testing();
