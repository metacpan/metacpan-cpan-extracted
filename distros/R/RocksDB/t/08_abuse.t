use strict;
use warnings;

use Test::More;
use Test::Warn;
use RocksDB;
use File::Temp ();

my $db = bless {}, 'RocksDB';
eval { $db->put(foo => 'bar') };
like $@, qr/invalid object/;

eval { RocksDB::put(undef, foo => 'bar') };
like $@, qr/THIS is not of type RocksDB/;

eval { RocksDB::put($db, foo => 'bar') };
like $@, qr/invalid object/;

bless $db, 't::RocksDBTest'; # suppress warnings in DESTROY
undef $db;

my $name = File::Temp::tmpnam;
warning_like {
    $db = RocksDB->new($name, { create_if_missing => 1 });
    $db->DESTROY;
    undef $db; 
} qr/\(in cleanup\) THIS: invalid object/;

$db = RocksDB->new($name);
my $batch = RocksDB::WriteBatch->new;
bless $batch, 'RocksDB';
eval { $batch->get_property('rocksdb.stats') };
like $@, qr/invalid object/;
bless $batch, 'RocksDB::Snapshot';
eval { $db->get('foo', { snapshot => $batch }) };
like $@, qr/snapshot is not of type RocksDB::Snapshot/;
bless $batch, 'RocksDB::WriteBatch';
undef $batch;
undef $db;

RocksDB->destroy_db($name);

done_testing;
