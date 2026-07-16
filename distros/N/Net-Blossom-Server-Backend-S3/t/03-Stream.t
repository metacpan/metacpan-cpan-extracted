use strictures 2;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/lib";
use Net::Blossom::Server::Backend::S3::BlobStore;
use TestS3Client;

my $client = TestS3Client->new(
    objects => {
        alpha => {body => 'abcdefghij'},
        empty => {body => ''},
    },
);
my $store = Net::Blossom::Server::Backend::S3::BlobStore->new(
    client     => $client,
    range_size => 4,
);

my $bounded_client = TestS3Client->new(
    objects => {alpha => {body => 'abcdefghij'}},
);
my $bounded_store = Net::Blossom::Server::Backend::S3::BlobStore->new(
    client     => $bounded_client,
    range_size => 4,
);
my $bounded = $bounded_store->get_blob('alpha');
my $bounded_chunk = '';
is($bounded->read($bounded_chunk, 100), 4,
    'large reads return a bounded short chunk');
is($bounded_chunk, 'abcd', 'bounded short read returns one range');
is_deeply($bounded_client->ranges, [['alpha', 0, 3]],
    'large read fetches only one range');

my $stream = $store->get_blob('alpha');
isa_ok($stream, 'Net::Blossom::Server::Backend::S3::BlobStore::_Stream');
is_deeply($client->ranges, [], 'get_blob does not download the body');

my $chunk = '';
is($stream->read($chunk, 2), 2, 'read returns requested bytes');
is($chunk, 'ab', 'first bytes are returned');
is_deeply($client->ranges, [['alpha', 0, 3]], 'the first bounded range is fetched');

is($stream->read($chunk, 5), 2, 'read drains the current range before fetching another');
is($chunk, 'cd', 'remaining bytes from the current range are returned');
is_deeply(
    $client->ranges,
    [['alpha', 0, 3]],
    'a partially consumed range prevents another fetch',
);

is($stream->read($chunk, 10), 4, 'the next read fetches one bounded range');
is($chunk, 'efgh', 'the next range is returned in order');
is($stream->read($chunk, 10), 2, 'final short read reports remaining bytes');
is($chunk, 'ij', 'remaining bytes are returned');
is($stream->read($chunk, 10), 0, 'read returns zero at EOF');
is($chunk, '', 'EOF clears the output buffer');
is_deeply($client->ranges->[-1], ['alpha', 8, 9], 'final range is bounded by object size');

my $zero = $store->get_blob('alpha');
is($zero->read($chunk, 0), 0, 'zero-length reads do not fetch data');
is_deeply($client->ranges->[-1], ['alpha', 8, 9], 'zero-length read makes no request');
is($zero->close, 1, 'close succeeds');
is($zero->close, 1, 'close is idempotent');
my $ok = eval { $zero->read($chunk, 1); 1 };
ok(!$ok, 'reading a closed stream fails');
like($@, qr/stream is closed/, 'closed stream error is clear');

is($store->get_blob('empty'), '', 'empty objects need no range stream');
is($store->get_blob('missing'), undef, 'missing objects return undef');

$ok = eval { $store->get_blob('alpha', size => 9); 1 };
ok(!$ok, 'object size must match authoritative metadata');
like($@, qr/object size does not match metadata/, 'metadata size mismatch is reported');

$client->short_range(1);
my $short = $store->get_blob('alpha');
$ok = eval { $short->read($chunk, 4); 1 };
ok(!$ok, 'truncated range responses are rejected');
like($@, qr/range length/, 'truncated response reports the protocol error');

$ok = eval { $stream->read($chunk, -1); 1 };
ok(!$ok, 'negative read lengths are rejected');
like($@, qr/non-negative integer/, 'invalid read length is reported');

done_testing;
