use strictures 2;

use Test::More;

use Net::Blossom::Server::BlobStore;
use Net::Blossom::Server::MetadataStore;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::MetadataStore;
    use Class::Tiny;

    sub deploy_schema    { 1 }
    sub with_transaction { $_[1]->() }
    sub lock_blob        { 1 }
    sub find_blob        { undef }
    sub insert_blob      { 1 }
    sub upsert_owner     { 1 }
    sub delete_owner     { 1 }
    sub delete_owners    { 1 }
    sub owner_count      { 0 }
    sub delete_blob      { 1 }
    sub list_blobs       { [] }
}

{
    package Local::BlobStore;
    use Class::Tiny;

    sub deploy_schema { 1 }
    sub begin_upload  { Local::BlobUpload->new }
    sub get_blob      { '' }
    sub delete_blob   { 1 }
}

{
    package Local::BlobUpload;
    use Class::Tiny;

    sub write   { length $_[1] }
    sub prepare { 'storage-key' }
    sub commit  { 1 }
    sub abort   { 1 }
}

is_deeply(
    [Net::Blossom::Server::MetadataStore->required_methods],
    [qw(
        deploy_schema with_transaction lock_blob find_blob insert_blob
        upsert_owner delete_owner delete_owners owner_count delete_blob
        list_blobs
    )],
    'metadata store contract lists required methods',
);
like(
    dies { Net::Blossom::Server::MetadataStore->assert_implements },
    qr/metadata store is required/,
    'metadata store contract requires a value',
);
like(
    dies { Net::Blossom::Server::MetadataStore->assert_implements({}) },
    qr/metadata store must be an object/,
    'metadata store contract requires an object',
);
ok(
    Net::Blossom::Server::MetadataStore->assert_implements(Local::MetadataStore->new),
    'metadata store implementation is accepted',
);
like(
    dies { Net::Blossom::Server::MetadataStore->assert_implements(Local::BlobStore->new) },
    qr/metadata store must provide with_transaction/,
    'metadata store contract rejects an incomplete object',
);

is_deeply(
    [Net::Blossom::Server::BlobStore->required_methods],
    [qw(deploy_schema begin_upload get_blob delete_blob)],
    'blob store contract lists required methods',
);
is_deeply(
    [Net::Blossom::Server::BlobStore->required_upload_methods],
    [qw(write prepare commit abort)],
    'blob upload contract lists required methods',
);
like(
    dies { Net::Blossom::Server::BlobStore->assert_implements },
    qr/blob store is required/,
    'blob store contract requires a value',
);
like(
    dies { Net::Blossom::Server::BlobStore->assert_implements({}) },
    qr/blob store must be an object/,
    'blob store contract requires an object',
);
ok(
    Net::Blossom::Server::BlobStore->assert_implements(Local::BlobStore->new),
    'blob store implementation is accepted',
);
ok(
    Net::Blossom::Server::BlobStore->assert_upload(Local::BlobUpload->new),
    'blob upload implementation is accepted',
);
like(
    dies { Net::Blossom::Server::BlobStore->assert_upload },
    qr/blob upload is required/,
    'blob upload contract requires a value',
);
like(
    dies { Net::Blossom::Server::BlobStore->assert_upload({}) },
    qr/blob upload must be an object/,
    'blob upload contract requires an object',
);
like(
    dies { Net::Blossom::Server::BlobStore->assert_upload(Local::MetadataStore->new) },
    qr/blob upload must provide write/,
    'blob upload contract rejects an incomplete object',
);

done_testing;
