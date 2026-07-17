use strictures 2;

use File::Spec;
use File::Temp qw(tempdir tempfile);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib";
use Net::Blossom::Server::Backend::Filesystem::BlobStore;

my $root = File::Spec->catdir(tempdir(CLEANUP => 1), 'storage');
my $generation = 0;
my $store = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => $root,
    generation => sub { 'generation-' . ++$generation },
);

is($store->deploy_schema, 1, 'filesystem layout is deployed');
ok(-d $root, 'root directory is created');
ok(-d File::Spec->catdir($root, 'blobs'), 'blob directory is created');
ok(-d File::Spec->catdir($root, '.staging'), 'staging directory is created');
is($store->deploy_schema, 1, 'filesystem layout deployment is idempotent');

my $nested_parent = tempdir(CLEANUP => 1);
my $nested_root = File::Spec->catdir($nested_parent, 'one', 'two');
my @schema_syncs;
{
    no warnings 'redefine';
    local *Net::Blossom::Server::Backend::Filesystem::BlobStore::_sync_directory = sub {
        push @schema_syncs, $_[0];
        return 1;
    };
    Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
        root => $nested_root,
    )->deploy_schema;
}
my %schema_synced = map { _path_id($_) => 1 } @schema_syncs;
ok($schema_synced{_path_id($nested_parent)},
    'deploy synchronizes a newly created root ancestor');
ok($schema_synced{_path_id(File::Spec->catdir($nested_parent, 'one'))},
    'deploy synchronizes the configured root entry');

my $sha256 = 'a' x 64;
my $upload = $store->begin_upload(type => 'text/plain');
is($upload->write('hello '), 6, 'write returns the byte count');
is($upload->write('world'), 5, 'a second chunk is appended');
my $key = $upload->prepare(
    sha256   => $sha256,
    size     => 11,
    type     => 'text/plain',
    uploaded => 1,
);
is($key, "aa/aa/$sha256-generation-1",
    'prepare returns a hash-sharded generation-specific key');
is(_read_file(_blob_path($root, $key)), 'hello world',
    'prepare publishes the complete staged file');
is(_staged_file_count($root), 0, 'prepare removes the staging link');
is($upload->commit, 1, 'commit succeeds');
is($upload->commit, 1, 'commit is idempotent');

my @abort_syncs;
my $aborted;
{
    no warnings 'redefine';
    local *Net::Blossom::Server::Backend::Filesystem::BlobStore::_sync_directory = sub {
        push @abort_syncs, $_[0];
        return 1;
    };
    $aborted = $store->begin_upload;
    $aborted->write('unfinished');
    is($aborted->abort, 1, 'an unfinished upload can be aborted');
    is($aborted->abort, 1, 'abort is idempotent');
}
is_deeply([map { _path_id($_) } @abort_syncs],
    [_path_id(File::Spec->catdir($root, '.staging'))],
    'abort synchronizes removal from the staging directory');
is(_staged_file_count($root), 0, 'abort removes staged bytes');

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
ok(!$ok, 'unsafe hashes cannot enter filesystem paths');
like($@, qr/sha256 must be 64 lowercase hexadecimal characters/,
    'bad hash is reported');
$bad_hash->abort;

my $unsafe_generation_store =
    Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
        root       => tempdir(CLEANUP => 1),
        generation => sub { '../unsafe' },
    );
$unsafe_generation_store->deploy_schema;
my $unsafe_generation = $unsafe_generation_store->begin_upload;
$unsafe_generation->write('abc');
$ok = eval {
    $unsafe_generation->prepare(
        sha256 => 'd' x 64,
        size => 3,
        type => 'text/plain',
        uploaded => 1,
    );
    1;
};
ok(!$ok, 'unsafe generation values cannot enter filesystem paths');
like($@, qr/generation returned an unsafe filesystem path segment/,
    'unsafe generation value is reported');
$unsafe_generation->abort;

my $collision_root = File::Spec->catdir(tempdir(CLEANUP => 1), 'storage');
my $collision_store = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => $collision_root,
    generation => sub { 'same' },
);
$collision_store->deploy_schema;
my $collision_sha = 'c' x 64;
my $first = $collision_store->begin_upload;
$first->write('first');
my $collision_key = $first->prepare(
    sha256 => $collision_sha,
    size => 5,
    type => 'text/plain',
    uploaded => 1,
);
$first->commit;
my $second = $collision_store->begin_upload;
$second->write('other');
$ok = eval {
    $second->prepare(
        sha256 => $collision_sha,
        size => 5,
        type => 'text/plain',
        uploaded => 2,
    );
    1;
};
ok(!$ok, 'generation collisions do not overwrite existing bytes');
like($@, qr/already exists/, 'generation collision is reported');
$second->abort;
is(_read_file(_blob_path($collision_root, $collision_key)), 'first',
    'the original generation survives a collision');
is(_staged_file_count($collision_root), 0,
    'the losing generation leaves no staged file');

for my $unsafe ('../secret', '/absolute', 'aa/aa/not-a-key',
    "aa/aa/$sha256-generation/extra", "bb/aa/$sha256-generation-1") {
    $ok = eval { $store->get_blob($unsafe); 1 };
    ok(!$ok, "unsafe storage key is rejected: $unsafe");
    like($@, qr/invalid filesystem storage key/, 'unsafe key reports the cause');
}

ok($store->delete_blob($key), 'delete removes an existing file');
ok(!-e _blob_path($root, $key), 'deleted file is gone');
ok(!$store->delete_blob($key), 'delete reports a missing file');

my $bad_generation = eval {
    Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
        root       => tempdir(CLEANUP => 1),
        generation => 0,
    );
    1;
};
ok(!$bad_generation, 'an explicit false generation callback is rejected');
like($@, qr/generation must be a code reference/,
    'invalid generation callback is reported');

my ($file_fh, $file_root) = tempfile();
close $file_fh;
my $file_store = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root => $file_root,
);
$ok = eval { $file_store->deploy_schema; 1 };
ok(!$ok, 'a non-directory root is rejected');
like($@, qr/root.*directory/, 'non-directory root reports the cause');

done_testing;

sub _blob_path {
    my ($root, $key) = @_;
    return File::Spec->catfile($root, 'blobs', split m{/}, $key);
}

sub _read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $body = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return $body;
}

sub _staged_file_count {
    my ($root) = @_;
    my $dir = File::Spec->catdir($root, '.staging');
    opendir my $dh, $dir or die "Unable to open $dir: $!";
    my @files = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or die "Unable to close $dir: $!";
    return scalar @files;
}

sub _path_id {
    my ($path) = @_;
    $path = File::Spec->canonpath($path);
    $path =~ s{[\\/]\z}{};
    return $path;
}
