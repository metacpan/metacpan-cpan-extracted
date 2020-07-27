#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Net::Curl::Easy;

use MyServer;
use ClientTest;

my $test_count = 1 + $ClientTest::TEST_COUNT;

plan tests => $test_count;

SKIP: {
    eval { require AnyEvent::Loop; 1 } or skip "AnyEvent isn’t available: $@", $test_count;

    diag "Using AnyEvent $AnyEvent::VERSION; backend: " . AnyEvent::detect();

    require Net::Curl::Promiser::AnyEvent;

    my $server = MyServer->new();

    my $port = $server->port();

    my $promiser = Net::Curl::Promiser::AnyEvent->new();

    my $cv = AnyEvent->condvar();

    ClientTest::run($promiser, $port)->finally($cv);

    $cv->recv();

    #----------------------------------------------------------------------

    _test_cancel($promiser, $port);

    #----------------------------------------------------------------------

    $server->finish();
}

#----------------------------------------------------------------------

sub _test_cancel {
    my ($promiser, $port) = @_;

    diag "Testing cancellation …";

    require Net::Curl::Easy;
    my $easy = Net::Curl::Easy->new();
    $easy->setopt( Net::Curl::Easy::CURLOPT_URL() => "http://127.0.0.1:$port/foo" );

    # $easy->setopt( CURLOPT_VERBOSE() => 1 );

    # Even on the slowest machines this ought to do it.
    $easy->setopt( Net::Curl::Easy::CURLOPT_TIMEOUT() => 30 );

    my $fate;

    $promiser->add_handle($easy)->then(
        sub { $fate = [0, shift] },
        sub { $fate = [1, shift] },
    );

    my @watches;

    my $cv = AnyEvent->condvar();

    $promiser->cancel_handle($easy);

    push @watches, AnyEvent->timer(
        after => 1,
        cb => sub {
            $cv->();
        },
    );

    $cv->recv();

    is( $fate, undef, 'canceled promise remains pending' ) or diag explain $fate;
}
