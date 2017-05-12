#!/usr/bin/perl

use strict;
use warnings FATAL   => 'all';
use Test::More tests => 14;

BEGIN {
    use_ok('NetAddr::MAC')
      or die "# NetAddr::MAC not available\n";
}

{

    local $NetAddr::MAC::die_on_error = 1;

    eval { NetAddr::MAC->new('') };
    like( $@, qr/Please provide a mac address/i, 'Empty MAC' );

    ok( !$NetAddr::MAC::errstr, 'errstr stays empty when die_on_error = 1' );

    eval { NetAddr::MAC->new() };
    like( $@, qr/please provide a mac address/i, 'Undef MAC' );

    eval { NetAddr::MAC->new('11:22:33:44:xx:55') };
    like( $@, qr/Invalid MAC format/, 'Bad MAC character' );

    eval { NetAddr::MAC->new('1:1') };
    like( $@, qr/Invalid MAC format/, 'Bad MAC octet' );

    eval { NetAddr::MAC->new('11:22:33') };
    like( $@, qr/Invalid MAC format/, 'Short MAC' );

    eval { NetAddr::MAC->new('2001:0db8::fe01') };
    like( $@, qr/Invalid MAC format/, 'IPv6 that could be MAC 1' );

    eval { NetAddr::MAC->new('2001::0db8:fe05') };
    like( $@, qr/Invalid MAC format/, 'IPv6 that could be MAC 2' );

    eval { NetAddr::MAC->new('2001:0db8:fe0a::') };
    like( $@, qr/Invalid MAC format/, 'IPv6 that could be MAC 3' );

    eval { NetAddr::MAC->new('2001:db8::fe01') };
    like( $@, qr/Invalid MAC format/, 'IPv6 that could be MAC 1a' );

    eval { NetAddr::MAC->new('2001::db8:fe05') };
    like( $@, qr/Invalid MAC format/, 'IPv6 that could be MAC 2a' );

    eval { NetAddr::MAC->new('2001:db8:fe0a::') };
    like( $@, qr/Invalid MAC format/, 'IPv6 that could be MAC 3a' );

    eval { NetAddr::MAC->new('2001:630:440:163::406') };
    like( $@, qr/Invalid MAC format/, 'IPv6 that could be MAC from Oliver Gorwits' );


}
