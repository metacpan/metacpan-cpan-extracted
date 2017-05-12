#!perl
use strict;
use warnings FATAL => 'all';
use 5.014;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END {done_testing; }
use Test::Exception;

use NetObj::IPv4Address;

for my $ipaddr (
    '0.0.0.0',         # extrem ends
    '255.255.255.255',
    '1.2.3.4',         # typical
    '127.0.0.1',
) {
    ok(
        NetObj::IPv4Address::is_valid($ipaddr),
        "$ipaddr is a valid IPv4 address",
    );
}

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
    ok(
        ! NetObj::IPv4Address::is_valid($ipaddr),
        "$ipaddr is not a valid IPv4 address",
    );
}

# make sure is_valid is a class method only
throws_ok(
    sub {
        NetObj::IPv4Address->new('127.0.0.1')->is_valid();
    },
    qr{class method},
    'NetObj::IPv4Adress is a class method only',
);
