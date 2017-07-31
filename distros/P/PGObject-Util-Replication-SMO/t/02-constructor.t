use Test::More tests => 10;

use PGObject::Util::Replication::SMO;

my $master = PGObject::Util::Replication::SMO->new();
ok($master, 'No args, construction successful');
is($master->port, 5432, 'Got 5432 back for port by default');
ok(scalar @{$master->manage_vars}, 'has some default managed config settings');
$master = PGObject::Util::Replication::SMO->new(host => 'localhost', user => 'postgres', password => 'test', manage_vars => [qw(a b c)]);
ok($master, 'more typical setup, got an object');
is($master->host, 'localhost', 'Got localhost for host');
is($master->user, 'postgres', 'got correct/set username');
is($master->password, 'test', 'got correct password back');
is(scalar @{$master->manage_vars}, 3, 'Correct number of managed vars');
$master = PGObject::Util::Replication::SMO->new(port => 5433);
ok($master, 'Got a valid object back again, port test');
is($master->port, 5433, 'Correct/set port');
