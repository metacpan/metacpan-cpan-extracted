#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use Net::Curl::Easy qw(:constants);

use FindBin;
use lib "$FindBin::Bin/lib";

use MyServer;

SKIP: {
    eval { require AnyEvent::Loop; 1 } or skip "AnyEvent isn’t available: $@", 2;

    require Net::Curl::Promiser::AnyEvent;

    my $server = MyServer->new();

    my $port = $server->port();

    my $promiser = Net::Curl::Promiser::AnyEvent->new();

    my $easy = Net::Curl::Easy->new();
    $easy->setopt( CURLOPT_URL() => "http://127.0.0.1:$port/foo" );

    my ($head, $body) = (q<>, q<>);

    $easy->setopt( CURLOPT_HEADERDATA() => \$head );
    $easy->setopt( CURLOPT_FILE() => \$body );

    my $cv = AnyEvent->condvar();

    $promiser->add_handle($easy)->then( sub {
        my ($h1, $b1) = ($head, $body);

        $_ = q<> for ($head, $body);

        return $promiser->add_handle($easy)->then( sub {
            $cv->();

            is( $head, $h1, 'same header' );
            is( $body, $b1, 'same body' );
        } );
    } );

    $cv->recv();
}

done_testing();

1;
