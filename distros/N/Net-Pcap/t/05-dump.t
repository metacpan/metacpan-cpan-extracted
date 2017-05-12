#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my $total = 10;  # number of packets to process

plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => $total * 22 + 20;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$dumper,$dump_file,$err) = ('','','','');

# Find a device and open it
$dev = find_network_device();
$pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 10 unless $has_test_exception;

    # dump_open() errors
    throws_ok(sub {
        Net::Pcap::dump_open()
    }, '/^Usage: Net::Pcap::dump_open\(p, fname\)/', 
       "calling dump_open() with no argument");

    throws_ok(sub {
        Net::Pcap::dump_open(0, 0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling dump_open() with incorrect argument type");

    # dump() errors
    throws_ok(sub {
        Net::Pcap::dump()
    }, '/^Usage: Net::Pcap::dump\(p, pkt_header, sp\)/', 
       "calling dump() with no argument");

    throws_ok(sub {
        Net::Pcap::dump(0, 0, 0)
    }, '/^p is not of type pcap_dumper_tPtr/', 
       "calling dump() with incorrect argument type for arg1");

    # dump_close() errors
    throws_ok(sub {
        Net::Pcap::dump_close()
    }, '/^Usage: Net::Pcap::dump_close\(p\)/', 
       "calling dump_close() with no argument");

    throws_ok(sub {
        Net::Pcap::dump_close(0)
    }, '/^p is not of type pcap_dumper_tPtr/', 
       "calling dump_close() with incorrect argument type");

    # dump_file() errors
    throws_ok(sub {
        Net::Pcap::dump_file()
    }, '/^Usage: Net::Pcap::dump_file\(p\)/', 
       "calling dump_file() with no argument");

    throws_ok(sub {
        Net::Pcap::dump_file(0)
    }, '/^p is not of type pcap_dumper_tPtr/', 
       "calling dump_file() with incorrect argument type");

    SKIP: {
        skip "pcap_dump_flush() is not available", 2 unless is_available('pcap_dump_flush');

        # dump_flush() errors
        throws_ok(sub {
            Net::Pcap::dump_flush()
        }, '/^Usage: Net::Pcap::dump_flush\(p\)/', 
            "calling dump_flush() with no argument");

        throws_ok(sub {
            Net::Pcap::dump_flush(0)
        }, '/^p is not of type pcap_dumper_tPtr/', 
            "calling dump_flush() with incorrect argument type");
    }
}

# Testing dump_open()
eval q{ use File::Temp qw(:mktemp); $dump_file = mktemp('pcap-XXXXXX') };
$dump_file ||= "pcap-$$.dmp";
my $user_text = "Net::Pcap test suite";
my $count = 0;
my $size = 0;

eval { $dumper = Net::Pcap::dump_open($pcap, $dump_file) };
is(   $@,   '', "dump_open()" );
ok( defined $dumper, " - dumper is defined" );

TODO: {
    todo_skip "Hmm.. when executed, dump_file() corrupts something somewhere, making this script dumps core at the end", 3;
    my $filehandle;
    eval { $filehandle = Net::Pcap::dump_file($dumper) };
    is( $@, '', "dump_file()" );
    ok( defined $filehandle, "returned filehandle is defined" );
    isa_ok( $filehandle, 'GLOB', "\$filehandle" );
}

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 1 unless $has_test_exception;

    # dump() errors
    throws_ok(sub {
        Net::Pcap::dump($dumper, 0, 0)
    }, '/^arg2 not a hash ref/', 
       "calling dump() with incorrect argument type for arg2");

}

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

    ok( $header->{caplen} <= $header->{len}, "    - caplen <= len" );

    ok( defined $packet,        " - packet is defined" );
    is( length $packet, $header->{caplen}, " - packet has the advertised size" );

    eval { Net::Pcap::dump($dumper, $header, $packet) };
    is(   $@,   '', "dump()");

    SKIP: {
        skip "pcap_dump_flush() is not available", 2 unless is_available('pcap_dump_flush');
        my $r;
        eval { $r = Net::Pcap::dump_flush($dumper) };
        is(   $@,   '', "dump_flush()");
        is( $r, 0, " - result: $r" );
    }

    $size += $header->{caplen};
    $count++;
}

Net::Pcap::loop($pcap, $total, \&process_packet, $user_text);
is( $count, $total, "all packets processed" );

eval { Net::Pcap::dump_close($dumper) };
is(   $@,   '', "dump_close()" );
ok( -f $dump_file, "dump file created" );
ok( -s $dump_file >= $size, "dump file size" );

unlink($dump_file);
Net::Pcap::close($pcap);

