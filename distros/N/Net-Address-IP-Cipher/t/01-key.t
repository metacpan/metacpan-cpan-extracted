#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 6;

# test vectors from ipcipher specification
my %samples = (
    '127.0.0.1' => '114.62.227.59',
    '8.8.8.8'   => '46.48.51.50',
    '1.2.3.4'   => '171.238.15.199',
    '::1'       => '3718:8853:1723:6c88:7e5f:2e60:c79a:2bf',
    '2001:503:ba3e::2:30' => '64d2:883d:ffb5:dd79:24b:943c:22aa:4ae7',
    '2001:DB8::'          => 'ce7e:7e39:d282:e7b1:1d6d:5ca1:d4de:246f',
);

use Net::Address::IP::Cipher;

my $ipcipher = Net::Address::IP::Cipher->new(
    barekey => '736f6d652031362d62797465206b6579' # some 16-byte key
);

for my $ip (keys %samples) {
    ok( $ipcipher->enc($ip) eq $samples{$ip}, "encoding $ip" );
}

