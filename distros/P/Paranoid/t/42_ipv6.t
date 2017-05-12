#!/usr/bin/perl -T

use Test::More tests => 31;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Network::IPv6 qw(:all);
use Paranoid::Network::Socket;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

my ( @net, $rv );

SKIP: {

    skip( 'Missing IPv6 support -- skipping IPv6 tests', 31 )
        unless has_ipv6();

    # Test ffff:ffff:ffff::/64 conversion
    @net = ipv6NetConvert('ffff:ffff:ffff::/64');
    is( scalar(@net), 3, 'convert ffff:ffff:ffff::/64 1' );
    is( inet_ntop( AF_INET6(), pack 'NNNN', @{ $net[0] } ),
        'ffff:ffff:ffff::', 'convert ffff:ffff:ffff::/64 2' );
    like( inet_ntop( AF_INET6(), pack 'NNNN', @{ $net[1] } ),
        qr/^ffff:ffff:ffff:0?:ffff:ffff:ffff:ffff$/,
        'convert ffff:ffff:ffff::/64 3'
        );
    is( inet_ntop( AF_INET6(), pack 'NNNN', @{ $net[2] } ),
        'ffff:ffff:ffff:ffff::', 'convert ffff:ffff:ffff::/64 4' );

    # Test ffff:ffff:ffee::/48 conversion
    @net = ipv6NetConvert('ffff:ffff:ffee::/48');
    is( scalar(@net), 3, 'convert ffff:ffff:ffee::/48 1' );
    is( inet_ntop( AF_INET6(), pack 'NNNN', @{ $net[0] } ),
        'ffff:ffff:ffee::', 'convert ffff:ffff:ffee::/48 2' );
    is( inet_ntop( AF_INET6(), pack 'NNNN', @{ $net[1] } ),
        'ffff:ffff:ffee:ffff:ffff:ffff:ffff:ffff',
        'convert ffff:ffff:ffee::/48 3'
        );
    is( inet_ntop( AF_INET6(), pack 'NNNN', @{ $net[2] } ),
        'ffff:ffff:ffff::', 'convert ffff:ffff:ffee::/48 4' );

    # Test ::1 conversion
    @net = ipv6NetConvert('::1');
    is( scalar(@net), 1, 'convert ::1 1' );
    is( inet_ntop( AF_INET6(), pack 'NNNN', @{ $net[0] } ),
        '::1', 'convert ::1 2' );

    # Test foo & undef
    @net = ipv6NetConvert('foo');
    is( scalar(@net), 0, 'convert foo 1' );
    @net = ipv6NetConvert(undef);
    is( scalar(@net), 0, 'convert undef 1' );

    # Test intersection of 192.168.0.0/24 and 192.168.0.128/25
    is( ipv6NetIntersect(qw(fe80::212:e9dd:fed9:a1f9 fe80::/64)),
        -1, 'netIntersect 1' );

    # Test intersection of 192.168.0.0/24 and 192.168.0.128/25
    is( ipv6NetIntersect(qw(fe80::/64 fe80::212:e9dd:fed9:a1f9)),
        1, 'netIntersect 2' );

    # Test intersection of 192.168.0.0/24 and 10.0.0.0/8
    is( ipv6NetIntersect(qw(fe81::/64 fe80::212:e9dd:fed9:a1f9)),
        0, 'netIntersect 3' );

    # Test intersection of 192.168.0.0/24 and 192.168.0.0/16
    is( ipv6NetIntersect(qw(fe80::/64 fe81::/64)), 0, 'netIntersect 4' );

    # Test intersection of 192.168.0.0/24 and 192.168.0.53
    is( ipv6NetIntersect(qw(192.168.0.0 fe80::212:e9dd:fed9:a1f9)),
        0, 'netIntersect 5' );

    # Test intersection of 192.168.0.0/24 and 10.0.0.53
    is( ipv6NetIntersect(qw(192.168.0.0/24 10.0.0.53)), 0, 'netIntersect 6' );

    # Test intersection of 192.168.0.0/24 and foo
    is( ipv6NetIntersect(qw(192.168.0.0/24 foo)), 0, 'netIntersect 7' );

    # Test intersection of bar and foo
    is( ipv6NetIntersect(qw(bar foo)), 0, 'netIntersect 8' );

    # Test intersection of bar and undef
    is( ipv6NetIntersect( qw(bar), 'undef' ), 0, 'netIntersect 9' );

    # Test ipv6NetPacked
    @net = ipv6NetConvert('ff::1');
    my @p = ipv6NetPacked('ff::1');
    is( $p[0], pack( 'NNNN', @{ $net[0] } ), 'netPacked 1' );

    # Test IPv6 string sort
    my @nets   = qw( fe80::8d46 a2e0:f4::3/64 ::1/128 );
    my @sorted = sort ipv6StrSort @nets;
    is( $sorted[0], '::1/128',       'ipv6StrSort 1' );
    is( $sorted[1], 'a2e0:f4::3/64', 'ipv6StrSort 2' );
    is( $sorted[2], 'fe80::8d46',    'ipv6StrSort 3' );

    # Test IPv6 packed sort
    foreach (@nets) { $_ =~ s#/\d+$## };    #
    foreach (@nets) { $_ = inet_pton( AF_INET6(), $_ ) }
    @sorted = sort ipv6PackedSort @nets;
    is( $sorted[0], $nets[2], 'ipv6PackedSort 1' );
    is( $sorted[1], $nets[1], 'ipv6PackedSort 2' );
    is( $sorted[2], $nets[0], 'ipv6PackedSort 3' );

    # Test IPv6 num sort
    foreach (@nets) { $_ = [ unpack 'NNNN', $_ ] }
    @sorted = sort ipv6NumSort @nets;
    is( $sorted[0], $nets[2], 'ipv6PackedSort 1' );
    is( $sorted[1], $nets[1], 'ipv6PackedSort 2' );
    is( $sorted[2], $nets[0], 'ipv6PackedSort 3' );
}

