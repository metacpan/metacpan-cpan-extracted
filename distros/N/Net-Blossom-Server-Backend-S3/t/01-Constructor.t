use strictures 2;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/lib";
use Net::Blossom::Server::Backend::S3;
use Net::Blossom::Server::Backend::S3::BlobStore;
use TestS3Client;

my $metadata = Local::MetadataStore->new;
my $client = TestS3Client->new;
my $blobs = Net::Blossom::Server::Backend::S3::BlobStore->new(client => $client);

my $storage = Net::Blossom::Server::Backend::S3->new(
    metadata_store => $metadata,
    blob_store     => $blobs,
    base_url       => 'https://cdn.example.test/',
);

isa_ok($storage, 'Net::Blossom::Server::Backend::S3');
is($storage->metadata_store, $metadata, 'metadata store is retained');
is($storage->blob_store, $blobs, 'blob store is retained');
is($storage->base_url, 'https://cdn.example.test', 'base URL is normalized');

for my $case (
    [[], qr/metadata_store is required/, 'metadata store is required'],
    [[metadata_store => $metadata], qr/base_url is required/, 'base URL is required'],
    [[metadata_store => $metadata, base_url => 'ftp://example.test'],
        qr/valid HTTP base URL/, 'base URL must use HTTP'],
    [[metadata_store => $metadata, base_url => 'https://example.test',
        blob_store => $blobs, unknown => 1],
        qr/unknown argument.*unknown/, 'unknown arguments are rejected'],
    [[metadata_store => $metadata, base_url => 'https://example.test',
        blob_store => $blobs, cleanup_error_handler => 'warn'],
        qr/code reference/, 'cleanup handler must be callable'],
) {
    my ($args, $error, $name) = @$case;
    my $ok = eval { Net::Blossom::Server::Backend::S3->new(@$args); 1 };
    ok(!$ok, $name);
    like($@, $error, "$name reports the cause");
}

my $ok = eval {
    Net::Blossom::Server::Backend::S3->new(
        metadata_store => Local::IncompleteMetadata->new,
        blob_store     => $blobs,
        base_url       => 'https://example.test',
    );
    1;
};
ok(!$ok, 'metadata contract is checked');
like($@, qr/metadata store must provide/, 'metadata contract error is useful');

done_testing;

{
    package Local::MetadataStore;

    use Class::Tiny;

    sub deploy_schema { 1 }
    sub with_transaction { $_[1]->() }
    sub lock_blob { 1 }
    sub find_blob { undef }
    sub insert_blob { 1 }
    sub upsert_owner { 1 }
    sub delete_owner { 0 }
    sub delete_owners { 0 }
    sub owner_count { 0 }
    sub delete_blob { 0 }
    sub list_blobs { [] }
}

{
    package Local::IncompleteMetadata;

    use Class::Tiny;
}
