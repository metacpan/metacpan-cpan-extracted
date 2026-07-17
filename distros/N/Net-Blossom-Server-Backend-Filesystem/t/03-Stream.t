use strictures 2;

use File::Temp qw(tempdir);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib";
use Net::Blossom::Server::Backend::Filesystem::BlobStore;

my $store = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => tempdir(CLEANUP => 1),
    generation => sub { 'stream' },
);
$store->deploy_schema;

my $key = _upload($store, 'a' x 64, 'abcdefghij');
my $stream = $store->get_blob($key);
isa_ok($stream,
    'Net::Blossom::Server::Backend::Filesystem::BlobStore::_Stream');

my $chunk = '';
is($stream->read($chunk, 2), 2, 'read returns requested bytes');
is($chunk, 'ab', 'first bytes are returned');
is($stream->read($chunk, 5), 5, 'a second read advances the stream');
is($chunk, 'cdefg', 'second bytes are returned in order');
is($stream->read($chunk, 10), 3, 'final read reports remaining bytes');
is($chunk, 'hij', 'final bytes are returned');
is($stream->read($chunk, 10), 0, 'read returns zero at EOF');
is($chunk, '', 'EOF clears the output buffer');

my $zero = $store->get_blob($key);
is($zero->read($chunk, 0), 0, 'zero-length reads return immediately');
is($chunk, '', 'zero-length reads clear the output buffer');
is($zero->close, 1, 'close succeeds');
is($zero->close, 1, 'close is idempotent');
my $ok = eval { $zero->read($chunk, 1); 1 };
ok(!$ok, 'reading a closed stream fails');
like($@, qr/stream is closed/, 'closed stream error is clear');

my $line = $store->get_blob($key);
is($line->getline, 'abcdefghij', 'getline returns a streamed chunk');
is($line->getline, undef, 'getline returns undef at EOF');

my $range = $store->get_blob_range(
    $key,
    offset => 3,
    length => 4,
    size   => 10,
);
isa_ok($range,
    'Net::Blossom::Server::Backend::Filesystem::BlobStore::_Stream');
is(tell($range->fh), 3, 'range stream seeks directly to the requested offset');
is($range->read($chunk, 100), 4, 'range read is bounded by requested length');
is($chunk, 'defg', 'range read returns only requested bytes');
is($range->read($chunk, 1), 0, 'range stream ends at the requested boundary');
is($chunk, '', 'range EOF clears the output buffer');

my $empty_key = _upload($store, 'b' x 64, '');
is($store->get_blob($empty_key), '', 'empty files need no stream object');
is($store->get_blob('cc/cc/' . ('c' x 64) . '-missing'), undef,
    'missing files return undef');

$ok = eval { $store->get_blob($key, size => 9); 1 };
ok(!$ok, 'file size must match authoritative metadata');
like($@, qr/file size does not match metadata/,
    'metadata size mismatch is reported');

$ok = eval { $store->get_blob_range($key, offset => 8, length => 3, size => 10); 1 };
ok(!$ok, 'ranges beyond the file size are rejected');
like($@, qr/range exceeds file size/, 'out-of-bounds range is reported');

$ok = eval { $stream->read($chunk, -1); 1 };
ok(!$ok, 'negative read lengths are rejected');
like($@, qr/non-negative integer/, 'invalid read length is reported');

done_testing;

sub _upload {
    my ($store, $sha256, $body) = @_;
    my $upload = $store->begin_upload;
    $upload->write($body);
    my $key = $upload->prepare(
        sha256 => $sha256,
        size => length($body),
        type => 'application/octet-stream',
        uploaded => 1,
    );
    $upload->commit;
    return $key;
}
