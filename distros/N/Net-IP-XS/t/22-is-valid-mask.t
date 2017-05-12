#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 16;

use Net::IP::XS qw(ip_is_valid_mask Error Errno);

my $res;
my @res;

$res = ip_is_valid_mask('', 0);
is($res, undef, 'No IP address version with empty mask');
is(Error(), 'Cannot determine IP version for ',
    'Got correct error');
is(Errno(), 101, 'Got correct error');

$res = ip_is_valid_mask('', 8);
is($res, 1, 'Bad IP address version with empty mask');

$res = ip_is_valid_mask('1'.('0' x 31), 4);
is($res, 1, 'IPv4 mask (1)');

$res = ip_is_valid_mask('1' x 32, 4);
is($res, 1, 'IPv4 mask (2)');

$res = ip_is_valid_mask('0' x 32, 4);
is($res, 1, 'IPv4 mask (3)');

$res = ip_is_valid_mask('asdf', 4);
is($res, undef, 'Invalid mask (contains letters, too short)');
is(Error(), "Invalid mask length for asdf", 'Got correct error');
is(Errno(), 150, 'Got correct errno');

$res = ip_is_valid_mask('asdf' x 8, 4);
is($res, undef, 'Invalid mask (contains letters, correct length)');
is(Error(), "Invalid mask ".('asdf' x 8), 'Got correct error');
is(Errno(), 151, 'Got correct errno');

$res = ip_is_valid_mask('asdf' x 500, 4);
is($res, undef, 'Invalid mask (contains letters, too long)');
is(Errno(), 150, 'Got correct errno');

$res = ip_is_valid_mask('0'.('1' x 31), 4);
is($res, undef, 'Invalid mask (0 then series of 1s)');

1;
