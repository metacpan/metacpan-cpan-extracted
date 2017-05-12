#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;

use Socket::Packet;

ok( defined PF_PACKET, 'PF_PACKET defined' );
ok( defined AF_PACKET, 'AF_PACKET defined' );

ok( defined PACKET_HOST,      'PACKET_HOST defined' );
ok( defined PACKET_BROADCAST, 'PACKET_BROADCAST defined' );
ok( defined PACKET_MULTICAST, 'PACKET_MULTICAST defined' );
ok( defined PACKET_OTHERHOST, 'PACKET_OTHERHOST defined' );
ok( defined PACKET_OUTGOING,  'PACKET_OUTGOING defined' );
