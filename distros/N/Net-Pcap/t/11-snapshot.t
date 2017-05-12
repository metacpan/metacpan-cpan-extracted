#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my @sizes = (128, 512, 1024, 2048, 4096, 8192, int(10000*rand), int(10000*rand), int(10000*rand), int(10000*rand));  # snapshot sizes

plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => @sizes * 2 + 2;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$snapshot,$err) = ('','','','');

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 2 unless $has_test_exception;

    # snapshot() errors
    throws_ok(sub {
        Net::Pcap::snapshot()
    }, '/^Usage: Net::Pcap::snapshot\(p\)/', 
       "calling snapshot() with no argument");

    throws_ok(sub {
        Net::Pcap::snapshot(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling snapshot() with incorrect argument type");
}

# Find a device
$dev = find_network_device();

for my $size (@sizes) {
    # Open the device
    $pcap = Net::Pcap::open_live($dev, $size, 1, 100, \$err);

    # Testing snapshot()
    $snapshot = 0;
    eval { $snapshot = Net::Pcap::snapshot($pcap) };
    is( $@, '', "snapshot()" );
    is( $snapshot, $size, " - snapshot has the expected size" );
    Net::Pcap::close($pcap);
}

