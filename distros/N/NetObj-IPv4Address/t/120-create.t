#!perl
use strict;
use warnings FATAL => 'all';
use 5.014;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END {done_testing; }
use Test::Exception;

use NetObj::IPv4Address;

my %valid_ips = (
    '0.0.0.0' => "\0\0\0\0",         # extrem ends
    '255.255.255.255' => "\377\377\377\377",
    '1.2.3.4' => "\1\2\3\4",         # typical
    '127.0.0.1' => "\177\0\0\1",
    "\177\0\0\1" => "\177\0\0\1",    # raw binary
);
for my $ipaddr (keys %valid_ips) {
    my $ip = NetObj::IPv4Address->new($ipaddr);
    is(ref($ip), 'NetObj::IPv4Address', "generate object for $ip");
    is($ip->binary(), $valid_ips{$ipaddr}, "stored correctly for $ip");
}

# cloning is valid
my $ip1 = NetObj::IPv4Address->new('127.0.0.1');
my $ip2 = NetObj::IPv4Address->new($ip1);
is(ref($ip2), 'NetObj::IPv4Address', 'cloning a NetObj::IPv4Address object');

for my $ipaddr (
    '256.1.1.1',  # each byte only up to 255
    '1.256.1.1',
    '1.1.256.1',
    '1.1.1.256',
    'm.n.o.p',    # only numeric
    '*/@[\],.',   # bad characters
    '1.2.3',      # too few components
    '1.2.3.4.5',  # too many components
) {
    throws_ok(
        sub { NetObj::IPv4Address->new($ipaddr) },
        qr{invalid IPv4 address},
        "$ipaddr is not a valid IPv4 address",
    );
}

# require exactly one argument
throws_ok(
    sub { NetObj::IPv4Address->new() },
    qr{no IPv4 address given},
    'must provide an IPv4 address in constructor',
);

throws_ok(
    sub { NetObj::IPv4Address->new('foo', 'bar') },
    qr{too many arguments},
    'only one IPv4 address allowed in constructor',
);
