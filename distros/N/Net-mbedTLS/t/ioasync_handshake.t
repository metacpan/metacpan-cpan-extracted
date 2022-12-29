#!perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

BEGIN {
    eval { require IO::Async::Loop; 1 } or do {
        plan skip_all => "require(IO::Async::Loop): $@";
    };
}

use Net::mbedTLS;
use Net::mbedTLS::IOAsync;

use IO::Socket::INET ();

my $socket = IO::Socket::INET->new('example.com:443') or do {
    plan skip_all => "Connect failed: $!";
};
$socket->blocking(0);

my $tls = Net::mbedTLS->new()->create_client(
    $socket,
    authmode => Net::mbedTLS::SSL_VERIFY_NONE,
);

my $loop = IO::Async::Loop->new();

my $tls_async = Net::mbedTLS::IOAsync->new($tls, $loop);

$tls_async->shake_hands()->finally( sub { $loop->stop() } );

undef $tls_async;

$loop->run();

ok 1;

done_testing;

1;
