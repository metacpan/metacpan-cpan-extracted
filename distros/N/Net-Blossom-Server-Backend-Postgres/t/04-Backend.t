use strictures 2;

use Digest::SHA qw(sha256_hex);
use Test::More;

use Net::Blossom::Server;
use Net::Blossom::Server::Backend::Postgres;

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $DBH = _test_dbh();

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

sub storage {
    _reset_schema($DBH);
    my $storage = Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $DBH,
        base_url => 'https://cdn.example.test/files',
    );
    $storage->deploy_schema;
    return $storage;
}

subtest 'blob descriptors use base URL and Postgres metadata' => sub {
    my $storage = storage();
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107000 });
    my $body = "postgres backend blob\0\n";
    my $sha256 = sha256_hex($body);

    my $upload = $server->receive_blob($body, type => 'application/octet-stream', pubkey => $PUBKEY);
    is($upload->descriptor->url, "https://cdn.example.test/files/$sha256", 'upload descriptor URL');

    my $head = $storage->head_blob($sha256);
    isa_ok($head, 'Net::Blossom::BlobDescriptor');
    is($head->url, "https://cdn.example.test/files/$sha256", 'head descriptor URL');
    is($head->type, 'application/octet-stream', 'head descriptor type');

    my ($body_oid) = $DBH->selectrow_array(
        'SELECT body_oid FROM blossom_blob_data WHERE storage_key = ?',
        undef,
        $sha256,
    );
    ok($body_oid, 'blob row stores a large-object OID');
    is_deeply(_large_object_oids($DBH), [$body_oid], 'upload creates one PostgreSQL large object');

    my $connections = _connection_count($DBH);
    my $result = $storage->get_blob($sha256);
    isa_ok($result, 'Net::Blossom::Server::BlobResult');
    my $stream = $result->body;
    ok(ref($stream), 'get_blob returns a stream instead of a scalar');
    can_ok($stream, qw(read getline close));

    SKIP: {
        skip 'stream methods are required for chunked retrieval', 3
            unless ref($stream) && $stream->can('read');
        is(_connection_count($DBH), $connections + 1, 'active download owns a dedicated connection');
        is(_read_stream($stream, 3), $body, 'stream returns stored binary bytes in bounded reads');
        is(_connection_count($DBH), $connections, 'EOF closes the dedicated connection');
    }
};

subtest 'duplicate owner uploads stay unique and update list metadata' => sub {
    my $storage = storage();
    my $body = "same owner duplicate\n";
    my $sha256 = sha256_hex($body);

    Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107000 })
        ->receive_blob($body, type => 'text/plain', pubkey => $PUBKEY);
    my ($first_oid) = $DBH->selectrow_array(
        'SELECT body_oid FROM blossom_blob_data WHERE storage_key = ?',
        undef,
        $sha256,
    );
    my $second = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107100 })
        ->receive_blob($body, type => 'application/octet-stream', pubkey => $PUBKEY);

    is($second->created, 0, 'duplicate bytes are not stored again');
    is($second->descriptor->type, 'application/octet-stream', 'duplicate result uses current upload type');

    my $listed = $storage->list_blobs($PUBKEY, limit => 10);
    is(scalar @$listed, 1, 'owner sees one descriptor for duplicate hash');
    is($listed->[0]->sha256, $sha256, 'listed duplicate hash');
    is($listed->[0]->type, 'application/octet-stream', 'owner list metadata was updated');
    is($listed->[0]->uploaded, 1725107100, 'owner list uploaded time was updated');
    is_deeply(_large_object_oids($DBH), [$first_oid], 'duplicate upload does not create another large object');
};

subtest 'anonymous blobs can be deleted without owner scope' => sub {
    my $storage = storage();
    my $body = "anonymous blob\n";
    my $sha256 = sha256_hex($body);

    Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107000 })
        ->receive_blob($body, type => 'text/plain');

    my ($body_oid) = $DBH->selectrow_array(
        'SELECT body_oid FROM blossom_blob_data WHERE storage_key = ?',
        undef,
        $sha256,
    );
    isa_ok($storage->head_blob($sha256), 'Net::Blossom::BlobDescriptor', 'anonymous blob stored');
    ok(!$storage->delete_blob($sha256, pubkey => $PUBKEY), 'owner-scoped delete does not remove anonymous blob');
    ok($storage->delete_blob($sha256), 'unscoped delete removes anonymous blob');
    is($storage->get_blob($sha256), undef, 'anonymous blob removed');
    my $remaining = grep { $_ == $body_oid } @{_large_object_oids($DBH)};
    ok(!$remaining, 'unscoped delete unlinks the large object');
};

subtest 'final owner deletion unlinks the large object' => sub {
    my $storage = storage();
    my $body = "owner-scoped blob\n";
    my $sha256 = sha256_hex($body);

    Net::Blossom::Server->new(storage => $storage)
        ->receive_blob($body, pubkey => $PUBKEY);
    my ($body_oid) = $DBH->selectrow_array(
        'SELECT body_oid FROM blossom_blob_data WHERE storage_key = ?',
        undef,
        $sha256,
    );

    ok($storage->delete_blob($sha256, pubkey => $PUBKEY), 'final owner relationship deleted');
    my $remaining = grep { $_ == $body_oid } @{_large_object_oids($DBH)};
    ok(!$remaining, 'final owner deletion unlinks the large object');
};

subtest 'direct blob preparation requires a metadata transaction' => sub {
    my $storage = storage();
    my $upload = $storage->blob_store->begin_upload;
    my $before = _large_object_oids($DBH);
    $upload->write('uncoordinated body');

    like(
        dies { $upload->prepare(sha256 => sha256_hex('uncoordinated body')) },
        qr/blob preparation requires an active transaction/,
        'prepare outside the coordinator transaction is rejected',
    );
    is(
        $DBH->selectrow_array(q{SELECT COUNT(*) FROM blossom_blob_data}),
        0,
        'rejected preparation leaves no blob-data row',
    );
    is_deeply(_large_object_oids($DBH), $before,
        'rejected preparation leaves no large object');
    ok($upload->abort, 'rejected preparation can be aborted');
};

subtest 'direct blob deletion requires a metadata transaction' => sub {
    my $storage = storage();
    my $body = 'coordinated body';
    my $sha256 = sha256_hex($body);
    Net::Blossom::Server->new(storage => $storage)->receive_blob($body);
    my ($body_oid) = $DBH->selectrow_array(
        q{SELECT body_oid FROM blossom_blob_data WHERE storage_key = ?},
        undef,
        $sha256,
    );

    like(
        dies { $storage->blob_store->delete_blob($sha256) },
        qr/blob deletion requires an active transaction/,
        'delete outside the coordinator transaction is rejected',
    );
    isa_ok($storage->get_blob($sha256), 'Net::Blossom::Server::BlobResult',
        'rejected deletion preserves metadata and bytes');
    my $remaining = grep { $_ == $body_oid } @{_large_object_oids($DBH)};
    ok($remaining, 'rejected deletion preserves the large object');
};

subtest 'direct metadata mutation requires a transaction' => sub {
    my $storage = storage();
    my $body = 'protected metadata';
    my $sha256 = sha256_hex($body);
    Net::Blossom::Server->new(storage => $storage)->receive_blob($body);

    like(
        dies { $storage->metadata_store->delete_blob($sha256) },
        qr/metadata change requires an active transaction/,
        'metadata deletion outside with_transaction is rejected',
    );
    like(
        dies { $storage->metadata_store->lock_blob($sha256) },
        qr/metadata change requires an active transaction/,
        'advisory lock outside with_transaction is rejected',
    );
    isa_ok($storage->get_blob($sha256), 'Net::Blossom::Server::BlobResult',
        'rejected metadata deletion preserves the blob');
};

subtest 'commit failure rolls back imported large object' => sub {
    my $storage = storage();
    $DBH->do(q{
        CREATE OR REPLACE FUNCTION blossom_reject_owner()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $$
        BEGIN
            RAISE EXCEPTION 'owner insert rejected';
        END
        $$
    });
    $DBH->do(q{
        CREATE TRIGGER blossom_reject_owner
        BEFORE INSERT ON blossom_owners
        FOR EACH ROW
        EXECUTE FUNCTION blossom_reject_owner()
    });
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $before = _large_object_oids($DBH);

    like(dies { $server->receive_blob('body', pubkey => $PUBKEY) },
        qr/owner insert rejected/i,
        'database failure is preserved');
    is_deeply(_large_object_oids($DBH), $before, 'rollback leaves no orphaned large object');
    is($storage->get_blob(sha256_hex('body')), undef, 'failed blob is not visible');
};

subtest 'empty and abandoned download streams release their connections' => sub {
    my $storage = storage();
    my $empty_sha256 = sha256_hex('');
    Net::Blossom::Server->new(storage => $storage)->receive_blob('');

    my $connections = _connection_count($DBH);
    my $empty = $storage->get_blob($empty_sha256)->body;
    is(_connection_count($DBH), $connections + 1, 'empty stream owns a connection before its first read');
    is(_read_stream($empty, 2), '', 'empty large object reaches EOF');
    is(_connection_count($DBH), $connections, 'empty stream EOF releases its connection');

    my $body = 'abandoned stream body';
    my $sha256 = sha256_hex($body);
    Net::Blossom::Server->new(storage => $storage)->receive_blob($body);
    my $stream = $storage->get_blob($sha256)->body;
    my $chunk = '';
    is($stream->read($chunk, 4), 4, 'partial stream read succeeds');
    is($chunk, 'aban', 'partial stream read returns bounded bytes');
    is(_connection_count($DBH), $connections + 1, 'partial stream keeps its connection');
    ok($stream->close, 'stream closes before EOF');
    ok($stream->close, 'stream close is idempotent');
    is(_connection_count($DBH), $connections, 'early close releases its connection');
    like(dies { $stream->read($chunk, 4) }, qr/stream is closed/, 'closed stream cannot be read');

    my $abandoned = $storage->get_blob($sha256)->body;
    is(_connection_count($DBH), $connections + 1, 'second stream owns a connection');
    undef $abandoned;
    is(_connection_count($DBH), $connections, 'stream destruction releases its connection');
};

subtest 'DSN connection streams through a cloned reader' => sub {
    _reset_schema($DBH);
    my $storage = Net::Blossom::Server::Backend::Postgres->new(
        dsn           => $ENV{NET_BLOSSOM_POSTGRES_DSN},
        username      => $ENV{NET_BLOSSOM_POSTGRES_USER},
        password      => $ENV{NET_BLOSSOM_POSTGRES_PASSWORD},
        base_url      => 'https://cdn.example.test/files',
        connect_attrs => { AutoCommit => 0, PrintError => 1 },
    );
    $storage->deploy_schema;

    ok($storage->dbh->{AutoCommit}, 'backend forces AutoCommit for its primary connection');
    ok(!$storage->dbh->{PrintError}, 'backend disables DBI PrintError');

    my $body = 'DSN-backed stream';
    my $sha256 = sha256_hex($body);
    Net::Blossom::Server->new(storage => $storage)->receive_blob($body);
    is(_read_stream($storage->get_blob($sha256)->body, 4), $body,
        'cloned reader uses the DSN credentials');
};

subtest 'storage remains bound to the schema active at construction' => sub {
    _reset_schema($DBH);
    my $schema = 'Net Blossom Test';
    my $quoted_schema = $DBH->quote_identifier($schema);
    $DBH->do("DROP SCHEMA IF EXISTS $quoted_schema CASCADE");
    $DBH->do("CREATE SCHEMA $quoted_schema");
    $DBH->do("SET search_path TO $quoted_schema");

    my $storage = Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $DBH,
        base_url => 'https://cdn.example.test/files',
    );
    $storage->deploy_schema;

    my $body = 'custom schema stream';
    my $sha256 = sha256_hex($body);
    Net::Blossom::Server->new(storage => $storage)
        ->receive_blob($body, pubkey => $PUBKEY);

    my ($get_error, $result);
    $get_error = dies { $result = $storage->get_blob($sha256) };
    is($get_error, undef, 'cloned reader uses the captured schema');
    isa_ok($result, 'Net::Blossom::Server::BlobResult');
    is(_read_stream($result->body, 4), $body, 'cloned reader streams from the captured schema')
        if defined $result;

    $DBH->do('SET search_path TO public');
    isa_ok($storage->head_blob($sha256), 'Net::Blossom::BlobDescriptor',
        'metadata lookup uses the captured schema');
    is(scalar @{$storage->list_blobs($PUBKEY)}, 1,
        'owner listing uses the captured schema');
    ok($storage->delete_blob($sha256, pubkey => $PUBKEY),
        'deletion uses the captured schema');

    $DBH->do("DROP SCHEMA $quoted_schema CASCADE");
};

subtest 'post-commit temp cleanup failure does not fail committed upload' => sub {
    my $storage = storage();
    my $body = "cleanup failure after commit\n";
    my $sha256 = sha256_hex($body);
    my $cleanup_calls = 0;

    {
        no warnings 'redefine';
        local *Net::Blossom::Server::Backend::Postgres::_Upload::_cleanup = sub {
            $cleanup_calls++;
            die "cleanup failed\n";
        };

        my $result = Net::Blossom::Server->new(storage => $storage)
            ->receive_blob($body, pubkey => $PUBKEY);
        isa_ok($result, 'Net::Blossom::Server::UploadResult', 'upload result');
    }

    ok($cleanup_calls, 'cleanup was attempted');
    isa_ok($storage->head_blob($sha256), 'Net::Blossom::BlobDescriptor', 'committed blob remains visible');
};

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
    $dbh->do('SET search_path TO public');
    $dbh->do('DROP TABLE IF EXISTS blossom_owners');
    $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
    $dbh->do('DROP TABLE IF EXISTS blossom_blob_data');
    $dbh->do('DROP FUNCTION IF EXISTS blossom_reject_owner()');
    $dbh->do('SELECT lo_unlink(oid) FROM pg_largeobject_metadata');
    return;
}

sub _large_object_oids {
    my ($dbh) = @_;
    return [map { 0 + $_->[0] } @{$dbh->selectall_arrayref(
        'SELECT oid FROM pg_largeobject_metadata ORDER BY oid'
    )}];
}

sub _connection_count {
    my ($dbh) = @_;
    my ($count) = $dbh->selectrow_array(q{
        SELECT COUNT(*)
          FROM pg_stat_activity
         WHERE datname = current_database()
           AND usename = current_user
           AND backend_type = 'client backend'
    });
    return 0 + $count;
}

sub _read_stream {
    my ($stream, $read_size) = @_;
    my $body = '';

    while (1) {
        my $chunk = '';
        my $read = $stream->read($chunk, $read_size);
        die "stream read failed\n" unless defined $read;
        last if $read == 0;
        cmp_ok(length($chunk), '<=', $read_size, 'stream read stays within requested size');
        $body .= $chunk;
    }

    return $body;
}
