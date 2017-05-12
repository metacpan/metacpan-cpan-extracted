#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan tests => 29;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$net,$mask,$pcap,$filter,$res,$err) = ('','',0,'','','','');

# Find a device
$dev = find_network_device();
$res = Net::Pcap::lookupnet($dev, \$net, \$mask, \$err);

SKIP: {
    skip "pcap_compile_nopcap() is not available", 7 
        unless is_available('pcap_compile_nopcap');

    # Testing error messages
    SKIP: {
        skip "Test::Exception not available", 2 unless $has_test_exception;

        # compile_nopcap()
        throws_ok(sub {
            Net::Pcap::compile_nopcap()
        }, '/^Usage: Net::Pcap::compile_nopcap\(snaplen, linktype, fp, str, optimize, mask\)/', 
           "calling compile_nopcap() with no argument");

        throws_ok(sub {
            Net::Pcap::compile_nopcap(0, 0, 0, 0, 0, 0)
        }, '/^arg3 not a reference/', 
           "calling compile_nopcap() with incorrect argument type for arg2");
    }

    # Testing compile_nopcap()
    eval { $res = Net::Pcap::compile_nopcap(1024, DLT_EN10MB, \$filter, "tcp", 0, $mask) };
    is(   $@,   '', "compile_nopcap()" );
    is(   $res,  0, " - result must be null: $res" );
    ok( defined $filter, " - \$filter is defined" );
    isa_ok( $filter, 'SCALAR', " - \$filter" );
    isa_ok( $filter, 'pcap_bpf_program_tPtr', " - \$filter" );
}


SKIP: {
    skip "must be run as root", 22 unless is_allowed_to_use_pcap();
    skip "no network device available", 22 unless find_network_device();

    # Open the device
    $pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

    # Testing error messages
    SKIP: {
        skip "Test::Exception not available", 10 unless $has_test_exception;

        # compile() errors
        throws_ok(sub {
            Net::Pcap::compile()
        }, '/^Usage: Net::Pcap::compile\(p, fp, str, optimize, mask\)/', 
           "calling compile() with no argument");

        throws_ok(sub {
            Net::Pcap::compile(0, 0, 0, 0, 0)
        }, '/^p is not of type pcap_tPtr/', 
           "calling compile() with incorrect argument type for arg1");

        throws_ok(sub {
            Net::Pcap::compile($pcap, 0, 0, 0, 0)
        }, '/^arg2 not a reference/', 
           "calling compile() with incorrect argument type for arg2");

        # geterr() errors
        throws_ok(sub {
            Net::Pcap::geterr()
        }, '/^Usage: Net::Pcap::geterr\(p\)/', 
           "calling compile() with no argument");

        throws_ok(sub {
            Net::Pcap::geterr(0)
        }, '/^p is not of type pcap_tPtr/', 
           "calling geterr() with incorrect argument type for arg1");

        # setfilter() errors
        throws_ok(sub {
            Net::Pcap::setfilter()
        }, '/^Usage: Net::Pcap::setfilter\(p, fp\)/', 
           "calling setfilter() with no argument");

        throws_ok(sub {
            Net::Pcap::setfilter(0, 0)
        }, '/^p is not of type pcap_tPtr/', 
           "calling setfilter() with incorrect argument type for arg1");

        throws_ok(sub {
            Net::Pcap::setfilter($pcap, 0)
        }, '/^fp is not of type pcap_bpf_program_tPtr/', 
           "calling setfilter() with incorrect argument type for arg2");

        # freecode() errors
        throws_ok(sub {
            Net::Pcap::freecode()
        }, '/^Usage: Net::Pcap::freecode\(fp\)/', 
           "calling freecode() with no argument");

        throws_ok(sub {
            Net::Pcap::freecode(0)
        }, '/^fp is not of type pcap_bpf_program_tPtr/', 
           "calling freecode() with incorrect argument type for arg1");

    }

    # Testing compile()
    eval { $res = Net::Pcap::compile($pcap, \$filter, "tcp", 0, $mask) };
    is(   $@,   '', "compile()" );
    is(   $res,  0, " - result must be null: $res" );
    ok( defined $filter, " - \$filter is defined" );
    isa_ok( $filter, 'SCALAR', " - \$filter" );
    isa_ok( $filter, 'pcap_bpf_program_tPtr', " - \$filter" );

    # Testing geterr()
    eval { $err = Net::Pcap::geterr($pcap) };
    is(   $@,   '', "geterr()" );
    if($res == 0) {
        is(   $err, '', " - \$err should be null" )
    } else {
        isnt(   $err, '', " - \$err should not be null" )
    }

    # Testing setfilter()
    eval { $res = Net::Pcap::setfilter($pcap, $filter) };
    is(   $@,   '', "setfilter()" );
    is(   $res,  0, " - result should be null: $res" );

    # Testing freecode()
    eval { Net::Pcap::freecode($filter) };
    is(   $@,   '', "freecode()" );

    # Testing geterr()
    eval { $err = Net::Pcap::geterr($pcap) };
    is(   $@,   '', "geterr()" );
    if($res == 0) {
        is(   $err, '', " - \$err should be null" )
    } else {
        isnt(   $err, '', " - \$err should not be null" )
    }

    Net::Pcap::close($pcap);
}
