package Net::Blossom::Server::Backend::Postgres::MetadataStore;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(dbh schema);
use Scalar::Util qw(blessed);

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my @unknown = grep { $_ ne 'dbh' } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    my $dbh = _validate_dbh($args{dbh});
    my ($schema) = $dbh->selectrow_array(q{SELECT current_schema()});
    croak "Postgres connection has no current schema" unless defined $schema && length $schema;
    return { dbh => $dbh, schema => $schema };
}

sub deploy_schema {
    my ($self) = @_;
    my $blobs = $self->_table('blossom_blobs');
    my $owners = $self->_table('blossom_owners');
    my $owner_index = $self->dbh->quote_identifier('blossom_owners_pubkey_order');

    $self->dbh->do(qq{
        CREATE TABLE IF NOT EXISTS $blobs (
            sha256      text PRIMARY KEY NOT NULL,
            storage_key text NOT NULL,
            size        bigint NOT NULL,
            type        text NOT NULL,
            uploaded    bigint NOT NULL
        )
    });
    $self->dbh->do(qq{
        CREATE TABLE IF NOT EXISTS $owners (
            pubkey   text NOT NULL,
            sha256   text NOT NULL,
            type     text NOT NULL,
            uploaded bigint NOT NULL,
            PRIMARY KEY (pubkey, sha256),
            FOREIGN KEY (sha256) REFERENCES $blobs(sha256) ON DELETE CASCADE
        )
    });
    $self->dbh->do(qq{
        CREATE INDEX IF NOT EXISTS $owner_index
            ON $owners (pubkey, uploaded DESC, sha256 ASC)
    });
    return 1;
}

sub with_transaction {
    my ($self, $code) = @_;
    croak "transaction callback must be a code reference" unless ref($code) eq 'CODE';
    my $dbh = $self->dbh;
    my $wantarray = wantarray;
    my (@result, $result);

    croak "dbh must have AutoCommit enabled" unless $dbh->{AutoCommit};
    $dbh->begin_work;
    my $ok = eval {
        if ($wantarray) {
            @result = $code->();
        }
        else {
            $result = $code->();
        }
        1;
    };
    my $error = $@;

    if (!$ok) {
        eval { $dbh->rollback };
        die $error;
    }

    $dbh->commit;
    return $wantarray ? @result : $result;
}

sub lock_blob {
    my ($self, $sha256) = @_;
    $self->_require_transaction;
    my @keys = map {
        my $key = unpack 'N', pack 'H8', substr($sha256, $_, 8);
        $key -= 4_294_967_296 if $key > 2_147_483_647;
        $key;
    } (0, 8);
    $self->dbh->selectrow_array(q{SELECT pg_advisory_xact_lock(?, ?)}, undef, @keys);
    return 1;
}

sub find_blob {
    my ($self, $sha256) = @_;
    my $blobs = $self->_table('blossom_blobs');
    return $self->dbh->selectrow_hashref(
        qq{SELECT sha256, storage_key, size, type, uploaded FROM $blobs WHERE sha256 = ?},
        undef,
        $sha256,
    );
}

sub insert_blob {
    my ($self, %record) = @_;
    $self->_require_transaction;
    my $blobs = $self->_table('blossom_blobs');
    my $rows = $self->dbh->do(
        qq{
            INSERT INTO $blobs (sha256, storage_key, size, type, uploaded)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT (sha256) DO NOTHING
        },
        undef,
        @record{qw(sha256 storage_key size type uploaded)},
    );
    return _changed_rows($rows) ? 1 : 0;
}

sub upsert_owner {
    my ($self, %owner) = @_;
    $self->_require_transaction;
    my $owners = $self->_table('blossom_owners');
    $self->dbh->do(
        qq{
            INSERT INTO $owners (pubkey, sha256, type, uploaded)
            VALUES (?, ?, ?, ?)
            ON CONFLICT (pubkey, sha256)
            DO UPDATE SET type = EXCLUDED.type,
                          uploaded = EXCLUDED.uploaded
        },
        undef,
        @owner{qw(pubkey sha256 type uploaded)},
    );
    return 1;
}

sub delete_owner {
    my ($self, $sha256, $pubkey) = @_;
    $self->_require_transaction;
    my $owners = $self->_table('blossom_owners');
    my $rows = $self->dbh->do(
        qq{DELETE FROM $owners WHERE sha256 = ? AND pubkey = ?},
        undef,
        $sha256,
        $pubkey,
    );
    return _changed_rows($rows) ? 1 : 0;
}

sub delete_owners {
    my ($self, $sha256) = @_;
    $self->_require_transaction;
    my $owners = $self->_table('blossom_owners');
    my $rows = $self->dbh->do(qq{DELETE FROM $owners WHERE sha256 = ?}, undef, $sha256);
    return _changed_rows($rows) ? 1 : 0;
}

sub owner_count {
    my ($self, $sha256) = @_;
    my $owners = $self->_table('blossom_owners');
    my ($count) = $self->dbh->selectrow_array(
        qq{SELECT COUNT(*) FROM $owners WHERE sha256 = ?},
        undef,
        $sha256,
    );
    return 0 + $count;
}

sub delete_blob {
    my ($self, $sha256) = @_;
    $self->_require_transaction;
    my $blobs = $self->_table('blossom_blobs');
    my $rows = $self->dbh->do(qq{DELETE FROM $blobs WHERE sha256 = ?}, undef, $sha256);
    return _changed_rows($rows) ? 1 : 0;
}

sub list_blobs {
    my ($self, $pubkey, %opts) = @_;
    my $blobs = $self->_table('blossom_blobs');
    my $owners = $self->_table('blossom_owners');
    my @where = ('o.pubkey = ?');
    my @bind = ($pubkey);

    if (defined $opts{cursor}) {
        my $cursor = $self->dbh->selectrow_hashref(
            qq{SELECT sha256, uploaded FROM $owners WHERE pubkey = ? AND sha256 = ?},
            undef,
            $pubkey,
            $opts{cursor},
        );
        return [] unless defined $cursor;
        push @where, q{(o.uploaded < ? OR (o.uploaded = ? AND o.sha256 > ?))};
        push @bind, $cursor->{uploaded}, $cursor->{uploaded}, $cursor->{sha256};
    }

    my $sql = qq{
        SELECT o.sha256, b.storage_key, b.size, o.type, o.uploaded
          FROM $owners o
          JOIN $blobs b ON b.sha256 = o.sha256
         WHERE
    } . join(' AND ', @where) . q{
         ORDER BY o.uploaded DESC, o.sha256 ASC
    };

    if (defined $opts{limit}) {
        return [] if $opts{limit} <= 0;
        $sql .= q{ LIMIT ?};
        push @bind, int($opts{limit});
    }

    return $self->dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
}

sub _table {
    my ($self, $name) = @_;
    return $self->dbh->quote_identifier($self->schema, $name);
}

sub _validate_dbh {
    my ($dbh) = @_;
    croak "dbh must be a DBI database handle"
        unless blessed($dbh) && $dbh->can('do') && $dbh->can('selectrow_array');
    my $driver = eval { $dbh->{Driver}{Name} };
    croak "dbh must be a Postgres DBI handle" unless defined $driver && $driver eq 'Pg';
    croak "dbh must have AutoCommit enabled" unless $dbh->{AutoCommit};
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    eval { $dbh->{pg_enable_utf8} = 0 };
    return $dbh;
}

sub _require_transaction {
    my ($self) = @_;
    croak "metadata change requires an active transaction"
        if $self->dbh->{AutoCommit};
    return;
}

sub _changed_rows {
    my ($rows) = @_;
    return defined $rows && $rows ne '0E0' && $rows > 0;
}

sub _constructor_args {
    return %{$_[0]} if @_ == 1 && ref($_[0]) eq 'HASH';
    croak "constructor arguments must be name/value pairs" if @_ % 2;
    return @_;
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Backend::Postgres::MetadataStore - PostgreSQL Blossom metadata

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::MetadataStore> using PostgreSQL.
It stores descriptors and owners but not blob bytes.

Use the same DBI handle for the paired
L<Net::Blossom::Server::Backend::Postgres::BlobStore> so their changes share one
transaction.

C<lock_blob> and all methods that change records require a transaction started
by C<with_transaction>.

=head1 CONSTRUCTOR

=head2 new

    my $metadata = Net::Blossom::Server::Backend::Postgres::MetadataStore->new(
        dbh => $dbh,
    );

Creates a metadata store in the current PostgreSQL schema using a PostgreSQL
DBI handle with C<AutoCommit> enabled.

=head1 METHODS

=head2 dbh

Returns the PostgreSQL DBI handle.

=head2 schema

Returns the schema selected when the component was created.

=head2 deploy_schema

Creates storage-neutral metadata tables and the owner ordering index.

=head2 with_transaction

Runs a callback in a PostgreSQL transaction.

=head2 lock_blob

Takes a transaction-level advisory lock for one SHA-256 hash.

=head2 find_blob

Returns one storage-neutral blob record by SHA-256.

=head2 insert_blob

Inserts a blob record and reports whether it was created.

=head2 upsert_owner

Creates or updates one owner record.

=head2 delete_owner

Deletes one owner record and reports whether it existed.

=head2 delete_owners

Deletes every owner record for a blob.

=head2 owner_count

Returns the number of owners for a blob.

=head2 delete_blob

Deletes one blob metadata record and reports whether it existed.

=head2 list_blobs

Returns ordered storage-neutral blob records for an owner.

=head2 BUILDARGS

Validates and normalizes constructor arguments for Class::Tiny.

=cut
