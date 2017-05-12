#!perl -T
use strict;
use Test::More;
use Net::Pcap qw(:openflag :mode);
use lib 't';
use Utils;

plan skip_all => "pcap_open() is not available" unless is_available('pcap_open');
plan tests => 24;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$r,$err) = ('','','','');

# Find a device and open it
$dev = find_network_device();

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 11 unless $has_test_exception;

    # pcap_open() errors
    throws_ok(sub {
        Net::Pcap::open()
    }, '/^Usage: Net::Pcap::open\(source, snaplen, flags, read_timeout, auth, err\)/', 
       "calling pcap_open() with no argument");

    throws_ok(sub {
        Net::Pcap::open(0, 0, 0, 0, 0, 0)
    }, '/^arg6 not a reference/', 
       "calling pcap_open() with incorrect argument type for arg6");

    throws_ok(sub {
        Net::Pcap::open(0, 0, 0, 0, 0, \$err)
    }, '/^arg5 not a hash ref/', 
       "calling pcap_open() with incorrect argument type for arg5");

    # setbuff() errors
    throws_ok(sub {
        Net::Pcap::setbuff()
    }, '/^Usage: Net::Pcap::setbuff\(p, dim\)/', 
       "calling setbuff() with no argument");

    throws_ok(sub {
        Net::Pcap::setbuff(0, 0)
    }, '/^arg1 not a reference/', 
       "calling setbuff() with no argument");

    # setuserbuffer() errors
    throws_ok(sub {
        Net::Pcap::userbuffer()
    }, '/^Usage: Net::Pcap::setbuff\(p, size\)/', 
       "calling userbuffer() with no argument");

    throws_ok(sub {
        Net::Pcap::userbuffer(0, 0)
    }, '/^arg1 not a reference/', 
       "calling userbuffer() with no argument");

    # setmode() errors
    throws_ok(sub {
        Net::Pcap::setmode()
    }, '/^Usage: Net::Pcap::setmode\(p, mode\)/', 
       "calling setmode() with no argument");

    throws_ok(sub {
        Net::Pcap::setmode(0, 0)
    }, '/^arg1 not a reference/', 
       "calling setmode() with no argument");

    # setmintocopy() errors
    throws_ok(sub {
        Net::Pcap::setmintocopy()
    }, '/^Usage: Net::Pcap::setmintocopy\(p, size\)/', 
       "calling setmintocopy() with no argument");

    throws_ok(sub {
        Net::Pcap::setmintocopy(0, 0)
    }, '/^arg1 not a reference/', 
       "calling setmintocopy() with no argument");

}

SKIP: {
    skip "must be run as root", 13 unless is_allowed_to_use_pcap();
    skip "no network device available", 13 unless find_network_device();

    # Testing pcap_open()
    $pcap = eval { Net::Pcap::open($dev, 1000, OPENFLAG_PROMISCUOUS, 1000, undef, \$err) };
    is( $@, '', "pcap_open()" );
    is( $err, '', " - \$err must be null: $err" );
    ok( defined $pcap, " - returned a defined value" );
    isa_ok( $pcap, 'SCALAR', " - \$pcap" );
    isa_ok( $pcap, 'pcap_tPtr', " - \$pcap" );

    # Testing setbuff()
    $r = eval { Net::Pcap::setbuff($pcap, 8*1024) };
    is( $@, '', "setbuff()" );
    is( $r, 0, " - return 0 for true" );

    # Testing setuserbuffer()
    $r = eval { Net::Pcap::setuserbuffer($pcap, 8*1024) };
    is( $@, '', "setuserbuffer()" );
    is( $r, 0, " - return 0 for true" );

    # Testing setmode()
    $r = eval { Net::Pcap::setmode($pcap, MODE_CAPT) };
    is( $@, '', "setmode()" );
    is( $r, 0, " - return 0 for true" );

    # Testing setmintocopy()
    $r = eval { Net::Pcap::setmintocopy($pcap, 8*1024) };
    is( $@, '', "setmintocopy()" );
    is( $r, 0, " - return 0 for true" );

    Net::Pcap::close($pcap);
}
