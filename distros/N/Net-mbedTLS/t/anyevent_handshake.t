#!perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

BEGIN {
    eval { require AnyEvent; 1 } or do {
        plan skip_all => "require(AnyEvent): $@";
    };
}

use Net::mbedTLS;
use Net::mbedTLS::AnyEvent;

use AnyEvent;

use IO::Socket::INET ();

my $socket = IO::Socket::INET->new('example.com:443') or do {
    plan skip_all => "Connect failed: $!";
};
$socket->blocking(0);

my $tls = Net::mbedTLS->new()->create_client(
    $socket,
    authmode => Net::mbedTLS::SSL_VERIFY_NONE,
);

my $tls_async = Net::mbedTLS::AnyEvent->new($tls);

my $cv = AnyEvent->condvar();

$tls_async->shake_hands()->finally($cv);

$cv->recv();

ok 1;

done_testing;

1;
