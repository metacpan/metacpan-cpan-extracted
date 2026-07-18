use strictures 2;

use Digest::SHA ();
use File::Temp qw(tempfile);
use Test::More;

use Net::Blossom::Server::Backend::Postgres;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

my $dbh = _test_dbh();
_reset_schema($dbh);

my $storage = Net::Blossom::Server::Backend::Postgres->new(
    dbh      => $dbh,
    base_url => 'https://cdn.example.test',
);

ok($storage->deploy_schema, 'schema deploy succeeds');
ok($storage->deploy_schema, 'schema deploy is idempotent');

my @tables = sort map { $_->[0] } @{$dbh->selectall_arrayref(q{
    SELECT table_name
      FROM information_schema.tables
     WHERE table_schema = current_schema()
       AND table_name LIKE 'blossom_%'
})};
is_deeply(\@tables, [qw(blossom_blob_data blossom_blobs blossom_owners)],
    'schema creates separate metadata and large-object tables');

my ($ordering_index_definition) = $dbh->selectrow_array(q{
    SELECT indexdef
      FROM pg_indexes
     WHERE schemaname = current_schema()
       AND tablename = 'blossom_owners'
       AND indexname = 'blossom_owners_pubkey_order'
});
like(
    $ordering_index_definition // '',
    qr/\(pubkey, uploaded DESC, sha256\)\z/,
    'schema creates the expected owner ordering index',
);

my ($hash_index_definition) = $dbh->selectrow_array(q{
    SELECT indexdef
      FROM pg_indexes
     WHERE schemaname = current_schema()
       AND tablename = 'blossom_owners'
       AND indexname = 'blossom_owners_sha256'
});
like(
    $hash_index_definition // '',
    qr/\(sha256\)\z/,
    'schema indexes owner lookups by blob hash',
);

my $columns = $dbh->selectall_arrayref(q{
    SELECT column_name, udt_name
      FROM information_schema.columns
     WHERE table_schema = current_schema()
       AND table_name = 'blossom_blobs'
     ORDER BY ordinal_position
});
is_deeply($columns, [
    [sha256 => 'text'],
    [storage_key => 'text'],
    [size => 'int8'],
    [type => 'text'],
    [uploaded => 'int8'],
], 'metadata table contains no large-object OID');

my $data_columns = $dbh->selectall_arrayref(q{
    SELECT column_name, udt_name
      FROM information_schema.columns
     WHERE table_schema = current_schema()
       AND table_name = 'blossom_blob_data'
     ORDER BY ordinal_position
});
is_deeply($data_columns, [
    [storage_key => 'text'],
    [body_oid => 'oid'],
], 'blob table contains storage keys and large-object OIDs');

_reset_schema($dbh);
my ($fh, $path) = tempfile('net-blossom-postgres-legacy-XXXXXX', TMPDIR => 1, UNLINK => 1);
binmode $fh;
my $legacy_body = "legacy postgres blob\n";
print {$fh} $legacy_body;
close $fh;
my $legacy_sha256 = Digest::SHA::sha256_hex($legacy_body);
my $legacy_pubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

$dbh->do(q{
    CREATE TABLE blossom_blobs (
        sha256   text PRIMARY KEY NOT NULL,
        body_oid oid NOT NULL,
        size     bigint NOT NULL,
        type     text NOT NULL,
        uploaded bigint NOT NULL
    )
});
$dbh->do(q{
    CREATE TABLE blossom_owners (
        pubkey   text NOT NULL,
        sha256   text NOT NULL,
        type     text NOT NULL,
        uploaded bigint NOT NULL,
        PRIMARY KEY (pubkey, sha256),
        FOREIGN KEY (sha256) REFERENCES blossom_blobs(sha256) ON DELETE CASCADE
    )
});
$dbh->begin_work;
my $legacy_oid = $dbh->pg_lo_import($path);
$dbh->do(
    q{INSERT INTO blossom_blobs (sha256, body_oid, size, type, uploaded) VALUES (?, ?, ?, ?, ?)},
    undef,
    $legacy_sha256,
    $legacy_oid,
    length($legacy_body),
    'text/plain',
    1725107000,
);
$dbh->do(
    q{INSERT INTO blossom_owners (pubkey, sha256, type, uploaded) VALUES (?, ?, ?, ?)},
    undef,
    $legacy_pubkey,
    $legacy_sha256,
    'text/plain',
    1725107000,
);
$dbh->commit;

ok($storage->deploy_schema, 'legacy large-object schema migration succeeds');
ok($storage->deploy_schema, 'migrated schema remains idempotent');
my ($migrated_hash_index) = $dbh->selectrow_array(q{
    SELECT 1
      FROM pg_indexes
     WHERE schemaname = current_schema()
       AND tablename = 'blossom_owners'
       AND indexname = 'blossom_owners_sha256'
});
ok($migrated_hash_index, 'legacy schema migration creates owner hash index');
is(_body_to_scalar($storage->get_blob($legacy_sha256)->body), $legacy_body,
    'legacy large-object bytes survive migration');
is_deeply(
    [map { $_->sha256 } @{$storage->list_blobs($legacy_pubkey)}],
    [$legacy_sha256],
    'legacy owner survives migration',
);
is_deeply(
    $dbh->selectrow_arrayref(
        q{SELECT storage_key, body_oid FROM blossom_blob_data WHERE storage_key = ?},
        undef,
        $legacy_sha256,
    ),
    [$legacy_sha256, $legacy_oid],
    'legacy OID moves to the blob table unchanged',
);

_reset_schema($dbh);
$dbh->do(q{
    CREATE TABLE blossom_blobs (
        sha256   text PRIMARY KEY NOT NULL,
        body     bytea NOT NULL,
        size     bigint NOT NULL,
        type     text NOT NULL,
        uploaded bigint NOT NULL
    )
});
like(dies { $storage->deploy_schema },
    qr/incompatible blossom_blobs schema.*recreate/i,
    'deploy rejects the obsolete bytea schema clearly');

done_testing;

sub _test_dbh {
    my $dsn = $ENV{NET_BLOSSOM_POSTGRES_DSN}
        or plan skip_all => 'NET_BLOSSOM_POSTGRES_DSN is not set';

    eval 'use DBI (); use DBD::Pg (); 1'
        or die $@;

    return DBI->connect(
        $dsn,
        $ENV{NET_BLOSSOM_POSTGRES_USER},
        $ENV{NET_BLOSSOM_POSTGRES_PASSWORD},
        {
            AutoCommit    => 1,
            RaiseError    => 1,
            PrintError    => 0,
            pg_enable_utf8 => 0,
        },
    );
}

sub _reset_schema {
    my ($dbh) = @_;
    $dbh->do('DROP TABLE IF EXISTS blossom_owners');
    $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
    $dbh->do('DROP TABLE IF EXISTS blossom_blob_data');
    $dbh->do('SELECT lo_unlink(oid) FROM pg_largeobject_metadata');
    return;
}

sub _body_to_scalar {
    my ($body) = @_;
    my $value = '';
    while (1) {
        my $chunk = '';
        my $read = $body->read($chunk, 8192);
        die 'stream read failed' unless defined $read;
        last unless $read;
        $value .= $chunk;
    }
    return $value;
}
