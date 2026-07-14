package Net::Blossom::Server::MetadataStore;

use strictures 2;

use Carp qw(croak);
use Scalar::Util qw(blessed);

my @REQUIRED_METHODS = qw(
    deploy_schema with_transaction lock_blob find_blob insert_blob
    upsert_owner delete_owner delete_owners owner_count delete_blob
    list_blobs
);

sub required_methods {
    return @REQUIRED_METHODS;
}

sub assert_implements {
    my ($class, $store) = @_;
    croak "metadata store is required" unless defined $store;
    croak "metadata store must be an object" unless blessed($store);

    for my $method (@REQUIRED_METHODS) {
        croak "metadata store must provide $method" unless $store->can($method);
    }

    return 1;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::MetadataStore - Metadata storage contract for Blossom backends

=head1 DESCRIPTION

C<Net::Blossom::Server::MetadataStore> documents and validates the metadata
component used by a Blossom storage backend. A metadata store manages blob
records and owner records, but never stores blob bytes.

Blob records are hash references with C<sha256>, C<storage_key>, C<size>,
C<type>, and C<uploaded> values. C<storage_key> is an opaque identifier owned by
the corresponding blob store.

C<lock_blob> and every method that changes records must be called from a
C<with_transaction> callback. Database implementations must reject those calls
when the transaction is not active.

=head1 METHODS

=head2 deploy_schema

Creates the metadata tables and indexes. It must be safe to call repeatedly.

=head2 with_transaction

    my $result = $metadata->with_transaction(sub { ... });

Runs the callback in a transaction, committing its result or rolling it back
when the callback dies.

=head2 lock_blob

    $metadata->lock_blob($sha256);

Prevents concurrent changes for the same hash from interleaving within the
current transaction. It may be a no-op only when the transaction model already
provides that serialization.

=head2 find_blob

    my $record = $metadata->find_blob($sha256);

Returns a blob record or C<undef>.

=head2 insert_blob

    my $created = $metadata->insert_blob(%record);

Inserts a blob record and returns true when it was created or false when the
hash already exists.

=head2 upsert_owner

    $metadata->upsert_owner(%owner);

Creates or updates the owner identified by C<pubkey> and C<sha256>. Owner data
also includes C<type> and C<uploaded>.

=head2 delete_owner

    my $deleted = $metadata->delete_owner($sha256, $pubkey);

Deletes one owner relationship and reports whether it existed.

=head2 delete_owners

    $metadata->delete_owners($sha256);

Deletes every owner relationship for a blob.

=head2 owner_count

    my $count = $metadata->owner_count($sha256);

Returns the number of owners for a blob.

=head2 delete_blob

    my $deleted = $metadata->delete_blob($sha256);

Deletes one blob record and reports whether it existed.

=head2 list_blobs

    my $records = $metadata->list_blobs($pubkey, %options);

Returns blob records for an owner using the ordering, C<cursor>, and C<limit>
rules from L<Net::Blossom::Server::Storage>.

=head2 required_methods

Returns the method names required from a metadata store.

=head2 assert_implements

    Net::Blossom::Server::MetadataStore->assert_implements($metadata);

Croaks unless C<$metadata> is an object implementing the contract.

=cut
