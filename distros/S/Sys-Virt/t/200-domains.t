# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 59;

BEGIN {
        use_ok('Sys::Virt');
}


my $conn = Sys::Virt->new(uri => "test:///default");

isa_ok($conn, "Sys::Virt");


my $nid = $conn->num_of_domains();
is($nid, 1, "1 active domain");

my @domids = $conn->list_domain_ids($nid);
is_deeply(\@domids, [1], "domain ids");

my @doms = $conn->list_all_domains();
isa_ok($doms[0], "Sys::Virt::Domain");
is(int(@doms), 1, "1 active domain");
is($doms[0]->get_id, "1", "domain id matches");

my $dom = $conn->get_domain_by_id($domids[0]);
isa_ok($dom, "Sys::Virt::Domain");

is($dom->get_name, "test", "name");
is($dom->get_id, "1", "id");
ok($dom->is_persistent(), "domain is persistent");
ok($dom->is_active(), "domain is active");
ok(!$dom->is_updated(), "domain is not updated");

# Lookup again via UUID to verify we get the same
my $uuid = $dom->get_uuid();

my $dom2 = $conn->get_domain_by_uuid($uuid);
isa_ok($dom2, "Sys::Virt::Domain");
is($dom2->get_name, "test", "name");
is($dom2->get_id, "1", "id");

my $uuidstr = $dom->get_uuid_string();

my $dom3 = $conn->get_domain_by_uuid($uuidstr);
isa_ok($dom3, "Sys::Virt::Domain");
is($dom3->get_name, "test", "name");
is($dom3->get_id, "1", "id");

@doms = $conn->list_domains();
is($#doms, 0, "one domain");
isa_ok($doms[0], "Sys::Virt::Domain");


my $nname = $conn->num_of_defined_domains();
is($nname, 0, "0 defined domain");

my $xml = "<domain type='test'>
  <name>wibble</name>
  <uuid>12341234-5678-5678-5678-123412341234</uuid>
  <memory>10241024</memory>
  <currentMemory>1024120</currentMemory>
  <vcpu>4</vcpu>
  <os>
    <type>hvm</type>
  </os>
</domain>";


$conn->define_domain($xml);

$nname = $conn->num_of_defined_domains();
is($nname, 1, "1 defined domain");

my @names = $conn->list_defined_domain_names($nname);
is_deeply(\@names, ["wibble"], "names");

@doms = $conn->list_defined_domains();
is($#doms, 0, "1 defined domain");
isa_ok($doms[0], "Sys::Virt::Domain");

$dom = $conn->get_domain_by_name("wibble");
isa_ok($dom, "Sys::Virt::Domain");

ok($dom->is_persistent(), "domain is persistent");
ok(!$dom->is_active(), "domain is not active");


$dom->create();

ok($dom->is_active(), "domain is active");

my $nids = $conn->num_of_domains();
is($nids, 2, "2 active domains");

my @ids = sort { $a <=> $b } $conn->list_domain_ids($nids);
is_deeply(\@ids, [1, 2], "domain ids");


my $info = $dom->get_info();
is($info->{memory}, "1024120", "memory");
is($info->{maxMem}, "10241024", "max mem");
is($info->{nrVirtCpu}, "4", "vcpu");
is($info->{state}, &Sys::Virt::Domain::STATE_RUNNING, "state");

my $params = $dom->get_scheduler_parameters();

ok(exists $params->{"weight"}, "weight param");
is($params->{"weight"}, 50, "weight param is 50");

$dom->set_scheduler_parameters({weight  => 20 });

$params = $dom->get_scheduler_parameters();

ok(exists $params->{"weight"}, "weight param");
# Temp disabled because test driver is not persisting the set request
SKIP: {
    skip "avoid bug in test driver sched params", 1;
    is($params->{"weight"}, 20, "weight param is now 20");
}

$dom->destroy();

#my $free = $conn->get_node_free_memory();
#print STDERR $free;
my @mem = $conn->get_node_cells_free_memory(0, 8);
is($#mem, 1, "2 cells");
is($mem[0], 2097152, "mem in cell 1");
is($mem[1], 4194304, "mem in cell 2");


$nids = $conn->num_of_domains();
is($nids, 1, "1 active domains");

@ids = $conn->list_domain_ids($nids);
is_deeply(\@ids, [1], "domain ids");

$dom = $conn->get_domain_by_name("wibble");

$dom->undefine();


$nname = $conn->num_of_defined_domains();
is($nname, 0, "0 defined domain");

@names = $conn->list_defined_domain_names($nname);
is_deeply(\@names, [], "names");



$conn->create_domain($xml);

$nname = $conn->num_of_domains();
is($nname, 2, "1 domain");

@ids = sort { $a <=> $b} $conn->list_domain_ids($nname);
is_deeply(\@ids, [1, 3], "domain ids");

@doms = $conn->list_domains();
is($#doms, 1, "2 domains");
isa_ok($doms[0], "Sys::Virt::Domain");
isa_ok($doms[1], "Sys::Virt::Domain");

$dom = $conn->get_domain_by_name("wibble");
isa_ok($dom, "Sys::Virt::Domain");

ok(!$dom->is_persistent(), "domain is not persistent");
ok($dom->is_active(), "domain is active");

$dom->destroy();


$nname = $conn->num_of_domains();
is($nname, 1, "1 domains");

@ids = $conn->list_domain_ids($nname);
is_deeply(\@ids, [1], "ids");

$nname = $conn->num_of_defined_domains();
is($nname, 0, "0 defined domain");

@names = $conn->list_defined_domain_names($nname);
is_deeply(\@names, [], "names");

