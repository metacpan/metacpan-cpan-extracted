# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use strict;
use Data::Dumper;

use Test::More tests => 27;
use t::TestFileIntoPackets;

#########################

BEGIN { use_ok('Net::Analysis::TCPMonologue') };

# Just check we can read packets etc.
my (@pkts) = @{tcpfile_into_packets ("t/t1_google.tcp")};
is (scalar(@pkts), 11, 'read in 11 packets from t1_google');

# Packets 4 and 6 form a short monologue. Test with them.

# Check the constructor constructs ...
my $mono = Net::Analysis::TCPMonologue->new();
isnt ($mono, undef, "TCPSession->new()");
is ("$mono", '[Mono undefined]', 'initial mono');

# Add the packets, and lazily brittle test via string_as() output ...
is ($mono->add_packet($pkts[4]), 1, 'packet added OK');
is ("$mono", '[Mono from     216.239.59.147:80]  0.000000s,   1pkts,   1368b',
    'mono, first packet');

is ($mono->add_packet($pkts[6]), 1, 'packet added OK');
is ("$mono", '[Mono from     216.239.59.147:80]  0.000069s,   2pkts,   2245b',
    'mono, second packet');

# Ensure accuracy of the time things
is (sprintf ("%017.6f", $mono->t_start()),  '1096989582.739317', 't_start');
is (sprintf ("%017.6f", $mono->t_end()),    '1096989582.739386', 't_end');
is (sprintf ("%017.6f", $mono->t_elapsed()),'0000000000.000069', 't_elapsed');

# Misc observers
is ($mono->n_packets(),    2, 'n_packets');
is ($mono->length(),    2245, 'length');
is_deeply ($mono->first_packet(), $pkts[4], 'first_packet');

# Check out which_pkt retrieval
is ($mono->which_pkt(-20), undef,                'which_pkt neg value');
is_deeply ($mono->which_pkt   (0), $pkts[4],     'byte    0 -> pkt 4');
is_deeply ($mono->which_pkt(1367), $pkts[4],     'byte 1367 -> pkt 4');
is_deeply ($mono->which_pkt(1368), $pkts[6],     'byte 1368 -> pkt 6');
is_deeply ($mono->which_pkt(2000), $pkts[6],     'byte 2000 -> pkt 6');
is ($mono->which_pkt($mono->length()+10), undef, 'which_pkt too big value');

my $i = 0;
my %pkt_id = map {$_ => $i++} @pkts;
my (@data) = ([ [   0      ] => [4]   ],
              [ [   0,  200] => [4]   ],
              [ [1400, 1800] => [6]   ],
              [ [   0, 1400] => [4,6] ],
              [ [ 333, 2800] => [4,6] ]);
foreach my $test (@data) {
    my ($args, $expected) = @$test;
    my @ret = map {$pkt_id{$_}} @{ $mono->which_pkts (@$args) };
    is_deeply (\@ret, $expected, "which_pkts (@$args) -> @$expected");
}

# concatenation of monologues
my $mono2 = Net::Analysis::TCPMonologue->new();
$mono2->add_packet($pkts[4]);
$mono2->add_packet($pkts[6]);

$mono->add_mono($mono2);
is ($mono->n_packets(),    4, 'n_packets after add_mono');
is ($mono->length(),    4490, 'length after add_mono');

__DATA__
