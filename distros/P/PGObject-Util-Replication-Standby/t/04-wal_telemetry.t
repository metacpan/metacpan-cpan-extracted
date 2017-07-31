use PGObject::Util::Replication::Standby;
use Test::More;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 5;

my $standby = PGObject::Util::Replication::Standby->new(port => 5434);
ok($standby, 'Got a standby SMO');
ok($standby->connect, 'Can connect to db');
ok($standby->is_recovering, 'Standby is recovering');
cmp_ok($standby->lag_bytes_from('00/00000000'), '<', 0, 'We have a positive wal location');
cmp_ok($standby->lag_bytes_from('ff/ffffffff'), '>', 0, 'We have not received the end of segments');
