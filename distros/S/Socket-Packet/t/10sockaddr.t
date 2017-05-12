#!/usr/bin/perl

use strict;
use Test::More tests => 4;

use Socket::Packet qw( AF_PACKET pack_sockaddr_ll unpack_sockaddr_ll );

my $sll = pack_sockaddr_ll( 1, 2, 3, 4, "ABCDE" );
ok( defined $sll, 'pack_sockaddr_ll returnes defined' );
is( length $sll, 20, 'packed sockaddr_ll is 20 byte structure' );

is_deeply( [ unpack( "s n i s c c a8", $sll ) ],
           [ AF_PACKET, 1, 2, 3, 4, 5, "ABCDE\0\0\0" ],
           'packed sockaddr_ll sll field members' );

is_deeply( [ unpack_sockaddr_ll( $sll ) ],
           [ 1, 2, 3, 4, "ABCDE" ],
           'unpack_sockaddr_ll' );
