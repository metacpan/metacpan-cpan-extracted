#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Socket::Packet qw( AF_PACKET pack_sockaddr_ll unpack_sockaddr_ll );

my $sll = pack_sockaddr_ll( 1, 2, 3, 4, "ABCDE" );
ok( defined $sll, 'pack_sockaddr_ll returnes defined' );
is( length $sll, 20, 'packed sockaddr_ll is 20 byte structure' );

is( [ unpack( "s n i s c c a8", $sll ) ],
    [ AF_PACKET, 1, 2, 3, 4, 5, "ABCDE\0\0\0" ],
    'packed sockaddr_ll sll field members' );

is( [ unpack_sockaddr_ll( $sll ) ],
    [ 1, 2, 3, 4, "ABCDE" ],
    'unpack_sockaddr_ll' );

done_testing;
