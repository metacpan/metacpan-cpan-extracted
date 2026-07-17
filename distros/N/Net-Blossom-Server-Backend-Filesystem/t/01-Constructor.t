use strictures 2;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib";
use Net::Blossom::Server::Backend::Filesystem;
use Net::Blossom::Server::Backend::Filesystem::BlobStore;

my $metadata = Local::MetadataStore->new;
my $root = tempdir(CLEANUP => 1);
my $storage = Net::Blossom::Server::Backend::Filesystem->new(
    metadata_store => $metadata,
    root           => $root,
    base_url       => 'https://cdn.example.test/',
);

isa_ok($storage, 'Net::Blossom::Server::Backend::Filesystem');
is($storage->metadata_store, $metadata, 'metadata store is retained');
isa_ok($storage->blob_store,
    'Net::Blossom::Server::Backend::Filesystem::BlobStore');
is($storage->blob_store->root, File::Spec->rel2abs($root),
    'filesystem root is normalized');
is($storage->base_url, 'https://cdn.example.test', 'base URL is normalized');

my $blobs = Local::BlobStore->new;
my $custom = Net::Blossom::Server::Backend::Filesystem->new(
    metadata_store => $metadata,
    blob_store     => $blobs,
    base_url       => 'https://cdn.example.test',
);
is($custom->blob_store, $blobs, 'custom blob store is retained');

my $false_blobs = Local::FalseBlobStore->new;
my $false_custom = Net::Blossom::Server::Backend::Filesystem->new(
    metadata_store => $metadata,
    blob_store     => $false_blobs,
    base_url       => 'https://cdn.example.test',
);
is($false_custom->blob_store, $false_blobs,
    'a false-overloaded custom blob store is retained');

for my $case (
    [[], qr/metadata_store is required/, 'metadata store is required'],
    [[metadata_store => $metadata], qr/base_url is required/, 'base URL is required'],
    [[metadata_store => $metadata, base_url => 'https://example.test'],
        qr/root is required/, 'root is required for the default blob store'],
    [[metadata_store => $metadata, root => $root, base_url => 'ftp://example.test'],
        qr/valid HTTP base URL/, 'base URL must use HTTP'],
    [[metadata_store => $metadata, root => $root,
        base_url => 'https://example.test', unknown => 1],
        qr/unknown argument.*unknown/, 'unknown arguments are rejected'],
    [[metadata_store => $metadata, root => $root,
        base_url => 'https://example.test', cleanup_error_handler => 'warn'],
        qr/code reference/, 'cleanup handler must be callable'],
    [[metadata_store => $metadata, blob_store => $blobs, root => $root,
        base_url => 'https://example.test'],
        qr/blob_store cannot be combined/, 'custom blob store excludes filesystem arguments'],
) {
    my ($args, $error, $name) = @$case;
    my $ok = eval { Net::Blossom::Server::Backend::Filesystem->new(@$args); 1 };
    ok(!$ok, $name);
    like($@, $error, "$name reports the cause");
}

my $ok = eval {
    Net::Blossom::Server::Backend::Filesystem->new(
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
    package Local::BlobStore;

    use Class::Tiny;

    sub deploy_schema { 1 }
    sub begin_upload { Local::BlobUpload->new }
    sub get_blob { undef }
    sub delete_blob { 0 }
}

{
    package Local::BlobUpload;

    use Class::Tiny;

    sub write { length $_[1] }
    sub prepare { 'key' }
    sub commit { 1 }
    sub abort { 1 }
}

{
    package Local::FalseBlobStore;

    use parent -norequire, 'Local::BlobStore';
    use overload bool => sub { 0 }, fallback => 1;
}

{
    package Local::IncompleteMetadata;

    use Class::Tiny;
}
