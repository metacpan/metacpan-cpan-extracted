package Net::Blossom::Server::Backend::Postgres;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(dbh base_url _schema metadata_store blob_store);
use DBI ();
use Net::Blossom::BlobDescriptor;
use Net::Blossom::_URL;
use Net::Blossom::Server::Backend::Postgres::BlobStore;
use Net::Blossom::Server::Backend::Postgres::MetadataStore;
use Net::Blossom::Server::BlobStore;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::MetadataStore;
use Scalar::Util qw(blessed);

our $VERSION = '0.001002';

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my %known = map { $_ => 1 } qw(dsn username password dbh base_url connect_attrs);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "dsn and dbh are mutually exclusive"
        if defined $args{dsn} && defined $args{dbh};
    croak "dsn or dbh is required"
        unless defined $args{dsn} || defined $args{dbh};
    croak "base_url is required"
        unless defined $args{base_url};
    croak "connect_attrs must be a hash reference"
        if defined $args{connect_attrs} && ref($args{connect_attrs}) ne 'HASH';

    my $base_url = _normalize_base_url($args{base_url});
    my $dbh = defined $args{dbh} ? _validate_dbh($args{dbh}) : _connect(%args);
    my ($schema) = $dbh->selectrow_array(q{SELECT current_schema()});
    croak "Postgres connection has no current schema"
        unless defined $schema && length $schema;

    my $metadata_store = Net::Blossom::Server::Backend::Postgres::MetadataStore->new(dbh => $dbh);
    my $blob_store = Net::Blossom::Server::Backend::Postgres::BlobStore->new(dbh => $dbh);
    Net::Blossom::Server::MetadataStore->assert_implements($metadata_store);
    Net::Blossom::Server::BlobStore->assert_implements($blob_store);

    return {
        dbh            => $dbh,
        base_url       => $base_url,
        _schema        => $schema,
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

    return Net::Blossom::Server::Backend::Postgres::_Upload->new(
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
    my $schema = $self->_schema;
    my $columns = $self->dbh->selectall_arrayref(q{
        SELECT column_name, udt_name
          FROM information_schema.columns
         WHERE table_schema = ?
           AND table_name = 'blossom_blobs'
    }, undef, $schema);
    return 1 unless @$columns;

    my %columns = map { $_->[0] => $_->[1] } @$columns;
    return 1 if exists $columns{storage_key} && !exists $columns{body_oid};
    croak "incompatible blossom_blobs schema; recreate it for PostgreSQL large-object storage"
        unless !exists $columns{body}
        && defined $columns{body_oid}
        && $columns{body_oid} eq 'oid';

    my $blobs = $self->_table('blossom_blobs');
    my $data = $self->_table('blossom_blob_data');
    $self->metadata_store->with_transaction(sub {
        $self->dbh->do(qq{
            CREATE TABLE $data (
                storage_key text PRIMARY KEY NOT NULL,
                body_oid    oid NOT NULL
            )
        });
        $self->dbh->do(qq{
            INSERT INTO $data (storage_key, body_oid)
            SELECT sha256, body_oid FROM $blobs
        });
        $self->dbh->do(qq{ALTER TABLE $blobs ADD COLUMN storage_key text});
        $self->dbh->do(qq{UPDATE $blobs SET storage_key = sha256});
        $self->dbh->do(qq{ALTER TABLE $blobs ALTER COLUMN storage_key SET NOT NULL});
        $self->dbh->do(qq{ALTER TABLE $blobs DROP COLUMN body_oid});
        return 1;
    });
    return 1;
}

sub _table {
    my ($self, $name) = @_;
    return $self->dbh->quote_identifier($self->_schema, $name);
}

sub _connect {
    my %args = @_;
    my $dsn = $args{dsn};
    croak "dsn must be a scalar" if ref($dsn);
    croak "dsn is required" unless length $dsn;
    croak "username must be a scalar" if defined $args{username} && ref($args{username});
    croak "password must be a scalar" if defined $args{password} && ref($args{password});

    eval 'use DBD::Pg (); 1'
        or die $@;

    my %attrs = (
        %{ $args{connect_attrs} || {} },
        AutoCommit    => 1,
        RaiseError    => 1,
        PrintError    => 0,
        pg_enable_utf8 => 0,
    );

    return DBI->connect(
        $dsn,
        $args{username},
        $args{password},
        \%attrs,
    );
}

sub _validate_dbh {
    my ($dbh) = @_;
    croak "dbh must be a DBI database handle"
        unless blessed($dbh) && $dbh->can('do') && $dbh->can('selectrow_array');
    my $driver = eval { $dbh->{Driver}{Name} };
    croak "dbh must be a Postgres DBI handle"
        unless defined $driver && $driver eq 'Pg';
    croak "dbh must have AutoCommit enabled"
        unless $dbh->{AutoCommit};
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    eval { $dbh->{pg_enable_utf8} = 0 };
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
    package Net::Blossom::Server::Backend::Postgres::_Upload;

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

Net::Blossom::Server::Backend::Postgres - Postgres storage backend for Blossom servers

=head1 SYNOPSIS

    use Net::Blossom::Server;
    use Net::Blossom::Server::Backend::Postgres;

    my $storage = Net::Blossom::Server::Backend::Postgres->new(
        dsn      => 'dbi:Pg:dbname=blossom;host=/var/run/postgresql',
        username => 'blossom',
        password => $password,
        base_url => 'https://cdn.example.com',
    );
    $storage->deploy_schema;

    my $server = Net::Blossom::Server->new(storage => $storage);

=head1 DESCRIPTION

C<Net::Blossom::Server::Backend::Postgres> is a Postgres storage backend for
L<Net::Blossom::Server>. It stores Blossom blob bytes and metadata in Postgres
and implements the L<Net::Blossom::Server::Storage> contract.

Postgres access is provided through L<DBI> and L<DBD::Pg>.

Blob bodies are stored as
L<PostgreSQL large objects|https://www.postgresql.org/docs/current/largeobjects.html>.
Uploads are written to a temporary file and imported only after the server has
validated the hash. Downloads are returned as streams, so blob bodies are not
loaded into Perl memory as a whole.

Each active download uses a cloned DBI connection and a read transaction until
the body reaches EOF or is closed. Deployments must allow enough PostgreSQL
connections for their concurrent downloads. Very large public media services
may still prefer a backend that stores blob bytes outside the metadata database.

This backend serializes uploads and deletes for the same hash with a
transaction-level PostgreSQL advisory lock. The lock is released when the
transaction commits or rolls back. Direct SQL writes to the backend tables do
not participate in this locking protocol. Operations for different hashes may
run concurrently.

The backend coordinates separate
L<Net::Blossom::Server::Backend::Postgres::MetadataStore> and
L<Net::Blossom::Server::Backend::Postgres::BlobStore> components on one DBI
handle. Applications normally use this top-level storage class.

=head1 UPGRADING FROM 0.001001

C<deploy_schema> automatically separates the current large-object schema into
metadata and blob-data tables. Existing large-object identifiers, descriptors,
and owners are preserved. Back up the database before upgrading.

=head1 CONSTRUCTOR

=head2 new

    my $storage = Net::Blossom::Server::Backend::Postgres->new(
        dsn      => $dsn,
        username => $username,
        password => $password,
        base_url => $url,
    );

Creates a storage object. C<dsn> is a DBI Postgres data source string.
C<username> and C<password> are optional and are passed to C<DBI-E<gt>connect>.
C<base_url> is the public HTTP or HTTPS URL prefix used when descriptors are
created. It may include a path prefix, but not userinfo, query, or fragment
parts. Trailing slashes are removed.

Instead of C<dsn>, callers may pass an existing DBI handle as C<dbh>. The handle
must be a Postgres handle with C<AutoCommit> enabled so the backend can manage
its transactions. The backend clones this handle for each active blob download.

The backend uses the connection's current schema at construction time. All
later operations, including cloned download connections, remain bound to that
schema.

Optional C<connect_attrs> may be supplied with C<dsn>. The backend always forces
C<AutoCommit>, C<RaiseError>, C<PrintError>, and C<pg_enable_utf8> to values
needed by the storage implementation.

=head1 METHODS

=head2 dbh

    my $dbh = $storage->dbh;

Returns the DBI handle used by the backend.

=head2 base_url

    my $url = $storage->base_url;

Returns the normalized descriptor URL prefix.

=head2 metadata_store

Returns the PostgreSQL metadata-store component.

=head2 blob_store

Returns the PostgreSQL large-object store component.

=head2 deploy_schema

    $storage->deploy_schema;

Creates the required Postgres tables and indexes if they do not already exist.
They are created in the schema captured by C<new>. This method is safe to call
more than once. It migrates the C<0.001001> schema automatically.

=head2 begin_upload

    my $upload = $storage->begin_upload(%context);

Starts a blob upload and returns an upload writer. The server core writes bytes
to a temporary file and later calls C<commit> with validated blob metadata. A
new blob is imported as a PostgreSQL large object transactionally.

=head2 get_blob

    my $result = $storage->get_blob($sha256);

Returns a L<Net::Blossom::Server::BlobResult> for C<$sha256>, or C<undef> when
the blob is absent. Its body is a stream backed by a dedicated DBI connection.
Reading to EOF or calling C<close> releases that connection.

=head2 head_blob

    my $descriptor = $storage->head_blob($sha256);

Returns a L<Net::Blossom::BlobDescriptor> without returning the blob body, or
C<undef> when the blob is absent.

=head2 delete_blob

    my $deleted = $storage->delete_blob($sha256, pubkey => $pubkey);

Deletes one owner relationship when C<pubkey> is supplied. The blob bytes are
deleted with C<pg_lo_unlink> when the final owner is removed. Without C<pubkey>,
the blob and all owners are deleted.

=head2 list_blobs

    my $descriptors = $storage->list_blobs($pubkey, limit => 100);

Returns descriptors owned by C<$pubkey>, sorted by C<uploaded> descending and
C<sha256> ascending. C<cursor> and C<limit> follow the
L<Net::Blossom::Server::Storage> contract.

=head1 SEE ALSO

L<PostgreSQL large objects|https://www.postgresql.org/docs/current/largeobjects.html>,
L<DBD::Pg/Large Objects>

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=cut
