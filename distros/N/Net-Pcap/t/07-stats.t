#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my $total = 10;  # number of packets to process

plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => $total * 13 + 4;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$dumper,$dump_file,$err) = ('','','','');

# Find a device and open it
$dev = find_network_device();
$pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 3 unless $has_test_exception;

    # stats() errors
    throws_ok(sub {
        Net::Pcap::stats()
    }, '/^Usage: Net::Pcap::stats\(p, ps\)/', 
       "calling stats() with no argument");

    throws_ok(sub {
        Net::Pcap::stats(0, 0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling stats() with incorrect argument type");

    throws_ok(sub {
        Net::Pcap::stats($pcap, 0)
    }, '/^arg2 not a hash ref/', 
       "calling stats() with no reference for arg2");

}

# Testing stats()
my $user_text = "Net::Pcap test suite";
my $count = 0;

sub process_packet {
    my($user_data, $header, $packet) = @_;
    my %stats = ();

    my $r = undef;
    eval { $r = Net::Pcap::stats($pcap, \%stats) };
    is(   $@,   '', "stats()" );
    is(   $r,    0, " - should return zero" );
    is( keys %stats, 3, " - %stats has 3 elements" );

    for my $field (qw(ps_recv ps_drop ps_ifdrop)) {
        ok( exists $stats{$field}, "    - field '$field' is present" );
        ok( defined $stats{$field}, "    - field '$field' is defined" );
        like( $stats{$field}, '/^\d+$/', "    - field '$field' is a number" );
    }

    $count++;
    TODO: { local $TODO = "BUG: ps_recv not correctly set";
    is( $stats{ps_recv}, $count, "    -  coherency check: number of processed packets" );
    }
}

Net::Pcap::loop($pcap, $total, \&process_packet, $user_text);
is( $count, $total, "all packets processed" );

Net::Pcap::close($pcap);

