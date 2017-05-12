#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Test::Deep;
use lib qw|../blib/lib ../blib/arch|;
use Net::MRT;

my @tests = (
        # Array rows:
        # - Test name
        # - Subtype (which subtype to decode)
        # - Message in HEX
        # - Decoded test (HASHREF)
        ########### SUBTYPE 1 TESTS - PEER_INDEX_TABLE ###########
        # Test head of PEER_INDEX_TABLE
        [   "Test PEER_INDEX_TABLE", 1,
            "0102030400000000",
            { 'collector_bgp_id' => '1.2.3.4', 'peers' => [], 'view_name' => undef }
        ],
        # Test view name
        [   "Test View name", 1,
            "01020304000A307454654573537454390000",
            { 'collector_bgp_id' => '1.2.3.4', 'peers' => [], 'view_name' => '0tTeEsStT9' }
        ],
        # Test peer entries
        [   "Test peer entries", 1,
            "010203040000000202010203040506070880FF090A010A0B0C0D20010DB80000000000000000DEADBEEF89AB",
            { 'collector_bgp_id' => '1.2.3.4', 'view_name' => undef,
              'peers' => [ {'as' => 0x80FF090A, 'bgp_id' => '1.2.3.4', 'peer_ip' => '5.6.7.8'},
                           {'as' => 0x89AB, 'bgp_id' => '10.11.12.13', 'peer_ip' => '2001:db8::dead:beef'}] }
        ],
        ########### SUBTYPE 2 & 4 TESTS ###########
        ## Sequence tests (formerly network to host order)
        [   "Test SEQUENCE=0", 2,
            "0000000008030000",
            { 'sequence' => 0, bits => 8, prefix => '3.0.0.0', 'entries' => [], }
        ],
        [   "Test SEQUENCE=1", 2,
            "0000000108030000",
            { 'sequence' => 1, bits => 8, prefix => '3.0.0.0', 'entries' => [], }
        ],
        [   "Test SEQUENCE=256", 2,
            "0000010008030000",
            { 'sequence' => 256, bits => 8, prefix => '3.0.0.0', 'entries' => [], }
        ],
        [   "Test SEQUENCE=4294967295", 2,
            "FFFFFFFF08030000",
            { 'sequence' => 4294967295, bits => 8, prefix => '3.0.0.0', 'entries' => [], }
        ],
        ## Prefix bits tests
        [   "Test IPv4 bits 0", 2,
            "00000000000000",
            { 'sequence' => 0, bits => 0, prefix => '0.0.0.0', 'entries' => [], }
        ],
        [   "Test IPv4 bits 1", 2,
            "0000000001800000",
            { 'sequence' => 0, bits => 1, prefix => '128.0.0.0', 'entries' => [], }
        ],
        [   "Test IPv4 bits 7", 2,
            "0000000007C00000",
            { 'sequence' => 0, bits => 7, prefix => '192.0.0.0', 'entries' => [], }
        ],
        [   "Test IPv4 bits 8", 2,
            "00000000087F0000",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [], }
        ],
        [   "Test IPv4 bits 9", 2,
            "00000000097F800000",
            { 'sequence' => 0, bits => 9, prefix => '127.128.0.0', 'entries' => [], }
        ],
        [   "Test IPv4 bits 23", 2,
            "00000000170102040000",
            { 'sequence' => 0, bits => 23, prefix => '1.2.4.0', 'entries' => [], }
        ],
        [   "Test IPv4 bits 24", 2,
            "00000000180102030000",
            { 'sequence' => 0, bits => 24, prefix => '1.2.3.0', 'entries' => [], }
        ],
        [   "Test IPv4 bits 25", 2,
            "0000000019010203800000",
            { 'sequence' => 0, bits => 25, prefix => '1.2.3.128', 'entries' => [], }
        ],
        [   "Test IPv4 bits 32", 2,
            "0000000020101214FF0000",
            { 'sequence' => 0, bits => 32, prefix => '16.18.20.255', 'entries' => [], }
        ],
        [   "Test IPv4 bits 0", 4,
            "00000000000000",
            { 'sequence' => 0, bits => 0, prefix => '::', 'entries' => [], }
        ],
        [   "Test IPv4 bits 1", 4,
            "0000000001800000",
            { 'sequence' => 0, bits => 1, prefix => '8000::', 'entries' => [], }
        ],
        [   "Test IPv4 bits 7", 4,
            "0000000007E00000",
            { 'sequence' => 0, bits => 7, prefix => 'e000::', 'entries' => [], }
        ],
        [   "Test IPv4 bits 8", 4,
            "0000000008200000",
            { 'sequence' => 0, bits => 8, prefix => '2000::', 'entries' => [], }
        ],
        [   "Test IPv4 bits 9", 4,
            "000000000920800000",
            { 'sequence' => 0, bits => 9, prefix => '2080::', 'entries' => [], }
        ],
        [   "Test IPv4 bits 23", 4,
            "00000000172001DE0000",
            { 'sequence' => 0, bits => 23, prefix => '2001:de00::', 'entries' => [], }
        ],
        [   "Test IPv4 bits 128", 4,
            "000000008020010DB8DEADBEEF0123456789ABCDEF0000",
            { 'sequence' => 0, bits => 128, prefix => '2001:db8:dead:beef:123:4567:89ab:cdef', 'entries' => [], }
        ],
        ## Entries testing ##
        [   "Test originated_time", 2,
            "00000000087F00018FFF7F3456780000",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, },
                ], }
        ],
        [   "Test originated_time=-1", 2,
            "00000000087F00018FFFFFFFFFFF0000",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => -1, },
                ], }
        ],
        [   "Test one entry (w/o BGP attributes)", 2,
            "00000000087F00018FFF7F3456780000",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, },
                ], }
        ],
        [   "Test two entries (w/o BGP attributes)", 2,
            "00000000087F00028FFF7F3456780000FF007F1234780000",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, },
                    { 'peer_index' => 0xFF00, 'originated_time' => 0x7F123478, },
                ], }
        ],
        ## Test BGP attributes ##
        # Test attribute short len & ORIGIN
        [   "Test BGP short len & attribute ORIGIN", 2,
            "00000000087F00018FFF7F345678000400010101",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'ORIGIN' => 1 },
                ], }
        ],
        # Test attribute extended len & ORIGIN
        [   "Test BGP extended len & attribute ORIGIN", 2,
            "00000000087F00018FFF7F34567800051001000101",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'ORIGIN' => 1 },
                ], }
        ],
        # Test attribute AS_PATH (AS_SET)
        [   "Test attribute AS_PATH (AS_SET)", 2,
            "00000000087F00018FFF7F345678000D00020A01020000123480123456",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'AS_PATH' => [[0x1234, 0x80123456]] },
                ], }
        ],
        # Test attribute AS_PATH (AS_SEQUENCE)
        [   "Test attribute AS_PATH (AS_SEQUENCE)", 2,
            "00000000087F00018FFF7F345678000D00020A02020000123480123456",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'AS_PATH' => [0x1234, 0x80123456] },
                ], }
        ],
        # Test attribute AS_PATH SEQ SET SEQ SET
        [   "Test attribute AS_PATH (SEQ SET SEQ SET)", 2,
            "00000000087F00018FFF7F345678003F00023C02040000000B0000000A00000009000000080104000000070000004D0000030900001E61020300000005000000040000000301020000000100000002",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678,
                        'AS_PATH' => [11, 10, 9, 8, [7, 77, 777, 7777], 5, 4, 3, [1, 2]] },
                ], }
        ],
        # Test attribute AS_PATH + AS_PATH
        [   "Test attribute AS_PATH + AS_PATH", 2,
            "00000000087F00018FFF7F345678001A40020A0202000012348012345640020A02020000432186543210",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'AS_PATH' => [0x1234, 0x80123456, 0x4321, 0x86543210] },
                ], }
        ],
        # Test attribute NEXT_HOP
        [   "Test attribute NEXT_HOP", 2,
            "00000000087F00018FFF7F345678000740030401020304",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['1.2.3.4'] },
                ], }
        ],
        # Test attribute MULTI_EXIT_DISC
        [   "Test attribute MULTI_EXIT_DISC", 2,
            "00000000087F00018FFF7F345678000700040486918275",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'MULTI_EXIT_DISC' => 0x86918275 },
                ], }
        ],
        # Test attribute LOCAL_PREF
        [   "Test attribute LOCAL_PREF", 2,
            "00000000087F00018FFF7F345678000700050485F7D302",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'LOCAL_PREF' => 0x85F7D302 },
                ], }
        ],
        # Test attribute ATOMIC_AGGREGATE
        [   "Test attribute ATOMIC_AGGREGATE", 2,
            "00000000087F00018FFF7F3456780003000600",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'ATOMIC_AGGREGATE' => undef },
                ], }
        ],
        # Test attribute AGGREGATOR
        [   "Test attribute AGGREGATOR (AGGREGATOR_AS & AGGREGATOR_BGPID)", 2,
            "00000000087F00018FFF7F345678000B000708FEDCBA980A0C0E01",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678,
                      'AGGREGATOR_AS' => 0xFEDCBA98, 'AGGREGATOR_BGPID' => '10.12.14.1', },
                ], }
        ],
        # Test attribute COMMUNITY
        [   "Test attribute COMMUNITY", 2,
            "00000000087F00018FFF7F345678000B40080800010001FFFEFDFB",
            { 'sequence' => 0, bits => 8, prefix => '127.0.0.0', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'COMMUNITY' => ['1:1', '65534:65019' ] },
                ], }
        ],
        # Test attribute NEXT_HOP (1xMP_REACH_NLRI; RFC6396)
        [   "Test attribute NEXT_HOP (1xMP_REACH_NLRI; RFC6396)", 4,
            "000000002020010DB800018FFF7F3456780014800E111020010DB8000000020000000000000124",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['2001:db8:0:2::124'] },
                ], }
        ],
        # Test attribute NEXT_HOP (2xMP_REACH_NLRI; RFC6396)
        [   "Test attribute NEXT_HOP (2xMP_REACH_NLRI; RFC6396)", 4,
            "000000002020010DB800018FFF7F3456780024800E212020010DB8000000020000000000000124FE8000000000000000000000DEADBEEF",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['2001:db8:0:2::124', 'fe80::dead:beef'] },
                ], }
        ],
        # Test attribute NEXT_HOP (MP_REACH_NLRI + NEXT_HOP; RFC6396)
        [   "Test attribute NEXT_HOP (NEXT_HOP + MP_REACH_NLRI; RFC6396)", 4,
            "000000002020010DB800018FFF7F345678002B40030401020304800E212020010DB8000000020000000000000124FE8000000000000000000000DEADBEEF",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678,
                      'NEXT_HOP' => ['1.2.3.4', '2001:db8:0:2::124', 'fe80::dead:beef'] },
                ], }
        ],
        [   sub { $Net::MRT::USE_RFC4760 = 1; } ], # Change variable
        # Test attribute NEXT_HOP (MP_REACH_NLRI AFI=1; No NLRI; RFC4760)
        [   "Test attribute NEXT_HOP (MP_REACH_NLRI AFI=1; No NLRI; RFC4760)", 4,
            "000000002020010DB800018FFF7F345678000C800E09000101040102030400",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['1.2.3.4'], 'MP_REACH_NLRI' => [], },
                ], }
        ],
        # Test attribute NEXT_HOP (MP_REACH_NLRI AFI=1; Two NEXT_HOP; No NLRI; RFC4760)
        [   "Test attribute NEXT_HOP (MP_REACH_NLRI AFI=1; Two NEXT_HOP; No NLRI; RFC4760)", 4,
            "000000002020010DB800018FFF7F345678001340030401020304800E09000101040708090A00",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678,
                      'NEXT_HOP' => ['1.2.3.4', '7.8.9.10'], 'MP_REACH_NLRI' => [], },
                ], }
        ],
        # Test attribute NEXT_HOP (MP_REACH_NLRI AFI=1; 3 NLRI; RFC4760)
        [   "Test attribute NEXT_HOP (MP_REACH_NLRI AFI=1; 3 NLRI; RFC4760)", 4,
            "000000002020010DB800018FFF7F3456780017800E14000101040102030400087F177F0102197F020380",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['1.2.3.4'],
                      'MP_REACH_NLRI' => [ '127.0.0.0/8', '127.1.2.0/23', '127.2.3.128/25' ], },
                ], }
        ],
        # Test attribute NEXT_HOP (MP_REACH_NLRI AFI=2; One N.H.; No NLRI; RFC4760)
        [   "Test attribute NEXT_HOP (MP_REACH_NLRI AFI=2; One N.H.; No NLRI; RFC4760)", 4,
            "000000002020010DB800018FFF7F3456780018800E150002011020010DB800000002000000000000012400",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['2001:db8:0:2::124'], 'MP_REACH_NLRI' => [], },
                ], }
        ],
        # Test attribute NEXT_HOP (MP_REACH_NLRI AFI=2; One N.H.; 2 NLRI; RFC4760)
        [   "Test attribute NEXT_HOP (MP_REACH_NLRI AFI=2; One N.H.; 2 NLRI; RFC4760)", 4,
            "000000002020010DB800018FFF7F3456780026800E230002011020010DB8000000020000000000000124002020010DB83F20010DB8DEADBEE0",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['2001:db8:0:2::124'],
                      'MP_REACH_NLRI' => [ '2001:db8::/32', '2001:db8:dead:bee0::/63' ], },
                ], }
        ],
        # Test attribute NEXT_HOP (MP_REACH_NLRI AFI=2; Two N.H.; No NLRI; RFC4760)
        [   "Test attribute NEXT_HOP (MP_REACH_NLRI AFI=2; One N.H.; No NLRI; RFC4760)", 4,
            "000000002020010DB800018FFF7F3456780028800E250002012020010DB8000000020000000000000124FE80000000000000DEADBEEF1234567800",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => ['2001:db8:0:2::124', 'fe80::dead:beef:1234:5678'],
                      'MP_REACH_NLRI' => [], },
                ], }
        ],

        [   sub { $Net::MRT::USE_RFC4760 = -1; } ], # Change variable
        # Test attribute NEXT_HOP (1xMP_REACH_NLRI processing disabled)
        [   "Test attribute NEXT_HOP (1xMP_REACH_NLRI processing disabled)", 4,
            "000000002020010DB800018FFF7F3456780014800E111020010DB8000000020000000000000124",
            { 'sequence' => 0, bits => 32, prefix => '2001:db8::', 'entries' => [
                    { 'peer_index' => 0x8FFF, 'originated_time' => 0x7F345678, 'NEXT_HOP' => [] },
                ], }
        ],
        [   sub { $Net::MRT::USE_RFC4760 = undef; } ], # Change variable
    );

plan tests => scalar(@tests);

foreach (@tests)
{
    if (ref(@{$_}[0]) eq 'CODE')
    {
        @{$_}[0]->();
        pass("No test here, only code block");
    } else {
        cmp_deeply(Net::MRT::mrt_decode_single(13, @{$_}[1], pack 'H*', @{$_}[2]), @{$_}[3], @{$_}[0]);
    }
}

done_testing();
