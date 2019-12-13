#!/usr/bin/env perl

use strict;
use warnings;

use Net::Curl::Easy qw(:constants);

use FindBin;

use lib "$FindBin::Bin/../lib";

use Net::Curl::Promiser::Mojo;

use Mojo::IOLoop;

my @urls = (
    'http://perl.org',
    'http://perl.com',
    'http://metacpan.org',
);

#----------------------------------------------------------------------

my $promiser = Net::Curl::Promiser::Mojo->new();

my @promises;

for my $url (@urls) {
    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );
    $handle->setopt( CURLOPT_FOLLOWLOCATION() => 1 );

    push @promises, $promiser->add_handle_p($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    );
}

Mojo::Promise->all(@promises)->wait();
