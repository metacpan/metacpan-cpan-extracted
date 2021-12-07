#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan skip_all => "no network device available" unless find_network_device();
plan tests => 10;

my($dev,$net,$mask,$pcap,$filter,$res,$err) = ('','',0,'','','','');

# Find a device and open it
$dev = find_network_device();
$res = Net::Pcap::lookupnet($dev, \$net, \$mask, \$err);
$pcap = Net::Pcap::open_dead(DLT_EN10MB, 1024);


# Testing compile() with an invalid filter
eval { $res = Net::Pcap::compile($pcap, \$filter, "this is not a filter", 0, $mask) };
is(   $@,   '', "compile() with an invalid filter string" );
is(   $res, -1, " - result must not be null: $res" );
eval { $err = Net::Pcap::geterr($pcap) };
is(   $@,   '', "geterr()" );
like( $err, '/(^|: )(?:parse|syntax) error$/', " - \$err must not be null: $err" );

# Testing compile() with a valid filter
eval { $res = Net::Pcap::compile($pcap, \$filter, "tcp", 0, $mask) };
is(   $@,   '', "compile() with a valid filter string" );
is(   $res,  0, " - result must be null: $res" );
eval { $err = Net::Pcap::geterr($pcap) };
is(   $@,   '', "geterr()" );
is(   $err, '', " - \$err must be null" );

# Testing strerror()
eval { $err = Net::Pcap::strerror(1) };
is(   $@,   '', "strerror()" );
isnt( $err, '', " - \$err must not be null" );
