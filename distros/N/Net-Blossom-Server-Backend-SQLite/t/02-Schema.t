use strictures 2;

use File::Temp qw(tempdir);
use Test::More;

use Net::Blossom::Server::Backend::SQLite;

my $dir = tempdir(CLEANUP => 1);
my $storage = Net::Blossom::Server::Backend::SQLite->new(
    database => "$dir/blossom.sqlite",
    base_url => 'https://cdn.example.test',
);

ok($storage->deploy_schema, 'schema deploy succeeds');
ok($storage->deploy_schema, 'schema deploy is idempotent');

my $dbh = $storage->dbh;
my @tables = sort map { $_->[0] } @{$dbh->selectall_arrayref(
    q{SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'blossom_%'},
)};
is_deeply(\@tables, [qw(blossom_blobs blossom_owners)], 'schema creates storage tables');

my ($foreign_keys) = $dbh->selectrow_array('PRAGMA foreign_keys');
is($foreign_keys, 1, 'foreign keys are enabled');

done_testing;
