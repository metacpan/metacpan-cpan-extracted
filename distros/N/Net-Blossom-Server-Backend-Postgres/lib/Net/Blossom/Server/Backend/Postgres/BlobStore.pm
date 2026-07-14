package Net::Blossom::Server::Backend::Postgres::BlobStore;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(dbh schema);
use File::Temp qw(tempfile);
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
    my $data = $self->_table('blossom_blob_data');
    $self->dbh->do(qq{
        CREATE TABLE IF NOT EXISTS $data (
            storage_key text PRIMARY KEY NOT NULL,
            body_oid    oid NOT NULL
        )
    });
    return 1;
}

sub begin_upload {
    my ($self, %context) = @_;
    my ($fh, $path) = tempfile('net-blossom-postgres-upload-XXXXXX', TMPDIR => 1, UNLINK => 0);
    binmode $fh or croak "unable to binmode upload temp file: $!";
    return Net::Blossom::Server::Backend::Postgres::BlobStore::_Upload->new(
        store => $self,
        fh    => $fh,
        path  => $path,
    );
}

sub get_blob {
    my ($self, $storage_key) = @_;
    my $dbh = $self->_reader_dbh;
    my $data = $dbh->quote_identifier($self->schema, 'blossom_blob_data');
    my ($body_oid, $fd);

    my $ok = eval {
        $dbh->begin_work;
        ($body_oid) = $dbh->selectrow_array(
            qq{SELECT body_oid FROM $data WHERE storage_key = ?},
            undef,
            $storage_key,
        );
        $fd = $dbh->pg_lo_open($body_oid, $dbh->{pg_INV_READ}) if defined $body_oid;
        croak "unable to open PostgreSQL large object" if defined $body_oid && !defined $fd;
        1;
    };

    if (!$ok || !defined $body_oid) {
        my $error = $@;
        eval { $dbh->rollback unless $dbh->{AutoCommit} };
        eval { $dbh->disconnect };
        die $error unless $ok;
        return;
    }

    return Net::Blossom::Server::Backend::Postgres::BlobStore::_Stream->new(
        dbh => $dbh,
        fd  => $fd,
    );
}

sub delete_blob {
    my ($self, $storage_key) = @_;
    croak "blob deletion requires an active transaction"
        if $self->dbh->{AutoCommit};
    my $data = $self->_table('blossom_blob_data');
    my ($body_oid) = $self->dbh->selectrow_array(
        qq{SELECT body_oid FROM $data WHERE storage_key = ?},
        undef,
        $storage_key,
    );
    return 0 unless defined $body_oid;
    $self->_unlink_body($body_oid);
    $self->dbh->do(qq{DELETE FROM $data WHERE storage_key = ?}, undef, $storage_key);
    return 1;
}

sub _unlink_body {
    my ($self, $body_oid) = @_;
    my $unlinked = $self->dbh->pg_lo_unlink($body_oid);
    croak "unable to unlink PostgreSQL large object" unless $unlinked;
    return 1;
}

sub _reader_dbh {
    my ($self) = @_;
    my $dbh = $self->dbh->clone({
        AutoCommit     => 1,
        RaiseError     => 1,
        PrintError     => 0,
        pg_enable_utf8 => 0,
    });
    croak "unable to clone Postgres DBI handle for blob stream" unless defined $dbh;
    return $dbh;
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

sub _changed_rows {
    my ($rows) = @_;
    return defined $rows && $rows ne '0E0' && $rows > 0;
}

sub _constructor_args {
    return %{$_[0]} if @_ == 1 && ref($_[0]) eq 'HASH';
    croak "constructor arguments must be name/value pairs" if @_ % 2;
    return @_;
}

{
    package Net::Blossom::Server::Backend::Postgres::BlobStore::_Upload;

    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(store fh path storage_key), {
        prepared => 0,
        committed => 0,
        aborted => 0,
    };

    sub BUILD {
        my ($self) = @_;
        $self->prepared;
        $self->committed;
        $self->aborted;
        return;
    }

    sub write {
        my ($self, $chunk) = @_;
        croak "upload is already prepared" if $self->{prepared};
        croak "upload is already committed" if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        print {$self->{fh}} $chunk or croak "storage write failed: $!";
        return length $chunk;
    }

    sub prepare {
        my ($self, %metadata) = @_;
        croak "upload is already prepared" if $self->{prepared};
        croak "upload is already committed" if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        croak "blob preparation requires an active transaction"
            if $self->{store}->dbh->{AutoCommit};
        $self->_close;

        my $body_oid = $self->{store}->dbh->pg_lo_import($self->{path});
        croak "unable to import PostgreSQL large object" unless defined $body_oid;
        my $storage_key = $metadata{sha256};
        my $data = $self->{store}->_table('blossom_blob_data');
        my $rows = $self->{store}->dbh->do(
            qq{
                INSERT INTO $data (storage_key, body_oid)
                VALUES (?, ?)
                ON CONFLICT (storage_key) DO NOTHING
            },
            undef,
            $storage_key,
            $body_oid,
        );
        $self->{store}->_unlink_body($body_oid)
            unless Net::Blossom::Server::Backend::Postgres::BlobStore::_changed_rows($rows);

        $self->{storage_key} = $storage_key;
        $self->{prepared} = 1;
        return $storage_key;
    }

    sub commit {
        my ($self) = @_;
        return 1 if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        croak "upload is not prepared" unless $self->{prepared};
        $self->{committed} = 1;
        $self->_cleanup;
        return 1;
    }

    sub abort {
        my ($self) = @_;
        return 1 if $self->{aborted} || $self->{committed};
        $self->{aborted} = 1;
        $self->_cleanup;
        return 1;
    }

    sub _cleanup {
        my ($self) = @_;
        $self->_close;
        unlink $self->{path}
            or croak "unable to remove upload temp file: $!"
            if defined $self->{path} && -e $self->{path};
        $self->{path} = undef;
        return 1;
    }

    sub _close {
        my ($self) = @_;
        return 1 unless defined $self->{fh};
        close $self->{fh} or croak "unable to close upload temp file: $!";
        $self->{fh} = undef;
        return 1;
    }

    sub DEMOLISH {
        my ($self) = @_;
        return if $self->{committed} || $self->{aborted};
        eval { $self->abort };
        return;
    }
}

{
    package Net::Blossom::Server::Backend::Postgres::BlobStore::_Stream;

    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(dbh fd), {
        closed => 0,
        eof    => 0,
    };

    my $READ_SIZE = 65536;

    sub BUILD {
        my ($self) = @_;
        $self->closed;
        $self->eof;
        return;
    }

    sub read {
        my ($self, undef, $length) = @_;
        if ($self->{eof}) {
            $_[1] = '';
            return 0;
        }
        croak "stream is closed" if $self->{closed};
        croak "read length must be a non-negative integer"
            unless defined $length && !ref($length) && $length =~ /\A[0-9]+\z/;
        if ($length == 0) {
            $_[1] = '';
            return 0;
        }

        my $chunk = '';
        my $read;
        my $ok = eval {
            $read = $self->{dbh}->pg_lo_read($self->{fd}, $chunk, $length);
            croak "PostgreSQL large-object read failed" unless defined $read;
            1;
        };
        if (!$ok) {
            my $error = $@;
            eval { $self->_finish(0) };
            die $error;
        }

        $_[1] = $chunk;
        if ($read == 0) {
            $self->{eof} = 1;
            $self->_finish(1);
        }
        return $read;
    }

    sub getline {
        my ($self) = @_;
        my $chunk = '';
        my $read = $self->read($chunk, $READ_SIZE);
        return if $read == 0;
        return $chunk;
    }

    sub close {
        my ($self) = @_;
        return 1 if $self->{closed};
        return $self->_finish(1);
    }

    sub _finish {
        my ($self, $commit) = @_;
        return 1 if $self->{closed};
        $self->{closed} = 1;

        my @errors;
        my $object_closed = eval {
            $self->{dbh}->pg_lo_close($self->{fd})
                or die "unable to close PostgreSQL large object\n";
            1;
        };
        push @errors, $@ unless $object_closed;

        if ($commit && $object_closed) {
            my $committed = eval { $self->{dbh}->commit; 1 };
            if (!$committed) {
                push @errors, $@;
                eval { $self->{dbh}->rollback };
                push @errors, $@ if $@;
            }
        }
        else {
            eval { $self->{dbh}->rollback };
            push @errors, $@ if $@;
        }

        eval { $self->{dbh}->disconnect };
        push @errors, $@ if $@;
        die $errors[0] if @errors;
        return 1;
    }

    sub DEMOLISH {
        my ($self) = @_;
        eval { $self->_finish(0) } unless $self->{closed};
        return;
    }
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Backend::Postgres::BlobStore - PostgreSQL large-object bytes

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::BlobStore> using PostgreSQL
large objects. It stores bytes by opaque storage key and contains no descriptor
or owner logic.

Use the same DBI handle for the paired
L<Net::Blossom::Server::Backend::Postgres::MetadataStore> so their changes share
one transaction.

=head1 CONSTRUCTOR

=head2 new

    my $blobs = Net::Blossom::Server::Backend::Postgres::BlobStore->new(
        dbh => $dbh,
    );

Creates a blob store in the current PostgreSQL schema using a PostgreSQL DBI
handle with C<AutoCommit> enabled.

=head1 METHODS

=head2 dbh

Returns the PostgreSQL DBI handle.

=head2 schema

Returns the schema selected when the component was created.

=head2 deploy_schema

Creates the storage-key to large-object table.

=head2 begin_upload

Starts a staged upload implementing the L<Net::Blossom::Server::BlobStore>
upload contract. Its C<prepare> method requires an active transaction on C<dbh>;
the top-level PostgreSQL backend manages this transaction.

=head2 get_blob

Returns a streaming large-object body by storage key, or C<undef>.

=head2 delete_blob

Unlinks and removes a large object by storage key. It requires an active
transaction on C<dbh>.

=head2 BUILDARGS

Validates and normalizes constructor arguments for Class::Tiny.

=cut
