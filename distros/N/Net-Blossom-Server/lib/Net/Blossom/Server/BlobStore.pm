package Net::Blossom::Server::BlobStore;

use strictures 2;

use Carp qw(croak);
use Scalar::Util qw(blessed);

my @REQUIRED_METHODS = qw(deploy_schema begin_upload get_blob delete_blob);
my @REQUIRED_UPLOAD_METHODS = qw(write prepare commit abort);

sub required_methods {
    return @REQUIRED_METHODS;
}

sub required_upload_methods {
    return @REQUIRED_UPLOAD_METHODS;
}

sub assert_implements {
    my ($class, $store) = @_;
    croak "blob store is required" unless defined $store;
    croak "blob store must be an object" unless blessed($store);

    for my $method (@REQUIRED_METHODS) {
        croak "blob store must provide $method" unless $store->can($method);
    }

    return 1;
}

sub assert_upload {
    my ($class, $upload) = @_;
    croak "blob upload is required" unless defined $upload;
    croak "blob upload must be an object" unless blessed($upload);

    for my $method (@REQUIRED_UPLOAD_METHODS) {
        croak "blob upload must provide $method" unless $upload->can($method);
    }

    return 1;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::BlobStore - Byte storage contract for Blossom backends

=head1 DESCRIPTION

C<Net::Blossom::Server::BlobStore> documents and validates the component that
stores blob bytes. Metadata stores refer to bytes through opaque storage keys.

Uploads use a two-phase lifecycle. C<prepare> stages bytes and returns a storage
key while the coordinating metadata transaction is open. After that transaction
succeeds, C<commit> finalizes local upload resources. C<abort> discards an
unfinished or rolled-back upload.

=head1 STORE METHODS

=head2 deploy_schema

Creates any byte-storage tables required by the implementation. Stores without
a database schema may implement this as a no-op.

=head2 begin_upload

    my $upload = $blobs->begin_upload(%context);

Starts an upload and returns a blob upload writer.
The context is the same as for
L<Net::Blossom::Server::Storage/begin_upload>.

=head2 get_blob

    my $body = $blobs->get_blob($storage_key);

Returns blob bytes as a scalar or stream object, or C<undef> when absent.

=head2 get_blob_range

    my $body = $blobs->get_blob_range(
        $storage_key,
        offset => $offset,
        length => $length,
        size   => $size,
    );

Optional method for efficient byte-range reads. C<offset> is zero-based and
C<length> is positive. It returns exactly C<length> bytes as a scalar or stream,
or C<undef> when the storage key is absent. C<size> may be supplied as the
expected full blob size.

=head2 delete_blob

    my $deleted = $blobs->delete_blob($storage_key);

Deletes the bytes identified by C<$storage_key> and reports whether they
existed. A database blob store must perform deletion in the transaction that
removes the corresponding metadata and reject the call when that transaction
is not active.

=head2 required_methods

Returns the method names required from a blob store.

=head2 required_upload_methods

Returns the method names required from a blob upload writer.

=head2 assert_implements

    Net::Blossom::Server::BlobStore->assert_implements($blobs);

Croaks unless C<$blobs> is an object implementing the store contract.

=head2 assert_upload

    Net::Blossom::Server::BlobStore->assert_upload($upload);

Croaks unless C<$upload> is an object implementing the upload contract.

=head1 UPLOAD METHODS

=head2 write

    $upload->write($bytes);

Appends one byte chunk to the staged upload.

=head2 prepare

    my $storage_key = $upload->prepare(%metadata);

Stages the bytes and returns their opaque storage key. Before metadata commits,
the bytes must either be durable already or be part of the same database
transaction. A database blob store must reject the call when its paired metadata
transaction is not active. C<%metadata> contains C<sha256>, C<size>, C<type>,
C<uploaded>, and optionally C<pubkey>.

=head2 commit

    $upload->commit;

Marks a prepared upload successful and releases staging resources. A
coordinator must not report a durable upload as failed solely because this
post-commit cleanup fails.

=head2 abort

    $upload->abort;

Discards staging resources. It must be safe to call more than once.
It must not delete pre-existing bytes that use the same storage key.

=cut
