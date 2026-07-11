package Net::Blossom::Server::Backend::Postgres;

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
            sha256   text PRIMARY KEY NOT NULL,
            body     bytea NOT NULL,
            size     bigint NOT NULL,
            type     text NOT NULL,
            uploaded bigint NOT NULL
        )
    });
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS blossom_owners (
            pubkey   text NOT NULL,
            sha256   text NOT NULL,
            type     text NOT NULL,
            uploaded bigint NOT NULL,
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
    my ($fh, $path) = tempfile('net-blossom-postgres-upload-XXXXXX', TMPDIR => 1, UNLINK => 0);
    binmode $fh
        or croak "unable to binmode upload temp file: $!";

    return Net::Blossom::Server::Backend::Postgres::_Upload->new(
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
        $self->_lock_blob($sha256);

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
        $self->_lock_blob($metadata{sha256});

        my $sth = $self->dbh->prepare(
            q{
                INSERT INTO blossom_blobs
                    (sha256, body, size, type, uploaded)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT (sha256) DO NOTHING
            }
        );
        $sth->bind_param(1, $metadata{sha256});
        $sth->bind_param(2, $body, { pg_type => _pg_bytea() });
        $sth->bind_param(3, $metadata{size});
        $sth->bind_param(4, $metadata{type});
        $sth->bind_param(5, $metadata{uploaded});
        my $rows = $sth->execute;
        $created = _changed_rows($rows) ? 1 : 0;

        if (defined $metadata{pubkey}) {
            $self->dbh->do(
                q{
                    INSERT INTO blossom_owners
                        (pubkey, sha256, type, uploaded)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT (pubkey, sha256)
                    DO UPDATE SET type = EXCLUDED.type,
                                  uploaded = EXCLUDED.uploaded
                },
                undef,
                $metadata{pubkey},
                $metadata{sha256},
                $metadata{type},
                $metadata{uploaded},
            );
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

sub _lock_blob {
    my ($self, $sha256) = @_;
    my @keys = map {
        my $key = unpack 'N', pack 'H8', substr($sha256, $_, 8);
        $key -= 4_294_967_296 if $key > 2_147_483_647;
        $key;
    } (0, 8);

    $self->dbh->selectrow_array(
        q{SELECT pg_advisory_xact_lock(?, ?)},
        undef,
        @keys,
    );
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

sub _changed_rows {
    my ($rows) = @_;
    return defined $rows && $rows ne '0E0' && $rows > 0;
}

sub _pg_bytea {
    eval 'use DBD::Pg qw(:pg_types); 1'
        or die $@;
    return PG_BYTEA();
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

Blob bodies are stored in Postgres C<bytea> values. This keeps the backend
self-contained and transactional. Very large public media services may still
prefer a backend that stores blob bytes outside the metadata database.

This backend serializes uploads and deletes for the same hash with a
transaction-level PostgreSQL advisory lock. The lock is released when the
transaction commits or rolls back. Direct SQL writes to the backend tables do
not participate in this locking protocol. Operations for different hashes may
run concurrently.

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
must be a Postgres handle.

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

=head2 deploy_schema

    $storage->deploy_schema;

Creates the required Postgres tables and indexes if they do not already exist.
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
