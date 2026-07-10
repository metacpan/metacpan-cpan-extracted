use strictures 2;

use DBI ();
use File::Temp qw(tempdir);
use Test::More;

use Net::Blossom::Server::Backend::SQLite;
use Net::Blossom::Server::Storage;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::FakeDBH;
    use strictures 2;

    sub do {}
    sub selectrow_array {}
}

my $dir = tempdir(CLEANUP => 1);
my $database = "$dir/blossom.sqlite";

like(dies { Net::Blossom::Server::Backend::SQLite->new },
    qr/database or dbh is required/, 'database or dbh required');
like(dies { Net::Blossom::Server::Backend::SQLite->new(database => $database, base_url => 'https://cdn.example.test', bogus => 1) },
    qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
like(dies { Net::Blossom::Server::Backend::SQLite->new(database => [], base_url => 'https://cdn.example.test') },
    qr/database must be a scalar/, 'database must be scalar');
like(dies { Net::Blossom::Server::Backend::SQLite->new(database => '', base_url => 'https://cdn.example.test') },
    qr/database is required/, 'database must not be empty');
like(dies { Net::Blossom::Server::Backend::SQLite->new(database => $database) },
    qr/base_url is required/, 'base_url required');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        dbh      => {},
        base_url => 'https://cdn.example.test',
    );
}, qr/database and dbh are mutually exclusive/, 'database and dbh rejected together');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        dbh      => {},
        base_url => 'https://cdn.example.test',
    );
}, qr/dbh must be a DBI database handle/, 'dbh must be a DBI handle');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        dbh      => bless({}, 'Local::FakeDBH'),
        base_url => 'https://cdn.example.test',
    );
}, qr/dbh must be a SQLite DBI handle/, 'dbh must be a SQLite handle');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => [],
    );
}, qr/base_url must be a scalar/, 'base_url must be scalar');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'ftp://cdn.example.test',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url scheme validated');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'https://',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url host validated');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'https://cdn.example.test:bad',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url bad port rejected');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'https://cdn.example.test:0',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url zero port rejected');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'https://cdn.example.test:65536',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url out of range port rejected');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => "https://cdn.example.test/blobs\n",
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url control character rejected');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'https://cdn.example.test/blobs?token=secret',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url query rejected');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'https://cdn.example.test/blobs#fragment',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url fragment rejected');
like(dies {
    Net::Blossom::Server::Backend::SQLite->new(
        database => $database,
        base_url => 'https://user:pass@cdn.example.test/blobs',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url userinfo rejected');

my $storage = Net::Blossom::Server::Backend::SQLite->new(
    database => $database,
    base_url => 'https://cdn.example.test/blobs/',
);

isa_ok($storage, 'Net::Blossom::Server::Backend::SQLite');
ok(Net::Blossom::Server::Storage->assert_implements($storage), 'storage contract methods exist');
is($storage->base_url, 'https://cdn.example.test/blobs', 'base_url is normalized');

my $hashref_storage = Net::Blossom::Server::Backend::SQLite->new({
    database => "$dir/hashref.sqlite",
    base_url => 'https://cdn.example.test/hashref/',
});
isa_ok($hashref_storage, 'Net::Blossom::Server::Backend::SQLite', 'hashref constructor');
is($hashref_storage->base_url, 'https://cdn.example.test/hashref', 'hashref constructor normalizes base_url');

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$dir/handle.sqlite",
    '',
    '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 },
);
my $dbh_storage = Net::Blossom::Server::Backend::SQLite->new(
    dbh      => $dbh,
    base_url => 'https://cdn.example.test/dbh',
);
is($dbh_storage->dbh, $dbh, 'constructor accepts an existing DBI handle');

done_testing;
