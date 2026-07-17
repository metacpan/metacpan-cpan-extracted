package Net::Blossom::Server::Backend::Filesystem;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(metadata_store blob_store base_url cleanup_error_handler);
use Net::Blossom::BlobDescriptor;
use Net::Blossom::_URL;
use Net::Blossom::Server::Backend::Filesystem::BlobStore;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::BlobStore;
use Net::Blossom::Server::MetadataStore;

our $VERSION = '0.001001';

my @BLOB_STORE_ARGS = qw(root generation);

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
    croak "blob_store cannot be combined with filesystem arguments"
        if defined $blob_store && keys %blob_args;
    $blob_store = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
        %blob_args,
    ) unless defined $blob_store;
    Net::Blossom::Server::BlobStore->assert_implements($blob_store);

    return {
        metadata_store        => $args{metadata_store},
        blob_store            => $blob_store,
        base_url              => $base_url,
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

    return Net::Blossom::Server::Backend::Filesystem::_Upload->new(
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

    $self->_delete_file($storage_key) if defined $storage_key;
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

sub _delete_file {
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
    package Net::Blossom::Server::Backend::Filesystem::_Upload;

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

Net::Blossom::Server::Backend::Filesystem - Filesystem storage for Blossom servers

=head1 SYNOPSIS

    use DBI;
    use Net::Blossom::Server;
    use Net::Blossom::Server::Backend::Filesystem;
    use Net::Blossom::Server::Backend::SQLite::MetadataStore;

    my $dbh = DBI->connect('dbi:SQLite:dbname=blossom.sqlite', '', '', {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
    });
    my $metadata = Net::Blossom::Server::Backend::SQLite::MetadataStore->new(
        dbh => $dbh,
    );
    my $storage = Net::Blossom::Server::Backend::Filesystem->new(
        metadata_store => $metadata,
        root           => '/srv/blossom',
        base_url       => 'https://cdn.example.com',
    );
    $storage->deploy_schema;

    my $server = Net::Blossom::Server->new(storage => $storage);

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::Storage> for
L<Net::Blossom::Server>. By default, blob bytes are stored in ordinary files.
Blob metadata is supplied separately through any
L<Net::Blossom::Server::MetadataStore> implementation. This distribution has
no runtime dependency on a particular metadata backend; install one
separately.

The default blob store stages uploads below C<root>, synchronizes them, and
publishes them under immutable, generation-specific keys. Blob paths are
sharded by the first four hexadecimal characters of their SHA-256 hash.
Downloads stream from open filehandles and do not load complete blobs into
memory.

=head1 CONSTRUCTOR

=head2 new

    my $storage = Net::Blossom::Server::Backend::Filesystem->new(%args);

Requires C<metadata_store> and an HTTP or HTTPS C<base_url>. Also requires
either C<root> or C<blob_store>. With the default blob store, C<root> is
converted to an absolute path and C<deploy_schema> creates the root, blob, and
staging directories when needed. The platform and filesystem must support hard
links and directory synchronization. C<root/blobs> and C<root/.staging> must be
on the same filesystem.

C<generation> may supply a callback that returns the safe filename suffix for
each new blob. The suffix must begin with an ASCII letter or digit and contain
only ASCII letters, digits, periods, underscores, or hyphens. The default is a
random 128-bit hexadecimal value. Reusing a suffix for the same hash makes the
upload fail instead of overwriting the existing file.

A custom C<blob_store> may replace the default filesystem component. It must
implement L<Net::Blossom::Server::BlobStore>. It must accept
C<< get_blob($key, size => $bytes) >> and permit deletion after the metadata
transaction commits. It cannot be combined with C<root> or C<generation>.

C<cleanup_error_handler> may provide a callback for a blob cleanup failure that
occurs after metadata commits. It receives the error and storage key. The
default handler warns.

=head1 CONSISTENCY

This section describes the default blob store. Prepared files are durable
before their storage keys enter metadata. Publishing uses a non-overwriting
hard link, so concurrent writers cannot replace an existing generation. A
metadata rollback after publication can leave an unreferenced file. With
uploads stopped, operators may remove files whose keys are absent from the
metadata store.

A process crash can leave files in C<root/.staging>. With uploads stopped, all
files in that directory may be removed.

Deletion commits metadata before unlinking the file. A cleanup failure is
reported through C<cleanup_error_handler> and may also leave an unreferenced
file. Generation-specific keys prevent delayed deletion from erasing a later
upload of the same hash.

The storage root must be writable only by trusted service processes. Files are
created with owner-only permissions. Direct external changes can violate the
backend's consistency guarantees.

=head1 SHARED FILESYSTEMS

With the default blob store, multiple processes on one host may use the same
root when all processes use the same metadata store and it serializes their
changes. This release is tested only on a local Linux filesystem. It makes no
compatibility claim for multi-node filesystems such as NFS or CephFS.

=head1 METHODS

These methods implement L<Net::Blossom::Server::Storage>.

=head2 BUILDARGS

Internal C<Class::Tiny> constructor hook.

=head2 metadata_store

Returns the configured metadata store.

=head2 blob_store

Returns the configured blob store.

=head2 base_url

Returns the public base URL without a trailing slash.

=head2 cleanup_error_handler

Returns the post-commit cleanup error callback.

=head2 deploy_schema

Deploys the blob store and metadata store.

=head2 begin_upload

Returns a streaming upload writer coordinated with the metadata store.

=head2 get_blob

Returns a L<Net::Blossom::Server::BlobResult> or C<undef> when metadata or bytes
are absent.

=head2 get_blob_range

Returns one requested byte range as a positioned, bounded file stream, or
C<undef> when metadata or bytes are absent.

=head2 head_blob

Returns a L<Net::Blossom::BlobDescriptor> from metadata without opening bytes.

=head2 delete_blob

Deletes one owner or the complete blob. Returns true when the requested record
existed.

=head2 list_blobs

Returns an array reference of descriptors in metadata-store order.

=cut
