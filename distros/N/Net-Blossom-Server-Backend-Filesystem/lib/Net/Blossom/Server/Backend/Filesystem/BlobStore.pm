package Net::Blossom::Server::Backend::Filesystem::BlobStore;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(root generation);
use Crypt::PRNG qw(random_bytes);
use Errno qw(EEXIST ENOENT);
use Fcntl qw(O_RDONLY SEEK_SET);
use File::Path qw(make_path);
use File::Spec;
use File::Sync qw(fsync);
use File::Temp qw(tempfile);
use IO::Handle;

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my %known = map { $_ => 1 } qw(root generation);
    my @unknown = grep { !$known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "root is required"
        unless defined $args{root} && !ref($args{root}) && length $args{root};
    croak "root contains unsafe characters" if $args{root} =~ /\0/;
    my $root = File::Spec->rel2abs($args{root});

    my $generation = defined $args{generation}
        ? $args{generation}
        : sub { return unpack 'H*', random_bytes(16) };
    croak "generation must be a code reference" unless ref($generation) eq 'CODE';

    return {
        root       => $root,
        generation => $generation,
    };
}

sub deploy_schema {
    my ($self) = @_;
    my @created = _ensure_directory($self->root, 'root');
    _sync_directory(_parent_directory($_)) for @created;
    _sync_directory($self->root)
        if _ensure_directory($self->_blob_dir, 'blob');
    _sync_directory($self->root)
        if _ensure_directory($self->_staging_dir, 'staging');
    return 1;
}

sub begin_upload {
    my ($self) = @_;
    my $staging = $self->_staging_dir;
    croak "filesystem staging directory is not deployed" unless -d $staging;
    my ($fh, $path) = tempfile(
        'net-blossom-filesystem-upload-XXXXXX',
        DIR    => $staging,
        UNLINK => 0,
    );
    binmode $fh or croak "unable to binmode upload staging file: $!";
    return Net::Blossom::Server::Backend::Filesystem::BlobStore::_Upload->new(
        store => $self,
        fh    => $fh,
        path  => $path,
    );
}

sub get_blob {
    my ($self, $storage_key, %opts) = @_;
    my ($fh, $size) = $self->_open_blob($storage_key, %opts);
    return unless defined $fh;
    if (!$size) {
        close $fh or croak "unable to close filesystem object: $!";
        return '';
    }

    return Net::Blossom::Server::Backend::Filesystem::BlobStore::_Stream->new(
        fh   => $fh,
        size => $size,
    );
}

sub get_blob_range {
    my ($self, $storage_key, %opts) = @_;
    my %known = map { $_ => 1 } qw(offset length size);
    my @unknown = grep { !$known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;
    _range_options(\%opts);

    my ($fh, $size) = $self->_open_blob(
        $storage_key,
        (defined $opts{size} ? (size => $opts{size}) : ()),
    );
    return unless defined $fh;
    croak "range exceeds file size"
        if $opts{offset} + $opts{length} > $size;
    seek($fh, $opts{offset}, SEEK_SET)
        or croak "unable to seek filesystem object: $!";

    return Net::Blossom::Server::Backend::Filesystem::BlobStore::_Stream->new(
        fh        => $fh,
        size      => $size,
        remaining => $opts{length},
    );
}

sub _open_blob {
    my ($self, $storage_key, %opts) = @_;
    my $path = $self->_path_for_key($storage_key);
    sysopen my $fh, $path, O_RDONLY or do {
        return if $! == ENOENT;
        croak "unable to open filesystem object: $!";
    };
    binmode $fh or croak "unable to binmode filesystem object: $!";
    croak "filesystem object is not a regular file" unless -f $fh;
    my $size = -s $fh;
    croak "unable to stat filesystem object: $!" unless defined $size;
    croak "file size does not match metadata"
        if defined $opts{size} && $size != $opts{size};
    return ($fh, $size);
}

sub delete_blob {
    my ($self, $storage_key) = @_;
    my $path = $self->_path_for_key($storage_key);
    if (!unlink $path) {
        return 0 if $! == ENOENT;
        croak "unable to delete filesystem object: $!";
    }
    _sync_directory(_parent_directory($path));
    return 1;
}

sub _storage_key {
    my ($self, $sha256) = @_;
    croak "sha256 must be 64 lowercase hexadecimal characters"
        unless defined $sha256 && !ref($sha256)
        && $sha256 =~ /\A[0-9a-f]{64}\z/;
    my $generation = $self->generation->();
    croak "generation returned an unsafe filesystem path segment"
        unless defined $generation
        && !ref($generation)
        && $generation =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;

    return join '/', substr($sha256, 0, 2), substr($sha256, 2, 2),
        "$sha256-$generation";
}

sub _path_for_key {
    my ($self, $storage_key) = @_;
    croak "invalid filesystem storage key"
        unless defined $storage_key && !ref($storage_key);
    my ($first, $second, $sha256) = $storage_key =~ m{
        \A([0-9a-f]{2})/([0-9a-f]{2})/
        ([0-9a-f]{64})-[A-Za-z0-9][A-Za-z0-9._-]*\z
    }x;
    croak "invalid filesystem storage key" unless defined $sha256;
    croak "invalid filesystem storage key"
        unless $first eq substr($sha256, 0, 2)
        && $second eq substr($sha256, 2, 2);
    return File::Spec->catfile($self->_blob_dir, split m{/}, $storage_key);
}

sub _publish {
    my ($self, $staging_path, $storage_key) = @_;
    my $path = $self->_path_for_key($storage_key);
    my $parent = $self->_ensure_blob_shards($storage_key);

    if (!link $staging_path, $path) {
        croak "filesystem object already exists" if $! == EEXIST;
        croak "unable to publish filesystem object: $!";
    }
    _sync_directory($parent);
    unlink $staging_path
        or croak "unable to remove upload staging file: $!";
    _sync_directory($self->_staging_dir);
    return 1;
}

sub _ensure_blob_shards {
    my ($self, $storage_key) = @_;
    my ($first, $second) = split m{/}, $storage_key;
    my $first_path = File::Spec->catdir($self->_blob_dir, $first);
    _sync_directory($self->_blob_dir)
        if _ensure_directory($first_path, 'blob shard');
    my $second_path = File::Spec->catdir($first_path, $second);
    _sync_directory($first_path)
        if _ensure_directory($second_path, 'blob shard');
    return $second_path;
}

sub _blob_dir {
    my ($self) = @_;
    return File::Spec->catdir($self->root, 'blobs');
}

sub _staging_dir {
    my ($self) = @_;
    return File::Spec->catdir($self->root, '.staging');
}

sub _ensure_directory {
    my ($path, $name) = @_;
    my @created;
    if (!-e $path) {
        eval { @created = make_path($path); 1 }
            or croak "unable to create $name directory: $@";
    }
    croak "$name path is not a directory" unless -d $path;
    croak "$name directory is not writable" unless -w $path;
    return wantarray ? @created : @created ? 1 : 0;
}

sub _sync_directory {
    my ($path) = @_;
    sysopen my $fh, $path, O_RDONLY
        or croak "unable to open filesystem directory for sync: $!";
    fsync($fh) or croak "unable to sync filesystem directory: $!";
    close $fh or croak "unable to close filesystem directory: $!";
    return 1;
}

sub _parent_directory {
    my ($path) = @_;
    my ($volume, $directories) = File::Spec->splitpath($path);
    return File::Spec->catpath($volume, $directories, '');
}

sub _constructor_args {
    return %{$_[0]} if @_ == 1 && ref($_[0]) eq 'HASH';
    croak "constructor arguments must be name/value pairs" if @_ % 2;
    return @_;
}

sub _range_options {
    my ($opts) = @_;
    croak "offset must be a non-negative integer"
        unless defined $opts->{offset}
        && !ref($opts->{offset})
        && $opts->{offset} =~ /\A[0-9]+\z/;
    croak "length must be a positive integer"
        unless defined $opts->{length}
        && !ref($opts->{length})
        && $opts->{length} =~ /\A[1-9][0-9]*\z/;
    return;
}

{
    package Net::Blossom::Server::Backend::Filesystem::BlobStore::_Upload;

    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(store fh path storage_key), {
        prepared  => 0,
        committed => 0,
        aborted   => 0,
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
        $self->_sync_and_close;

        my $size = -s $self->{path};
        croak "unable to stat upload staging file: $!" unless defined $size;
        croak "upload size does not match metadata"
            unless defined $metadata{size} && $metadata{size} == $size;
        my $storage_key = $self->{store}->_storage_key($metadata{sha256});
        $self->{store}->_publish($self->{path}, $storage_key);

        $self->{path} = undef;
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
        if (defined $self->{path} && -e $self->{path}) {
            unlink $self->{path}
                or croak "unable to remove upload staging file: $!";
            Net::Blossom::Server::Backend::Filesystem::BlobStore::_sync_directory(
                $self->{store}->_staging_dir,
            );
        }
        $self->{path} = undef;
        return 1;
    }

    sub _sync_and_close {
        my ($self) = @_;
        return 1 unless defined $self->{fh};
        $self->{fh}->flush or croak "unable to flush upload staging file: $!";
        $self->{fh}->sync or croak "unable to sync upload staging file: $!";
        return $self->_close;
    }

    sub _close {
        my ($self) = @_;
        return 1 unless defined $self->{fh};
        close $self->{fh} or croak "unable to close upload staging file: $!";
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
    package Net::Blossom::Server::Backend::Filesystem::BlobStore::_Stream;

    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(fh size remaining), { closed => 0 };

    sub BUILD {
        my ($self) = @_;
        $self->closed;
        return;
    }

    sub read {
        my ($self, undef, $length) = @_;
        croak "stream is closed" if $self->{closed};
        croak "read length must be a non-negative integer"
            if !defined $length || ref($length) || $length !~ /\A[0-9]+\z/;
        $_[1] = '';
        return 0 unless $length;
        return 0 if defined $self->{remaining} && !$self->{remaining};
        $length = $self->{remaining}
            if defined $self->{remaining} && $length > $self->{remaining};
        my $read = CORE::read($self->{fh}, $_[1], $length);
        croak "unable to read filesystem object: $!" unless defined $read;
        croak "filesystem range ended before requested length"
            if defined $self->{remaining} && !$read;
        $self->{remaining} -= $read if defined $self->{remaining};
        return $read;
    }

    sub getline {
        my ($self) = @_;
        my $chunk = '';
        my $read = $self->read($chunk, 8192);
        return unless $read;
        return $chunk;
    }

    sub close {
        my ($self) = @_;
        return 1 if $self->{closed};
        close $self->{fh} or croak "unable to close filesystem object: $!";
        $self->{closed} = 1;
        $self->{fh} = undef;
        return 1;
    }

    sub DEMOLISH {
        my ($self) = @_;
        eval { $self->close } unless $self->{closed};
        return;
    }
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Backend::Filesystem::BlobStore - Blossom blob files

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::BlobStore> using ordinary files.
It is normally constructed by
L<Net::Blossom::Server::Backend::Filesystem>.

Files use generation-specific, hash-sharded paths below C<root/blobs>. Uploads
are staged below C<root/.staging>, synchronized, and atomically hard-linked into
place without overwriting an existing file.

=head1 CONSTRUCTOR

=head2 new

    my $blobs = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
        root => '/srv/blossom',
    );

Requires C<root>. C<generation> may provide a callback for generation filename
suffixes; it defaults to random 128-bit hexadecimal values. A suffix must begin
with an ASCII letter or digit and contain only ASCII letters, digits, periods,
underscores, or hyphens. Reusing a suffix for the same hash makes C<prepare>
fail instead of overwriting the existing file.

The platform and filesystem must support hard links and directory
synchronization. C<root/blobs> and C<root/.staging> must be on the same
filesystem.

=head1 METHODS

=head2 BUILDARGS

Internal C<Class::Tiny> constructor hook.

=head2 root

Returns the absolute filesystem root.

=head2 generation

Returns the callback used to create generation filename suffixes.

=head2 deploy_schema

Creates the root, blob, and staging directories. Repeated calls are safe.

=head2 begin_upload

Returns a file-backed upload writer.

=head2 get_blob

Returns C<''> for an empty file, a stream for a nonempty file, or C<undef> when
the file is absent. When C<size> is supplied, a size mismatch is an error.

=head2 get_blob_range

Returns a bounded stream for the requested zero-based C<offset> and positive
C<length>, or C<undef> when the file is absent. The stream starts at C<offset>
and ends after C<length> bytes. When C<size> is supplied, a size mismatch is an
error.

=head2 delete_blob

Deletes one file and reports whether it existed.

=cut
