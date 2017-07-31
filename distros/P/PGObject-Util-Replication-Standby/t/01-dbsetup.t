use PGObject::Util::Replication::SMO;
use Test::More;
use Data::Dumper;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 6;

my $master = PGObject::Util::Replication::SMO->new(host => 'localhost', port => '5433');
my $replica = PGObject::Util::Replication::SMO->new(host => 'localhost', port => '5434');

ok($master, 'have a master db smo');
ok($replica, 'Have an smo for the replica');
ok($master->connect, 'got a database connection back to master');
ok($replica->connect, 'Got a database connection back to replica');
ok((not $master->is_recovering), 'Moaster is not recovering');
ok($replica->is_recovering, 'Replica is recovering') or diag(Dumper($replica->connect));
