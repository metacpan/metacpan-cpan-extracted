#!perl -T
use strict;
use File::Spec;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan skip_all => "no network device available" unless find_network_device();
plan tests => 21;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$filehandle,$fileno,$err) = ('','','','','');

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 6 unless $has_test_exception;

    # file() errors
    throws_ok(sub {
        Net::Pcap::file()
    }, '/^Usage: Net::Pcap::file\(p\)/', 
       "calling file() with no argument");

    throws_ok(sub {
        Net::Pcap::file(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling file() with incorrect argument type");

    # fileno() errors
    throws_ok(sub {
        Net::Pcap::fileno()
    }, '/^Usage: Net::Pcap::fileno\(p\)/', 
       "calling fileno() with no argument");

    throws_ok(sub {
        Net::Pcap::fileno(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling fileno() with incorrect argument type");

    skip "pcap_get_selectable_fd() is not available", 2 unless is_available('pcap_get_selectable_fd');
    # get_selectable_fd() errors
    throws_ok(sub {
        Net::Pcap::get_selectable_fd()
    }, '/^Usage: Net::Pcap::get_selectable_fd\(p\)/', 
       "calling get_selectable_fd() with no argument");

    throws_ok(sub {
        Net::Pcap::get_selectable_fd(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling get_selectable_fd() with incorrect argument type");
}

SKIP: {
    skip "must be run as root", 7 unless is_allowed_to_use_pcap();

    # Find a device and open it
    $dev = find_network_device();
    $pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);
    isa_ok( $pcap, 'pcap_tPtr', "\$pcap" );

    # Testing file()
    $filehandle = 0;
    eval { $filehandle = Net::Pcap::file($pcap) };
    is( $@, '', "file() on a live connection" );
    is( $filehandle, undef, " - returned filehandle should be undef" );

    # Testing fileno()
    $fileno = undef;
    eval { $fileno = Net::Pcap::fileno($pcap) };
    is( $@, '', "fileno() on a live connection" );
    like( $fileno, '/^\d+$/', " - fileno must be an integer: $fileno" );

    skip "pcap_get_selectable_fd() is not available", 2 unless is_available('pcap_get_selectable_fd');
    # Testing get_selectable_fd()
    $fileno = undef;
    eval { $fileno = Net::Pcap::get_selectable_fd($pcap) };
    is( $@, '', "get_selectable_fd() on a live connection" );
    like( $fileno, '/^\d+$/', " - fileno must be an integer: $fileno" );

    Net::Pcap::close($pcap);
}

# Open a sample dump
$pcap = Net::Pcap::open_offline(File::Spec->catfile(qw(t samples ping-ietf-20pk-be.dmp)), \$err);
isa_ok( $pcap, 'pcap_tPtr', "\$pcap" );

# Testing file()
TODO: {
    todo_skip "file() on a dump file currently causes a segmentation fault", 3;
    eval { $filehandle = Net::Pcap::file($pcap) };
    is( $@, '', "file() on a dump file" );
    ok( defined $filehandle, " - returned filehandle must be defined" );
    isa_ok( $filehandle, 'GLOB', " - \$filehandle" );
}

# Testing fileno()
eval { $fileno = Net::Pcap::fileno($pcap) };
is( $@, '', "fileno() on a dump file" );
# fileno() is documented to return -1 when called on save file, but seems 
# to always return an actual file number. 
TODO: {
    local $TODO = " => result should be -1";
    like( $fileno, '/^(?:\d+|-1)$/', " - fileno must be an integer: $fileno" );
}

# Testing get_selectable_fd()
SKIP: {
    skip "pcap_get_selectable_fd() is not available", 2 unless is_available('pcap_get_selectable_fd');
    $fileno = undef;
    eval { $fileno = Net::Pcap::get_selectable_fd($pcap) };
    is( $@, '', "get_selectable_fd() on a dump file" );
    like( $fileno, '/^\d+$/', " - fileno must be an integer: $fileno" );
}

Net::Pcap::close($pcap);

