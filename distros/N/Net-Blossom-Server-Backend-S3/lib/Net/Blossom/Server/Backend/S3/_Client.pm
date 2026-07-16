package Net::Blossom::Server::Backend::S3::_Client;

use strictures 2;

use Carp qw(croak);
use Class::Tiny qw(bucket);
use Net::Amazon::S3 0.992;
use Net::Amazon::S3::Client;
use Net::Amazon::S3::Signature::V4;
use Net::Amazon::S3::Vendor::Generic;
use Scalar::Util qw(blessed);
use URI;

my $MIB = 1024 * 1024;
my $GIB = 1024 * $MIB;
my $GB = 1_000_000_000;
my $MAX_PARTS = 10_000;
my $MAX_PART_SIZE = 5 * $GIB;
my $MAX_OBJECT_SIZE = $MAX_PARTS * $MAX_PART_SIZE;
my $MAX_SINGLE_PUT = 5 * $GB;

sub BUILDARGS {
    my $class = shift;
    my %args = _constructor_args(@_);
    my %known = map { $_ => 1 } qw(
        bucket bucket_object endpoint region access_key_id secret_access_key
        session_token path_style s3 timeout retry
    );
    my @unknown = grep { !$known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    if (defined $args{bucket_object}) {
        my @other = grep { exists $args{$_} && $_ ne 'bucket_object' } keys %args;
        croak "bucket_object cannot be combined with connection arguments" if @other;
        croak "bucket_object must provide object"
            unless blessed($args{bucket_object}) && $args{bucket_object}->can('object');
        return {bucket => $args{bucket_object}};
    }

    croak "bucket is required"
        unless defined $args{bucket} && !ref($args{bucket}) && length $args{bucket};
    my $s3 = delete $args{s3};
    if (defined $s3) {
        my @connection_args = grep { exists $args{$_} } qw(
            endpoint region access_key_id secret_access_key session_token
            path_style timeout retry
        );
        croak "s3 cannot be combined with connection arguments"
            if @connection_args;
        croak "s3 must be a Net::Amazon::S3 object"
            unless blessed($s3) && $s3->isa('Net::Amazon::S3');
    }
    else {
        $s3 = _build_s3(%args);
    }

    my $client = Net::Amazon::S3::Client->new(s3 => $s3);
    return {bucket => $client->bucket(name => $args{bucket})};
}

sub upload_file {
    my ($self, %args) = @_;
    croak "S3 object size exceeds multipart limit"
        if $args{size} > $MAX_OBJECT_SIZE;
    croak "multipart part size exceeds 5 GiB"
        if $args{multipart_part_size} > $MAX_PART_SIZE;
    return $args{size} < $args{multipart_threshold}
        && $args{size} <= $MAX_SINGLE_PUT
        ? $self->_put_file(%args)
        : $self->_multipart_put_file(%args);
}

sub head {
    my ($self, $key) = @_;
    my $response = $self->_object($key)->_perform_operation(
        'Net::Amazon::S3::Operation::Object::Head',
    );
    return if $response->code == 404;
    _assert_success('S3 HEAD', $response);
    my $size = $response->http_response->header('Content-Length');
    croak "S3 HEAD response has no Content-Length"
        unless defined $size;
    return {size => 0 + $size};
}

sub get_range {
    my ($self, $key, $start, $end) = @_;
    my $response = $self->_object($key)->range("bytes=$start-$end")->_get;
    return if $response->code == 404;
    _assert_success('S3 ranged GET', $response);
    return $response->content;
}

sub delete {
    my ($self, $key) = @_;
    return 0 unless defined $self->head($key);
    my $response = $self->_object($key)->_perform_operation(
        'Net::Amazon::S3::Operation::Object::Delete',
    );
    _assert_success('S3 DELETE', $response);
    return 1;
}

sub _put_file {
    my ($self, %args) = @_;
    my $object = $self->_object(
        $args{key},
        content_type => $args{content_type},
        user_metadata => {sha256 => $args{sha256}},
        size => $args{size},
    );
    $object->put_filename($args{path});
    return 1;
}

sub _multipart_put_file {
    my ($self, %args) = @_;
    my $object = $self->_object($args{key});
    my $part_size = _part_size_for($args{size}, $args{multipart_part_size});
    my $upload_id;
    my (@etags, @part_numbers);

    my $ok = eval {
        $upload_id = $object->initiate_multipart_upload(headers => {
            'Content-Type'        => $args{content_type},
            'x-amz-meta-sha256'   => $args{sha256},
        });
        croak "S3 did not return a multipart upload ID" unless defined $upload_id;

        open my $fh, '<:raw', $args{path}
            or croak "unable to read upload temp file: $!";
        my $part_number = 0;
        while (1) {
            my $part = '';
            my $bytes = read $fh, $part, $part_size;
            croak "unable to read upload temp file: $!" unless defined $bytes;
            last unless $bytes;
            ++$part_number;
            my $response = $object->put_part(
                upload_id   => $upload_id,
                part_number => $part_number,
                value       => $part,
                headers     => {},
            );
            croak "S3 multipart part $part_number failed: " . $response->status_line
                unless $response->is_success;
            my $etag = $response->header('ETag');
            croak "S3 multipart part $part_number returned no ETag"
                unless defined $etag && length $etag;
            push @etags, $etag;
            push @part_numbers, $part_number;
        }
        close $fh or croak "unable to close upload temp file: $!";

        my $response = $object->_perform_operation(
            'Net::Amazon::S3::Operation::Object::Upload::Complete',
            upload_id    => $upload_id,
            etags        => \@etags,
            part_numbers => \@part_numbers,
        );
        _assert_success('S3 multipart completion', $response);
        1;
    };
    my $error = $@;

    if (!$ok) {
        eval {
            $object->abort_multipart_upload(upload_id => $upload_id)
                if defined $upload_id;
        };
        die $error;
    }
    return 1;
}

sub _object {
    my ($self, $key, %args) = @_;
    return $self->bucket->object(key => $key, %args);
}

sub _part_size_for {
    my ($size, $preferred) = @_;
    my $minimum = int(($size + $MAX_PARTS - 1) / $MAX_PARTS);
    my $part_size = $preferred > $minimum ? $preferred : $minimum;
    $part_size = 5 * $MIB if $part_size < 5 * $MIB;
    return $part_size;
}

sub _assert_success {
    my ($action, $response) = @_;
    my $embedded_error = $response->is_success
        && $response->can('is_error')
        && $response->is_error;
    return 1 if $response->is_success && !$embedded_error;

    my $detail = $embedded_error && $response->can('error_code')
        ? $response->error_code
        : $response->status_line;
    croak "$action failed: $detail";
}

sub _build_s3 {
    my %args = @_;
    my $region = defined $args{region} ? $args{region} : 'us-east-1';
    croak "region must be a non-empty scalar"
        if ref($region) || !length $region;
    croak "region contains unsafe characters"
        unless $region =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;
    my ($host, $use_https, $custom_endpoint) = _endpoint(
        $args{endpoint},
        $region,
    );
    my $path_style = defined $args{path_style}
        ? _boolean($args{path_style}, 'path_style')
        : $custom_endpoint;
    my $retry = defined $args{retry}
        ? _boolean($args{retry}, 'retry')
        : 1;

    my $access_key_id = defined $args{access_key_id}
        ? $args{access_key_id}
        : $ENV{AWS_ACCESS_KEY_ID};
    my $secret_access_key = defined $args{secret_access_key}
        ? $args{secret_access_key}
        : $ENV{AWS_SECRET_ACCESS_KEY};
    my $session_token = defined $args{session_token}
        ? $args{session_token}
        : $ENV{AWS_SESSION_TOKEN};
    croak "access_key_id or AWS_ACCESS_KEY_ID is required"
        unless defined $access_key_id && !ref($access_key_id) && length $access_key_id;
    croak "secret_access_key or AWS_SECRET_ACCESS_KEY is required"
        unless defined $secret_access_key && !ref($secret_access_key) && length $secret_access_key;
    croak "session_token must be a non-empty scalar"
        if defined $session_token && (ref($session_token) || !length $session_token);

    my $vendor = Net::Amazon::S3::Vendor::Generic->new(
        host                 => $host,
        use_https            => $use_https,
        use_virtual_host     => !$path_style,
        authorization_method => 'Net::Amazon::S3::Signature::V4',
        default_region       => $region,
    );
    return Net::Amazon::S3->new(
        vendor                => $vendor,
        aws_access_key_id     => $access_key_id,
        aws_secret_access_key => $secret_access_key,
        (defined $session_token ? (aws_session_token => $session_token) : ()),
        timeout => defined $args{timeout} ? $args{timeout} : 30,
        retry   => $retry,
    );
}

sub _endpoint {
    my ($endpoint, $region) = @_;
    if (!defined $endpoint) {
        my $host = $region eq 'us-east-1'
            ? 's3.amazonaws.com'
            : "s3.$region.amazonaws.com";
        return ($host, 1, 0);
    }

    croak "endpoint must be a scalar" if ref($endpoint);
    my $uri = URI->new($endpoint);
    croak "endpoint must be an HTTP URL with a host"
        unless ($uri->scheme || '') =~ /\Ahttps?\z/
        && defined $uri->host
        && length $uri->host;
    croak "endpoint cannot contain userinfo, query, or fragment"
        if defined $uri->userinfo || defined $uri->query || defined $uri->fragment;
    croak "endpoint cannot contain a path"
        if defined $uri->path && $uri->path ne '' && $uri->path ne '/';
    croak "endpoint contains unsafe characters"
        if $endpoint =~ /[\x00-\x20\x7f]/;
    my $authority = $uri->authority;
    my $port;
    if ($authority =~ /\A\[[^\]]+\](?::([^:]+))?\z/) {
        $port = $1;
    }
    elsif ($authority =~ /\A[^:]+(?::([^:]+))?\z/) {
        $port = $1;
    }
    else {
        croak "endpoint authority is invalid";
    }
    if (defined $port) {
        croak "endpoint must use a numeric port" unless $port =~ /\A[0-9]+\z/;
        croak "endpoint port must be between 1 and 65535"
            if $port < 1 || $port > 65_535;
    }
    return ($authority, $uri->scheme eq 'https' ? 1 : 0, 1);
}

sub _boolean {
    my ($value, $name) = @_;
    croak "$name must be 0 or 1"
        if ref($value) || $value !~ /\A[01]\z/;
    return 0 + $value;
}

sub _constructor_args {
    return %{$_[0]} if @_ == 1 && ref($_[0]) eq 'HASH';
    croak "constructor arguments must be name/value pairs" if @_ % 2;
    return @_;
}

1;
