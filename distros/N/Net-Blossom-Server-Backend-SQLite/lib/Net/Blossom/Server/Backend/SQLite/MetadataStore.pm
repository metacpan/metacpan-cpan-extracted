package Net::Blossom::Server::Backend::SQLite::MetadataStore;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(dbh);
use Scalar::Util qw(blessed);

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my @unknown = grep { $_ ne 'dbh' } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return { dbh => _validate_dbh($args{dbh}) };
}

sub deploy_schema {
    my ($self) = @_;
    my $dbh = $self->dbh;

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS blossom_blobs (
            sha256      TEXT PRIMARY KEY NOT NULL,
            storage_key TEXT NOT NULL,
            size        INTEGER NOT NULL,
            type        TEXT NOT NULL,
            uploaded    INTEGER NOT NULL
        )
    });
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS blossom_owners (
            pubkey   TEXT NOT NULL,
            sha256   TEXT NOT NULL,
            type     TEXT NOT NULL,
            uploaded INTEGER NOT NULL,
            PRIMARY KEY (pubkey, sha256),
            FOREIGN KEY (sha256) REFERENCES blossom_blobs(sha256) ON DELETE CASCADE
        )
    });
    $dbh->do(q{
        CREATE INDEX IF NOT EXISTS blossom_owners_pubkey_order
            ON blossom_owners (pubkey, uploaded DESC, sha256 ASC)
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
    my ($self) = @_;
    $self->_require_transaction;
    return 1;
}

sub find_blob {
    my ($self, $sha256) = @_;
    return $self->dbh->selectrow_hashref(
        q{SELECT sha256, storage_key, size, type, uploaded FROM blossom_blobs WHERE sha256 = ?},
        undef,
        $sha256,
    );
}

sub insert_blob {
    my ($self, %record) = @_;
    $self->_require_transaction;
    my $rows = $self->dbh->do(
        q{
            INSERT OR IGNORE INTO blossom_blobs
                (sha256, storage_key, size, type, uploaded)
            VALUES (?, ?, ?, ?, ?)
        },
        undef,
        @record{qw(sha256 storage_key size type uploaded)},
    );
    return _changed_rows($rows) ? 1 : 0;
}

sub upsert_owner {
    my ($self, %owner) = @_;
    $self->_require_transaction;
    my $rows = $self->dbh->do(
        q{
            UPDATE blossom_owners
               SET type = ?, uploaded = ?
             WHERE pubkey = ? AND sha256 = ?
        },
        undef,
        @owner{qw(type uploaded pubkey sha256)},
    );
    if (!_changed_rows($rows)) {
        $self->dbh->do(
            q{
                INSERT INTO blossom_owners
                    (pubkey, sha256, type, uploaded)
                VALUES (?, ?, ?, ?)
            },
            undef,
            @owner{qw(pubkey sha256 type uploaded)},
        );
    }
    return 1;
}

sub delete_owner {
    my ($self, $sha256, $pubkey) = @_;
    $self->_require_transaction;
    my $rows = $self->dbh->do(
        q{DELETE FROM blossom_owners WHERE sha256 = ? AND pubkey = ?},
        undef,
        $sha256,
        $pubkey,
    );
    return _changed_rows($rows) ? 1 : 0;
}

sub delete_owners {
    my ($self, $sha256) = @_;
    $self->_require_transaction;
    my $rows = $self->dbh->do(
        q{DELETE FROM blossom_owners WHERE sha256 = ?},
        undef,
        $sha256,
    );
    return _changed_rows($rows) ? 1 : 0;
}

sub owner_count {
    my ($self, $sha256) = @_;
    my ($count) = $self->dbh->selectrow_array(
        q{SELECT COUNT(*) FROM blossom_owners WHERE sha256 = ?},
        undef,
        $sha256,
    );
    return 0 + $count;
}

sub delete_blob {
    my ($self, $sha256) = @_;
    $self->_require_transaction;
    my $rows = $self->dbh->do(
        q{DELETE FROM blossom_blobs WHERE sha256 = ?},
        undef,
        $sha256,
    );
    return _changed_rows($rows) ? 1 : 0;
}

sub list_blobs {
    my ($self, $pubkey, %opts) = @_;
    my @where = ('o.pubkey = ?');
    my @bind = ($pubkey);

    if (defined $opts{cursor}) {
        my $cursor = $self->dbh->selectrow_hashref(
            q{SELECT sha256, uploaded FROM blossom_owners WHERE pubkey = ? AND sha256 = ?},
            undef,
            $pubkey,
            $opts{cursor},
        );
        return [] unless defined $cursor;
        push @where, q{(o.uploaded < ? OR (o.uploaded = ? AND o.sha256 > ?))};
        push @bind, $cursor->{uploaded}, $cursor->{uploaded}, $cursor->{sha256};
    }

    my $sql = q{
        SELECT o.sha256, b.storage_key, b.size, o.type, o.uploaded
          FROM blossom_owners o
          JOIN blossom_blobs b ON b.sha256 = o.sha256
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

sub _validate_dbh {
    my ($dbh) = @_;
    croak "dbh must be a DBI database handle"
        unless blessed($dbh) && $dbh->can('do') && $dbh->can('selectrow_array');
    my $driver = eval { $dbh->{Driver}{Name} };
    croak "dbh must be a SQLite DBI handle"
        unless defined $driver && $driver eq 'SQLite';
    croak "dbh must have AutoCommit enabled" unless $dbh->{AutoCommit};
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
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

Net::Blossom::Server::Backend::SQLite::MetadataStore - SQLite Blossom metadata

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::MetadataStore> using SQLite. It
stores descriptors and owners but not blob bytes.

Use the same DBI handle for the paired
L<Net::Blossom::Server::Backend::SQLite::BlobStore> so their changes share one
transaction.

C<lock_blob> and all methods that change records require a transaction started
by C<with_transaction>.

=head1 CONSTRUCTOR

=head2 new

    my $metadata = Net::Blossom::Server::Backend::SQLite::MetadataStore->new(
        dbh => $dbh,
    );

Creates a metadata store using a SQLite DBI handle with C<AutoCommit> enabled.

=head1 METHODS

=head2 dbh

Returns the SQLite DBI handle.

=head2 deploy_schema

Creates the metadata tables and owner ordering index.

=head2 with_transaction

Runs a callback in a SQLite transaction.

=head2 lock_blob

Provides the contract's per-blob lock point. SQLite serializes writes for the
whole database, so this method is a no-op. Conflicting writers may receive a
SQLite busy or locked error.

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
