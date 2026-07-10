use strictures 2;

use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use Test::More;

use Net::Blossom::Server;
use Net::Blossom::Server::Backend::SQLite;

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
