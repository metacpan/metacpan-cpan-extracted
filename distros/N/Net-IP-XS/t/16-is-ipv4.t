#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 47;

use Net::IP::XS qw(ip_is_ipv4 Error Errno);
use IO::Capture::Stderr;

my @data = (
    [ '' => 0,
      107, 'Invalid chars in IP ' ],
    [ undef, 0,
      107, 'Invalid chars in IP ' ],
    [ '127' => 1 ],
    [ '127.0' => 1 ],
    [ '127.0.0' => 1 ],
    [ '127.0.0.0' => 1 ],
    [ '0'   => 1 ],
    [ '255.255.255.255' => 1 ],
    [ '1.2.3.4' => 1 ],
    [ '192.168.0.1' => 1 ],
    [ '127.256' => 0,
      107, 'Invalid quad in IP address 127.256 - 256' ],
    [ '127.127.256' => 0,
      107, 'Invalid quad in IP address 127.127.256 - 256' ],
    [ '127.127.127.256' => 0,
      107, 'Invalid quad in IP address 127.127.127.256 - 256' ],
    [ '1.1.1.256' => 0,
      107, 'Invalid quad in IP address 1.1.1.256 - 256' ],
    [ '123459125' => 0,
      107, 'Invalid quad in IP address 123459125 - 123459125' ],
    [ 'ABCD' => 0,
      107, 'Invalid chars in IP ABCD' ],
    [ '.123' => 0,
      103, 'Invalid IP .123 - starts with a dot' ],
    [ '123.' => 0,
      104, 'Invalid IP 123. - ends with a dot' ],
    [ '1.....2' => 0,
      105, 'Invalid IP address 1.....2' ],
    [ '123..123.123' => 0,
      106, 'Empty quad in IP address 123..123.123' ],
    [ '92233720368547758078' => 0,
      107, qr/^Invalid quad in IP address 92233720368547758078/ ],
);

my $cap = IO::Capture::Stderr->new();

for my $entry (@data) {
    my ($input, $res, $errno, $error) = @{$entry};
    $cap->start();
    my $res_t = ip_is_ipv4($input);
    $cap->stop();
    if (not defined $input) {
        $input = '(undef)';
    }
    is($res_t, $res, "Got correct ip_is_ipv4 result for $input");
    if (defined $errno) {
        is(Errno(), $errno, 'Got correct errno');
    }
    if (defined $error) {
        if (ref $error) {
            like(Error(), $error, 'Got correct error');
        }
        else {
            is(Error(), $error, 'Got correct error');
        }
    }
}

1;
