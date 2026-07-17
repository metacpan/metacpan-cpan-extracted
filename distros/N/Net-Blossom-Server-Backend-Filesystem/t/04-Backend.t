use strictures 2;

use DBI;
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib";
use Net::Blossom::Server;
use Net::Blossom::Server::Backend::Filesystem;
use Net::Blossom::Server::Backend::Filesystem::BlobStore;
use Net::Blossom::Server::Backend::SQLite::MetadataStore;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
});
my $metadata = Net::Blossom::Server::Backend::SQLite::MetadataStore->new(dbh => $dbh);
my $root = tempdir(CLEANUP => 1);
my $generation = 0;
my $inner = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => $root,
    generation => sub { 'g' . ++$generation },
);
my $controlled = Local::ControlledBlobStore->new(inner => $inner);
my @cleanup_errors;
my $storage = _new_storage(
    $metadata,
    blob_store => $controlled,
    cleanup_error_handler => sub { push @cleanup_errors, $_[0] },
);
$storage->deploy_schema;

my $first_body = 'first generation';
my $sha256 = sha256_hex($first_body);
my $first = _upload($storage, $first_body, 1);
ok($first->created, 'first upload creates bytes');
my $first_key = $metadata->find_blob($sha256)->{storage_key};
my $range = $storage->get_blob_range($sha256, offset => 6, length => 4);
my $range_body = '';
is($range->read($range_body, 20), 4,
    'backend range stream is bounded by requested length');
is($range_body, 'gene', 'backend range retrieval returns requested bytes');
my $duplicate = _upload($storage, $first_body, 2);
ok(!$duplicate->created, 'duplicate upload reuses existing bytes');
is($generation, 1, 'duplicate upload does not publish another file');

my $reuploaded;
$controlled->on_delete(sub {
    $controlled->on_delete(undef);
    is($metadata->find_blob($sha256), undef,
        'metadata is removed before file deletion');
    $reuploaded = _upload($storage, $first_body, 2);
});

ok($storage->delete_blob($sha256),
    'delete succeeds while a re-upload races file cleanup');
ok($reuploaded->created, 'racing re-upload creates a new generation');
my $second_key = $metadata->find_blob($sha256)->{storage_key};
isnt($second_key, $first_key, 're-upload uses a different file key');
is($inner->get_blob($first_key), undef,
    'delayed cleanup removes only the old generation');
ok(defined $inner->get_blob($second_key),
    'new generation survives delayed cleanup');

$controlled->fail_delete(1);
ok($storage->delete_blob($sha256),
    'metadata deletion remains successful when file cleanup fails');
is($metadata->find_blob($sha256), undef,
    'failed cleanup does not restore deleted metadata');
is(scalar @cleanup_errors, 1, 'post-commit cleanup failure is reported');
like($cleanup_errors[0], qr/injected delete failure/,
    'cleanup callback receives the failure');
ok(defined $inner->get_blob($second_key),
    'failed cleanup leaves an unreachable file');
$controlled->fail_delete(0);

_reset_metadata($dbh);
$metadata->deploy_schema;
my $handler_inner = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => tempdir(CLEANUP => 1),
    generation => sub { 'handler' },
);
my $handler_controlled = Local::ControlledBlobStore->new(inner => $handler_inner);
my $handler_storage = _new_storage(
    $metadata,
    blob_store => $handler_controlled,
    cleanup_error_handler => sub { die "injected handler failure\n" },
);
$handler_storage->deploy_schema;
my $handler_blob = _upload($handler_storage, 'handler failure body', 3)->descriptor;
$handler_controlled->fail_delete(1);
my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    ok($handler_storage->delete_blob($handler_blob->sha256),
        'cleanup handler failure does not undo metadata deletion');
}
like(join('', @warnings), qr/injected handler failure/,
    'cleanup handler failure is warned');

_reset_metadata($dbh);
$metadata->deploy_schema;
my $rollback = Local::FailingMetadata->new(
    inner => $metadata,
    mode  => 'rollback',
);
my $rollback_inner = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => tempdir(CLEANUP => 1),
    generation => sub { 'rollback' },
);
my $rollback_storage = _new_storage($rollback, blob_store => $rollback_inner);
$rollback_storage->deploy_schema;
my $rollback_body = 'rolled back metadata';
my $rollback_sha = sha256_hex($rollback_body);
my $ok = eval { _upload($rollback_storage, $rollback_body, 3); 1 };
ok(!$ok, 'metadata rollback makes commit fail');
like($@, qr/injected transaction rollback/, 'rollback error is preserved');
is($metadata->find_blob($rollback_sha), undef,
    'rolled-back metadata is not visible');
ok(defined $rollback_inner->get_blob(_key($rollback_sha, 'rollback')),
    'durable file is retained after metadata rollback');

_reset_metadata($dbh);
$metadata->deploy_schema;
my $ambiguous = Local::FailingMetadata->new(
    inner => $metadata,
    mode  => 'commit_then_die',
);
my $ambiguous_inner = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => tempdir(CLEANUP => 1),
    generation => sub { 'ambiguous' },
);
my $ambiguous_storage = _new_storage($ambiguous, blob_store => $ambiguous_inner);
$ambiguous_storage->deploy_schema;
my $ambiguous_body = 'committed before disconnect';
my $ambiguous_sha = sha256_hex($ambiguous_body);
$ok = eval { _upload($ambiguous_storage, $ambiguous_body, 4); 1 };
ok(!$ok, 'ambiguous transaction outcome reaches the caller');
like($@, qr/injected disconnect after commit/,
    'ambiguous commit error is preserved');
ok(defined $metadata->find_blob($ambiguous_sha),
    'committed metadata remains visible');
ok(defined $ambiguous_inner->get_blob(_key($ambiguous_sha, 'ambiguous')),
    'committed file is retained after disconnect');

_reset_metadata($dbh);
$metadata->deploy_schema;
my @upload_cleanup_errors;
my $cleanup_storage = _new_storage(
    $metadata,
    blob_store => Local::CleanupFailingBlobStore->new,
    cleanup_error_handler => sub { push @upload_cleanup_errors, [@_] },
);
my $cleanup_body = 'post-commit cleanup failure';
my $cleanup_result = _upload($cleanup_storage, $cleanup_body, 5);
ok($cleanup_result->created,
    'post-commit cleanup failure does not fail the upload');
is(scalar @upload_cleanup_errors, 1,
    'post-commit upload cleanup failure is reported');
like($upload_cleanup_errors[0][0], qr/injected upload cleanup failure/,
    'upload cleanup callback receives the failure');
is($upload_cleanup_errors[0][1], 'cleanup-' . sha256_hex($cleanup_body),
    'upload cleanup callback receives the committed storage key');
my $cleanup_duplicate = _upload($cleanup_storage, $cleanup_body, 6);
ok(!$cleanup_duplicate->created,
    'duplicate remains successful when abort cleanup fails');
is(scalar @upload_cleanup_errors, 2,
    'duplicate upload cleanup failure is reported');

done_testing;

sub _new_storage {
    my ($metadata_store, %args) = @_;
    return Net::Blossom::Server::Backend::Filesystem->new(
        metadata_store => $metadata_store,
        base_url       => 'https://cdn.example.test',
        %args,
    );
}

sub _upload {
    my ($storage, $body, $uploaded) = @_;
    my $server = Net::Blossom::Server->new(
        storage => $storage,
        clock   => sub { $uploaded },
    );
    return $server->receive_blob(
        $body,
        type           => 'text/plain',
        content_length => length($body),
    );
}

sub _key {
    my ($sha256, $generation) = @_;
    return join '/', substr($sha256, 0, 2), substr($sha256, 2, 2),
        "$sha256-$generation";
}

sub _reset_metadata {
    my ($dbh) = @_;
    $dbh->do('DROP TABLE IF EXISTS blossom_owners');
    $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
    return;
}

{
    package Local::ControlledBlobStore;

    use Class::Tiny qw(inner on_delete fail_delete);

    sub deploy_schema { shift->inner->deploy_schema(@_) }
    sub begin_upload { shift->inner->begin_upload(@_) }
    sub get_blob { shift->inner->get_blob(@_) }
    sub get_blob_range { shift->inner->get_blob_range(@_) }

    sub delete_blob {
        my ($self, @args) = @_;
        if (my $callback = $self->on_delete) {
            $self->on_delete(undef);
            $callback->();
        }
        die "injected delete failure\n" if $self->fail_delete;
        return $self->inner->delete_blob(@args);
    }
}

{
    package Local::FailingMetadata;

    use Class::Tiny qw(inner mode);

    sub deploy_schema { $_[0]->inner->deploy_schema }

    sub with_transaction {
        my ($self, $code) = @_;
        if ($self->mode eq 'rollback') {
            return $self->inner->with_transaction(sub {
                $code->();
                die "injected transaction rollback\n";
            });
        }

        my $result = $self->inner->with_transaction($code);
        die "injected disconnect after commit\n";
    }

    sub lock_blob { shift->inner->lock_blob(@_) }
    sub find_blob { shift->inner->find_blob(@_) }
    sub insert_blob { shift->inner->insert_blob(@_) }
    sub upsert_owner { shift->inner->upsert_owner(@_) }
    sub delete_owner { shift->inner->delete_owner(@_) }
    sub delete_owners { shift->inner->delete_owners(@_) }
    sub owner_count { shift->inner->owner_count(@_) }
    sub delete_blob { shift->inner->delete_blob(@_) }
    sub list_blobs { shift->inner->list_blobs(@_) }
}

{
    package Local::CleanupFailingBlobStore;

    use Class::Tiny;

    sub deploy_schema { 1 }
    sub begin_upload { Local::CleanupFailingUpload->new }
    sub get_blob { undef }
    sub delete_blob { 0 }
}

{
    package Local::CleanupFailingUpload;

    use Class::Tiny;

    sub write { return length $_[1] }

    sub prepare {
        my ($self, %metadata) = @_;
        return 'cleanup-' . $metadata{sha256};
    }

    sub commit { die "injected upload cleanup failure\n" }
    sub abort { die "injected upload cleanup failure\n" }
}
