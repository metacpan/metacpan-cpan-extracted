# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 32;

BEGIN {
        use_ok('Sys::Virt');
}


my $conn = Sys::Virt->new(uri => "test:///default");

isa_ok($conn, "Sys::Virt");


my $nid = $conn->num_of_storage_pools();
is($nid, 1, "1 active storage_pool");

my @poolnames = $conn->list_storage_pool_names($nid);
is_deeply(\@poolnames, ["default-pool"], "storage_pool names");

my @pools = $conn->list_all_storage_pools();
isa_ok($pools[0], "Sys::Virt::StoragePool");
is(int(@pools), 1, "1 active pool");
is($pools[0]->get_name, "default-pool", "pool name matches");

my $pool = $conn->get_storage_pool_by_name($poolnames[0]);
isa_ok($pool, "Sys::Virt::StoragePool");

is($pool->get_name, "default-pool", "name");
ok($pool->is_persistent(), "pool is persistent");
ok($pool->is_active(), "pool is active");


# Lookup again via UUID to verify we get the same
my $uuid = $pool->get_uuid();

my $pool2 = $conn->get_storage_pool_by_uuid($uuid);
isa_ok($pool2, "Sys::Virt::StoragePool");
is($pool2->get_name, "default-pool", "name");

my $uuidstr = $pool->get_uuid_string();

my $pool3 = $conn->get_storage_pool_by_uuid($uuidstr);
isa_ok($pool3, "Sys::Virt::StoragePool");
is($pool3->get_name, "default-pool", "name");


@pools = $conn->list_storage_pools();
is($#pools, 0, "one storage_pool");
isa_ok($pools[0], "Sys::Virt::StoragePool");


my $nname = $conn->num_of_defined_storage_pools();
is($nname, 0, "0 defined storage_pool");

my $xml = "<pool type='dir'>
  <name>wibble</name>
  <uuid>12341234-5678-5678-5678-123412341234</uuid>
  <target>
    <path>/default-pool</path>
  </target>
</pool>";

$pool = $conn->define_storage_pool($xml);

$nname = $conn->num_of_defined_storage_pools();
is($nname, 1, "1 defined storage_pool");
ok($pool->is_persistent(), "pool is persistent");
ok(!$pool->is_active(), "pool is not active");

my @names = $conn->list_defined_storage_pool_names($nname);
is_deeply(\@names, ["wibble"], "names");

@pools = $conn->list_defined_storage_pools();
is($#pools, 0, "1 defined storage_pool");
isa_ok($pools[0], "Sys::Virt::StoragePool");

$pool = $conn->get_storage_pool_by_name("wibble");
isa_ok($pool, "Sys::Virt::StoragePool");


$pool->create();
ok($pool->is_active(), "pool is active");

my $nids = $conn->num_of_storage_pools();
is($nids, 2, "2 active storage_pools");

my @ids = sort { $a cmp $b } $conn->list_storage_pool_names($nids);
is_deeply(\@ids, ["default-pool", "wibble"], "storage_pool names");

$pool->destroy();


$nids = $conn->num_of_storage_pools();
is($nids, 1, "1 active storage_pools");

@ids = $conn->list_storage_pool_names($nids);
is_deeply(\@ids, ["default-pool"], "storage_pool names");

$pool = $conn->get_storage_pool_by_name("wibble");

$pool->undefine();


$nname = $conn->num_of_defined_storage_pools();
is($nname, 0, "0 defined storage_pool");

@names = $conn->list_defined_storage_pool_names($nname);
is_deeply(\@names, [], "names");

