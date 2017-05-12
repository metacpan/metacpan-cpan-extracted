#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => 14;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$err) = ('','','');


# Testing error messages
SKIP: {
    skip "Test::Exception not available", 4 unless $has_test_exception;

    # open_live() errors
    throws_ok(sub {
        Net::Pcap::open_live()
    }, '/^Usage: Net::Pcap::open_live\(device, snaplen, promisc, to_ms, err\)/', 
       "calling open_live() with no argument");

    throws_ok(sub {
        Net::Pcap::open_live(0, 0, 0, 0, 0)
    }, '/^arg5 not a reference/', 
       "calling open_live() with no reference for arg5");

    # close() errors
    throws_ok(sub {
        Net::Pcap::close()
    }, '/^Usage: Net::Pcap::close\(p\)/', 
       "calling close() with no argument");

    throws_ok(sub {
        Net::Pcap::close(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling close() with incorrect argument type");

}

# Find a device
$dev = find_network_device();

# Testing open_live()
eval { $pcap = Net::Pcap::open_live($dev, 1024, 1, 0, \$err) };
is(   $@,   '', "open_live()" );
is(   $err, '', " - \$err must be null: $err" ); $err = '';
ok( defined $pcap, " - \$pcap is defined" );
isa_ok( $pcap, 'SCALAR', " - \$pcap" );
isa_ok( $pcap, 'pcap_tPtr', " - \$pcap" );

# Testing close()
eval { Net::Pcap::close($pcap) };
is(   $@,   '', "close()" );
is(   $err, '', " - \$err must be null: $err" ); $err = '';

# Testing open_live() with fake device name
my $fakedev = 'this is not a device';
eval { $pcap = Net::Pcap::open_live($fakedev, 1024, 1, 0, \$err) };
is(   $@,   '', "open_live()" );
cmp_ok( length($err), '>', 0, " - \$err must be set: $err" );
is( $pcap, undef, " - \$pcap isn't defined" );
$err = '';

