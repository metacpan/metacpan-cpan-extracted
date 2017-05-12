#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my $total = 1;  # number of packets to process

plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => $total * 11 + 5;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$dumper,$dump_file,$err) = ('','','','');

# Find a device and open it
$dev = find_network_device();
$pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 2 unless $has_test_exception;

    # dispatch() errors
    throws_ok(sub {
        Net::Pcap::dispatch()
    }, '/^Usage: Net::Pcap::dispatch\(p, cnt, callback, user\)/', 
       "calling dispatch() with no argument");

    throws_ok(sub {
        Net::Pcap::dispatch(0, 0, 0, 0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling dispatch() with incorrect argument type");

}

my $user_text = "Net::Pcap test suite";
my $count = 0;

sub process_packet {
    my($user_data, $header, $packet) = @_;
    my %stats = ();

    eval { Net::Pcap::stats($pcap, \%stats) };
    is(   $@,   '', "stats()" );
    is( keys %stats, 3, " - %stats has 3 elements" );

    for my $field (qw(ps_recv ps_drop ps_ifdrop)) {
        ok( exists $stats{$field}, "    - field '$field' is present" );
        ok( defined $stats{$field}, "    - field '$field' is defined" );
        like( $stats{$field}, '/^\d+$/', "    - field '$field' is a number" );
    }

    $count++;
}

my $retval = 0;
eval { $retval = Net::Pcap::dispatch($pcap, $total, \&process_packet, $user_text) };
is(   $@,   '', "dispatch()" );

SKIP: {
    skip "not enought packets or other unknown problem", 
      11 * ($total - $count) + 2 if $count < $total;
    is( $count, $total, "checking the number of processed packets" );
    is( $retval, $count, "checking return value" );
}

Net::Pcap::close($pcap);

