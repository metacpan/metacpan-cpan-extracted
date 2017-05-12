#!/usr/bin/perl

use strict;
use Test::More tests => 4;

use Socket::Netlink qw( AF_NETLINK pack_sockaddr_nl unpack_sockaddr_nl );

my $snl = pack_sockaddr_nl( 123, 0x20 );
ok( defined $snl, 'pack_sockaddr_nl returns defined' );
is( length $snl, 12, 'packed sockaddr_nl is 12 byte structure' );

is_deeply( [ unpack( "s xx i I", $snl ) ],
           [ AF_NETLINK, 123, 0x20 ],
           'packed sockaddr_nl snl field members' );

is_deeply( [ unpack_sockaddr_nl( $snl ) ],
           [ 123, 0x20 ],
           'unpack_sockaddr_nl' );
