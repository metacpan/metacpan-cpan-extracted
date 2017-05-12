#!perl -T
use strict;
use File::Spec;
use Test::More;
use Net::Pcap;

plan tests => 5;

my($pcap,$err) = ('','');

# from perlport/"Numbers endianness and Width"
my $is_big_endian    = unpack("h*", pack("s", 1)) =~ /01/;
my $is_little_endian = unpack("h*", pack("s", 1)) =~ /^1/;

is( $is_big_endian, !$is_little_endian, "checking flags consistency" );
my $type = $is_big_endian ? "big" : "little";
diag("This platform has been detected as a $type endian architecture");

# make these values numbers because is_swapped() return 0 or 1, not true or false
$is_big_endian += 0;  $is_little_endian += 0;

# testing with a big endian dump
$pcap = Net::Pcap::open_offline(File::Spec->catfile(qw(t samples ping-ietf-20pk-be.dmp)), \$err);
isa_ok( $pcap, 'pcap_tPtr', "\$pcap" );
is( Net::Pcap::is_swapped($pcap) , $is_little_endian, "testing with a big endian dump" );
Net::Pcap::close($pcap);

# testing with a little endian dump
$pcap = Net::Pcap::open_offline(File::Spec->catfile(qw(t samples ping-ietf-20pk-le.dmp)), \$err);
isa_ok( $pcap, 'pcap_tPtr', "\$pcap" );
is( Net::Pcap::is_swapped($pcap) , $is_big_endian, "testing with a little endian dump" );
Net::Pcap::close($pcap);
