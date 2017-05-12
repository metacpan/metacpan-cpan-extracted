#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 22;

use Net::IP::XS qw(ip_aggregate ip_iptobin
                   Error Errno);
use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

$c->start();
my $res = ip_aggregate(undef, undef, undef, undef, 0);
$c->stop();
is($res, undef, 'Got undef on no version');
is(Error(), 'Cannot determine IP version for ',
   'Got correct error');
is(Errno(), 101, 'Got correct errno');

$res = ip_aggregate('0' . 1024, '1' x 1024, '1'.('0' x 1024), '1' x 1025, 4);
is($res, undef, 'Got undef where bitstrings too large (IPv4)');

$res = ip_aggregate('0' . 1024, '1' x 1024, '1'.('0' x 1024), '1' x 1025, 6);
is($res, undef, 'Got undef where bitstrings too large (IPv6)');

my $addr = ip_iptobin('127.0.0.0', 4);
$res = ip_aggregate($addr, $addr, $addr, $addr, 4);
is($res, undef, 'Got undef on non-contiguous ranges');
is(Error(), "Ranges not contiguous - $addr - $addr",
    'Got correct error');
is(Errno(), 160, 'Got correct errno');

$addr = ip_iptobin((join ':', ('0000') x 8), 6);
$res = ip_aggregate($addr, $addr, $addr, $addr, 6);
is($res, undef, 'Got undef on non-contiguous ranges');
is(Error(), "Ranges not contiguous - $addr - $addr",
    'Got correct error');
is(Errno(), 160, 'Got correct errno');

my $addr1 = ip_iptobin('0.0.0.1', 4);
my $addr2 = ip_iptobin('127.255.255.255', 4);
my $addr3 = ip_iptobin('128.0.0.0', 4);
my $addr4 = ip_iptobin('255.255.255.255', 4);

$res = ip_aggregate($addr1, $addr2, $addr3, $addr4, 4);
is($res, undef, 'Got undef on multiple prefixes');
is(Error(), "$addr1 - $addr4 is not a single prefix",
    'Got correct error');
is(Errno(), 161, 'Got correct errno');

my @data = (
    [ qw(127.0.0.0    127.0.0.255
         127.0.1.0    124.0.0.255
         4            undef) ],
    [ qw(127.0.0.0    127.0.0.255
         127.0.1.0    127.0.3.255
         4            127.0.0.0/22) ],
    [ qw(127.0.0.0    127.0.0.1
         127.0.0.2    127.0.0.3
         4            127.0.0.0/30) ],
    [ qw(0.0.0.0      127.255.255.255
         128.0.0.0    255.255.255.255
         4            0.0.0.0/0) ],
    [ '0000:0000:0000:0000:0000:0000:1234:0000',
      '0000:0000:0000:0000:0000:0000:1234:00FF',
      '0000:0000:0000:0000:0000:0000:1234:0100',
      '0000:0000:0000:0000:0000:0000:1234:01FF',
      6,
      '0000:0000:0000:0000:0000:0000:1234:0000/119' ],
    [ '0000:0000:0000:0000:0000:0000:0000:0000',
      '0000:0000:0000:0000:0000:0000:0000:0001',
      '0000:0000:0000:0000:0000:0000:0000:0002',
      '0000:0000:0000:0000:0000:0000:0000:0003',
      6,
      '0000:0000:0000:0000:0000:0000:0000:0000/126' ],
    [ '0000:0000:0000:0000:0000:0000:0000:0000',
      '7fff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      '8000:0000:0000:0000:0000:0000:0000:0000',
      'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      6,
      '0000:0000:0000:0000:0000:0000:0000:0000/0' ],
    [ '0000:0000:0000:0000:0000:0000:0000:0000',
      '0000:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      '0001:0000:0000:0000:0000:0000:0000:0000',
      '0001:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
      6,
      '0000:0000:0000:0000:0000:0000:0000:0000/15' ],
);

for (@data) {
    my ($b1, $e1, $b2, $e2, $version, $res_exp) = @{$_};
    if ($res_exp eq 'undef') {
        $res_exp = undef;
    }
    my $res = ip_aggregate(ip_iptobin($b1, $version),
                           ip_iptobin($e1, $version),
                           ip_iptobin($b2, $version),
                           ip_iptobin($e2, $version),
                           $version);
    is($res, $res_exp, "$b1 - $e1, $b2 - $e2");
}

1;
