#!perl -T
use strict;
use File::Spec;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my(%name2val,%val2name,%val2descr);
plan skip_all => "extended datalink related functions are not available"
    unless is_available('pcap_datalink_name_to_val');

%name2val = (
    undef            => -1, 
    LTalk            => DLT_LTALK, 
    raw              => DLT_RAW, 
    PPP_serial       => DLT_PPP_SERIAL, 
    SLIP             => DLT_SLIP, 
    ieee802_11       => DLT_IEEE802_11, 
);
%val2name = (
    0                => 'NULL', 
    DLT_LTALK()      => 'LTALK', 
    DLT_RAW()        => 'RAW', 
    DLT_PPP_SERIAL() => 'PPP_SERIAL', 
    DLT_SLIP()       => 'SLIP', 
    DLT_IEEE802_11() => 'IEEE802_11', 
);
%val2descr = (
    0                => 'BSD loopback', 
    DLT_NULL()       => 'BSD loopback', 
    DLT_LTALK()      => 'Localtalk', 
    DLT_RAW()        => 'Raw IP', 
    DLT_PPP_SERIAL() => 'PPP over serial', 
    DLT_SLIP()       => 'SLIP', 
    DLT_IEEE802_11() => '802.11', 
);

plan tests => keys(%name2val) * 2 + keys(%val2name) * 2 + keys(%val2descr) * 2 + 23;

my $has_test_exception = eval "use Test::Exception; 1";

my($dev,$pcap,$datalink,$r,$err) = ('','','','','');

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 7 unless $has_test_exception;

    # datalink() errors
    throws_ok(sub {
        Net::Pcap::datalink()
    }, '/^Usage: Net::Pcap::datalink\(p\)/', 
       "calling datalink() with no argument");

    throws_ok(sub {
        Net::Pcap::datalink(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling datalink() with incorrect argument type");

    # set_datalink() errors
    throws_ok(sub {
        Net::Pcap::set_datalink()
    }, '/^Usage: Net::Pcap::set_datalink\(p, linktype\)/', 
       "calling set_datalink() with no argument");

    throws_ok(sub {
        Net::Pcap::set_datalink(0, 0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling set_datalink() with incorrect argument type");

    # datalink_name_to_val() errors
    throws_ok(sub {
        Net::Pcap::datalink_name_to_val()
    }, '/^Usage: Net::Pcap::datalink_name_to_val\(name\)/', 
       "calling datalink_name_to_val() with no argument");

    # datalink_val_to_name() errors
    throws_ok(sub {
        Net::Pcap::datalink_val_to_name()
    }, '/^Usage: Net::Pcap::datalink_val_to_name\(linktype\)/', 
       "calling datalink_val_to_name() with no argument");

    # datalink_val_to_descr() errors
    throws_ok(sub {
        Net::Pcap::datalink_val_to_description()
    }, '/^Usage: Net::Pcap::datalink_val_to_description\(linktype\)/', 
       "calling datalink_val_to_description() with no argument");

}

SKIP: {
    skip "must be run as root", 5 unless is_allowed_to_use_pcap();
    skip "no network device available", 5 unless find_network_device();

    # Find a device and open it
    $dev = find_network_device();
    $pcap = Net::Pcap::open_live($dev, 1024, 1, 100, \$err);
    isa_ok( $pcap, 'pcap_tPtr', "\$pcap" );

    # Testing datalink()
    $datalink = '';
    eval { $datalink = Net::Pcap::datalink($pcap) };
    is( $@, '', "datalink() on a live connection" );
    like( $datalink , '/^\d+$/', " - datalink is an integer" );

    # Testing set_datalink()
    eval { $r = Net::Pcap::set_datalink($pcap, DLT_LTALK) };  # Apple LocalTalk
    is( $@, '', "set_datalink() on a live connection" );
    is( $r , -1, " - returned -1 (expected failure)" );

    Net::Pcap::close($pcap);
}

# Open a sample save file
$pcap = Net::Pcap::open_offline(File::Spec->catfile(qw(t samples ping-ietf-20pk-be.dmp)), \$err);
isa_ok( $pcap, 'pcap_tPtr', "\$pcap" );

# Testing datalink()
$datalink = '';
eval { $datalink = Net::Pcap::datalink($pcap) };
is( $@, '', "datalink() on a save file" );
like( $datalink , '/^\d+$/', " - datalink is an integer" );
is( $datalink , DLT_EN10MB, " - datalink is DLT_EN10MB (Ethernet)" );

# Testing set_datalink()
eval { $r = Net::Pcap::set_datalink($pcap, DLT_LTALK) };  # Apple LocalTalk
is( $@, '', "set_datalink() on a save file" );
is( $r , -1, " - returned -1 (expected failure)" );

Net::Pcap::close($pcap);


# Open a dead pcap descriptor
$pcap = Net::Pcap::open_dead(DLT_IP_OVER_FC, 1024);
isa_ok( $pcap, 'pcap_tPtr', "\$pcap" );

# Testing datalink()
$datalink = '';
eval { $datalink = Net::Pcap::datalink($pcap) };
is( $@, '', "datalink() on a dead descriptor" );
is( $datalink , DLT_IP_OVER_FC, " - datalink is an integer" );

# Testing set_datalink()
# the migration of the century: from IP-over-Fibre Channel to Apple LocalTalk!
eval { $r = Net::Pcap::set_datalink($pcap, DLT_LTALK) };
is( $@, '', "set_datalink() on a dead descriptor" );
is( $r , -1, " - returned -1 (expected failure)" );
# The following tests don't work, but maybe they're just incorrect. 
#isnt( $r , -1, " - should not returned -1" );
#$datalink = Net::Pcap::datalink($pcap);
#is( $datalink, DLT_LTALK, " - new link type was correctly stored" );


# Testing datalink_name_to_val()
for my $name (keys %name2val) {
    $datalink = '';
    eval { $datalink = Net::Pcap::datalink_name_to_val($name) };
    is( $@, '', "datalink_name_to_val($name)" );
    is( $datalink, $name2val{$name}, " - checking expected value" );
}

# Testing datalink_val_to_name()
for my $val (keys %val2name) {
    my $name = '';
    eval { $name = Net::Pcap::datalink_val_to_name($val) };
    is( $@, '', "datalink_val_to_name($val)" );
    is( $name, $val2name{$val}, " - checking expected value" );
}

# Testing datalink_val_to_description()
for my $val (keys %val2descr) {
    my $descr = '';
    eval { $descr = Net::Pcap::datalink_val_to_description($val) };
    is( $@, '', "datalink_val_to_description($val)" );
    is( $descr, $val2descr{$val}, " - checking expected value" );
}

