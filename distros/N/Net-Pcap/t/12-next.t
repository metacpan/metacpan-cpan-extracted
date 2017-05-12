#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my $total = 3;  # number of packets to process

plan skip_all => "pcap_next() behaves too strangely for being tested on random machines";
plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => $total * 16 + 4;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$net,$mask,$filter,$data,$r,$err) = ('','','','','','','');
my %header = ();

# Find a device and open it
$dev = find_network_device();
Net::Pcap::lookupnet($dev, \$net, \$mask, \$err);
$pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 3 unless $has_test_exception;

    # next() errors
    throws_ok(sub {
        Net::Pcap::next()
    }, '/^Usage: Net::Pcap::next\(p, pkt_header\)/', 
       "calling next() with no argument");

    throws_ok(sub {
        Net::Pcap::next(0, 0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling next() with incorrect argument type for arg1");

    throws_ok(sub {
        Net::Pcap::next($pcap, 0)
    }, '/^arg2 not a hash ref/', 
       "calling next() with incorrect argument type for arg2");

}

# Compile and set a filter
Net::Pcap::compile($pcap, \$filter, "ip", 0, $mask);
Net::Pcap::setfilter($pcap, $filter);

# Test next()
my $count = 0;
for (1..$total) {
    my($packet, %header);
    eval { $packet = Net::Pcap::next($pcap, \%header) };
    is( $@, '', "next()" );

    for my $field (qw(len caplen tv_sec tv_usec)) {
        ok( exists $header{$field}, " - field '$field' is present" );
        ok( defined $header{$field}, " - field '$field' is defined" );
        like( $header{$field}, '/^\d+$/', " - field '$field' is a number" );
    }

    ok( $header{caplen} <= $header{len}, " - coherency check: packet length (caplen <= len)" );

    ok( defined $packet, " - packet is defined" );
    is( length $packet, $header{caplen}, " - packet has the advertised size" );

    $count++;
}

is( $count, $total, "all packets processed" );

Net::Pcap::close($pcap);
