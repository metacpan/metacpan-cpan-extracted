package Net::Blossom::Server::Backend::SQLite;

use strictures 2;

use Carp qw(croak);
use DBI ();
use File::Temp qw(tempfile);
use Net::Blossom::BlobDescriptor;
use Net::Blossom::_URL;
use Net::Blossom::Server::BlobResult;
use Scalar::Util qw(blessed);

our $VERSION = '0.001000';

sub new {
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

    return bless {
        dbh      => $dbh,
        base_url => $base_url,
    }, $class;
}

sub dbh {
    my ($self) = @_;
    return $self->{dbh};
}

sub base_url {
    my ($self) = @_;
    return $self->{base_url};
}

sub deploy_schema {
    my ($self) = @_;
    my $dbh = $self->dbh;

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS blossom_blobs (
            sha256   TEXT PRIMARY KEY NOT NULL,
            body     BLOB NOT NULL,
            size     INTEGER NOT NULL,
            type     TEXT NOT NULL,
            uploaded INTEGER NOT NULL
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

sub begin_upload {
    my ($self, %context) = @_;
    my ($fh, $path) = tempfile('net-blossom-sqlite-upload-XXXXXX', TMPDIR => 1, UNLINK => 0);
    binmode $fh
        or croak "unable to binmode upload temp file: $!";

    return Net::Blossom::Server::Backend::SQLite::_Upload->new(
        storage => $self,
        fh      => $fh,
        path    => $path,
    );
}

sub get_blob {
    my ($self, $sha256) = @_;
    my $row = $self->dbh->selectrow_hashref(
        q{SELECT sha256, body, size, type, uploaded FROM blossom_blobs WHERE sha256 = ?},
        undef,
        $sha256,
    );
    return unless defined $row;

    return Net::Blossom::Server::BlobResult->new(
        descriptor => $self->_descriptor($row),
        body       => $row->{body},
    );
}

sub head_blob {
    my ($self, $sha256) = @_;
    my $row = $self->dbh->selectrow_hashref(
        q{SELECT sha256, size, type, uploaded FROM blossom_blobs WHERE sha256 = ?},
        undef,
        $sha256,
    );
    return unless defined $row;
    return $self->_descriptor($row);
}

sub delete_blob {
    my ($self, $sha256, %opts) = @_;

    return $self->_with_transaction(sub {
        if (defined $opts{pubkey}) {
            my $rows = $self->dbh->do(
                q{DELETE FROM blossom_owners WHERE sha256 = ? AND pubkey = ?},
                undef,
                $sha256,
                $opts{pubkey},
            );
            return 0 unless _changed_rows($rows);
            $self->_delete_blob_if_unowned($sha256);
            return 1;
        }

        my ($exists) = $self->dbh->selectrow_array(
            q{SELECT 1 FROM blossom_blobs WHERE sha256 = ?},
            undef,
            $sha256,
        );
        return 0 unless $exists;

        $self->dbh->do(q{DELETE FROM blossom_owners WHERE sha256 = ?}, undef, $sha256);
        $self->dbh->do(q{DELETE FROM blossom_blobs WHERE sha256 = ?}, undef, $sha256);
        return 1;
    });
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
        SELECT o.sha256, b.size, o.type, o.uploaded
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

    my $rows = $self->dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
    return [map { $self->_descriptor($_) } @$rows];
}

sub _commit_upload {
    my ($self, $upload, %metadata) = @_;
    my $body = $upload->_body;
    my $created;

    $self->_with_transaction(sub {
        my $rows = $self->dbh->do(
            q{
                INSERT OR IGNORE INTO blossom_blobs
                    (sha256, body, size, type, uploaded)
                VALUES (?, ?, ?, ?, ?)
            },
            undef,
            $metadata{sha256},
            $body,
            $metadata{size},
            $metadata{type},
            $metadata{uploaded},
        );
        $created = _changed_rows($rows) ? 1 : 0;

        if (defined $metadata{pubkey}) {
            $rows = $self->dbh->do(
                q{
                    UPDATE blossom_owners
                       SET type = ?, uploaded = ?
                     WHERE pubkey = ? AND sha256 = ?
                },
                undef,
                $metadata{type},
                $metadata{uploaded},
                $metadata{pubkey},
                $metadata{sha256},
            );
            if (!_changed_rows($rows)) {
                $self->dbh->do(
                    q{
                        INSERT INTO blossom_owners
                            (pubkey, sha256, type, uploaded)
                        VALUES (?, ?, ?, ?)
                    },
                    undef,
                    $metadata{pubkey},
                    $metadata{sha256},
                    $metadata{type},
                    $metadata{uploaded},
                );
            }
        }

        return 1;
    });

    eval { $upload->_cleanup };

    return {
        descriptor => $self->_descriptor(\%metadata),
        created    => $created,
    };
}

sub _delete_blob_if_unowned {
    my ($self, $sha256) = @_;
    my ($owners) = $self->dbh->selectrow_array(
        q{SELECT COUNT(*) FROM blossom_owners WHERE sha256 = ?},
        undef,
        $sha256,
    );
    return if $owners;
    $self->dbh->do(q{DELETE FROM blossom_blobs WHERE sha256 = ?}, undef, $sha256);
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

sub _with_transaction {
    my ($self, $code) = @_;
    my $dbh = $self->dbh;
    my $manage = $dbh->{AutoCommit};
    my $wantarray = wantarray;
    my (@result, $result);

    $dbh->begin_work if $manage;
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
        eval { $dbh->rollback if $manage };
        die $error;
    }

    $dbh->commit if $manage;
    return $wantarray ? @result : $result;
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
    package Net::Blossom::Server::Backend::SQLite::_Upload;

    use strictures 2;

    use Carp qw(croak);

    sub new {
        my ($class, %args) = @_;
        return bless {
            storage   => $args{storage},
            fh        => $args{fh},
            path      => $args{path},
            committed => 0,
            aborted   => 0,
        }, $class;
    }

    sub write {
        my ($self, $chunk) = @_;
        croak "upload is already committed" if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        print {$self->{fh}} $chunk
            or croak "storage write failed: $!";
        return length $chunk;
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
        $self->_cleanup;
        return 1;
    }

    sub _body {
        my ($self) = @_;
        $self->_close;

        open my $fh, '<:raw', $self->{path}
            or croak "unable to read upload temp file: $!";
        my $body = do { local $/; <$fh> };
        close $fh
            or croak "unable to close upload temp file: $!";
        return $body;
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
        close $self->{fh}
            or croak "unable to close upload temp file: $!";
        $self->{fh} = undef;
        return 1;
    }

    sub DESTROY {
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
handle must be a SQLite handle.

=head1 METHODS

=head2 dbh

    my $dbh = $storage->dbh;

Returns the DBI handle used by the backend.

=head2 base_url

    my $url = $storage->base_url;

Returns the normalized descriptor URL prefix.

=head2 deploy_schema

    $storage->deploy_schema;

Creates the required SQLite tables and indexes if they do not already exist.
This method is safe to call more than once.

=head2 begin_upload

    my $upload = $storage->begin_upload(%context);

Starts a blob upload and returns an upload writer. The server core writes bytes
to the writer and later calls C<commit> with validated blob metadata.

=head2 get_blob

    my $result = $storage->get_blob($sha256);

Returns a L<Net::Blossom::Server::BlobResult> for C<$sha256>, or C<undef> when
the blob is absent.

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

=cut
