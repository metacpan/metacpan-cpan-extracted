use strictures 2;

use File::Temp qw(tempdir);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/lib";
use Net::Blossom::Server::Backend::S3::BlobStore;
use TestS3Client;

my $temp_dir = tempdir(CLEANUP => 1);
my $generation = 0;
my $client = TestS3Client->new;
my $store = Net::Blossom::Server::Backend::S3::BlobStore->new(
    client     => $client,
    temp_dir   => $temp_dir,
    prefix     => '/blossom/data/',
    generation => sub { 'generation-' . ++$generation },
);

is($store->deploy_schema, 1, 'object storage has no schema to deploy');
is($store->prefix, 'blossom/data', 'object key prefix is normalized');

my $sha256 = 'a' x 64;
my $upload = $store->begin_upload(type => 'text/plain');
is($upload->write('hello '), 6, 'write returns the byte count');
is($upload->write('world'), 5, 'a second chunk is appended');
my $key = $upload->prepare(
    sha256  => $sha256,
    size    => 11,
    type    => 'text/plain',
    uploaded => 1,
);
is($key, "blossom/data/$sha256/generation-1", 'prepare returns a generation-specific key');
is($client->objects->{$key}{body}, 'hello world', 'prepare uploads staged bytes');
is($client->uploads->[0]{content_type}, 'text/plain', 'content type is sent to object storage');
is($client->uploads->[0]{sha256}, $sha256, 'hash is sent as object metadata');
is($upload->commit, 1, 'commit releases local staging resources');
is(_staged_file_count($temp_dir), 0, 'commit removes the staging file');

my $second = $store->begin_upload;
$second->write('different');
my $second_key = $second->prepare(
    sha256   => $sha256,
    size     => 9,
    type     => 'application/octet-stream',
    uploaded => 2,
);
isnt($second_key, $key, 'each prepared upload gets a distinct object key');
$second->abort;
ok(exists $client->objects->{$second_key}, 'abort does not delete already durable bytes');
is(_staged_file_count($temp_dir), 0, 'abort removes the local staging file');
is($second->abort, 1, 'abort is idempotent');

my $aborted = $store->begin_upload;
$aborted->write('unfinished');
is($aborted->abort, 1, 'an unfinished upload can be aborted');
is(_staged_file_count($temp_dir), 0, 'unfinished staging bytes are removed');

my $bad_size = $store->begin_upload;
$bad_size->write('abc');
my $ok = eval {
    $bad_size->prepare(
        sha256 => 'b' x 64,
        size => 4,
        type => 'text/plain',
        uploaded => 1,
    );
    1;
};
ok(!$ok, 'declared size must match staged bytes');
like($@, qr/size does not match/, 'size mismatch is reported');
$bad_size->abort;

my $bad_hash = $store->begin_upload;
$bad_hash->write('abc');
$ok = eval {
    $bad_hash->prepare(
        sha256 => '../not-a-hash',
        size => 3,
        type => 'text/plain',
        uploaded => 1,
    );
    1;
};
ok(!$ok, 'unsafe hashes cannot enter object keys');
like($@, qr/sha256 must be 64 lowercase hexadecimal characters/, 'bad hash is reported');
$bad_hash->abort;

$client->fail_upload(1);
my $failed = $store->begin_upload;
$failed->write('abc');
$ok = eval {
    $failed->prepare(
        sha256 => 'c' x 64,
        size => 3,
        type => 'text/plain',
        uploaded => 1,
    );
    1;
};
ok(!$ok, 'object upload failures propagate');
like($@, qr/injected upload failure/, 'upload error is preserved');
$failed->abort;
is(_staged_file_count($temp_dir), 0, 'failed uploads can release staging bytes');

ok($store->delete_blob($key), 'delete removes an existing object');
ok(!exists $client->objects->{$key}, 'deleted object is gone');
ok(!$store->delete_blob('missing'), 'delete reports a missing object');

my $too_large_part = eval {
    Net::Blossom::Server::Backend::S3::BlobStore->new(
        client              => TestS3Client->new,
        multipart_part_size => 5 * 1024 * 1024 * 1024 + 1,
    );
    1;
};
ok(!$too_large_part, 'multipart parts cannot exceed the S3 maximum');
like($@, qr/at most 5 GiB/, 'oversized multipart part is reported');

my $bad_generation = eval {
    Net::Blossom::Server::Backend::S3::BlobStore->new(
        client     => TestS3Client->new,
        generation => 0,
    );
    1;
};
ok(!$bad_generation, 'an explicit false generation callback is rejected');
like($@, qr/generation must be a code reference/, 'invalid generation callback is reported');

done_testing;

sub _staged_file_count {
    my ($dir) = @_;
    opendir my $dh, $dir or die "cannot read $dir: $!";
    my @files = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    return scalar @files;
}
