package Net::Blossom::Server::Backend::S3::BlobStore;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(
    client temp_dir prefix range_size multipart_threshold multipart_part_size
    generation
);
use Crypt::PRNG qw(random_bytes);
use File::Spec;
use File::Temp qw(tempfile);
use Net::Blossom::Server::Backend::S3::_Client;
use Scalar::Util qw(blessed);

my $MIB = 1024 * 1024;
my $GIB = 1024 * $MIB;

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my %known = map { $_ => 1 } qw(
        client bucket endpoint region access_key_id secret_access_key
        session_token path_style s3 timeout retry temp_dir prefix range_size
        multipart_threshold multipart_part_size generation
    );
    my @unknown = grep { !$known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    my $client = delete $args{client};
    if (defined $client) {
        for my $method (qw(upload_file head get_range delete)) {
            croak "client must provide $method"
                unless blessed($client) && $client->can($method);
        }
        my @client_args = grep {
            exists $args{$_}
        } qw(bucket endpoint region access_key_id secret_access_key session_token path_style s3 timeout retry);
        croak "client cannot be combined with S3 connection arguments"
            if @client_args;
    }
    else {
        my %client_args = map {
            exists $args{$_} ? ($_ => delete $args{$_}) : ()
        } qw(bucket endpoint region access_key_id secret_access_key session_token path_style s3 timeout retry);
        $client = Net::Blossom::Server::Backend::S3::_Client->new(%client_args);
    }

    my $temp_dir = defined $args{temp_dir} ? $args{temp_dir} : File::Spec->tmpdir;
    croak "temp_dir must be a writable directory"
        unless !ref($temp_dir) && -d $temp_dir && -w $temp_dir;

    my $prefix = defined $args{prefix} ? $args{prefix} : 'blossom';
    croak "prefix must be a scalar" if ref($prefix);
    $prefix =~ s{\A/+}{};
    $prefix =~ s{/+\z}{};
    croak "prefix contains an unsafe path segment"
        if $prefix =~ m{(?:\A|/)\.\.?\z|(?:\A|/)\.\.?/|[\x00-\x1f\x7f]};

    my $range_size = _positive_integer(
        defined $args{range_size} ? $args{range_size} : 8 * $MIB,
        'range_size',
    );
    my $multipart_threshold = _positive_integer(
        defined $args{multipart_threshold} ? $args{multipart_threshold} : 100 * $MIB,
        'multipart_threshold',
    );
    my $multipart_part_size = _positive_integer(
        defined $args{multipart_part_size} ? $args{multipart_part_size} : 16 * $MIB,
        'multipart_part_size',
    );
    croak "multipart_part_size must be at least 5 MiB"
        if $multipart_part_size < 5 * $MIB;
    croak "multipart_part_size must be at most 5 GiB"
        if $multipart_part_size > 5 * $GIB;

    my $generation = defined $args{generation}
        ? $args{generation}
        : sub { return unpack 'H*', random_bytes(16) };
    croak "generation must be a code reference" unless ref($generation) eq 'CODE';

    return {
        client              => $client,
        temp_dir            => $temp_dir,
        prefix              => $prefix,
        range_size          => $range_size,
        multipart_threshold => $multipart_threshold,
        multipart_part_size => $multipart_part_size,
        generation          => $generation,
    };
}

sub deploy_schema {
    return 1;
}

sub begin_upload {
    my ($self) = @_;
    my ($fh, $path) = tempfile(
        'net-blossom-s3-upload-XXXXXX',
        DIR    => $self->temp_dir,
        UNLINK => 0,
    );
    binmode $fh or croak "unable to binmode upload temp file: $!";
    return Net::Blossom::Server::Backend::S3::BlobStore::_Upload->new(
        store => $self,
        fh    => $fh,
        path  => $path,
    );
}

sub get_blob {
    my ($self, $storage_key, %opts) = @_;
    my $size = $self->_object_size($storage_key, $opts{size});
    return unless defined $size;
    return '' unless $size;

    return Net::Blossom::Server::Backend::S3::BlobStore::_Stream->new(
        client     => $self->client,
        storage_key => $storage_key,
        size       => $size,
        range_size => $self->range_size,
    );
}

sub get_blob_range {
    my ($self, $storage_key, %opts) = @_;
    my %known = map { $_ => 1 } qw(offset length size);
    my @unknown = grep { !$known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;
    _range_options(\%opts);

    my $size = $self->_object_size($storage_key, $opts{size});
    return unless defined $size;
    croak "range exceeds object size"
        if $opts{offset} + $opts{length} > $size;

    return Net::Blossom::Server::Backend::S3::BlobStore::_Stream->new(
        client      => $self->client,
        storage_key => $storage_key,
        size        => $opts{offset} + $opts{length},
        range_size  => $self->range_size,
        offset      => $opts{offset},
    );
}

sub _object_size {
    my ($self, $storage_key, $expected) = @_;
    my $head = $self->client->head($storage_key);
    return unless defined $head;
    croak "object head response has no size" unless defined $head->{size};
    my $size = 0 + $head->{size};
    croak "object size does not match metadata"
        if defined $expected && $size != $expected;
    return $size;
}

sub delete_blob {
    my ($self, $storage_key) = @_;
    return $self->client->delete($storage_key) ? 1 : 0;
}

sub _object_key {
    my ($self, $sha256) = @_;
    croak "sha256 must be 64 lowercase hexadecimal characters"
        unless defined $sha256 && !ref($sha256) && $sha256 =~ /\A[0-9a-f]{64}\z/;
    my $generation = $self->generation->();
    croak "generation returned an unsafe object-key segment"
        unless defined $generation
        && !ref($generation)
        && $generation =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;
    return join '/', grep { length } $self->prefix, $sha256, $generation;
}

sub _positive_integer {
    my ($value, $name) = @_;
    croak "$name must be a positive integer"
        if ref($value) || $value !~ /\A[0-9]+\z/ || $value < 1;
    return 0 + $value;
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
    package Net::Blossom::Server::Backend::S3::BlobStore::_Upload;

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
        $self->_close;

        my $size = -s $self->{path};
        croak "unable to stat upload temp file: $!" unless defined $size;
        croak "upload size does not match metadata"
            unless defined $metadata{size} && $metadata{size} == $size;
        my $storage_key = $self->{store}->_object_key($metadata{sha256});

        $self->{store}->client->upload_file(
            key                 => $storage_key,
            path                => $self->{path},
            size                => $size,
            content_type        => $metadata{type},
            sha256              => $metadata{sha256},
            multipart_threshold => $self->{store}->multipart_threshold,
            multipart_part_size => $self->{store}->multipart_part_size,
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

{
    package Net::Blossom::Server::Backend::S3::BlobStore::_Stream;

    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(client storage_key size range_size), {
        offset => 0,
        buffer => '',
        closed => 0,
    };

    sub BUILD {
        my ($self) = @_;
        $self->offset;
        $self->buffer;
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
        return 0 if $self->{offset} >= $self->{size};

        if (!length($self->{buffer}) && $self->{offset} < $self->{size}) {
            my $start = $self->{offset};
            my $end = $start + $self->{range_size} - 1;
            $end = $self->{size} - 1 if $end >= $self->{size};
            my $bytes = $self->{client}->get_range($self->{storage_key}, $start, $end);
            croak "object disappeared during ranged read" unless defined $bytes;
            my $expected = $end - $start + 1;
            croak "object range length does not match response"
                unless length($bytes) == $expected;
            $self->{buffer} = $bytes;
        }

        my $take = length($self->{buffer}) < $length
            ? length($self->{buffer})
            : $length;
        $_[1] = substr($self->{buffer}, 0, $take, '');
        $self->{offset} += $take;
        return $take;
    }

    sub getline {
        my ($self) = @_;
        my $chunk = '';
        my $read = $self->read($chunk, $self->{range_size});
        return unless $read;
        return $chunk;
    }

    sub close {
        my ($self) = @_;
        $self->{closed} = 1;
        $self->{buffer} = '';
        return 1;
    }

    sub DEMOLISH {
        my ($self) = @_;
        $self->close unless $self->{closed};
        return;
    }
}

1;

=pod

=head1 NAME

Net::Blossom::Server::Backend::S3::BlobStore - S3-compatible Blossom blob bytes

=head1 DESCRIPTION

This module implements L<Net::Blossom::Server::BlobStore> with an
S3-compatible object service. It is normally constructed by
L<Net::Blossom::Server::Backend::S3>.

Uploads use local temporary files and generation-specific object keys.
Downloads are returned as bounded range streams. A read may return fewer bytes
than requested so memory remains bounded by the configured range size.

=head1 CONSTRUCTOR

=head2 new

Accepts the S3 connection, staging, multipart, and range options documented by
L<Net::Blossom::Server::Backend::S3/new>.

C<client> may provide a custom object client. It cannot be combined with S3
connection options.

=head1 METHODS

=head2 BUILDARGS

Normalizes and validates constructor arguments for C<Class::Tiny>.

=head2 client

Returns the object client used for S3 requests.

=head2 temp_dir

Returns the upload staging directory.

=head2 prefix

Returns the object key prefix.

=head2 range_size

Returns the ranged-download chunk size in bytes.

=head2 multipart_threshold

Returns the configured multipart-upload threshold.

=head2 multipart_part_size

Returns the preferred multipart part size.

=head2 generation

Returns the callback used to create object-key generation segments.

=head2 deploy_schema

Returns true; object storage has no database schema.

=head2 begin_upload

Returns a file-backed blob upload writer.

=head2 get_blob

Returns C<''> for an empty object, a ranged stream for a nonempty object, or
C<undef> when the object is absent. When C<size> is supplied, a size mismatch
is an error.

=head2 get_blob_range

Returns a stream for the requested zero-based C<offset> and positive C<length>,
or C<undef> when the object is absent. Only the requested S3 byte ranges are
fetched. When C<size> is supplied, a size mismatch is an error.

=head2 delete_blob

Deletes an object and reports whether it existed.

=cut
