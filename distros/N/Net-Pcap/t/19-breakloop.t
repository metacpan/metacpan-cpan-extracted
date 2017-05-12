#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan skip_all => "pcap_breakloop() is not available" unless is_available('pcap_breakloop');
plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => 5;

my $has_test_exception = eval "use Test::Exception; 1";

my $total = 10;  # number of packets to process

my($dev,$pcap,$dumper,$dump_file,$err) = ('','','','');

# Find a device and open it
$dev = find_network_device();
$pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 2 unless $has_test_exception;

    # breakloop() errors
    throws_ok(sub {
        Net::Pcap::breakloop()
    }, '/^Usage: Net::Pcap::breakloop\(p\)/', 
       "calling breakloop() with no argument");

    throws_ok(sub {
        Net::Pcap::breakloop(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling breakloop() with incorrect argument type");
}

# Testing stats()
my $user_text = "Net::Pcap test suite";
my $count = 0;

sub process_packet {
    my($user_data, $header, $packet) = @_;
    my %stats = ();

    if(++$count == $total/2) {
        eval { Net::Pcap::breakloop($pcap) };
        is( $@, '', "breakloop()" );
    }
}

my $r = Net::Pcap::loop($pcap, $total, \&process_packet, $user_text);
ok( ($r == -2 or $r == $count), "checking loop() return value" );
is( $count, $total/2, "half the packets processed" );

# Note: I'm not sure why $count is always $total/2 even when $r == -2
# Maybe I just don't understand what the docmentation says. 
# Or maybe I shouldn't write tests at 02:10 %-)

Net::Pcap::close($pcap);
