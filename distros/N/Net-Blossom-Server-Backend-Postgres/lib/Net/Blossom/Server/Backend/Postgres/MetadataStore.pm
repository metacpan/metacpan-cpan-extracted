package Net::Blossom::Server::Backend::Postgres::MetadataStore;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(dbh schema);
use Scalar::Util qw(blessed);

my $SCHEMA_LOCK_KEY = '-6335862357210207029';

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
    my $dbh = $self->dbh;
    croak "schema deployment requires AutoCommit" unless $dbh->{AutoCommit};

    # One-key advisory locks do not overlap the two-key per-blob lock space.
    $self->_acquire_schema_lock;

    my $ok = eval {
        $self->_deploy_schema;
        1;
    };
    my $error = $@;
    my $released;
    my $unlock_ok = eval {
        ($released) = $dbh->selectrow_array(
            q{SELECT pg_advisory_unlock(CAST(? AS bigint))},
            undef,
            $SCHEMA_LOCK_KEY,
        );
        1;
    };
    my $unlock_error = $@;

    if (!$ok) {
        $error .= "unable to release PostgreSQL schema lock: $unlock_error"
            unless $unlock_ok;
        $error .= "unable to release PostgreSQL schema lock\n"
            if $unlock_ok && !$released;
        die $error;
    }
    die $unlock_error unless $unlock_ok;
    croak "unable to release PostgreSQL schema lock" unless $released;
    return 1;
}

sub _acquire_schema_lock {
    my ($self) = @_;
    while (1) {
        my ($acquired) = $self->dbh->selectrow_array(
            q{SELECT pg_try_advisory_lock(CAST(? AS bigint))},
            undef,
            $SCHEMA_LOCK_KEY,
        );
        return 1 if $acquired;
        select undef, undef, undef, 0.05;
    }
}

sub _deploy_schema {
    my ($self) = @_;
    my $blobs = $self->_table('blossom_blobs');
    my $owners = $self->_table('blossom_owners');

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
    $self->_ensure_index(
        name       => 'blossom_owners_pubkey_order',
        definition => 'pubkey, uploaded DESC, sha256 ASC',
        columns    => [qw(pubkey uploaded sha256)],
        options    => '0 3 0',
    );
    $self->_ensure_index(
        name       => 'blossom_owners_sha256',
        definition => 'sha256',
        columns    => ['sha256'],
        options    => '0',
    );
    return 1;
}

sub _ensure_index {
    my ($self, %expected) = @_;
    my $state = $self->_index_state($expected{name});

    if (defined $state) {
        croak "incompatible PostgreSQL index $expected{name}"
            unless $state->{is_index}
            && $state->{table_schema} eq $self->schema
            && $state->{table_name} eq 'blossom_owners';

        if (!$state->{valid}) {
            $self->_drop_index_concurrently($expected{name});
            $state = undef;
        }
        elsif (!$self->_index_matches($state, \%expected)) {
            croak "incompatible PostgreSQL index $expected{name}";
        }
        else {
            return 1;
        }
    }

    my $index = $self->dbh->quote_identifier($expected{name});
    my $owners = $self->_table('blossom_owners');
    my $created = eval {
        $self->dbh->do(qq{
            CREATE INDEX CONCURRENTLY $index
                ON $owners ($expected{definition})
        });
        1;
    };
    my $error = $@;

    if (!$created) {
        eval {
            my $failed = $self->_index_state($expected{name});
            $self->_drop_index_concurrently($expected{name})
                if defined $failed
                && $failed->{is_index}
                && $failed->{table_schema} eq $self->schema
                && $failed->{table_name} eq 'blossom_owners'
                && !$failed->{valid};
        };
        die $error;
    }

    $state = $self->_index_state($expected{name});
    croak "PostgreSQL did not create valid index $expected{name}"
        unless defined $state && $self->_index_matches($state, \%expected);
    return 1;
}

sub _index_state {
    my ($self, $name) = @_;
    my $row = $self->dbh->selectrow_hashref(q{
        SELECT c.relkind,
               i.indexrelid,
               CASE WHEN i.indisvalid THEN 1 ELSE 0 END AS valid,
               CASE WHEN i.indisready THEN 1 ELSE 0 END AS ready,
               CASE WHEN i.indislive THEN 1 ELSE 0 END AS live,
               CASE WHEN i.indisunique THEN 1 ELSE 0 END AS unique_index,
               i.indnatts,
               i.indoption::text AS options,
               CASE WHEN i.indpred IS NULL THEN 1 ELSE 0 END AS unpredicated,
               CASE WHEN i.indexprs IS NULL THEN 1 ELSE 0 END AS no_expressions,
               CASE WHEN NOT EXISTS (
                    SELECT 1
                      FROM generate_series(0, i.indnatts - 1) AS p(position)
                      LEFT JOIN pg_attribute a
                        ON a.attrelid = i.indrelid
                       AND a.attnum = i.indkey[p.position]
                      LEFT JOIN pg_opclass opc
                        ON opc.oid = i.indclass[p.position]
                     WHERE a.attnum IS NULL
                        OR opc.oid IS NULL
                        OR NOT opc.opcdefault
                        OR opc.opcmethod <> c.relam
                        OR opc.opcintype <> a.atttypid
                        OR i.indcollation[p.position] <> a.attcollation
               ) THEN 1 ELSE 0 END AS default_semantics,
               am.amname,
               tn.nspname AS table_schema,
               t.relname AS table_name
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          LEFT JOIN pg_index i ON i.indexrelid = c.oid
          LEFT JOIN pg_class t ON t.oid = i.indrelid
          LEFT JOIN pg_namespace tn ON tn.oid = t.relnamespace
          LEFT JOIN pg_am am ON am.oid = c.relam
         WHERE n.nspname = ?
           AND c.relname = ?
    }, undef, $self->schema, $name);
    return unless defined $row;

    $row->{is_index} = defined $row->{indexrelid} && $row->{relkind} eq 'i' ? 1 : 0;
    if ($row->{is_index}) {
        my @columns;
        for my $position (1 .. $row->{indnatts}) {
            push @columns, scalar $self->dbh->selectrow_array(
                q{SELECT pg_get_indexdef(CAST(? AS oid), ?, true)},
                undef,
                $row->{indexrelid},
                $position,
            );
        }
        $row->{columns} = \@columns;
    }
    return $row;
}

sub _index_matches {
    my ($self, $state, $expected) = @_;
    return 0 unless $state->{is_index}
        && $state->{valid}
        && $state->{ready}
        && $state->{live}
        && !$state->{unique_index}
        && $state->{unpredicated}
        && $state->{no_expressions}
        && $state->{default_semantics}
        && defined $state->{amname}
        && $state->{amname} eq 'btree'
        && defined $state->{options}
        && $state->{options} eq $expected->{options}
        && @{$state->{columns}} == @{$expected->{columns}};

    for my $position (0 .. $#{$expected->{columns}}) {
        return 0 unless $state->{columns}[$position] eq $expected->{columns}[$position];
    }
    return 1;
}

sub _drop_index_concurrently {
    my ($self, $name) = @_;
    my $index = $self->dbh->quote_identifier($self->schema, $name);
    $self->dbh->do(qq{DROP INDEX CONCURRENTLY $index});
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

C<deploy_schema> requires C<AutoCommit>. It serializes concurrent deployments
and builds missing indexes without blocking ordinary metadata writes. An
invalid index left by an interrupted build is replaced automatically.

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

Creates storage-neutral metadata tables and the owner lookup indexes. Missing
indexes are built concurrently.

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
