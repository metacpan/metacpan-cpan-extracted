#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan skip_all => "pcap_open_dead() is not available" unless is_available('pcap_open_dead');
plan tests => 5;

my $has_test_exception = eval "use Test::Exception; 1";

my($pcap,$datalink) = ('',0);  # datalink == DLT_NULL => no link-layer encapsulation

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 1 unless $has_test_exception;

    # open_dead() errors
    throws_ok(sub {
        Net::Pcap::open_dead()
    }, '/^Usage: Net::Pcap::open_dead\(linktype, snaplen\)/',
       "calling open_dead() with no argument");
}

# Testing open_dead()
eval { $pcap = Net::Pcap::open_dead($datalink, 1024) };
is( $@, '', "open_dead()" );
ok( defined $pcap, " - \$pcap is defined" );
isa_ok( $pcap, 'SCALAR', " - \$pcap" );
isa_ok( $pcap, 'pcap_tPtr', " - \$pcap" );
