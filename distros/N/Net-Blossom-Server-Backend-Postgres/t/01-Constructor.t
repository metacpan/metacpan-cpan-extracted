use strictures 2;

use Test::More;

use Net::Blossom::Server::Backend::Postgres;
use Net::Blossom::Server::BlobStore;
use Net::Blossom::Server::MetadataStore;
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
    sub selectrow_array { return 'public' }
    sub selectrow_hashref {}
    sub selectall_arrayref {}
    sub quote_identifier {
        shift;
        return join '.', map { qq{"$_"} } @_;
    }
}

{
    package Local::NoSchemaDBH;
    use strictures 2;

    our @ISA = ('Local::FakeDBH');

    sub selectrow_array { return }
}

my $fake_pg = bless {
    Driver     => { Name => 'Pg' },
    AutoCommit => 1,
}, 'Local::FakeDBH';
my $fake_sqlite = bless {
    Driver     => { Name => 'SQLite' },
    AutoCommit => 1,
}, 'Local::FakeDBH';
my $manual_transaction_pg = bless {
    Driver     => { Name => 'Pg' },
    AutoCommit => 0,
}, 'Local::FakeDBH';
my $no_schema_pg = bless {
    Driver     => { Name => 'Pg' },
    AutoCommit => 1,
}, 'Local::NoSchemaDBH';

like(dies { Net::Blossom::Server::Backend::Postgres->new },
    qr/dsn or dbh is required/, 'dsn or dbh required');
like(dies { Net::Blossom::Server::Backend::Postgres->new(dsn => 'dbi:Pg:dbname=blossom', base_url => 'https://cdn.example.test', bogus => 1) },
    qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
like(dies { Net::Blossom::Server::Backend::Postgres->new(dsn => [], base_url => 'https://cdn.example.test') },
    qr/dsn must be a scalar/, 'dsn must be scalar');
like(dies { Net::Blossom::Server::Backend::Postgres->new(dsn => '', base_url => 'https://cdn.example.test') },
    qr/dsn is required/, 'dsn must not be empty');
like(dies { Net::Blossom::Server::Backend::Postgres->new(dsn => 'dbi:Pg:dbname=blossom', username => [], base_url => 'https://cdn.example.test') },
    qr/username must be a scalar/, 'username must be scalar');
like(dies { Net::Blossom::Server::Backend::Postgres->new(dsn => 'dbi:Pg:dbname=blossom', password => [], base_url => 'https://cdn.example.test') },
    qr/password must be a scalar/, 'password must be scalar');
like(dies { Net::Blossom::Server::Backend::Postgres->new(dsn => 'dbi:Pg:dbname=blossom') },
    qr/base_url is required/, 'base_url required');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dsn      => 'dbi:Pg:dbname=blossom',
        dbh      => $fake_pg,
        base_url => 'https://cdn.example.test',
    );
}, qr/dsn and dbh are mutually exclusive/, 'dsn and dbh rejected together');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => {},
        base_url => 'https://cdn.example.test',
    );
}, qr/dbh must be a DBI database handle/, 'dbh must be a DBI handle');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_sqlite,
        base_url => 'https://cdn.example.test',
    );
}, qr/dbh must be a Postgres DBI handle/, 'dbh must be a Postgres handle');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $manual_transaction_pg,
        base_url => 'https://cdn.example.test',
    );
}, qr/dbh must have AutoCommit enabled/, 'dbh must let the backend own transactions');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $no_schema_pg,
        base_url => 'https://cdn.example.test',
    );
}, qr/Postgres connection has no current schema/, 'dbh must have a current schema');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => [],
    );
}, qr/base_url must be a scalar/, 'base_url must be scalar');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'ftp://cdn.example.test',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url scheme validated');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'https://',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url host validated');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'https://cdn.example.test:bad',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url bad port rejected');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'https://cdn.example.test:0',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url zero port rejected');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'https://cdn.example.test:65536',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url out of range port rejected');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => "https://cdn.example.test/blobs\n",
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url control character rejected');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'https://cdn.example.test/blobs?token=secret',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url query rejected');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'https://cdn.example.test/blobs#fragment',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url fragment rejected');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $fake_pg,
        base_url => 'https://user:pass@cdn.example.test/blobs',
    );
}, qr/base_url must be a valid HTTP base URL/, 'base_url userinfo rejected');
like(dies {
    Net::Blossom::Server::Backend::Postgres->new(
        dbh           => $fake_pg,
        base_url      => 'https://cdn.example.test/blobs',
        connect_attrs => [],
    );
}, qr/connect_attrs must be a hash reference/, 'connect_attrs must be a hash reference');

my $storage = Net::Blossom::Server::Backend::Postgres->new(
    dbh      => $fake_pg,
    base_url => 'https://cdn.example.test/blobs/',
);

isa_ok($storage, 'Net::Blossom::Server::Backend::Postgres');
ok(Net::Blossom::Server::Storage->assert_implements($storage), 'storage contract methods exist');
is($storage->dbh, $fake_pg, 'constructor accepts an existing DBI handle');
is($storage->base_url, 'https://cdn.example.test/blobs', 'base_url is normalized');
isa_ok($storage->metadata_store, 'Net::Blossom::Server::Backend::Postgres::MetadataStore');
isa_ok($storage->blob_store, 'Net::Blossom::Server::Backend::Postgres::BlobStore');
is($storage->metadata_store->dbh, $storage->dbh, 'metadata store shares backend DB handle');
is($storage->blob_store->dbh, $storage->dbh, 'blob store shares backend DB handle');
ok(Net::Blossom::Server::MetadataStore->assert_implements($storage->metadata_store),
    'metadata component implements its contract');
ok(Net::Blossom::Server::BlobStore->assert_implements($storage->blob_store),
    'blob component implements its contract');

my $hashref_storage = Net::Blossom::Server::Backend::Postgres->new({
    dbh      => $fake_pg,
    base_url => 'https://cdn.example.test/hashref/',
});
isa_ok($hashref_storage, 'Net::Blossom::Server::Backend::Postgres', 'hashref constructor');
is($hashref_storage->base_url, 'https://cdn.example.test/hashref', 'hashref constructor normalizes base_url');

done_testing;
