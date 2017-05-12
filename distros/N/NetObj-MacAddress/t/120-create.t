#!perl
use strict;
use warnings;
use 5.10.1;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }
use Test::Exception;

use NetObj::MacAddress;

for my $macaddr (
    # some typical notations of valid MAC addresses
    '00:12:34:a4:ce:53', # colon separated
    '20-33-01-7B-27-BF', # dash separated
    '2015.0401.1514',    # dot separated
    '082015e5da7c',      # base16
    'P3/v5-',            # raw binary MAC (any 6 bytes)
) {
    my $mac = NetObj::MacAddress->new($macaddr);
    is(ref($mac), 'NetObj::MacAddress', "generate object for $macaddr");
}

# cloning an exiting NetObj::MacAddress is valid
my $mac1 = NetObj::MacAddress->new('0123456789ab');
my $mac2 = NetObj::MacAddress->new($mac1);
is(ref($mac2), 'NetObj::MacAddress', 'cloning a NetObj::MacAddress object');

# mentioning binary explicitly

is(
    ref(NetObj::MacAddress->new(binary => 'foobar')),
    'NetObj::MacAddress',
    'specifying binary in constructor',
);
is(
    ref(NetObj::MacAddress->new({binary => 'foobar'})),
    'NetObj::MacAddress',
    'specifying hashref with binary key in constructor',
);
for my $macaddr (
    # valid but not binary
    '00:12:34:a4:ce:53',
    '20-33-01-7B-27-BF',
    '2015.0401.1514',
    '082015e5da7c',
) {
    throws_ok(
        sub { NetObj::MacAddress->new(binary => $macaddr) },
        qr{invalid MAC},
        "not a binary MAC: $macaddr",
    );
    throws_ok(
        sub { NetObj::MacAddress->new({binary => $macaddr}) },
        qr{invalid MAC},
        "not a binary MAC: $macaddr",
    );
}

for my $macaddr (
    # some invalid MAC addresses
    '00:12:34:a4:ce',    # too short
    'ab:cd:ef:gh:ij:kl', # non-hex-digits
    'ABC',               # too short
) {
    throws_ok(
        sub { NetObj::MacAddress->new($macaddr) },
        qr{invalid MAC},
        "$macaddr is not a valid MAC address",
    );
}

# no argument in constructor is fatal
throws_ok(
    sub { NetObj::MacAddress->new() },
    qr{no MAC address},
    'must provide MAC address in constructor',
);

# two or more arguments in constructor is fatal
throws_ok(
    sub { NetObj::MacAddress->new('foo', 'bar') },
    qr{too many arguments},
    'only one argument (MAC address) allowed in constructor',
);
