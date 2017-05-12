# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 25;

BEGIN {
        use_ok('Sys::Virt');
}


my $conn = Sys::Virt->new(uri => "test:///default");

isa_ok($conn, "Sys::Virt");


my $nid = $conn->num_of_interfaces();
is($nid, 1, "1 active interface");

my @ifacenames = $conn->list_interface_names($nid);
is_deeply(\@ifacenames, ["eth1"], "interface names");

my $iface = $conn->get_interface_by_name($ifacenames[0]);
isa_ok($iface, "Sys::Virt::Interface");

is($iface->get_name, "eth1", "name");

my @ifaces;
SKIP: {
    skip "Impl missing in test driver in libvirt 0.10.2", 2;

    @ifaces = $conn->list_all_interfaces();
    is(int(@ifaces), 1, "1 active interface");
    is($ifaces[0]->get_name, "2eth1", "interface name matches");
}

ok($iface->is_active(), "interface is active");

# Lookup again via MAC to verify we get the same
my $mac = $iface->get_mac();

my $iface2 = $conn->get_interface_by_mac($mac);
isa_ok($iface2, "Sys::Virt::Interface");
is($iface2->get_name, "eth1", "name");

@ifaces = $conn->list_interfaces();
is($#ifaces, 0, "one interface");
isa_ok($ifaces[0], "Sys::Virt::Interface");


my $nname = $conn->num_of_defined_networks();
is($nname, 0, "0 defined interfaces");

my $xml = "
<interface type='ethernet' name='eth2'>
  <start mode='onboot'/>
  <mac address='aa:bb:cc:ff:ee:ff'/>
  <mtu size='1492'/>
  <protocol family='ipv4'>
    <ip address='192.168.0.6' prefix='24'/>
    <route gateway='192.168.0.1'/>
  </protocol>
</interface>";

$iface = $conn->define_interface($xml);

$nname = $conn->num_of_defined_interfaces();
is($nname, 1, "1 defined interface");

my @names = $conn->list_defined_interface_names($nname);
is_deeply(\@names, ["eth2"], "names");

@ifaces = $conn->list_defined_interfaces();
is($#ifaces, 0, "1 defined interface");
isa_ok($ifaces[0], "Sys::Virt::Interface");

$iface = $conn->get_interface_by_name("eth2");
isa_ok($iface, "Sys::Virt::Interface");


$iface->create();

my $nids = $conn->num_of_interfaces();
is($nids, 2, "2 active interfaces");

my @ids = sort { $a cmp $b } $conn->list_interface_names($nids);
is_deeply(\@ids, ["eth1", "eth2"], "interface names");

$iface->destroy();


$nids = $conn->num_of_interfaces();
is($nids, 1, "1 active interfaces");

@ids = $conn->list_interface_names($nids);
is_deeply(\@ids, ["eth1"], "interface names");

$iface = $conn->get_interface_by_name("eth2");

$iface->undefine();


$nname = $conn->num_of_defined_interfaces();
is($nname, 0, "0 defined interface");

@names = $conn->list_defined_interface_names($nname);
is_deeply(\@names, [], "names");

