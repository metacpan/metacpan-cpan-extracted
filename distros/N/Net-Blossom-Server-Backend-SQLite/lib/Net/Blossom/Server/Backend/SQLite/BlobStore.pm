package Net::Blossom::Server::Backend::SQLite::BlobStore;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(dbh);
use File::Temp qw(tempfile);
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
    $self->dbh->do(q{
        CREATE TABLE IF NOT EXISTS blossom_blob_data (
            storage_key TEXT PRIMARY KEY NOT NULL,
            body        BLOB NOT NULL
        )
    });
    return 1;
}

sub begin_upload {
    my ($self, %context) = @_;
    my ($fh, $path) = tempfile('net-blossom-sqlite-upload-XXXXXX', TMPDIR => 1, UNLINK => 0);
    binmode $fh or croak "unable to binmode upload temp file: $!";

    return Net::Blossom::Server::Backend::SQLite::BlobStore::_Upload->new(
        store => $self,
        fh    => $fh,
        path  => $path,
    );
}

sub get_blob {
    my ($self, $storage_key) = @_;
    my ($body) = $self->dbh->selectrow_array(
        q{SELECT body FROM blossom_blob_data WHERE storage_key = ?},
        undef,
        $storage_key,
    );
    return $body;
}

sub delete_blob {
    my ($self, $storage_key) = @_;
    croak "blob deletion requires an active transaction"
        if $self->dbh->{AutoCommit};
    my $rows = $self->dbh->do(
        q{DELETE FROM blossom_blob_data WHERE storage_key = ?},
        undef,
        $storage_key,
    );
    return _changed_rows($rows) ? 1 : 0;
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
    package Net::Blossom::Server::Backend::SQLite::BlobStore::_Upload;

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
        open my $fh, '<:raw', $self->{path}
            or croak "unable to read upload temp file: $!";
        my $body = do { local $/; <$fh> };
        close $fh or croak "unable to close upload temp file: $!";

        my $storage_key = $metadata{sha256};
        $self->{store}->dbh->do(
            q{INSERT OR IGNORE INTO blossom_blob_data (storage_key, body) VALUES (?, ?)},
            undef,
            $storage_key,
            $body,
        );
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

1;

=pod

=head1 NAME

Net::Blossom::Server::Backend::SQLite::BlobStore - SQLite Blossom blob bytes

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::BlobStore> using SQLite C<BLOB>
values. It stores bytes by opaque storage key and contains no descriptor or
owner logic.

Use the same DBI handle for the paired
L<Net::Blossom::Server::Backend::SQLite::MetadataStore> so their changes share
one transaction.

=head1 CONSTRUCTOR

=head2 new

    my $blobs = Net::Blossom::Server::Backend::SQLite::BlobStore->new(
        dbh => $dbh,
    );

Creates a blob store using a SQLite DBI handle with C<AutoCommit> enabled.

=head1 METHODS

=head2 dbh

Returns the SQLite DBI handle.

=head2 deploy_schema

Creates the blob byte table.

=head2 begin_upload

Starts a staged upload implementing the L<Net::Blossom::Server::BlobStore>
upload contract. Its C<prepare> method requires an active transaction on C<dbh>;
the top-level SQLite backend manages this transaction.

=head2 get_blob

Returns bytes by storage key or C<undef>.

=head2 delete_blob

Deletes bytes by storage key and reports whether they existed. It requires an
active transaction on C<dbh>.

=head2 BUILDARGS

Validates and normalizes constructor arguments for Class::Tiny.

=cut
