#!/usr/bin/env perl

use strict;
use warnings;

use Net::Curl::Easy qw(:constants);

use FindBin;

use lib "$FindBin::Bin/../lib";

use IO::Async::Loop;

use Net::Curl::Promiser::IOAsync;

my @urls = (
    'http://perl.org',
    'http://perl.com',
    'http://metacpan.org',
);

#----------------------------------------------------------------------

my $loop = IO::Async::Loop->new();

my $promiser = Net::Curl::Promiser::IOAsync->new($loop);

my @promises;

for my $url (@urls) {
    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );
    $handle->setopt( CURLOPT_FOLLOWLOCATION() => 1 );

    push @promises, $promiser->add_handle($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    );
}

Promise::ES6->all(\@promises)->finally( sub {
    $loop->stop();
} );

$loop->run();
