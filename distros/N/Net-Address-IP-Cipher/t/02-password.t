#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 6;

# test vectors from ipcipher specification
my %samples = (
    '198.41.0.4' => '139.111.117.167',
    '130.161.180.1' => '66.235.221.231',
    '0.0.0.0' => '203.253.152.187',
    '::1' => 'a551:9cb0:c9b:f6e1:6112:58a:af29:3a6c',
    '2001:503:ba3e::2:30' => '6e60:2674:2fac:d383:f9d5:dcfe:fc53:328e',
    '2001:DB8::' => 'a8f5:16c8:e2ea:23b9:748d:67a2:4107:9d2e',
);

use Net::Address::IP::Cipher;

my $ipcipher = Net::Address::IP::Cipher->new(
    password => 'crypto is not a coin'
);

for my $ip (keys %samples) {
    ok( $ipcipher->enc($ip) eq $samples{$ip}, "encoding $ip" );
}

