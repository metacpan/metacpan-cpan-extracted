#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

BEGIN {
    eval { require IP::Authority; };
    if (my $error = $@) {
        plan skip_all => "IP::Authority not available";
    } else {
        plan tests => 8;
    }
};

use Net::IP::XS qw(ip_auth Error Errno);

my $res = ip_auth('', 0);
is($res, undef, 'Got undef on no version');
is(Error(), 'Cannot determine IP version for ',
    'Got correct error');
is(Errno(), 101, 'Got correct errno');

$res = ip_auth('', 8);
is($res, undef, 'Got undef on non-IPv4 address');
is(Error(), 'Cannot get auth information: Not an IPv4 address',
    'Got correct error');
is(Errno(), 308, 'Got correct errno');

my @data = (
    [['203.0.0.0', 4] => 'AP'],
    [['202.0.0.0', 4] => 'AP'],
);

for my $entry (@data) {
    my ($arg, $res) = @{$entry};
    my ($ip, $version) = @{$arg};
    my $res_t = ip_auth($ip, $version);
    is($res_t, $res, "Got correct auth for $ip ($version)");
}

1;
