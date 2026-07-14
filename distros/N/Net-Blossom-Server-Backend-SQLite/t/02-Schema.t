use strictures 2;

use DBI ();
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use Test::More;

use Net::Blossom::Server::Backend::SQLite;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

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
is_deeply(\@tables, [qw(blossom_blob_data blossom_blobs blossom_owners)],
    'schema creates separate metadata and byte tables');

is_deeply(
    [_column_names($dbh, 'blossom_blobs')],
    [qw(sha256 storage_key size type uploaded)],
    'metadata table contains no blob bytes',
);
is_deeply(
    [_column_names($dbh, 'blossom_blob_data')],
    [qw(storage_key body)],
    'blob table contains storage keys and bytes',
);

my ($foreign_keys) = $dbh->selectrow_array('PRAGMA foreign_keys');
is($foreign_keys, 1, 'foreign keys are enabled');

subtest 'legacy combined schema is migrated without data loss' => sub {
    my $legacy_dir = tempdir(CLEANUP => 1);
    my $legacy_dbh = DBI->connect(
        "dbi:SQLite:dbname=$legacy_dir/legacy.sqlite",
        '',
        '',
        { AutoCommit => 1, RaiseError => 1, PrintError => 0, sqlite_unicode => 0 },
    );
    $legacy_dbh->do('PRAGMA foreign_keys = ON');
    $legacy_dbh->do(q{
        CREATE TABLE blossom_blobs (
            sha256   TEXT PRIMARY KEY NOT NULL,
            body     BLOB NOT NULL,
            size     INTEGER NOT NULL,
            type     TEXT NOT NULL,
            uploaded INTEGER NOT NULL
        )
    });
    $legacy_dbh->do(q{
        CREATE TABLE blossom_owners (
            pubkey   TEXT NOT NULL,
            sha256   TEXT NOT NULL,
            type     TEXT NOT NULL,
            uploaded INTEGER NOT NULL,
            PRIMARY KEY (pubkey, sha256),
            FOREIGN KEY (sha256) REFERENCES blossom_blobs(sha256) ON DELETE CASCADE
        )
    });

    my $body = "legacy sqlite blob\0\n";
    my $sha256 = sha256_hex($body);
    my $pubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
    $legacy_dbh->do(
        q{INSERT INTO blossom_blobs (sha256, body, size, type, uploaded) VALUES (?, ?, ?, ?, ?)},
        undef,
        $sha256,
        $body,
        length($body),
        'text/plain',
        1725107000,
    );
    $legacy_dbh->do(
        q{INSERT INTO blossom_owners (pubkey, sha256, type, uploaded) VALUES (?, ?, ?, ?)},
        undef,
        $pubkey,
        $sha256,
        'text/plain',
        1725107000,
    );

    my $legacy = Net::Blossom::Server::Backend::SQLite->new(
        dbh      => $legacy_dbh,
        base_url => 'https://cdn.example.test',
    );
    ok($legacy->deploy_schema, 'legacy schema migration succeeds');
    ok($legacy->deploy_schema, 'migrated schema remains idempotent');

    is($legacy->get_blob($sha256)->body, $body, 'legacy blob bytes survive migration');
    is_deeply(
        [map { $_->sha256 } @{$legacy->list_blobs($pubkey)}],
        [$sha256],
        'legacy owner survives migration',
    );
    is_deeply(
        [_column_names($legacy_dbh, 'blossom_blobs')],
        [qw(sha256 storage_key size type uploaded)],
        'legacy byte column is removed from metadata table',
    );
    is_deeply(
        $legacy_dbh->selectrow_arrayref(
            q{SELECT storage_key, body FROM blossom_blob_data WHERE storage_key = ?},
            undef,
            $sha256,
        ),
        [$sha256, $body],
        'legacy bytes move to the blob table',
    );
    is_deeply($legacy_dbh->selectall_arrayref('PRAGMA foreign_key_check'), [],
        'migrated foreign keys are valid');
};

subtest 'invalid legacy owners leave the old schema intact' => sub {
    my $legacy_dir = tempdir(CLEANUP => 1);
    my $legacy_dbh = DBI->connect(
        "dbi:SQLite:dbname=$legacy_dir/invalid-legacy.sqlite",
        '',
        '',
        { AutoCommit => 1, RaiseError => 1, PrintError => 0, sqlite_unicode => 0 },
    );
    $legacy_dbh->do(q{
        CREATE TABLE blossom_blobs (
            sha256   TEXT PRIMARY KEY NOT NULL,
            body     BLOB NOT NULL,
            size     INTEGER NOT NULL,
            type     TEXT NOT NULL,
            uploaded INTEGER NOT NULL
        )
    });
    $legacy_dbh->do(q{
        CREATE TABLE blossom_owners (
            pubkey   TEXT NOT NULL,
            sha256   TEXT NOT NULL,
            type     TEXT NOT NULL,
            uploaded INTEGER NOT NULL,
            PRIMARY KEY (pubkey, sha256),
            FOREIGN KEY (sha256) REFERENCES blossom_blobs(sha256) ON DELETE CASCADE
        )
    });
    $legacy_dbh->do(
        q{INSERT INTO blossom_owners (pubkey, sha256, type, uploaded) VALUES (?, ?, ?, ?)},
        undef,
        '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
        'a' x 64,
        'text/plain',
        1725107000,
    );

    my $legacy = Net::Blossom::Server::Backend::SQLite->new(
        dbh      => $legacy_dbh,
        base_url => 'https://cdn.example.test',
    );
    like(
        dies { $legacy->deploy_schema },
        qr/invalid foreign keys/,
        'invalid legacy owner rejects migration',
    );
    is_deeply(
        [_column_names($legacy_dbh, 'blossom_blobs')],
        [qw(sha256 body size type uploaded)],
        'failed migration preserves the old blob table',
    );
    is_deeply(
        [_column_names($legacy_dbh, 'blossom_blob_data')],
        [],
        'failed migration leaves no blob-data table',
    );
    is($legacy_dbh->selectrow_array('PRAGMA foreign_keys'), 1,
        'failed migration restores foreign-key enforcement');
};

done_testing;

sub _column_names {
    my ($dbh, $table) = @_;
    return map { $_->[1] } @{$dbh->selectall_arrayref("PRAGMA table_info($table)")};
}
