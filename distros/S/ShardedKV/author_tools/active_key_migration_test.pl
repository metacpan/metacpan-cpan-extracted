use ShardedKV;
use ShardedKV::Continuum::Ketama;
use ShardedKV::Storage::MySQL;
use ShardedKV::Storage::MySQL::ActiveKeyMigration;

use lib qw(lib t/lib);
use ShardedKV::Test;


my $continuum_spec = [
  ["server1", 100],
  ["server2", 150],
  ["server3", 200],
];

my $skv = make_skv($continuum_spec, \&mysql_storage);
my @keys = (1..10000);
for (@keys) {
  $skv->set($_, ["v$_"]);
  warn "$_" if not $_ % 1000;
}

warn "Adding server";

# Setup new server and an extended continuum
$skv->storages->{server4} = mysql_storage();
$skv->storages->{server5} = mysql_storage();
$skv->storages->{server6} = mysql_storage();

my $new_cont = $skv->continuum->clone;
$new_cont->extend([
  ["server4", 120],
  ["server5", 220],
  ["server6", 320],
]);

my $time = Time::HiRes::time();
warn "Starting migration";
# set continuum
$skv->begin_migration($new_cont);

ShardedKV::Storage::MySQL::ActiveKeyMigration::migrate_to_additional_storage(
  shardedkv => $skv,
  chunksleep => 0,
);

$skv->end_migration;
warn "Migration time " . ($time-Time::HiRes::time());
