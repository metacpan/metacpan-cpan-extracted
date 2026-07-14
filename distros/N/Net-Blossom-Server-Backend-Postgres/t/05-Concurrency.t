use strictures 2;

use Digest::SHA qw(sha256_hex);
use Test::More;

use Net::Blossom::Server::Backend::Postgres;

my $BARRIER = 74839201;
my $FIRST_PUBKEY = 'a' x 64;
my $SECOND_PUBKEY = 'b' x 64;
my $BODY = "concurrent upload and delete\n";
my $SHA256 = sha256_hex($BODY);

my $admin = _test_dbh('blossom-race-admin');
_reset_schema($admin);

my $storage = _storage($admin);
$storage->deploy_schema;
_upload($storage, $BODY, $FIRST_PUBKEY, 100);

$admin->do(q{
    CREATE OR REPLACE FUNCTION blossom_pause_blob_delete()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        PERFORM pg_advisory_lock(74839201);
        PERFORM pg_advisory_unlock(74839201);
        RETURN NULL;
    END
    $$
});
$admin->do(q{
    CREATE TRIGGER blossom_pause_blob_delete
    BEFORE DELETE ON blossom_blobs
    FOR EACH STATEMENT
    EXECUTE FUNCTION blossom_pause_blob_delete()
});
$admin->selectrow_array('SELECT pg_advisory_lock(?)', undef, $BARRIER);

my $delete_pid = fork();
die "fork failed: $!\n" unless defined $delete_pid;

if (!$delete_pid) {
    $admin->{InactiveDestroy} = 1;
    my $ok = eval {
        my $dbh = _test_dbh('blossom-race-delete');
        _storage($dbh)->delete_blob($SHA256, pubkey => $FIRST_PUBKEY)
            or die "owner delete unexpectedly returned false\n";
        1;
    };
    warn $@ unless $ok;
    exit($ok ? 0 : 1);
}

_wait_until_advisory_lock($admin, 'blossom-race-delete');

my $upload_pid = fork();
die "fork failed: $!\n" unless defined $upload_pid;

if (!$upload_pid) {
    $admin->{InactiveDestroy} = 1;
    my $ok = eval {
        my $dbh = _test_dbh('blossom-race-upload');
        _upload(_storage($dbh), $BODY, $SECOND_PUBKEY, 200);
        1;
    };
    warn $@ unless $ok;
    exit($ok ? 0 : 1);
}

my $race_reached = _wait_until_upload_is_committed_or_locked($admin);
$admin->selectrow_array('SELECT pg_advisory_unlock(?)', undef, $BARRIER);

waitpid($delete_pid, 0);
my $delete_status = $?;
waitpid($upload_pid, 0);
my $upload_status = $?;

ok($race_reached, 'upload reached the concurrent mutation before delete resumed');
is($delete_status, 0, 'delete process succeeded');
is($upload_status, 0, 'upload process succeeded');

my ($blob_count) = $admin->selectrow_array(
    'SELECT COUNT(*) FROM blossom_blobs WHERE sha256 = ?',
    undef,
    $SHA256,
);
my ($owner_count) = $admin->selectrow_array(
    'SELECT COUNT(*) FROM blossom_owners WHERE pubkey = ? AND sha256 = ?',
    undef,
    $SECOND_PUBKEY,
    $SHA256,
);

is($blob_count, 1, 'successful concurrent upload keeps the blob');
is($owner_count, 1, 'successful concurrent upload keeps its owner');

$admin->do('DROP TRIGGER blossom_pause_blob_delete ON blossom_blobs');
$admin->do('DROP FUNCTION blossom_pause_blob_delete()');

done_testing;

sub _test_dbh {
    my ($application_name) = @_;
    my $dsn = $ENV{NET_BLOSSOM_POSTGRES_DSN}
        or plan skip_all => 'NET_BLOSSOM_POSTGRES_DSN is not set';

    eval 'use DBI (); use DBD::Pg (); 1'
        or die $@;

    my $dbh = DBI->connect(
        $dsn,
        $ENV{NET_BLOSSOM_POSTGRES_USER},
        $ENV{NET_BLOSSOM_POSTGRES_PASSWORD},
        {
            AutoCommit     => 1,
            RaiseError     => 1,
            PrintError     => 0,
            pg_enable_utf8 => 0,
        },
    );
    $dbh->do('SET application_name = ' . $dbh->quote($application_name));
    $dbh->do(q{SET statement_timeout = '15s'});
    return $dbh;
}

sub _storage {
    my ($dbh) = @_;
    return Net::Blossom::Server::Backend::Postgres->new(
        dbh      => $dbh,
        base_url => 'https://cdn.example.test',
    );
}

sub _upload {
    my ($storage, $body, $pubkey, $uploaded) = @_;
    my $writer = $storage->begin_upload;
    $writer->write($body);
    return $writer->commit(
        sha256   => sha256_hex($body),
        size     => length($body),
        type     => 'application/octet-stream',
        uploaded => $uploaded,
        pubkey   => $pubkey,
    );
}

sub _wait_until_advisory_lock {
    my ($dbh, $application_name) = @_;

    for (1 .. 200) {
        my ($waiting) = $dbh->selectrow_array(q{
            SELECT 1
              FROM pg_stat_activity
             WHERE application_name = ?
               AND wait_event_type = 'Lock'
               AND wait_event = 'advisory'
        }, undef, $application_name);
        return 1 if $waiting;
        select undef, undef, undef, 0.025;
    }

    die "$application_name did not reach the advisory barrier\n";
}

sub _wait_until_upload_is_committed_or_locked {
    my ($dbh) = @_;

    for (1 .. 200) {
        my ($owner_exists) = $dbh->selectrow_array(
            'SELECT 1 FROM blossom_owners WHERE pubkey = ? AND sha256 = ?',
            undef,
            $SECOND_PUBKEY,
            $SHA256,
        );
        return 1 if $owner_exists;

        my ($waiting) = $dbh->selectrow_array(q{
            SELECT 1
              FROM pg_stat_activity
             WHERE application_name = 'blossom-race-upload'
               AND wait_event_type = 'Lock'
               AND wait_event = 'advisory'
        });
        return 1 if $waiting;
        select undef, undef, undef, 0.025;
    }

    return 0;
}

sub _reset_schema {
    my ($dbh) = @_;
    $dbh->do('DROP TABLE IF EXISTS blossom_owners');
    $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
    $dbh->do('DROP TABLE IF EXISTS blossom_blob_data');
    $dbh->do('DROP FUNCTION IF EXISTS blossom_pause_blob_delete()');
    $dbh->do('SELECT lo_unlink(oid) FROM pg_largeobject_metadata');
    return;
}
