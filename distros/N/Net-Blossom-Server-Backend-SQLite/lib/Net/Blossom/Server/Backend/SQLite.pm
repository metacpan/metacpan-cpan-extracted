package Net::Blossom::Server::Backend::SQLite;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(dbh base_url metadata_store blob_store);
use DBI ();
use Net::Blossom::BlobDescriptor;
use Net::Blossom::_URL;
use Net::Blossom::Server::Backend::SQLite::BlobStore;
use Net::Blossom::Server::Backend::SQLite::MetadataStore;
use Net::Blossom::Server::BlobStore;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::MetadataStore;
use Scalar::Util qw(blessed);

our $VERSION = '0.001004';

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my %known = map { $_ => 1 } qw(database dbh base_url);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "database and dbh are mutually exclusive"
        if defined $args{database} && defined $args{dbh};
    croak "database or dbh is required"
        unless defined $args{database} || defined $args{dbh};
    croak "base_url is required"
        unless defined $args{base_url};

    my $base_url = _normalize_base_url($args{base_url});
    my $dbh = defined $args{dbh} ? _validate_dbh($args{dbh}) : _connect($args{database});
    $dbh->do('PRAGMA foreign_keys = ON');

    my $metadata_store = Net::Blossom::Server::Backend::SQLite::MetadataStore->new(dbh => $dbh);
    my $blob_store = Net::Blossom::Server::Backend::SQLite::BlobStore->new(dbh => $dbh);
    Net::Blossom::Server::MetadataStore->assert_implements($metadata_store);
    Net::Blossom::Server::BlobStore->assert_implements($blob_store);

    return {
        dbh            => $dbh,
        base_url       => $base_url,
        metadata_store => $metadata_store,
        blob_store     => $blob_store,
    };
}

sub deploy_schema {
    my ($self) = @_;
    $self->_migrate_legacy_schema;
    $self->blob_store->deploy_schema;
    $self->metadata_store->deploy_schema;
    return 1;
}

sub begin_upload {
    my ($self, %context) = @_;
    my $blob_upload = $self->blob_store->begin_upload(%context);
    Net::Blossom::Server::BlobStore->assert_upload($blob_upload);

    return Net::Blossom::Server::Backend::SQLite::_Upload->new(
        storage     => $self,
        blob_upload => $blob_upload,
    );
}

sub get_blob {
    my ($self, $sha256) = @_;
    my $row = $self->metadata_store->find_blob($sha256);
    return unless defined $row;
    my $body = $self->blob_store->get_blob($row->{storage_key});
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

    return $metadata->with_transaction(sub {
        $metadata->lock_blob($sha256);
        if (defined $opts{pubkey}) {
            return 0 unless $metadata->delete_owner($sha256, $opts{pubkey});
            $self->_delete_blob_if_unowned($sha256);
            return 1;
        }

        my $record = $metadata->find_blob($sha256);
        return 0 unless defined $record;

        $metadata->delete_owners($sha256);
        $self->blob_store->delete_blob($record->{storage_key});
        $metadata->delete_blob($sha256);
        return 1;
    });
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

    $store->with_transaction(sub {
        $store->lock_blob($metadata{sha256});
        my $record = $store->find_blob($metadata{sha256});

        if (defined $record) {
            $created = 0;
        }
        else {
            my $storage_key = $upload->_prepare(%metadata);
            $created = $store->insert_blob(%metadata, storage_key => $storage_key) ? 1 : 0;
        }

        if (defined $metadata{pubkey}) {
            $store->upsert_owner(%metadata);
        }

        return 1;
    });

    eval { $upload->_cleanup($created) };

    return {
        descriptor => $self->_descriptor(\%metadata),
        created    => $created,
    };
}

sub _delete_blob_if_unowned {
    my ($self, $sha256) = @_;
    my $metadata = $self->metadata_store;
    return if $metadata->owner_count($sha256);
    my $record = $metadata->find_blob($sha256);
    return unless defined $record;
    $self->blob_store->delete_blob($record->{storage_key});
    $metadata->delete_blob($sha256);
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

sub _migrate_legacy_schema {
    my ($self) = @_;
    my $dbh = $self->dbh;
    my %columns = map { $_->[1] => 1 } @{$dbh->selectall_arrayref(
        q{PRAGMA table_info(blossom_blobs)},
    )};
    return 1 unless %columns;
    return 1 if $columns{storage_key} && !$columns{body};
    croak "incompatible blossom_blobs schema"
        unless $columns{body} && !$columns{storage_key};

    my ($foreign_keys) = $dbh->selectrow_array('PRAGMA foreign_keys');
    $dbh->do('PRAGMA foreign_keys = OFF');
    $dbh->begin_work;
    my $ok = eval {
        $dbh->do(q{ALTER TABLE blossom_owners RENAME TO blossom_owners_legacy});
        $dbh->do(q{ALTER TABLE blossom_blobs RENAME TO blossom_blobs_legacy});
        $dbh->do(q{
            CREATE TABLE blossom_blob_data (
                storage_key TEXT PRIMARY KEY NOT NULL,
                body        BLOB NOT NULL
            )
        });
        $dbh->do(q{
            INSERT INTO blossom_blob_data (storage_key, body)
            SELECT sha256, CAST(body AS BLOB) FROM blossom_blobs_legacy
        });
        $dbh->do(q{
            CREATE TABLE blossom_blobs (
                sha256      TEXT PRIMARY KEY NOT NULL,
                storage_key TEXT NOT NULL,
                size        INTEGER NOT NULL,
                type        TEXT NOT NULL,
                uploaded    INTEGER NOT NULL
            )
        });
        $dbh->do(q{
            INSERT INTO blossom_blobs (sha256, storage_key, size, type, uploaded)
            SELECT sha256, sha256, size, type, uploaded FROM blossom_blobs_legacy
        });
        $dbh->do(q{
            CREATE TABLE blossom_owners (
                pubkey   TEXT NOT NULL,
                sha256   TEXT NOT NULL,
                type     TEXT NOT NULL,
                uploaded INTEGER NOT NULL,
                PRIMARY KEY (pubkey, sha256),
                FOREIGN KEY (sha256) REFERENCES blossom_blobs(sha256) ON DELETE CASCADE
            )
        });
        $dbh->do(q{
            INSERT INTO blossom_owners (pubkey, sha256, type, uploaded)
            SELECT pubkey, sha256, type, uploaded FROM blossom_owners_legacy
        });
        $dbh->do(q{DROP TABLE blossom_owners_legacy});
        $dbh->do(q{DROP TABLE blossom_blobs_legacy});
        my $violations = $dbh->selectall_arrayref('PRAGMA foreign_key_check');
        croak "SQLite schema migration left invalid foreign keys" if @$violations;
        1;
    };
    my $error = $@;

    if (!$ok) {
        eval { $dbh->rollback };
        $dbh->do('PRAGMA foreign_keys = ON') if $foreign_keys;
        die $error;
    }

    $dbh->commit;
    $dbh->do('PRAGMA foreign_keys = ON') if $foreign_keys;
    return 1;
}

sub _connect {
    my ($database) = @_;
    croak "database must be a scalar" if ref($database);
    croak "database is required" unless length $database;

    return DBI->connect(
        "dbi:SQLite:dbname=$database",
        '',
        '',
        {
            AutoCommit => 1,
            RaiseError => 1,
            PrintError => 0,
            sqlite_unicode => 0,
        },
    );
}

sub _validate_dbh {
    my ($dbh) = @_;
    croak "dbh must be a DBI database handle"
        unless blessed($dbh) && $dbh->can('do') && $dbh->can('selectrow_array');
    my $driver = eval { $dbh->{Driver}{Name} };
    croak "dbh must be a SQLite DBI handle"
        unless defined $driver && $driver eq 'SQLite';
    croak "dbh must have AutoCommit enabled"
        unless $dbh->{AutoCommit};
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    return $dbh;
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
    package Net::Blossom::Server::Backend::SQLite::_Upload;

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

Net::Blossom::Server::Backend::SQLite - SQLite storage backend for Blossom servers

=head1 SYNOPSIS

    use Net::Blossom::Server;
    use Net::Blossom::Server::Backend::SQLite;

    my $storage = Net::Blossom::Server::Backend::SQLite->new(
        database => '/var/lib/blossom/blossom.sqlite',
        base_url => 'https://cdn.example.com',
    );
    $storage->deploy_schema;

    my $server = Net::Blossom::Server->new(storage => $storage);

=head1 DESCRIPTION

C<Net::Blossom::Server::Backend::SQLite> is a SQLite storage backend for
L<Net::Blossom::Server>. It stores Blossom blob bytes and metadata in a SQLite
database and implements the L<Net::Blossom::Server::Storage> contract.

SQLite access is provided through L<DBI> and L<DBD::SQLite>.

This backend is intended for self-contained single-node deployments, local
development, and tests. It can be a reasonable production choice when blob sizes,
traffic, and write concurrency are controlled.

Blob bodies are stored in SQLite C<BLOB> values. This keeps storage simple, but
large media archives or high-traffic public servers should usually use Postgres
or a backend that stores blob bytes outside the metadata database.

The backend coordinates separate
L<Net::Blossom::Server::Backend::SQLite::MetadataStore> and
L<Net::Blossom::Server::Backend::SQLite::BlobStore> components on one DBI
handle. Applications normally use this top-level storage class.

=head1 UPGRADING FROM 0.001000 OR 0.001001

C<deploy_schema> automatically moves blob bodies from the C<blossom_blobs>
table into C<blossom_blob_data>. Existing descriptors and owners are preserved.
Back up the database before upgrading.

=head1 CONSTRUCTOR

=head2 new

    my $storage = Net::Blossom::Server::Backend::SQLite->new(
        database => $path,
        base_url => $url,
    );

Creates a storage object. C<database> is the SQLite database file path.
C<base_url> is the public HTTP or HTTPS URL prefix used when descriptors are
created. It may include a path prefix, but not userinfo, query, or fragment
parts. Trailing slashes are removed.

Instead of C<database>, callers may pass an existing DBI handle as C<dbh>. The
handle must be a SQLite handle with C<AutoCommit> enabled.

=head1 METHODS

=head2 dbh

    my $dbh = $storage->dbh;

Returns the DBI handle used by the backend.

=head2 base_url

    my $url = $storage->base_url;

Returns the normalized descriptor URL prefix.

=head2 metadata_store

Returns the SQLite metadata-store component.

=head2 blob_store

Returns the SQLite blob-store component.

=head2 deploy_schema

    $storage->deploy_schema;

Creates the required SQLite tables and indexes if they do not already exist.
This method is safe to call more than once and migrates the earlier combined
schema when needed.

=head2 begin_upload

    my $upload = $storage->begin_upload(%context);

Starts a blob upload and returns an upload writer. The server core writes bytes
to the writer and later calls C<commit> with validated blob metadata.

=head2 get_blob

    my $result = $storage->get_blob($sha256);

Returns a L<Net::Blossom::Server::BlobResult> for C<$sha256>, or C<undef> when
the blob is absent.

=head2 get_blob_range

Returns one requested byte range as a scalar, or C<undef> when the blob is
absent. SQLite extracts the range without returning the complete BLOB to Perl.

=head2 head_blob

    my $descriptor = $storage->head_blob($sha256);

Returns a L<Net::Blossom::BlobDescriptor> without returning the blob body, or
C<undef> when the blob is absent.

=head2 delete_blob

    my $deleted = $storage->delete_blob($sha256, pubkey => $pubkey);

Deletes one owner relationship when C<pubkey> is supplied. The blob bytes are
deleted when the final owner is removed. Without C<pubkey>, the blob and all
owners are deleted.

=head2 list_blobs

    my $descriptors = $storage->list_blobs($pubkey, limit => 100);

Returns descriptors owned by C<$pubkey>, sorted by C<uploaded> descending and
C<sha256> ascending. C<cursor> and C<limit> follow the
L<Net::Blossom::Server::Storage> contract.

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=cut
