# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 32;

BEGIN {
        use_ok('Sys::Virt');
}


my $conn = Sys::Virt->new(uri => "test:///default");

isa_ok($conn, "Sys::Virt");


my $nid = $conn->num_of_networks();
is($nid, 1, "1 active network");

my @netnames = $conn->list_network_names($nid);
is_deeply(\@netnames, ["default"], "network names");

my @nets = $conn->list_all_networks();
isa_ok($nets[0], "Sys::Virt::Network");
is(int(@nets), 1, "1 active network");
is($nets[0]->get_name, "default", "network name matches");

my $net = $conn->get_network_by_name($netnames[0]);
isa_ok($net, "Sys::Virt::Network");

is($net->get_name, "default", "name");
ok($net->is_persistent(), "net is persistent");
ok($net->is_active(), "net is active");

# Lookup again via UUID to verify we get the same
my $uuid = $net->get_uuid();

my $net2 = $conn->get_network_by_uuid($uuid);
isa_ok($net2, "Sys::Virt::Network");
is($net2->get_name, "default", "name");

my $uuidstr = $net->get_uuid_string();

my $net3 = $conn->get_network_by_uuid($uuidstr);
isa_ok($net3, "Sys::Virt::Network");
is($net3->get_name, "default", "name");

@nets = $conn->list_networks();
is($#nets, 0, "one network");
isa_ok($nets[0], "Sys::Virt::Network");


my $nname = $conn->num_of_defined_networks();
is($nname, 0, "0 defined network");

my $xml = "<network>
  <name>wibble</name>
  <uuid>12341234-5678-5678-5678-123412341234</uuid>
  <forward dev='eth0'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.2' end='192.168.100.25'/>
    </dhcp>
  </ip>
</network>";

$net = $conn->define_network($xml);

ok($net->is_persistent(), "net is persistent");
ok(!$net->is_active(), "net is not active");

$nname = $conn->num_of_defined_networks();
is($nname, 1, "1 defined network");

my @names = $conn->list_defined_network_names($nname);
is_deeply(\@names, ["wibble"], "names");

@nets = $conn->list_defined_networks();
is($#nets, 0, "1 defined network");
isa_ok($nets[0], "Sys::Virt::Network");

$net = $conn->get_network_by_name("wibble");
isa_ok($net, "Sys::Virt::Network");


$net->create();

ok($net->is_active(), "net is active");

my $nids = $conn->num_of_networks();
is($nids, 2, "2 active networks");

my @ids = sort { $a cmp $b } $conn->list_network_names($nids);
is_deeply(\@ids, ["default", "wibble"], "network names");

$net->destroy();


$nids = $conn->num_of_networks();
is($nids, 1, "1 active networks");

@ids = $conn->list_network_names($nids);
is_deeply(\@ids, ["default"], "network names");

$net = $conn->get_network_by_name("wibble");

$net->undefine();


$nname = $conn->num_of_defined_networks();
is($nname, 0, "0 defined network");

@names = $conn->list_defined_network_names($nname);
is_deeply(\@names, [], "names");

