use Test::More;
use PGObject::Util::DBAdmin;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 33;

# Constructor

my $dbh;
my $db;

ok($db = PGObject::Util::DBAdmin->new(
     username => 'postgres',
     password => undef,
     dbname   => 'pgobject_test_db',
     host     => 'localhost',
     port     => '5432'
), 'Created db admin object');

# Drop db if exists

eval { $db->drop };

ok($db->backup_globals, 'can backup globals');

# List dbs
my @dblist;

ok(@dblist = $db->list_dbs, 'Got a db list');

ok (!grep {$_ eq 'pgobject_test_db'} @dblist, 'DB list does not contain pgobject_test_db');

# Create db

$db->create;

ok($db->server_version, 'Got a server version');

ok (grep {$_ eq 'pgobject_test_db'} $db->list_dbs, 'DB list does contain pgobject_test_db after create call');

# load with schema

ok ($db->run_file(file => 't/data/schema.sql'), 'Loaded schema');

ok ($dbh = $db->connect, 'Got dbi handle');

my ($foo) = @{ $dbh->selectall_arrayref('select count(*) from test_data') };
is ($foo->[0], 1, 'Correct count of data') ;

$dbh->disconnect;

# backup/drop/create/restore, formats undef, p, and c

no warnings;
for ((undef, 'p', 'c')) {
    my $backup;
    ok($backup = $db->backup(
           format => $_,
           tempdir => 't/var/',
       ), 'Made backup, format ' . $_ || 'undef');
    ok($db->drop, 'dropped db, format ' . $_ || 'undef');
    ok (!(grep{$_ eq 'pgobject_test_db'} @dblist), 
           'DB list does not contain pgobject_test_db');

    ok($db->create, 'created db, format ' . $_ || 'undef');
    ok($dbh = $db->connect, 'Got dbi handle ' . $_ || 'undef');
    ok($db->restore(
          format => $_,
          file   => $backup,
       ), 'Restored backup, format ' . $_ || 'undef');
    ok(($foo) = $dbh->selectall_arrayref('select count(*) from test_data'),
               'Got results from test data count ' . $_ || 'undef');
    is($foo->[0]->[0], 1, 'correct data count ' . $_ || 'undef');
    $dbh->disconnect;
    unlink $backup;
}
