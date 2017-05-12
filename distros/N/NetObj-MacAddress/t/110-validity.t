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
) {
    ok(
        NetObj::MacAddress::is_valid($macaddr),
        "$macaddr is a valid MAC address",
    );
}

for my $macaddr (
    # some invalid MAC addresses
    '00:12:34:a4:ce',    # too short
    'ab:cd:ef:gh:ij:kl', # non-hex-digits
    'ABC',               # too short
) {
    ok(
        !NetObj::MacAddress::is_valid($macaddr),
        "$macaddr is not a valid MAC address",
    );
}

# make sure is_valid is a class method only
throws_ok(
    sub {
        NetObj::MacAddress::->new('000001000001')->is_valid()
    },
    qr{class method},
    'NetObj::MacAddress::is_valid is a class method only',
);
