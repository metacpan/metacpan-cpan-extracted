package Net::Blossom::Server::Backend::S3;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(metadata_store blob_store base_url cleanup_error_handler);
use Net::Blossom::BlobDescriptor;
use Net::Blossom::_URL;
use Net::Blossom::Server::Backend::S3::BlobStore;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::BlobStore;
use Net::Blossom::Server::MetadataStore;

our $VERSION = '0.001001';

my @BLOB_STORE_ARGS = qw(
    bucket endpoint region access_key_id secret_access_key session_token
    path_style s3 timeout retry temp_dir prefix range_size
    multipart_threshold multipart_part_size generation client
);

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my %known = map { $_ => 1 } (
        qw(metadata_store blob_store base_url cleanup_error_handler),
        @BLOB_STORE_ARGS,
    );
    my @unknown = grep { !$known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "metadata_store is required" unless defined $args{metadata_store};
    croak "base_url is required" unless defined $args{base_url};
    croak "cleanup_error_handler must be a code reference"
        if defined $args{cleanup_error_handler}
        && ref($args{cleanup_error_handler}) ne 'CODE';

    Net::Blossom::Server::MetadataStore->assert_implements($args{metadata_store});
    my $base_url = _normalize_base_url($args{base_url});
    my $blob_store = delete $args{blob_store};
    my %blob_args = map {
        exists $args{$_} ? ($_ => delete $args{$_}) : ()
    } @BLOB_STORE_ARGS;
    croak "blob_store cannot be combined with S3 client arguments"
        if defined $blob_store && keys %blob_args;
    $blob_store ||= Net::Blossom::Server::Backend::S3::BlobStore->new(%blob_args);
    Net::Blossom::Server::BlobStore->assert_implements($blob_store);

    return {
        metadata_store       => $args{metadata_store},
        blob_store           => $blob_store,
        base_url             => $base_url,
        cleanup_error_handler => $args{cleanup_error_handler} || sub { warn $_[0] },
    };
}

sub deploy_schema {
    my ($self) = @_;
    $self->blob_store->deploy_schema;
    $self->metadata_store->deploy_schema;
    return 1;
}

sub begin_upload {
    my ($self, %context) = @_;
    my $blob_upload = $self->blob_store->begin_upload(%context);
    Net::Blossom::Server::BlobStore->assert_upload($blob_upload);

    return Net::Blossom::Server::Backend::S3::_Upload->new(
        storage     => $self,
        blob_upload => $blob_upload,
    );
}

sub get_blob {
    my ($self, $sha256) = @_;
    my $row = $self->metadata_store->find_blob($sha256);
    return unless defined $row;
    my $body = $self->blob_store->get_blob(
        $row->{storage_key},
        size => $row->{size},
    );
    return unless defined $body;

    return Net::Blossom::Server::BlobResult->new(
        descriptor => $self->_descriptor($row),
        body       => $body,
    );
}

sub get_blob_range {
    my ($self, $sha256, %opts) = @_;
    my $row = $self->metadata_store->find_blob($sha256);
    return unless defined $row;
    return $self->blob_store->get_blob_range(
        $row->{storage_key},
        %opts,
        size => $row->{size},
    );
}

sub head_blob {
    my ($self, $sha256) = @_;
    my $row = $self->metadata_store->find_blob($sha256);
    return unless defined $row;
    return $self->_descriptor($row);
}

sub delete_blob {
    my ($self, $sha256, %opts) = @_;
    my $metadata = $self->metadata_store;
    my $storage_key;

    my $deleted = $metadata->with_transaction(sub {
        $metadata->lock_blob($sha256);

        if (defined $opts{pubkey}) {
            return 0 unless $metadata->delete_owner($sha256, $opts{pubkey});
            if (!$metadata->owner_count($sha256)) {
                my $record = $metadata->find_blob($sha256);
                if (defined $record) {
                    $storage_key = $record->{storage_key};
                    $metadata->delete_blob($sha256);
                }
            }
            return 1;
        }

        my $record = $metadata->find_blob($sha256);
        return 0 unless defined $record;
        $storage_key = $record->{storage_key};
        $metadata->delete_owners($sha256);
        $metadata->delete_blob($sha256);
        return 1;
    });

    $self->_delete_object($storage_key) if defined $storage_key;
    return $deleted ? 1 : 0;
}

sub list_blobs {
    my ($self, $pubkey, %opts) = @_;
    my $rows = $self->metadata_store->list_blobs($pubkey, %opts);
    return [map { $self->_descriptor($_) } @$rows];
}

sub _commit_upload {
    my ($self, $upload, %metadata) = @_;
    my $store = $self->metadata_store;
    my $created;
    my $storage_key;

    my $ok = eval {
        $store->with_transaction(sub {
            $store->lock_blob($metadata{sha256});
            my $record = $store->find_blob($metadata{sha256});

            if (defined $record) {
                $created = 0;
                $storage_key = $record->{storage_key};
            }
            else {
                $storage_key = $upload->_prepare(%metadata);
                $created = $store->insert_blob(
                    %metadata,
                    storage_key => $storage_key,
                ) ? 1 : 0;
            }

            $store->upsert_owner(%metadata) if defined $metadata{pubkey};
            return 1;
        });
        1;
    };
    my $error = $@;

    if (!$ok) {
        eval { $upload->_cleanup(0) };
        die $error;
    }

    my $cleanup_ok = eval { $upload->_cleanup($created); 1 };
    $self->_report_cleanup_error($@, $storage_key) unless $cleanup_ok;

    return {
        descriptor => $self->_descriptor(\%metadata),
        created    => $created,
    };
}

sub _delete_object {
    my ($self, $storage_key) = @_;
    my $ok = eval { $self->blob_store->delete_blob($storage_key); 1 };
    $self->_report_cleanup_error($@, $storage_key) unless $ok;
    return;
}

sub _report_cleanup_error {
    my ($self, $error, $storage_key) = @_;
    return unless defined $error && length $error;
    my $ok = eval { $self->cleanup_error_handler->($error, $storage_key); 1 };
    warn $@ unless $ok;
    return;
}

sub _descriptor {
    my ($self, $row) = @_;
    return Net::Blossom::BlobDescriptor->new(
        url      => $self->base_url . '/' . $row->{sha256},
        sha256   => $row->{sha256},
        size     => 0 + $row->{size},
        type     => $row->{type},
        uploaded => 0 + $row->{uploaded},
    );
}

sub _normalize_base_url {
    my ($base_url) = @_;
    croak "base_url must be a scalar" if ref($base_url);
    croak "base_url is required" unless length $base_url;
    croak "base_url must be a valid HTTP base URL"
        unless Net::Blossom::_URL::http_base_url($base_url);
    $base_url =~ s{/+\z}{};
    return $base_url;
}

sub _constructor_args {
    return %{$_[0]} if @_ == 1 && ref($_[0]) eq 'HASH';
    croak "constructor arguments must be name/value pairs" if @_ % 2;
    return @_;
}

{
    package Net::Blossom::Server::Backend::S3::_Upload;

    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(storage blob_upload), {
        committed => 0,
        aborted   => 0,
    };

    sub BUILD {
        my ($self) = @_;
        $self->committed;
        $self->aborted;
        return;
    }

    sub write {
        my ($self, $chunk) = @_;
        croak "upload is already committed" if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        return $self->{blob_upload}->write($chunk);
    }

    sub commit {
        my ($self, %metadata) = @_;
        croak "upload is already committed" if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        my $result = $self->{storage}->_commit_upload($self, %metadata);
        $self->{committed} = 1;
        return $result;
    }

    sub abort {
        my ($self) = @_;
        return 1 if $self->{aborted} || $self->{committed};
        $self->{aborted} = 1;
        return $self->{blob_upload}->abort;
    }

    sub _prepare {
        my ($self, %metadata) = @_;
        return $self->{blob_upload}->prepare(%metadata);
    }

    sub _cleanup {
        my ($self, $created) = @_;
        return $created
            ? $self->{blob_upload}->commit
            : $self->{blob_upload}->abort;
    }

    sub DEMOLISH {
        my ($self) = @_;
        return if $self->{committed} || $self->{aborted};
        eval { $self->abort };
        return;
    }
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Backend::S3 - S3-compatible storage for Blossom servers

=head1 SYNOPSIS

    use DBI;
    use Net::Blossom::Server;
    use Net::Blossom::Server::Backend::S3;
    use Net::Blossom::Server::Backend::SQLite::MetadataStore;

    my $sqlite_dbh = DBI->connect('dbi:SQLite:dbname=blossom.sqlite', '', '', {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
    });
    my $metadata = Net::Blossom::Server::Backend::SQLite::MetadataStore->new(
        dbh => $sqlite_dbh,
    );
    my $storage = Net::Blossom::Server::Backend::S3->new(
        metadata_store => $metadata,
        base_url       => 'https://cdn.example.com',
        bucket         => 'blossom',
        endpoint       => 'https://s3.example.com',
        region         => 'us-east-1',
        access_key_id  => $ENV{AWS_ACCESS_KEY_ID},
        secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
    );
    $storage->deploy_schema;

    my $server = Net::Blossom::Server->new(storage => $storage);

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::Storage> with S3-compatible
object storage. It works with Amazon S3 and independent implementations such
as Ceph and Garage.

Descriptor and owner metadata are supplied separately through any
L<Net::Blossom::Server::MetadataStore> implementation. The S3 backend has no
runtime dependency on a particular database backend.

The default blob store stages uploads in a temporary file. Files below
C<multipart_threshold> use one PUT unless they exceed S3's single-PUT limit.
Other files use multipart upload. Downloads use bounded range requests and may
return short reads, so blob bodies are not held in memory in full.

=head1 CONSTRUCTOR

=head2 new

    my $storage = Net::Blossom::Server::Backend::S3->new(%args);

Requires C<metadata_store> and C<base_url>. The default S3 client also requires
C<bucket>. Credentials may be passed as C<access_key_id>,
C<secret_access_key>, and C<session_token>, or read from
C<AWS_ACCESS_KEY_ID>, C<AWS_SECRET_ACCESS_KEY>, and C<AWS_SESSION_TOKEN>.

C<region> defaults to C<us-east-1>. C<endpoint> selects a compatible service;
when omitted, Amazon S3 is used. Custom endpoints use path-style bucket URLs by
default. Set C<path_style> explicitly when the service requires another style.

C<timeout> defaults to 30 seconds and C<retry> is enabled by default. An
existing C<Net::Amazon::S3> object may be passed as C<s3> for advanced client
configuration. It cannot be combined with other connection arguments.

C<temp_dir> selects the upload staging directory. C<prefix> defaults to
C<blossom>. C<multipart_threshold>, C<multipart_part_size>, and C<range_size>
default to 100 MiB, 16 MiB, and 8 MiB. Multipart parts are enlarged when needed
to remain within S3's 10,000-part limit. The configured part size must be
between 5 MiB and 5 GiB; the final part may be smaller. Objects above 5 GB
always use multipart upload. The client follows
L<Amazon S3's multipart limits|https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html>:
10,000 5-GiB parts, or about 48.8 TiB. Compatible services may impose lower
limits.

C<generation> may supply an object-key callback for testing. Each result must
be unique for a given hash. The default uses 128 random bits.

C<client> may supply an object client that implements C<upload_file>, C<head>,
C<get_range>, and C<delete>. It cannot be combined with S3 connection options.

C<cleanup_error_handler> may be a code reference. It receives a post-commit
cleanup error and the storage key, when available. The default warns.

C<blob_store> may be supplied for custom composition or tests. It cannot be
combined with any option used to construct the default blob store.

=head1 CONSISTENCY

The default blob store uses a new generation-specific object key for each newly
stored object. Object bytes are durable before metadata commits, so the metadata
transaction remains open during a new object upload. Database-backed metadata
stores also keep their connection occupied. Deletion commits the metadata change
before deleting that exact object key, so delayed cleanup cannot erase a later
upload of the same hash.

S3 and the metadata store cannot commit atomically. A metadata failure or failed
object deletion can therefore leave an unreachable object.
The object remains invisible because metadata is authoritative. Operators
should monitor cleanup errors and may remove unreachable objects separately.

The bucket must already exist and have the required access policy. This module
does not create buckets or configure encryption, lifecycle, or replication.
Only an HTTP 404 response is treated as a missing object. Other service errors
propagate. On Amazon S3, grant C<s3:ListBucket> so a missing object returns 404
rather than an indistinguishable 403 permission error.

=head1 LIVE TESTING

C<t/20-LiveS3.t> runs the same storage contract against any S3-compatible
endpoint. Set C<NET_BLOSSOM_S3_ENDPOINT>, C<NET_BLOSSOM_S3_BUCKET>,
C<NET_BLOSSOM_S3_REGION>, C<NET_BLOSSOM_S3_ACCESS_KEY_ID>, and
C<NET_BLOSSOM_S3_SECRET_ACCESS_KEY>. Set C<NET_BLOSSOM_POSTGRES_DSN>,
C<NET_BLOSSOM_POSTGRES_USER>, and C<NET_BLOSSOM_POSTGRES_PASSWORD> to also run
the contract with Postgres metadata.

C<t/21-LiveMultiNode.t> repeats cross-node operations through two independent
backend instances. Set C<NET_BLOSSOM_S3_PEER_ENDPOINT> to route the second
instance through another S3 gateway; otherwise it uses the primary endpoint.

When live S3 testing is required, CI runs both tests against three-node Garage
and Ceph clusters.

=head1 METHODS

=head2 BUILDARGS

Normalizes and validates constructor arguments for C<Class::Tiny>.

=head2 metadata_store

Returns the configured metadata store.

=head2 blob_store

Returns the configured byte store.

=head2 base_url

Returns the normalized public blob URL prefix.

=head2 cleanup_error_handler

Returns the post-commit cleanup error callback.

=head2 deploy_schema

Deploys both store schemas. The default S3 byte store has no schema.

=head2 begin_upload

Starts a blob upload.

=head2 get_blob

Returns a L<Net::Blossom::Server::BlobResult>, or C<undef> when metadata or
object bytes are absent. The default byte store returns a ranged-read stream
for nonempty objects.

=head2 get_blob_range

Returns one requested byte range as a bounded ranged-read stream, or C<undef>
when metadata or object bytes are absent.

=head2 head_blob

Returns the blob descriptor from metadata, or C<undef> when absent.

=head2 delete_blob

With C<pubkey>, removes that owner and deletes the object after its final owner
is removed. Without C<pubkey>, deletes the whole blob.

=head2 list_blobs

Returns an array reference of L<Net::Blossom::BlobDescriptor> objects for one
pubkey. C<cursor> and C<limit> follow L<Net::Blossom::Server::Storage>.

=cut
