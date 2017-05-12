# $ cd Net-Analysis
# $ make test                        # Run all test files
# $ PERL5LIB=./lib perl t/00_stub.t  # Run just this test suite

# $Id: 04_Net-Analysis-Packet.t 143 2005-11-03 17:36:58Z abworrall $

use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 7;

use Net::Analysis::Constants qw(:packetclasses);

#########################

BEGIN { use_ok('Net::Analysis::Packet', qw(:all)) };

my $data = [];
$data->[PKT_SLOT_TO] = "1.2.3.4:80";
$data->[PKT_SLOT_FROM] = "10.0.0.1:1024";
$data->[PKT_SLOT_FLAGS] = 0x12;
$data->[PKT_SLOT_DATA] = 'some nice sample data';
$data->[PKT_SLOT_SEQNUM] = 23;
$data->[PKT_SLOT_ACKNUM] = 24;
$data->[PKT_SLOT_PKT_NUMBER] = 666;
$data->[PKT_SLOT_TV_SEC] = 1097432695;
$data->[PKT_SLOT_TV_USEC] = 123456;


my $pkt = [@$data];
$pkt = pkt_init($pkt);
isnt ($pkt, undef, "created packet");

like ($pkt->[PKT_SLOT_SOCKETPAIR_KEY], qr/$data->[PKT_SLOT_FROM]/,
      "socketpair correct");

my $str1 = "( 666 18:24:55.123456 10.0.0.1:1024-1.2.3.4:80) -SA     SEQ:23 ACK:24 21b";
my $str2 =<<EO;
( 666 18:24:55.123456 10.0.0.1:1024-1.2.3.4:80) -SA     SEQ:23 ACK:24 21b
 73 6f 6d 65 20 6e 69 63 65 20 73 61 6d 70 6c 65   {some nice sample}
 20 64 61 74 61                                    { data}
EO

is (pkt_as_string($pkt), $str1, "as_string");
is (pkt_as_string($pkt,1), $str2, "as_string(verbose)");

$str1 =~ s/-SA/*SA/; # Change the expected output to a known class
is (pkt_class($pkt,PKT_DATA), PKT_DATA, "->class(PKT_DATA)");
is (pkt_as_string($pkt), $str1, "as_string summary after class");

__END__
