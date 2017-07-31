use Test::More;
use PGObject::Util::Replication::SMO;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 7;

my $master = PGObject::Util::Replication::SMO->new();

ok($master, 'got a master object');
is($master->port, 5432, 'with a default port');

ok($master->config, 'got a config object back');
$master->readconfig;
ok(scalar $master->config->known_keys, 'got a config object back with values');
ok($master->config->get_value('wal_level'), 'retrieved wal_level setting');
ok($master->config->get_value('max_replication_slots'), 
'retrieved max_replication_slots setting');

ok(( defined $master->config->get_value('max_wal_senders')), 
'retrieved max_wal_senders setting');
