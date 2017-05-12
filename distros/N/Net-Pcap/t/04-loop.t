#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my $total = 10;  # number of packets to process

plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => $total * 19 + 5;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$err) = ('','','');

# Find a device and open it
$dev = find_network_device();
$pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 2 unless $has_test_exception;

    # loop() errors
    throws_ok(sub {
        Net::Pcap::loop()
    }, '/^Usage: Net::Pcap::loop\(p, cnt, callback, user\)/', 
       "calling loop() with no argument");

    throws_ok(sub {
        Net::Pcap::loop(0, 0, 0, 0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling loop() with incorrect argument type");

}

# Testing loop()
my $user_text = "Net::Pcap test suite";
my $count = 0;

sub process_packet {
    my($user_data, $header, $packet) = @_;

    pass( "process_packet() callback" );
    is( $user_data, $user_text, " - user data is the expected text" );
    ok( defined $header,        " - header is defined" );
    isa_ok( $header, 'HASH',    " - header" );

    for my $field (qw(len caplen tv_sec tv_usec)) {
        ok( exists $header->{$field}, "    - field '$field' is present" );
        ok( defined $header->{$field}, "    - field '$field' is defined" );
        like( $header->{$field}, '/^\d+$/', "    - field '$field' is a number" );
    }

    ok( $header->{caplen} <= $header->{len}, "    - coherency check: packet length (caplen <= len)" );

    ok( defined $packet,        " - packet is defined" );
    is( length $packet, $header->{caplen}, " - packet has the advertised size" );

    $count++;
}

my $retval = eval { Net::Pcap::loop($pcap, $total, \&process_packet, $user_text) };
is(   $@,   '', "loop()" );
is( $count, $total, "all packets processed" );
is( $retval, 0, "checking return value" );

Net::Pcap::close($pcap);
