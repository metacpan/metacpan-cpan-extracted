#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 14;

use Net::IP::XS qw(ip_check_prefix Error Errno);
use IO::Capture::Stderr;
my $c= IO::Capture::Stderr->new();

my $res;

$c->start();
$res = ip_check_prefix(undef, undef, undef);
$c->stop();
is($res, 1, 'Prefix is correct where all arguments are undef');

$res = ip_check_prefix('1010', '5', 4);
is($res, undef, 'Got correct result when prefix length too large');
is(Error(), "Prefix length 5 is longer than IP address (4)",
    'Got correct error');
is(Errno(), 170, 'Got correct errno');

$res = ip_check_prefix('1010', '2', 4);
is($res, undef, 
    'Got correct result when prefix part not only zeroes');
is(Error(), 'Invalid prefix 1010/2',
    'Got correct error');
is(Errno(), 171, 'Got correct errno');

$res = ip_check_prefix('10000000', '2', 4);
is($res, undef, 
    'Got correct result when IP address too small');
is(Error(), "Invalid prefix length /2",
    'Got correct error');
is(Errno(), 172, 'Got correct errno');

$res = ip_check_prefix('1010', -10, 6);
is($res, undef, 
    'Got correct result when negative length provided');
is(Error(), 'Invalid prefix length /-10',
    'Got correct error');
is(Errno(), 172, 'Got correct errno');

$res = ip_check_prefix('10000000000000000000000000000000', '1', 4);
is($res, 1, 'Valid prefix');

1;
