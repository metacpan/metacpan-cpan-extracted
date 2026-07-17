package Net::Blossom::Server::Storage;

use strictures 2;

use Carp qw(croak);
use Scalar::Util qw(blessed);

my @REQUIRED_METHODS = qw(begin_upload get_blob delete_blob list_blobs);
my @REQUIRED_UPLOAD_METHODS = qw(write commit abort);

sub required_methods {
    return @REQUIRED_METHODS;
}

sub required_upload_methods {
    return @REQUIRED_UPLOAD_METHODS;
}

sub assert_implements {
    my ($class, $storage) = @_;
    croak "storage is required" unless defined $storage;
    croak "storage must be an object" unless blessed($storage);

    for my $method (@REQUIRED_METHODS) {
        croak "storage must provide $method" unless $storage->can($method);
    }

    return 1;
}

sub assert_upload {
    my ($class, $upload) = @_;
    croak "upload writer is required" unless defined $upload;
    croak "upload writer must be an object" unless blessed($upload);

    for my $method (@REQUIRED_UPLOAD_METHODS) {
        croak "upload writer must provide $method" unless $upload->can($method);
    }

    return 1;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Storage - Storage contract for Blossom servers

=head1 SYNOPSIS

    package My::Storage;

    sub begin_upload { ... }
    sub get_blob     { ... }
    sub delete_blob  { ... }
    sub list_blobs   { ... }

    Net::Blossom::Server::Storage->assert_implements($storage);

=head1 DESCRIPTION

C<Net::Blossom::Server::Storage> documents and validates the role-style storage
contract used by C<Net::Blossom::Server>. It is not a base class. Storage
implementations only need to provide the required methods.

The Blossom server core owns SHA-256 calculation. Storage implementations do not
calculate or trust blob hashes. For uploads, storage receives bytes through an
upload writer and receives the computed C<sha256>, C<size>, C<type>,
C<uploaded>, and optional C<pubkey> values at commit time.

=head1 IMPLEMENTATION NOTES

Backends normally store blob bytes, descriptor metadata, and owner metadata. The
descriptor URL is deployment policy, so a storage constructor will usually take
a public C<base_url> and use it when building descriptors.

Backends may separate these responsibilities using
L<Net::Blossom::Server::MetadataStore> and
L<Net::Blossom::Server::BlobStore>. A coordinator still implements this
storage contract and keeps metadata and byte changes consistent.

A minimal upload writer records bytes in C<write>, makes the blob and owner
relationship visible in C<commit>, and discards unfinished bytes in C<abort>:

    sub begin_upload { ...; return My::Upload->new(...) }
    sub write        { ... }
    sub commit       { ...; return { descriptor => $blob, created => $created } }
    sub abort        { ... }

Database backends can implement pagination by ordering owner rows with:

    ORDER BY uploaded DESC, sha256 ASC

When C<cursor> is present, first find that descriptor for the pubkey, then
return rows after it in the same order.

Filesystem backends should write uploads to a temporary path and move bytes into
place only during C<commit>, reusing the existing SHA-256 path for duplicate
bytes. They still need a metadata index for owners, descriptors, ordering, and
cursor lookup; scanning blob files alone is not enough.

=head1 STORAGE METHODS

=head2 begin_upload

    my $upload = $storage->begin_upload(%context);

Starts an upload and returns an upload writer object. The context includes
C<type> and may include C<expected_sha256>, C<allowed_sha256>,
C<content_length>, and C<pubkey>. The upload writer must provide C<write>,
C<commit>, and C<abort>.

No blob or owner relationship may become visible until C<commit> succeeds.

=head2 get_blob

    my $result = $storage->get_blob($sha256, %opts);

Returns a C<Net::Blossom::Server::BlobResult> for an available blob, or
C<undef> when the blob is not available. The result contains both the
C<Net::Blossom::BlobDescriptor> and the blob body as a scalar, an array
reference of scalar chunks, or a stream object with C<read> or C<getline>.

=head2 head_blob

    my $descriptor = $storage->head_blob($sha256);

Optional method used by C<HEAD /E<lt>sha256E<gt>>. Storage implementations with
large blobs should provide this to avoid loading blob bodies for metadata-only
requests. It may return a C<Net::Blossom::BlobDescriptor>, a
C<Net::Blossom::Server::BlobResult>, or C<undef> when the blob is unavailable.
When absent, the server falls back to C<get_blob>. The server closes a
closeable body returned in a C<Net::Blossom::Server::BlobResult>.

=head2 get_blob_range

    my $body = $storage->get_blob_range(
        $sha256,
        offset => $offset,
        length => $length,
    );

Optional method for efficient byte-range reads. C<offset> is a zero-based,
non-negative byte offset. C<length> is a positive byte count. It returns exactly
C<length> bytes in any body form accepted by C<get_blob>, or C<undef> when the
blob is unavailable.

Implement this together with C<head_blob>. The server only uses the native range
path when both methods are present. Otherwise it uses C<get_blob> and limits the
response body to the requested bytes.

=head2 delete_blob

    my $deleted = $storage->delete_blob($sha256, %opts);

Deletes one owner relationship for a blob. When C<pubkey> is passed in C<%opts>,
only that pubkey's ownership is removed. Storage may remove the underlying bytes
after the final owner is deleted. Returns true when something was deleted and
false when the blob or owner relationship was not available.

=head2 list_blobs

    my $blobs = $storage->list_blobs($pubkey, %opts);

Returns an array reference of C<Net::Blossom::BlobDescriptor> objects uploaded
by C<$pubkey>, sorted by C<uploaded> descending and C<sha256> ascending.
C<cursor> is the SHA-256 hash of the last blob from the previous page and must
be excluded from the returned page. The next page starts after that descriptor in
the ordered list. An unknown C<cursor> returns an empty page. C<limit>, when
present, caps the number of descriptors returned and must be honored.

=head1 UPLOAD WRITER METHODS

=head2 write

    $upload->write($bytes);

Writes a byte chunk. The server core calls this while it hashes the same bytes.

=head2 commit

    my $result = $upload->commit(%metadata);

Commits the upload after the server core has computed and validated the SHA-256
hash. C<%metadata> includes C<sha256>, C<size>, C<type>, C<uploaded>, and
optionally C<pubkey>. The method should return either a
C<Net::Blossom::Server::UploadResult> object or a hash reference with
C<descriptor> and C<created>. C<descriptor> may be a
C<Net::Blossom::BlobDescriptor> object or a hash reference suitable for
C<Net::Blossom::BlobDescriptor-E<gt>from_hash>. C<created> must be C<1> when
the blob bytes were newly stored and C<0> when the blob already existed.

For pre-release compatibility, raw C<Net::Blossom::BlobDescriptor> objects and
descriptor hash references are accepted and treated as C<< created => 1 >>.

C<commit> must be atomic from the caller's view. After a successful C<commit>,
the blob and owner relationship must be visible. If C<commit> fails, neither may
be visible.

=head2 abort

    $upload->abort;

Aborts an upload after validation or write failure. C<abort> should be safe to
call more than once. Aborted uploads must not become visible through C<get_blob>
or C<list_blobs>.

=head1 METHODS

=head2 required_methods

    my @methods = Net::Blossom::Server::Storage->required_methods;

Returns the required storage method names.

=head2 required_upload_methods

    my @methods = Net::Blossom::Server::Storage->required_upload_methods;

Returns the required upload writer method names.

=head2 assert_implements

    Net::Blossom::Server::Storage->assert_implements($storage);

Croaks unless C<$storage> is an object that provides the required storage
methods. Returns true otherwise.

=head2 assert_upload

    Net::Blossom::Server::Storage->assert_upload($upload);

Croaks unless C<$upload> is an object that provides the required upload writer
methods. Returns true otherwise.

=head1 BACKEND TESTS

Backend distributions should use
L<Net::Blossom::Server::Storage::Test/run_storage_contract_tests> to verify that
their storage implementation satisfies this contract.

=cut
