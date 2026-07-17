package Net::Blossom::Server::Storage::Test;

use strictures 2;

use Carp qw(croak);
use Digest::SHA qw(sha256_hex);
use Exporter qw(import);
use Scalar::Util qw(blessed);
use Test::More ();

use Net::Blossom::BlobDescriptor;
use Net::Blossom::Server;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::Storage;
use Net::Blossom::Server::UploadResult;

our @EXPORT_OK = qw(run_storage_contract_tests);

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $OTHER_PUBKEY = '266815e0c9210dfa324c6cba3573b14bee49da4209a9456f9484e5106cd408a5';
my $MISSING_SHA256 = 'f' x 64;

sub run_storage_contract_tests {
    my %args = @_;
    my $name = delete $args{name};
    my $factory = delete $args{factory};
    croak "unknown argument(s): " . join(', ', sort keys %args) if keys %args;
    croak "name is required" unless defined $name && !ref($name) && length $name;
    croak "factory must be a code reference" unless ref($factory) eq 'CODE';

    Test::More::subtest $name => sub {
        _committed_uploads_are_visible($factory);
        _head_blob_returns_metadata_if_supported($factory);
        _get_blob_range_returns_requested_bytes_if_supported($factory);
        _failed_uploads_are_not_visible($factory);
        _delete_hides_blob($factory);
        _delete_is_pubkey_scoped($factory);
    };

    return 1;
}

sub _get_blob_range_returns_requested_bytes_if_supported {
    my ($factory) = @_;
    my $storage = _fresh_storage($factory);

    if (!$storage->can('get_blob_range')) {
        Test::More::pass('optional get_blob_range is not implemented');
        return;
    }

    my $body = "range contract body\n";
    my $blob = _upload($storage, $body, 1725105921)->descriptor;
    my $range = $storage->get_blob_range(
        $blob->sha256,
        offset => 6,
        length => 8,
    );
    Test::More::is(_body_to_scalar($range), 'contract',
        'get_blob_range returns only requested bytes');
    Test::More::is(
        $storage->get_blob_range($MISSING_SHA256, offset => 0, length => 1),
        undef,
        'get_blob_range returns undef for missing blobs',
    );
}

sub _committed_uploads_are_visible {
    my ($factory) = @_;
    my $storage = _fresh_storage($factory);
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });
    my $body = "contract blob one\n";
    my $sha256 = sha256_hex($body);

    my $result = $server->receive_blob(
        $body,
        type            => 'text/plain',
        expected_sha256 => $sha256,
        content_length  => length($body),
        pubkey          => $PUBKEY,
    );

    _is_upload_result($result, 1, 'new upload result');
    my $blob = $result->descriptor;
    _is_descriptor($blob, $sha256, length($body), 'text/plain', 1725105921, 'upload descriptor');
    _is_blob_result($storage->get_blob($sha256), $sha256, length($body), 'text/plain', 1725105921, $body, 'get_blob result');

    my $second = _upload($storage, "contract blob two\n", 1725105922);
    my $same_time_a = _upload($storage, "same timestamp a\n", 1725105923);
    my $same_time_b = _upload($storage, "same timestamp b\n", 1725105923);
    my @same_time = sort { $a->sha256 cmp $b->sha256 } (
        $same_time_a->descriptor,
        $same_time_b->descriptor,
    );
    my @ordered = (
        (map { $_->sha256 } @same_time),
        $second->descriptor->sha256,
        $sha256,
    );

    my $listed = $storage->list_blobs($PUBKEY, limit => 10);
    _is_descriptor_list($listed, \@ordered, 'list_blobs returns uploaded-desc sha256-asc order');

    my $first_page = $storage->list_blobs($PUBKEY, limit => 1);
    _is_descriptor_list($first_page, [$ordered[0]], 'list_blobs honors limit');

    my $page = $storage->list_blobs($PUBKEY, cursor => $ordered[0], limit => 2);
    _is_descriptor_list($page, [@ordered[1, 2]], 'list_blobs starts after cursor and honors limit');

    my $unknown_cursor = $storage->list_blobs($PUBKEY, cursor => $MISSING_SHA256, limit => 10);
    _is_descriptor_list($unknown_cursor, [], 'list_blobs returns an empty page for an unknown cursor');

    my $empty = $storage->list_blobs($OTHER_PUBKEY, limit => 10);
    _is_descriptor_list($empty, [], 'list_blobs scopes by pubkey');

    my $duplicate = _upload($storage, $body, 1725105924);
    _is_upload_result($duplicate, 0, 'duplicate upload result');
    $listed = $storage->list_blobs($PUBKEY, limit => 10);
    my @same = grep { $_->sha256 eq $sha256 } @$listed;
    Test::More::is(scalar @same, 1, 'duplicate upload is visible once for the same pubkey');
}

sub _head_blob_returns_metadata_if_supported {
    my ($factory) = @_;
    my $storage = _fresh_storage($factory);

    if (!$storage->can('head_blob')) {
        Test::More::pass('optional head_blob is not implemented');
        return;
    }

    my $body = "head contract blob\n";
    my $uploaded = 1725105921;
    my $blob = _upload($storage, $body, $uploaded)->descriptor;

    my $result = $storage->head_blob($blob->sha256);
    my $descriptor = _descriptor_from_head_result($result);
    _is_descriptor(
        $descriptor,
        $blob->sha256,
        length($body),
        'application/octet-stream',
        $uploaded,
        'head_blob descriptor',
    );
    Test::More::is($storage->head_blob($MISSING_SHA256), undef, 'head_blob returns undef for missing blobs');
}

sub _failed_uploads_are_not_visible {
    my ($factory) = @_;
    my $storage = _fresh_storage($factory);
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });
    my $body = "bad contract blob\n";
    my $sha256 = sha256_hex($body);

    my $ok = eval {
        $server->receive_blob($body, expected_sha256 => '0' x 64, pubkey => $PUBKEY);
        1;
    };

    Test::More::ok(!$ok, 'failed upload croaks');
    Test::More::like($@, qr/sha256 mismatch/, 'failed upload reports sha mismatch');
    Test::More::is($storage->get_blob($sha256), undef, 'failed upload is not retrievable');
    _is_descriptor_list($storage->list_blobs($PUBKEY, limit => 10), [], 'failed upload is not listed');
}

sub _delete_hides_blob {
    my ($factory) = @_;
    my $storage = _fresh_storage($factory);
    my $blob = _upload($storage, "delete contract blob\n", 1725105921)->descriptor;

    Test::More::ok($storage->delete_blob($blob->sha256, pubkey => $PUBKEY), 'delete_blob returns true for existing blob');
    Test::More::is($storage->get_blob($blob->sha256), undef, 'deleted blob is not retrievable');
    _is_descriptor_list($storage->list_blobs($PUBKEY, limit => 10), [], 'deleted blob is not listed');
    Test::More::ok(!$storage->delete_blob($blob->sha256, pubkey => $PUBKEY), 'delete_blob returns false for missing blob');
}

sub _delete_is_pubkey_scoped {
    my ($factory) = @_;
    my $storage = _fresh_storage($factory);
    my $body = "shared contract blob\n";
    my $first = _upload($storage, $body, 1725105921, $PUBKEY);
    my $second = _upload($storage, $body, 1725105922, $OTHER_PUBKEY);
    my $sha256 = $first->descriptor->sha256;

    _is_upload_result($first, 1, 'first shared upload result');
    _is_upload_result($second, 0, 'second shared upload result');
    Test::More::is($second->descriptor->sha256, $sha256, 'same bytes produce same hash for another pubkey');
    Test::More::ok($storage->delete_blob($sha256, pubkey => $PUBKEY), 'delete_blob removes one owner');
    Test::More::isa_ok($storage->get_blob($sha256), 'Net::Blossom::Server::BlobResult', 'shared blob remains retrievable');
    _is_descriptor_list($storage->list_blobs($PUBKEY, limit => 10), [], 'deleted owner no longer lists shared blob');
    _is_descriptor_list($storage->list_blobs($OTHER_PUBKEY, limit => 10), [$sha256], 'other owner still lists shared blob');
    Test::More::ok($storage->delete_blob($sha256, pubkey => $OTHER_PUBKEY), 'delete_blob removes final owner');
    Test::More::is($storage->get_blob($sha256), undef, 'shared blob is removed after final owner delete');
}

sub _upload {
    my ($storage, $body, $uploaded, $pubkey) = @_;
    $pubkey = $PUBKEY unless defined $pubkey;
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { $uploaded });
    return $server->receive_blob(
        $body,
        type           => 'application/octet-stream',
        content_length => length($body),
        pubkey         => $pubkey,
    );
}

sub _fresh_storage {
    my ($factory) = @_;
    my $storage = $factory->();
    Net::Blossom::Server::Storage->assert_implements($storage);
    return $storage;
}

sub _descriptor_from_head_result {
    my ($result) = @_;
    return undef unless defined $result;
    return $result
        if blessed($result) && $result->isa('Net::Blossom::BlobDescriptor');
    return $result->descriptor
        if blessed($result) && $result->isa('Net::Blossom::Server::BlobResult');
    Test::More::fail('head_blob returns a descriptor or blob result');
    return undef;
}

sub _is_descriptor {
    my ($descriptor, $sha256, $size, $type, $uploaded, $name) = @_;
    Test::More::isa_ok($descriptor, 'Net::Blossom::BlobDescriptor', $name);
    return unless blessed($descriptor) && $descriptor->isa('Net::Blossom::BlobDescriptor');
    Test::More::is($descriptor->sha256, $sha256, "$name sha256");
    Test::More::is($descriptor->size, $size, "$name size");
    Test::More::is($descriptor->type, $type, "$name type");
    Test::More::is($descriptor->uploaded, $uploaded, "$name uploaded");
}

sub _is_upload_result {
    my ($result, $created, $name) = @_;
    Test::More::isa_ok($result, 'Net::Blossom::Server::UploadResult', $name);
    return unless blessed($result) && $result->isa('Net::Blossom::Server::UploadResult');
    Test::More::isa_ok($result->descriptor, 'Net::Blossom::BlobDescriptor', "$name descriptor");
    Test::More::is($result->created, $created, "$name created");
}

sub _is_blob_result {
    my ($result, $sha256, $size, $type, $uploaded, $body, $name) = @_;
    Test::More::isa_ok($result, 'Net::Blossom::Server::BlobResult', $name);
    return unless blessed($result) && $result->isa('Net::Blossom::Server::BlobResult');
    _is_descriptor($result->descriptor, $sha256, $size, $type, $uploaded, "$name descriptor");
    Test::More::is(_body_to_scalar($result->body), $body, "$name body");
}

sub _is_descriptor_list {
    my ($list, $sha256, $name) = @_;
    Test::More::is(ref($list), 'ARRAY', "$name returns array reference");
    return unless ref($list) eq 'ARRAY';
    my @got;
    for my $descriptor (@$list) {
        Test::More::isa_ok($descriptor, 'Net::Blossom::BlobDescriptor', "$name item");
        push @got, blessed($descriptor) && $descriptor->isa('Net::Blossom::BlobDescriptor')
            ? $descriptor->sha256
            : undef;
    }
    Test::More::is_deeply(\@got, $sha256, $name);
}

sub _body_to_scalar {
    my ($body) = @_;
    return $body unless ref($body);

    if (ref($body) eq 'ARRAY') {
        return join '', @$body;
    }

    if (blessed($body) && $body->can('read')) {
        my $content = '';
        while (1) {
            my $chunk = '';
            my $read = $body->read($chunk, 8192);
            die "body stream read failed" unless defined $read;
            last if $read == 0;
            $content .= $chunk;
        }
        return $content;
    }

    if (blessed($body) && $body->can('getline')) {
        my $content = '';
        while (defined(my $chunk = $body->getline)) {
            $content .= $chunk;
        }
        return $content;
    }

    Test::More::fail('blob result body is a scalar, array reference, or stream object');
    return undef;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Storage::Test - Conformance tests for Blossom server storage backends

=head1 SYNOPSIS

    use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

    run_storage_contract_tests(
        name    => 'postgres storage',
        factory => sub {
            reset_test_database($dbh);
            return My::Blossom::Storage::Postgres->new(
                dbh      => $dbh,
                base_url => 'https://cdn.example.test',
            );
        },
    );

=head1 DESCRIPTION

C<Net::Blossom::Server::Storage::Test> provides reusable tests for storage
backend distributions. A backend can be database-backed, filesystem-backed, or
object-storage-backed as long as it satisfies L<Net::Blossom::Server::Storage>.

The test helper creates fresh storage instances with a caller-provided factory
and verifies observable behavior through the public server and storage APIs.

=head1 FUNCTIONS

=head2 run_storage_contract_tests

    run_storage_contract_tests(
        name    => $name,
        factory => sub { ... },
    );

Runs a C<Test::More> subtest named C<$name>. C<factory> must return a fresh,
empty storage object each time it is called. Persistent backends should delete
test rows or files before returning the storage object.

The tests cover successful uploads, duplicate upload deduplication, retrieval,
optional C<head_blob> and C<get_blob_range>, failed upload abort behavior,
owner-scoped deletion, shared blobs, list ordering, cursor pagination, unknown
cursors, and limit handling.

=head1 STORAGE EXPECTATIONS

The storage object must implement the runtime contract documented by
L<Net::Blossom::Server::Storage>. In particular, C<list_blobs> must return
descriptors ordered by C<uploaded> descending and C<sha256> ascending, and
C<cursor> must start the next page after the matching descriptor in that order.

Missing blobs return C<undef> from C<get_blob> and optional C<head_blob> and
C<get_blob_range>.
C<delete_blob> returns false when there is no matching blob or owner
relationship. Failed uploads and aborted uploads must not become visible through
C<get_blob> or C<list_blobs>.

=cut
