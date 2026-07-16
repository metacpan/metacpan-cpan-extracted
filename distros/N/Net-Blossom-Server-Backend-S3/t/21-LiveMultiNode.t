use strictures 2;

use DBI;
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(blessed);
use Test::More;

use Net::Blossom::Server;
use Net::Blossom::Server::Backend::S3;
use Net::Blossom::Server::Backend::SQLite::MetadataStore;

my $endpoint = $ENV{NET_BLOSSOM_S3_ENDPOINT}
    or plan skip_all => 'NET_BLOSSOM_S3_ENDPOINT is not set';
my %s3_common = (
    bucket            => $ENV{NET_BLOSSOM_S3_BUCKET} || 'blossom-test',
    region            => $ENV{NET_BLOSSOM_S3_REGION} || 'us-east-1',
    access_key_id     => $ENV{NET_BLOSSOM_S3_ACCESS_KEY_ID},
    secret_access_key => $ENV{NET_BLOSSOM_S3_SECRET_ACCESS_KEY},
    (defined $ENV{NET_BLOSSOM_S3_SESSION_TOKEN}
        ? (session_token => $ENV{NET_BLOSSOM_S3_SESSION_TOKEN})
        : ()),
);
my @s3 = (
    { %s3_common, endpoint => $endpoint },
    {
        %s3_common,
        endpoint => $ENV{NET_BLOSSOM_S3_PEER_ENDPOINT} || $endpoint,
    },
);

my $sqlite_dir = tempdir(CLEANUP => 1);
my $sqlite_file = File::Spec->catfile($sqlite_dir, 'metadata.sqlite');
my @sqlite = map { _sqlite_dbh($sqlite_file) } 1 .. 2;
_run_cross_node_test(
    name => 'independent S3 backends with shared SQLite metadata',
    dbhs => \@sqlite,
    metadata => sub {
        return Net::Blossom::Server::Backend::SQLite::MetadataStore->new(
            dbh => shift,
        );
    },
    s3 => \@s3,
);

SKIP: {
    my $dsn = $ENV{NET_BLOSSOM_POSTGRES_DSN};
    skip 'NET_BLOSSOM_POSTGRES_DSN is not set', 1 unless defined $dsn;
    eval 'use DBD::Pg (); use Net::Blossom::Server::Backend::Postgres::MetadataStore (); 1'
        or die $@;
    my @postgres = map { _postgres_dbh($dsn) } 1 .. 2;
    _run_cross_node_test(
        name => 'independent S3 backends with shared Postgres metadata',
        dbhs => \@postgres,
        metadata => sub {
            return Net::Blossom::Server::Backend::Postgres::MetadataStore->new(
                dbh => shift,
            );
        },
        s3 => \@s3,
    );
}

done_testing;

sub _run_cross_node_test {
    my %args = @_;

    subtest $args{name} => sub {
        _reset_metadata($args{dbhs}[0]);
        my $prefix = join '-', 'net-blossom-multinode', $^T, $$,
            $args{name} =~ /Postgres/ ? 'postgres' : 'sqlite';
        my @nodes = map {
            my $metadata = $args{metadata}->($args{dbhs}[$_]);
            Net::Blossom::Server::Backend::S3->new(
                metadata_store => $metadata,
                base_url       => 'https://cdn.example.test',
                %{$args{s3}[$_]},
                prefix    => $prefix,
                temp_dir  => tempdir(CLEANUP => 1),
                range_size => 7,
            );
        } 0 .. 1;
        isnt($nodes[0], $nodes[1], 'nodes use independent backend objects');
        isnt($nodes[0]->metadata_store, $nodes[1]->metadata_store,
            'nodes use independent metadata-store objects');
        isnt($nodes[0]->blob_store, $nodes[1]->blob_store,
            'nodes use independent S3 blob-store objects');
        $_->deploy_schema for @nodes;

        my $first_pubkey = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
        my $second_pubkey = '266815e0c9210dfa324c6cba3573b14bee49da4209a9456f9484e5106cd408a5';
        my $body = "cross-node live blob\n";
        my $sha256 = sha256_hex($body);

        my $first = _upload($nodes[0], $body, $first_pubkey, 1725105921);
        ok($first->created, 'node one creates the object');
        is(_read_body($nodes[1]->get_blob($sha256)->body), $body,
            'node two reads bytes uploaded through node one');
        is($nodes[1]->head_blob($sha256)->sha256, $sha256,
            'node two reads metadata uploaded through node one');
        is_deeply(
            [map { $_->sha256 } @{$nodes[1]->list_blobs($first_pubkey)}],
            [$sha256],
            'node two lists ownership created through node one',
        );

        my $duplicate = _upload($nodes[1], $body, $second_pubkey, 1725105922);
        ok(!$duplicate->created, 'node two deduplicates the shared object');
        ok($nodes[0]->delete_blob($sha256, pubkey => $first_pubkey),
            'node one removes its ownership');
        is(_read_body($nodes[1]->get_blob($sha256)->body), $body,
            'node two still reads an object owned by another user');
        ok($nodes[1]->delete_blob($sha256, pubkey => $second_pubkey),
            'node two removes the final ownership');
        is($nodes[0]->get_blob($sha256), undef,
            'node one observes deletion performed through node two');

        _reset_metadata($args{dbhs}[0]);
    };

    return;
}

sub _upload {
    my ($storage, $body, $pubkey, $uploaded) = @_;
    my $server = Net::Blossom::Server->new(
        storage => $storage,
        clock   => sub { $uploaded },
    );
    return $server->receive_blob(
        $body,
        type           => 'text/plain',
        content_length => length($body),
        pubkey         => $pubkey,
    );
}

sub _read_body {
    my ($body) = @_;
    return $body unless ref($body);
    die "unsupported body type" unless blessed($body) && $body->can('read');

    my $content = '';
    while (1) {
        my $chunk = '';
        my $read = $body->read($chunk, 8192);
        die "body stream read failed" unless defined $read;
        last unless $read;
        $content .= $chunk;
    }
    return $content;
}

sub _sqlite_dbh {
    my ($file) = @_;
    return DBI->connect("dbi:SQLite:dbname=$file", '', '', {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
    });
}

sub _postgres_dbh {
    my ($dsn) = @_;
    return DBI->connect(
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
}

sub _reset_metadata {
    my ($dbh) = @_;
    $dbh->do('DROP TABLE IF EXISTS blossom_owners');
    $dbh->do('DROP TABLE IF EXISTS blossom_blobs');
    return;
}
