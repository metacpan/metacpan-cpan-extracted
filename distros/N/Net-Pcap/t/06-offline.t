#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my $total = 10;  # number of packets to process

plan skip_all => "must be run as root" unless is_allowed_to_use_pcap();
plan skip_all => "no network device available" unless find_network_device();
plan tests => $total * 19 * 2 + 23;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$dumper,$dump_file,$err) = ('','','','');

# Find a device and open it
$dev = find_network_device();
$pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 2 unless $has_test_exception;

    # open_offline() errors
    throws_ok(sub {
        Net::Pcap::open_offline()
    }, '/^Usage: Net::Pcap::open_offline\(fname, err\)/', 
       "calling open_offline() with no argument");

    throws_ok(sub {
        Net::Pcap::open_offline(0, 0)
    }, '/^arg2 not a reference/', 
       "calling open_offline() with incorrect argument type for arg2");

}

# Testing open_offline()
eval q{ use File::Temp qw(:mktemp); $dump_file = mktemp('pcap-XXXXXX'); };
$dump_file ||= "pcap-$$.dmp";

# calling open_offline() with a non-existent file name
eval { Net::Pcap::open_offline($dump_file, \$err) };
is(   $@,   '', "open_offline() with non existent dump file" );
isnt( $err, '', " - \$err is not null: $err" ); $err = '';

# creating a dump file
$dumper = Net::Pcap::dump_open($pcap, $dump_file);

my $user_text = "Net::Pcap test suite";
my $count = 0;
my @data1 = ();

sub store_packet {
    my($user_data, $header, $packet) = @_;

    pass( "process_packet() callback" );
    is( $user_data, $user_text, " - user data is the expected text" );
    ok( defined $header,        " - header is defined" );
    isa_ok( $header, 'HASH',    " - header" );

    for my $field (qw(len caplen tv_sec tv_usec)) {
        ok( exists $header->{$field}, "    - field '$field' is present" );
        ok( defined $header->{$field}, "    - field '$field' is defined" );
        like( $header->{$field}, '/^\d+$/', 
            "    - field '$field' is a number: $header->{$field}" );
    }

    ok( $header->{caplen} <= $header->{len}, "    - caplen <= len" );

    ok( defined $packet,        " - packet is defined" );
    is( length $packet, $header->{caplen}, " - packet has the advertised size" );

    Net::Pcap::dump($dumper, $header, $packet);
    push @data1, [$header, $packet];
    $count++;
}

Net::Pcap::loop($pcap, $total, \&store_packet, $user_text);
is( $count, $total, "all packets processed" );

Net::Pcap::dump_close($dumper);

# now opening this dump file
eval { $pcap = Net::Pcap::open_offline($dump_file, \$err) };
is(   $@,   '', "open_offline() with existent dump file" );
is(   $err, '', " - \$err must be null: $err" ); $err = '';
ok( defined $pcap, " - \$pcap is defined" );
isa_ok( $pcap, 'SCALAR', " - \$pcap" );
isa_ok( $pcap, 'pcap_tPtr', " - \$pcap" );

my($major, $minor, $swapped);

eval { $major = Net::Pcap::major_version($pcap) };
is(   $@,   '', "major_version()" );
like( $major, '/^\d+$/', " - major is a number: $major" );

eval { $minor = Net::Pcap::minor_version($pcap) };
is(   $@,   '', "minor_version()" );
like( $minor, '/^\d+$/', " - minor is a number: $minor" );

eval { $swapped = Net::Pcap::is_swapped($pcap) };
is(   $@,   '', "is_swapped()" );
like( $swapped, '/^[01]$/', " - swapped is 0 or 1: $swapped" );

$count = 0;
my @data2 = ();

sub read_packet {
    my($user_data, $header, $packet) = @_;

    pass( "process_packet() callback" );
    is( $user_data, $user_text, " - user data is the expected text" );
    ok( defined $header,        " - header is defined" );
    isa_ok( $header, 'HASH',    " - header" );

    for my $field (qw(len caplen tv_sec tv_usec)) {
        ok( exists $header->{$field}, "    - field '$field' is present" );
        ok( defined $header->{$field}, "    - field '$field' is defined" );
        like( $header->{$field}, '/^\d+$/', 
            "    - field '$field' is a number: $header->{$field}" );
    }

    ok( $header->{caplen} <= $header->{len}, "    - caplen <= len" );

    ok( defined $packet,        " - packet is defined" );
    is( length $packet, $header->{caplen}, " - packet has the advertised size" );

    push @data2, [$header, $packet];
    $count++;
}

Net::Pcap::loop($pcap, $total, \&read_packet, $user_text);
is( $count, $total, "all packets processed" );

TODO: {
    local $TODO = "caplen is sometimes wrong, dunno why";
    is_deeply( \@data1, \@data2, "checking data" );
}

Net::Pcap::close($pcap);
unlink($dump_file);


# Testing open_offline() using known samples
$dump_file = File::Spec->catfile(qw(t samples ping-ietf-20pk-be.dmp));
eval { $pcap = Net::Pcap::open_offline($dump_file, \$err) };
is(   $@,   '', "open_offline() with existent dump file" );
is(   $err, '', " - \$err must be null: $err" ); $err = '';
ok( defined $pcap, " - \$pcap is defined" );
isa_ok( $pcap, 'SCALAR', " - \$pcap" );
isa_ok( $pcap, 'pcap_tPtr', " - \$pcap" );

Net::Pcap::close($pcap);

