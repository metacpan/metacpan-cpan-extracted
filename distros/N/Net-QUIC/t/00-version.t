use strict;
use warnings;

use Test2::V0;

use Net::QUIC;
use Net::QUIC::Connection;
use Net::QUIC::Datagram;
use Net::QUIC::Driver;
use Net::QUIC::Endpoint;
use Net::QUIC::Stream;

my @packages = qw(
    Net::QUIC
    Net::QUIC::Connection
    Net::QUIC::Datagram
    Net::QUIC::Driver
    Net::QUIC::Endpoint
    Net::QUIC::Stream
);

for my $package (@packages) {
    no strict 'refs';

    my $version = ${$package . '::VERSION'};

    is(
        $version,
        $Net::QUIC::VERSION,
        "$package version matches Net::QUIC",
    );
}

done_testing;
