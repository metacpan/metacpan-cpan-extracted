use strictures 2;

use DBI;
use File::Temp qw(tempdir);
use Test::More;

use Net::Blossom::Server::Backend::S3;
use Net::Blossom::Server::Backend::S3::BlobStore;
use Net::Blossom::Server::Backend::SQLite::MetadataStore;
use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

my $endpoint = $ENV{NET_BLOSSOM_S3_ENDPOINT}
    or plan skip_all => 'NET_BLOSSOM_S3_ENDPOINT is not set';
my %s3 = (
    endpoint          => $endpoint,
    bucket            => $ENV{NET_BLOSSOM_S3_BUCKET} || 'blossom-test',
    region            => $ENV{NET_BLOSSOM_S3_REGION} || 'us-east-1',
    access_key_id     => $ENV{NET_BLOSSOM_S3_ACCESS_KEY_ID},
    secret_access_key => $ENV{NET_BLOSSOM_S3_SECRET_ACCESS_KEY},
    (defined $ENV{NET_BLOSSOM_S3_SESSION_TOKEN}
        ? (session_token => $ENV{NET_BLOSSOM_S3_SESSION_TOKEN})
        : ()),
);

my $probe = Net::Blossom::Server::Backend::S3::BlobStore->new(%s3);
is($probe->get_blob('net-blossom-definitely-missing'), undef,
    'a missing object in the live service returns undef');
my $empty_upload = $probe->begin_upload;
my $empty_key = $empty_upload->prepare(
    sha256   => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    size     => 0,
    type     => 'application/octet-stream',
    uploaded => 1,
);
$empty_upload->commit;
is($probe->get_blob($empty_key), '', 'single PUT stores an empty object');
ok($probe->delete_blob($empty_key), 'empty live object is cleaned up');

my $sqlite = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
    AutoCommit => 1,
    RaiseError => 1,
    PrintError => 0,
});
_run_contract(
    name => 'live S3-compatible storage with SQLite metadata',
    dbh  => $sqlite,
    reset => sub {
        $sqlite->do('DROP TABLE IF EXISTS blossom_owners');
        $sqlite->do('DROP TABLE IF EXISTS blossom_blobs');
    },
    metadata => sub {
        return Net::Blossom::Server::Backend::SQLite::MetadataStore->new(
            dbh => $sqlite,
        );
    },
    s3 => \%s3,
);

SKIP: {
    my $dsn = $ENV{NET_BLOSSOM_POSTGRES_DSN};
    skip 'NET_BLOSSOM_POSTGRES_DSN is not set', 1 unless defined $dsn;
    eval 'use DBD::Pg (); use Net::Blossom::Server::Backend::Postgres::MetadataStore (); 1'
        or die $@;
    my $postgres = DBI->connect(
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
    _run_contract(
        name => 'live S3-compatible storage with Postgres metadata',
        dbh  => $postgres,
        reset => sub {
            $postgres->do('DROP TABLE IF EXISTS blossom_owners');
            $postgres->do('DROP TABLE IF EXISTS blossom_blobs');
        },
        metadata => sub {
            return Net::Blossom::Server::Backend::Postgres::MetadataStore->new(
                dbh => $postgres,
            );
        },
        s3 => \%s3,
    );
}

done_testing;

sub _run_contract {
    my %args = @_;
    my $factory_number = 0;
    my ($previous_store, $previous_dbh);

    run_storage_contract_tests(
        name    => $args{name},
        factory => sub {
            _remove_objects($previous_store, $previous_dbh);
            $args{reset}->();
            my $metadata = $args{metadata}->();
            my $blob_store = Net::Blossom::Server::Backend::S3::BlobStore->new(
                %{$args{s3}},
                temp_dir            => tempdir(CLEANUP => 1),
                prefix              => join('-', 'net-blossom-test', $^T, $$,
                    ++$factory_number),
                multipart_threshold => 1,
                multipart_part_size => 5 * 1024 * 1024,
                range_size          => 7,
            );
            my $storage = Net::Blossom::Server::Backend::S3->new(
                metadata_store => $metadata,
                blob_store     => $blob_store,
                base_url       => 'https://cdn.example.test',
            );
            $storage->deploy_schema;
            $previous_store = $blob_store;
            $previous_dbh = $args{dbh};
            return $storage;
        },
    );

    _remove_objects($previous_store, $previous_dbh);
    $args{reset}->();
    return;
}

sub _remove_objects {
    my ($store, $dbh) = @_;
    return unless defined $store && defined $dbh;
    my $keys = eval { $dbh->selectcol_arrayref('SELECT storage_key FROM blossom_blobs') };
    return unless defined $keys;
    $store->delete_blob($_) for @$keys;
    return;
}
