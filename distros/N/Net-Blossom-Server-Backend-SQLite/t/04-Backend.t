use strictures 2;

use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use Test::More;

use Net::Blossom::Server;
use Net::Blossom::Server::Backend::SQLite;
use Net::Blossom::Server::Backend::SQLite::BlobStore;

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

sub storage {
    my $dir = tempdir(CLEANUP => 1);
    my $storage = Net::Blossom::Server::Backend::SQLite->new(
        database => "$dir/blossom.sqlite",
        base_url => 'https://cdn.example.test/files',
    );
    $storage->deploy_schema;
    return $storage;
}

subtest 'blob descriptors use base URL and SQLite metadata' => sub {
    my $storage = storage();
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107000 });
    my $body = "sqlite backend blob\n";
    my $sha256 = sha256_hex($body);

    my $upload = $server->receive_blob($body, type => 'text/plain', pubkey => $PUBKEY);
    is($upload->descriptor->url, "https://cdn.example.test/files/$sha256", 'upload descriptor URL');

    my $head = $storage->head_blob($sha256);
    isa_ok($head, 'Net::Blossom::BlobDescriptor');
    is($head->url, "https://cdn.example.test/files/$sha256", 'head descriptor URL');
    is($head->type, 'text/plain', 'head descriptor type');

    my $result = $storage->get_blob($sha256);
    isa_ok($result, 'Net::Blossom::Server::BlobResult');
    is($result->body, $body, 'get_blob returns stored bytes');

    is(
        $storage->get_blob_range($sha256, offset => 7, length => 7),
        'backend',
        'backend range retrieval returns requested bytes',
    );
};

subtest 'binary ranges use byte offsets' => sub {
    my $storage = storage();
    my $body = pack 'C*', 0xc3, 0xa9, 0x41;
    my $sha256 = sha256_hex($body);

    Net::Blossom::Server->new(storage => $storage)->receive_blob($body);

    is(
        $storage->dbh->selectrow_array(
            q{SELECT typeof(body) FROM blossom_blob_data WHERE storage_key = ?},
            undef,
            $sha256,
        ),
        'blob',
        'uploaded bytes are stored as a SQLite BLOB',
    );
    is(
        unpack('H*', $storage->get_blob_range($sha256, offset => 1, length => 1)),
        'a9',
        'range offsets count bytes rather than UTF-8 characters',
    );
};

subtest 'blob store retrieves ranges inside SQLite' => sub {
    my $dbh = Local::RangeDBH->new(body => 'backend');
    my $store = Net::Blossom::Server::Backend::SQLite::BlobStore->new(
        dbh => $dbh,
    );

    is(
        $store->get_blob_range('storage-key', offset => 7, length => 7, size => 20),
        'backend',
        'blob store returns the database range result',
    );
    like(
        $dbh->{select_calls}[0][0],
        qr/SELECT substr\(CAST\(body AS BLOB\), \?, \?\)/,
        'blob store asks SQLite for a BLOB substring',
    );
    is_deeply(
        [@{$dbh->{select_calls}[0]}[2 .. 4]],
        [8, 7, 'storage-key'],
        'SQLite receives one-based offset, length, and storage key',
    );
};

subtest 'duplicate owner uploads stay unique and update list metadata' => sub {
    my $storage = storage();
    my $body = "same owner duplicate\n";
    my $sha256 = sha256_hex($body);

    Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107000 })
        ->receive_blob($body, type => 'text/plain', pubkey => $PUBKEY);
    my $second = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107100 })
        ->receive_blob($body, type => 'application/octet-stream', pubkey => $PUBKEY);

    is($second->created, 0, 'duplicate bytes are not stored again');
    is($second->descriptor->type, 'application/octet-stream', 'duplicate result uses current upload type');

    my $listed = $storage->list_blobs($PUBKEY, limit => 10);
    is(scalar @$listed, 1, 'owner sees one descriptor for duplicate hash');
    is($listed->[0]->sha256, $sha256, 'listed duplicate hash');
    is($listed->[0]->type, 'application/octet-stream', 'owner list metadata was updated');
    is($listed->[0]->uploaded, 1725107100, 'owner list uploaded time was updated');
    is(
        $storage->dbh->selectrow_array(
            q{SELECT COUNT(*) FROM blossom_blob_data WHERE storage_key = ?},
            undef,
            $sha256,
        ),
        1,
        'duplicate upload keeps one physical blob row',
    );
};

subtest 'empty and binary bodies remain distinguishable from missing blobs' => sub {
    my $storage = storage();
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $binary = "binary\0body";

    $server->receive_blob($binary);
    $server->receive_blob('');

    is($storage->get_blob(sha256_hex($binary))->body, $binary,
        'binary body round trips unchanged');
    is($storage->get_blob(sha256_hex(''))->body, '',
        'empty body is returned as an empty scalar');
    is($storage->get_blob('f' x 64), undef,
        'missing blob remains undef');
};

subtest 'anonymous blobs can be deleted without owner scope' => sub {
    my $storage = storage();
    my $body = "anonymous blob\n";
    my $sha256 = sha256_hex($body);

    Net::Blossom::Server->new(storage => $storage, clock => sub { 1725107000 })
        ->receive_blob($body, type => 'text/plain');

    isa_ok($storage->get_blob($sha256), 'Net::Blossom::Server::BlobResult', 'anonymous blob stored');
    ok(!$storage->delete_blob($sha256, pubkey => $PUBKEY), 'owner-scoped delete does not remove anonymous blob');
    ok($storage->delete_blob($sha256), 'unscoped delete removes anonymous blob');
    is($storage->get_blob($sha256), undef, 'anonymous blob removed');
};

subtest 'direct blob preparation requires a metadata transaction' => sub {
    my $storage = storage();
    my $upload = $storage->blob_store->begin_upload;
    $upload->write('uncoordinated body');

    like(
        dies { $upload->prepare(sha256 => sha256_hex('uncoordinated body')) },
        qr/blob preparation requires an active transaction/,
        'prepare outside the coordinator transaction is rejected',
    );
    is(
        $storage->dbh->selectrow_array(q{SELECT COUNT(*) FROM blossom_blob_data}),
        0,
        'rejected preparation leaves no blob-data row',
    );
    ok($upload->abort, 'rejected preparation can be aborted');
};

subtest 'direct blob deletion requires a metadata transaction' => sub {
    my $storage = storage();
    my $body = 'coordinated body';
    my $sha256 = sha256_hex($body);
    Net::Blossom::Server->new(storage => $storage)->receive_blob($body);

    like(
        dies { $storage->blob_store->delete_blob($sha256) },
        qr/blob deletion requires an active transaction/,
        'delete outside the coordinator transaction is rejected',
    );
    my $result = $storage->get_blob($sha256);
    isa_ok($result, 'Net::Blossom::Server::BlobResult',
        'rejected deletion preserves metadata');
    is(defined $result ? $result->body : undef, $body,
        'rejected deletion preserves bytes');
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
        'blob lock outside with_transaction is rejected',
    );
    my $result = $storage->get_blob($sha256);
    isa_ok($result, 'Net::Blossom::Server::BlobResult',
        'rejected metadata deletion preserves the blob');
    is(defined $result ? $result->body : undef, $body,
        'rejected metadata deletion preserves bytes');
};

subtest 'commit failure rolls back and aborts upload' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $storage = Net::Blossom::Server::Backend::SQLite->new(
        database => "$dir/missing-schema.sqlite",
        base_url => 'https://cdn.example.test/files',
    );
    my $server = Net::Blossom::Server->new(storage => $storage);

    like(dies { $server->receive_blob('body', pubkey => $PUBKEY) },
        qr/blossom_blobs|no such table/i,
        'database failure is preserved');
};

subtest 'upload rejects a handle changed to manual transaction mode' => sub {
    my $storage = storage();
    my $server = Net::Blossom::Server->new(storage => $storage);
    $storage->dbh->{AutoCommit} = 0;

    like(dies { $server->receive_blob('body', pubkey => $PUBKEY) },
        qr/dbh must have AutoCommit enabled/,
        'manual transaction mode is rejected before upload');

    $storage->dbh->rollback;
    $storage->dbh->{AutoCommit} = 1;
};

subtest 'post-commit temp cleanup failure does not fail committed upload' => sub {
    my $storage = storage();
    my $body = "cleanup failure after commit\n";
    my $sha256 = sha256_hex($body);
    my $cleanup_calls = 0;

    {
        no warnings 'redefine';
        local *Net::Blossom::Server::Backend::SQLite::_Upload::_cleanup = sub {
            $cleanup_calls++;
            die "cleanup failed\n";
        };

        my $result = Net::Blossom::Server->new(storage => $storage)
            ->receive_blob($body, pubkey => $PUBKEY);
        isa_ok($result, 'Net::Blossom::Server::UploadResult', 'upload result');
    }

    ok($cleanup_calls, 'cleanup was attempted');
    isa_ok($storage->get_blob($sha256), 'Net::Blossom::Server::BlobResult', 'committed blob remains visible');
};

done_testing;

{
    package Local::RangeDBH;

    use Class::Tiny qw(body), {
        AutoCommit  => 1,
        RaiseError  => 1,
        PrintError  => 0,
        Driver      => sub { {Name => 'SQLite'} },
        select_calls => sub { [] },
    };

    sub BUILD {
        my ($self) = @_;
        $self->AutoCommit;
        $self->RaiseError;
        $self->PrintError;
        $self->Driver;
        $self->select_calls;
        return;
    }

    sub selectrow_array {
        my ($self, @args) = @_;
        push @{$self->{select_calls}}, \@args;
        return $self->body;
    }

    sub do {
        return 1;
    }
}
