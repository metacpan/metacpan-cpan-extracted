#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Net::BitTorrent::PeerPacket qw(:all);

my @packet_tests = (
    {
        name   => 'Handshake Packet',
        parsed => {
            bt_code   => BT_HANDSHAKE,
            protocol  => 'BitTorrent protocol',
            info_hash => 'A' x 20,
            peer_id   => 'B' x 20,
        },
        unparsed => "\x{13}" .    # constant size
          'BitTorrent protocol' . # protocol name
          "\x{00}" x 8 .          # reserved space
          'A' x 20 .              # info hash
          'B' x 20                # peer id
        ,
    },
    {
        name     => 'Choke Packet',
        parsed   => { bt_code => BT_CHOKE },
        unparsed => "\x{00}\x{00}\x{00}\x{01}" .    # packet size
          "\x{00}",                                 # packet type
    },
    {
        name     => 'Unchoke Packet',
        parsed   => { bt_code => BT_UNCHOKE },
        unparsed => "\x{00}\x{00}\x{00}\x{01}" .    # packet size
          "\x{01}",                                 # packet type
    },
    {
        name     => 'Interested Packet',
        parsed   => { bt_code => BT_INTERESTED },
        unparsed => "\x{00}\x{00}\x{00}\x{01}" .    # packet size
          "\x{02}",                                 # packet type
    },
    {
        name     => 'Uninterested Packet',
        parsed   => { bt_code => BT_UNINTERESTED },
        unparsed => "\x{00}\x{00}\x{00}\x{01}" .      # packet size
          "\x{03}",                                   # packet type
    },
    {
        name   => 'Have Packet',
        parsed => {
            bt_code     => BT_HAVE,
            piece_index => 1
        },
        unparsed => "\x{00}\x{00}\x{00}\x{05}" .      # packet size
          "\x{04}" .                                  # packet type
          "\x{00}\x{00}\x{00}\x{01}",                 # piece index
    },
    {
        name   => 'Bitfield Packet',
        parsed => {
            bt_code      => BT_BITFIELD,
            bitfield_ref => \"\x{FF}\x{FF}\x{FF}"
        },
        unparsed => "\x{00}\x{00}\x{00}\x{04}" .      # packet size
          "\x{05}" .                                  # packet type
          "\x{FF}\x{FF}\x{FF}",                       # bitfield
    },
    {
        name   => 'Request Packet',
        parsed => {
            bt_code      => BT_REQUEST,
            piece_index  => 1,
            block_offset => 0,
            block_size   => 65536
        },
        unparsed => "\x{00}\x{00}\x{00}\x{0D}" .      # packet size
          "\x{06}" .                                  # packet type
          "\x{00}\x{00}\x{00}\x{01}" .                # piece index
          "\x{00}\x{00}\x{00}\x{00}" .                # block offset
          "\x{00}\x{01}\x{00}\x{00}",                 # block size
    },
    {
        name   => 'Piece Packet',
        parsed => {
            bt_code      => BT_PIECE,
            piece_index  => 1,
            block_offset => 0,
            data_ref     => \"\x{FF}\x{FF}\x{FF}"
        },
        unparsed => "\x{00}\x{00}\x{00}\x{0C}" .      # packet size
          "\x{07}" .                                  # packet type
          "\x{00}\x{00}\x{00}\x{01}" .                # piece index
          "\x{00}\x{00}\x{00}\x{00}" .                # block offset
          "\x{FF}\x{FF}\x{FF}",                       # data
    },
    {
        name   => 'Cancel Packet',
        parsed => {
            bt_code      => BT_CANCEL,
            piece_index  => 1,
            block_offset => 0,
            block_size   => 65536
        },
        unparsed => "\x{00}\x{00}\x{00}\x{0D}" .      # packet size
          "\x{08}" .                                  # packet type
          "\x{00}\x{00}\x{00}\x{01}" .                # piece index
          "\x{00}\x{00}\x{00}\x{00}" .                # block offset
          "\x{00}\x{01}\x{00}\x{00}",                 # block size
    },
);

plan tests => scalar(@packet_tests) * 2;

for my $packet_test (@packet_tests) {
    my $binary_packet = bt_build_packet( %{ $packet_test->{parsed} } );
    is(
        $binary_packet,
        $packet_test->{unparsed},
        'Build ' . $packet_test->{name}
    );

    my $parsed_packet = bt_parse_packet( \$packet_test->{unparsed} );

    # de-reference references for some fields so that tests pass
    for my $ref_name ( 'data_ref', 'bitfield_ref' ) {
        if ( defined $packet_test->{parsed}->{$ref_name} ) {
            $packet_test->{parsed}->{$ref_name} =
              ${ $packet_test->{parsed}->{$ref_name} };

            $parsed_packet->{$ref_name} = ${ $parsed_packet->{$ref_name} };
        }
    }

    is_deeply(
        $parsed_packet,
        $packet_test->{parsed},
        'Parse ' . $packet_test->{name}
    );
}
