package Net::Blossom::Server;

use strictures 2;

use Net::Blossom ();
use Net::Blossom::BlobDescriptor;
use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::Server::AuthorizationResult;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::Error;
use Net::Blossom::Server::Request;
use Net::Blossom::Server::Response;
use Net::Blossom::Server::Storage;
use Net::Blossom::Server::UploadResult;

use Carp qw(croak);
use Class::Tiny qw(storage chunk_size clock mirror_fetcher max_upload_bytes max_list_limit);
use Digest::SHA ();
use JSON ();
use Scalar::Util qw(blessed);
use URI ();

our $VERSION = '0.001000';

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my $JSON = JSON->new->utf8;
my $MAX_MIRROR_REQUEST_BYTES = 65536;
my $DEFAULT_MAX_LIST_LIMIT = 100;

# Content types a browser renders as active content (can execute script) when
# served inline. Blobs are attacker-supplied, so these are sent as downloads
# rather than rendered in the origin's security context. Everything else
# (images, audio, video, PDF, plain text, octet-stream) is left inline, which
# BUD-01 relies on for blobs to be "correctly displayed by clients".
my %ATTACHMENT_ONLY_TYPES = map { $_ => 1 } qw(
    text/html
    application/xhtml+xml
    image/svg+xml
    application/xml
    text/xml
);

sub _blob_response_headers {
    my ($descriptor) = @_;

    my %headers = (
        'Content-Type'   => $descriptor->type,
        'Content-Length' => $descriptor->size,

        # Do not let the browser second-guess the declared type: a blob served
        # as text/plain or application/octet-stream must not be sniffed into
        # HTML and executed.
        'X-Content-Type-Options' => 'nosniff',
    );

    my $type = $descriptor->type;
    if (defined $type) {
        (my $base = lc $type) =~ s/;.*//s;    # drop parameters like "; charset=utf-8"
        $base =~ s/\s+//g;
        $headers{'Content-Disposition'} = 'attachment' if $ATTACHMENT_ONLY_TYPES{$base};
    }

    return \%headers;
}

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(storage chunk_size clock mirror_fetcher max_upload_bytes max_list_limit);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    Net::Blossom::Server::Storage->assert_implements($args{storage});

    croak "max_upload_bytes must be a positive integer"
        if defined $args{max_upload_bytes}
        && (ref($args{max_upload_bytes}) || $args{max_upload_bytes} !~ /\A[1-9][0-9]*\z/);

    $args{max_list_limit} = $DEFAULT_MAX_LIST_LIMIT unless defined $args{max_list_limit};
    croak "max_list_limit must be a positive integer"
        if ref($args{max_list_limit}) || $args{max_list_limit} !~ /\A[1-9][0-9]*\z/;

    $args{chunk_size} = 65536 unless defined $args{chunk_size};
    croak "chunk_size must be a positive integer"
        unless !ref($args{chunk_size}) && $args{chunk_size} =~ /\A[1-9][0-9]*\z/;

    $args{clock} = sub { time } unless defined $args{clock};
    croak "clock must be a code reference" unless ref($args{clock}) eq 'CODE';

    croak "mirror_fetcher must be a code reference or object with fetch_blob"
        if defined $args{mirror_fetcher}
        && !(ref($args{mirror_fetcher}) eq 'CODE'
            || (blessed($args{mirror_fetcher}) && $args{mirror_fetcher}->can('fetch_blob')));

    return bless \%args, $class;
}

sub receive_blob {
    my $self = shift;
    my ($body, %opts) = @_;
    my %known = map { $_ => 1 } qw(
        type expected_sha256 allowed_sha256 content_length uploaded pubkey
        sha256_mismatch_status sha256_mismatch_reason
        content_length_mismatch_status content_length_mismatch_reason
    );
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "body is required" unless defined $body;
    _validate_body($body);

    my $type = defined $opts{type} ? $opts{type} : 'application/octet-stream';
    croak "type must be a scalar" if ref($type);
    croak "type is required" unless length $type;

    if (defined $opts{expected_sha256}) {
        croak "expected_sha256 must be 64-char lowercase hex"
            unless !ref($opts{expected_sha256}) && $opts{expected_sha256} =~ $HEX64;
    }
    _validate_allowed_sha256($opts{allowed_sha256}) if defined $opts{allowed_sha256};

    _validate_content_length($opts{content_length}) if defined $opts{content_length};
    _validate_uploaded($opts{uploaded}) if defined $opts{uploaded};
    _validate_pubkey($opts{pubkey}) if defined $opts{pubkey};
    _validate_http_status($opts{sha256_mismatch_status}, 'sha256_mismatch_status')
        if defined $opts{sha256_mismatch_status};
    croak "sha256_mismatch_reason must be a scalar"
        if defined $opts{sha256_mismatch_reason} && ref($opts{sha256_mismatch_reason});
    _validate_http_status($opts{content_length_mismatch_status}, 'content_length_mismatch_status')
        if defined $opts{content_length_mismatch_status};
    croak "content_length_mismatch_reason must be a scalar"
        if defined $opts{content_length_mismatch_reason} && ref($opts{content_length_mismatch_reason});

    my %upload_context = (type => $type);
    $upload_context{expected_sha256} = $opts{expected_sha256} if defined $opts{expected_sha256};
    $upload_context{allowed_sha256} = [@{$opts{allowed_sha256}}] if defined $opts{allowed_sha256};
    $upload_context{content_length} = $opts{content_length} if defined $opts{content_length};
    $upload_context{pubkey} = $opts{pubkey} if defined $opts{pubkey};

    my $upload = $self->storage->begin_upload(%upload_context);
    Net::Blossom::Server::Storage->assert_upload($upload);

    my $sha = Digest::SHA->new(256);
    my $size = 0;
    my $ok = eval {
        $size = $self->_copy_body_to_upload($body, $upload, $sha);
        _content_length_mismatch(%opts)
            if defined $opts{content_length} && $size != $opts{content_length};

        my $sha256 = $sha->hexdigest;
        _sha256_mismatch(%opts)
            if defined $opts{expected_sha256} && $sha256 ne $opts{expected_sha256};
        _sha256_mismatch(%opts, default_reason => 'sha256 is not allowed')
            if defined $opts{allowed_sha256}
            && !grep { $_ eq $sha256 } @{$opts{allowed_sha256}};

        my $uploaded = defined $opts{uploaded} ? $opts{uploaded} : $self->clock->();
        my %commit_metadata = (
            sha256   => $sha256,
            size     => $size,
            type     => $type,
            uploaded => $uploaded,
        );
        $commit_metadata{pubkey} = $opts{pubkey} if defined $opts{pubkey};

        my $result = _upload_result_from_commit($upload->commit(%commit_metadata));
        _validate_committed_descriptor($result->descriptor, $sha256, $size, $type);
        $result;
    };

    if (!$ok) {
        my $error = $@;
        eval { $upload->abort };
        die $error;
    }

    return $ok;
}

sub handle_upload {
    my $self = shift;
    my ($request, %opts) = @_;
    my %known = map { $_ => 1 } qw(pubkey);
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "upload request method must be PUT" unless $request->method eq 'PUT';
    croak "upload request path must be /upload" unless $request->path eq '/upload';
    croak "upload request body is required" unless defined $request->body;

    my %upload_opts;
    $upload_opts{type} = $request->content_type if defined $request->content_type;
    if (defined $request->content_length) {
        $upload_opts{content_length} = $request->content_length;
        $upload_opts{content_length_mismatch_status} = 400;
        $upload_opts{content_length_mismatch_reason} = 'content_length mismatch';
    }
    $upload_opts{pubkey} = $opts{pubkey} if defined $opts{pubkey};
    if (defined(my $expected_sha256 = _optional_sha256_header($request))) {
        $upload_opts{expected_sha256} = $expected_sha256;
        $upload_opts{sha256_mismatch_status} = 409;
        $upload_opts{sha256_mismatch_reason} = 'sha256 mismatch';
    }

    my $result = $self->receive_blob($request->body, %upload_opts);
    return Net::Blossom::Server::Response->json(
        $result->descriptor->to_hash,
        status => $result->created ? 201 : 200,
    );
}

sub handle_head_upload {
    my $self = shift;
    my ($request, %opts) = @_;
    my @unknown = keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "upload preflight method must be HEAD" unless $request->method eq 'HEAD';
    croak "upload preflight path must be /upload" unless $request->path eq '/upload';

    my $error = _preflight_error($request);
    return $error if defined $error;
    return Net::Blossom::Server::Response->empty(200);
}

sub handle_get_blob {
    my $self = shift;
    my ($request, %opts) = @_;
    my @unknown = keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "blob request method must be GET" unless $request->method eq 'GET';

    my $sha256 = _sha256_from_blob_path($request->path, allow_extension => 1);
    my $result = $self->storage->get_blob($sha256);
    return Net::Blossom::Server::Response->empty(404) unless defined $result;

    croak "storage get_blob must return a Net::Blossom::Server::BlobResult"
        unless blessed($result) && $result->isa('Net::Blossom::Server::BlobResult');
    my $descriptor = $result->descriptor;
    croak "storage returned descriptor sha256 mismatch" unless $descriptor->sha256 eq $sha256;

    return Net::Blossom::Server::Response->new(
        status  => 200,
        headers => _blob_response_headers($descriptor),
        body    => $result->body,
    );
}

sub handle_head_blob {
    my $self = shift;
    my ($request, %opts) = @_;
    my @unknown = keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "blob head request method must be HEAD" unless $request->method eq 'HEAD';

    my $sha256 = _sha256_from_blob_path($request->path, allow_extension => 1);
    my $descriptor;
    if ($self->storage->can('head_blob')) {
        my $result = $self->storage->head_blob($sha256);
        return Net::Blossom::Server::Response->empty(404) unless defined $result;
        $descriptor = _descriptor_from_head_result($result);
    }
    else {
        my $result = $self->storage->get_blob($sha256);
        return Net::Blossom::Server::Response->empty(404) unless defined $result;
        croak "storage get_blob must return a Net::Blossom::Server::BlobResult"
            unless blessed($result) && $result->isa('Net::Blossom::Server::BlobResult');
        $descriptor = $result->descriptor;
    }

    croak "storage returned descriptor sha256 mismatch" unless $descriptor->sha256 eq $sha256;

    return Net::Blossom::Server::Response->new(
        status  => 200,
        headers => _blob_response_headers($descriptor),
        body    => '',
    );
}

sub handle_media {
    my $self = shift;
    my ($request, %opts) = @_;
    my %known = map { $_ => 1 } qw(pubkey);
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "media request method must be PUT" unless $request->method eq 'PUT';
    croak "media request path must be /media" unless $request->path eq '/media';
    croak "media request body is required" unless defined $request->body;

    my %upload_opts;
    $upload_opts{type} = $request->content_type if defined $request->content_type;
    if (defined $request->content_length) {
        $upload_opts{content_length} = $request->content_length;
        $upload_opts{content_length_mismatch_status} = 400;
        $upload_opts{content_length_mismatch_reason} = 'content_length mismatch';
    }
    $upload_opts{pubkey} = $opts{pubkey} if defined $opts{pubkey};
    if (defined(my $expected_sha256 = _optional_sha256_header($request))) {
        $upload_opts{expected_sha256} = $expected_sha256;
        $upload_opts{sha256_mismatch_status} = 409;
        $upload_opts{sha256_mismatch_reason} = 'sha256 mismatch';
    }

    my $result = $self->receive_blob($request->body, %upload_opts);
    return Net::Blossom::Server::Response->json(
        $result->descriptor->to_hash,
        status => $result->created ? 201 : 200,
    );
}

sub handle_head_media {
    my $self = shift;
    my ($request, %opts) = @_;
    my @unknown = keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "media preflight method must be HEAD" unless $request->method eq 'HEAD';
    croak "media preflight path must be /media" unless $request->path eq '/media';

    my $error = _preflight_error($request);
    return $error if defined $error;
    return Net::Blossom::Server::Response->empty(200);
}

sub handle_mirror {
    my $self = shift;
    my ($request, %opts) = @_;
    my %known = map { $_ => 1 } qw(pubkey authorization);
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "mirror request method must be PUT" unless $request->method eq 'PUT';
    croak "mirror request path must be /mirror" unless $request->path eq '/mirror';
    croak "mirror request body is required" unless defined $request->body;
    croak "authorization must be a Net::Blossom::Server::AuthorizationResult"
        if defined $opts{authorization}
        && !(blessed($opts{authorization}) && $opts{authorization}->isa('Net::Blossom::Server::AuthorizationResult'));

    return Net::Blossom::Server::Response->error(503, 'Mirror service unavailable')
        unless defined $self->mirror_fetcher;

    my $content = eval { _body_to_scalar($request->body, $MAX_MIRROR_REQUEST_BYTES) };
    return _typed_error_response($@) if blessed($@) && $@->isa('Net::Blossom::Server::Error');
    die $@ if $@;

    my $data = eval { $JSON->decode($content) };
    return Net::Blossom::Server::Response->error(400, 'Malformed mirror request')
        if $@ || ref($data) ne 'HASH';
    return Net::Blossom::Server::Response->error(400, 'Invalid mirror URL')
        unless exists $data->{url} && defined $data->{url} && !ref($data->{url}) && length $data->{url}
        && _valid_mirror_url($data->{url});

    my %upload_opts = (
        content_length_mismatch_status => 502,
        content_length_mismatch_reason => 'origin content length mismatch',
    );
    $upload_opts{pubkey} = $opts{pubkey} if defined $opts{pubkey};
    if (defined $opts{authorization}) {
        $upload_opts{allowed_sha256} = $opts{authorization}->hashes;
        $upload_opts{sha256_mismatch_status} = 409;
        $upload_opts{sha256_mismatch_reason} = 'mirrored blob hash is not authorized';
    }

    my $sink = Net::Blossom::Server::_MirrorSink->new(
        server => $self,
        opts   => \%upload_opts,
    );
    my $metadata = eval {
        _mirror_fetch_metadata(
            _fetch_mirror_blob($self->mirror_fetcher, $data->{url}, sink => $sink),
        );
    };
    if ($@) {
        my $error = $@;
        eval { $sink->abort };
        return $error->as_response
            if blessed($error) && $error->isa('Net::Blossom::Server::Error');
        return Net::Blossom::Server::Response->error(502, 'Origin fetch failed');
    }

    $sink->start(%$metadata) unless $sink->started;
    my $result = eval { $sink->finish };
    if (!$result) {
        my $error = $@;
        eval { $sink->abort };
        die $error;
    }

    return Net::Blossom::Server::Response->json(
        $result->descriptor->to_hash,
        status => $result->created ? 201 : 200,
    );
}

sub handle_delete_blob {
    my $self = shift;
    my ($request, %opts) = @_;
    my %known = map { $_ => 1 } qw(pubkey);
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "delete request method must be DELETE" unless $request->method eq 'DELETE';
    croak "pubkey is required" unless defined $opts{pubkey};
    _validate_pubkey($opts{pubkey});

    my $sha256 = _sha256_from_blob_path($request->path);
    my $deleted = $self->storage->delete_blob($sha256, pubkey => $opts{pubkey});
    return Net::Blossom::Server::Response->empty(404) unless $deleted;
    return Net::Blossom::Server::Response->empty(204);
}

sub handle_list_blobs {
    my $self = shift;
    my ($request, %opts) = @_;
    my @unknown = keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');
    croak "list request method must be GET" unless $request->method eq 'GET';

    my $pubkey = _pubkey_from_list_path($request->path);
    my %list_opts = _list_options_from_query($request->query, $self->max_list_limit);
    my $blobs = $self->storage->list_blobs($pubkey, %list_opts);
    croak "storage list_blobs must return an array reference" unless ref($blobs) eq 'ARRAY';

    my @body;
    for my $blob (@$blobs) {
        croak "storage list_blobs items must be Net::Blossom::BlobDescriptor"
            unless blessed($blob) && $blob->isa('Net::Blossom::BlobDescriptor');
        push @body, $blob->to_hash;
    }

    return Net::Blossom::Server::Response->json(\@body, status => 200);
}

sub handle_request {
    my $self = shift;
    my ($request, %opts) = @_;
    my %known = map { $_ => 1 } qw(pubkey authorization);
    my @unknown = grep { !exists $known{$_} } keys %opts;
    croak "unknown option(s): " . join(', ', sort @unknown) if @unknown;

    croak "request must be a Net::Blossom::Server::Request"
        unless blessed($request) && $request->isa('Net::Blossom::Server::Request');

    if ($request->path eq '/upload') {
        return $self->handle_head_upload($request) if $request->method eq 'HEAD';
        return $self->handle_upload($request, _pubkey_opt(%opts)) if $request->method eq 'PUT';
        return Net::Blossom::Server::Response->empty(405, headers => { Allow => 'HEAD, PUT' });
    }

    if ($request->path eq '/media') {
        return $self->handle_head_media($request) if $request->method eq 'HEAD';
        return $self->handle_media($request, _pubkey_opt(%opts)) if $request->method eq 'PUT';
        return Net::Blossom::Server::Response->empty(405, headers => { Allow => 'HEAD, PUT' });
    }

    if ($request->path eq '/mirror') {
        return $self->handle_mirror($request, _mirror_opts(%opts)) if $request->method eq 'PUT';
        return Net::Blossom::Server::Response->empty(405, headers => { Allow => 'PUT' });
    }

    if ($request->path =~ m{\A/list/[0-9a-f]{64}\z}) {
        return Net::Blossom::Server::Response->empty(405, headers => { Allow => 'GET' })
            unless $request->method eq 'GET';
        return $self->handle_list_blobs($request);
    }

    if (_is_blob_retrieval_path($request->path)) {
        if ($request->method eq 'GET') {
            return $self->handle_get_blob($request);
        }
        if ($request->method eq 'HEAD') {
            return $self->handle_head_blob($request);
        }
        if (_is_exact_blob_path($request->path) && $request->method eq 'DELETE') {
            return $self->handle_delete_blob($request, _pubkey_opt(%opts));
        }
        my $allow = _is_exact_blob_path($request->path) ? 'DELETE, GET, HEAD' : 'GET, HEAD';
        return Net::Blossom::Server::Response->empty(405, headers => { Allow => $allow });
    }

    return Net::Blossom::Server::Response->empty(404);
}

sub _pubkey_from_list_path {
    my ($path) = @_;
    my ($pubkey) = defined $path ? ($path =~ m{\A/list/([^/]+)\z}) : ();
    croak "list request path must be /list/<pubkey>"
        unless defined $pubkey && length($pubkey) == 64;
    _validate_pubkey($pubkey);
    return $pubkey;
}

sub _sha256_from_blob_path {
    my ($path, %opts) = @_;
    my $pattern = $opts{allow_extension}
        ? qr{\A/([^/.]+)(?:\.[^/]+)?\z}
        : qr{\A/([^/]+)\z};
    my ($sha256) = defined $path ? ($path =~ $pattern) : ();
    croak "blob request path must be /<sha256>"
        unless defined $sha256 && length($sha256) == 64;
    croak "sha256 must be 64-char lowercase hex" unless $sha256 =~ $HEX64;
    return $sha256;
}

sub _list_options_from_query {
    my ($query, $max_list_limit) = @_;

    # Query parameters are client input, so malformed values are a BUD-12 400,
    # not an internal error.
    my %known = map { $_ => 1 } qw(cursor limit);
    my @unknown = grep { !exists $known{$_} } keys %$query;
    _bad_list_query('unknown query parameter(s): ' . join(', ', sort @unknown)) if @unknown;

    my %opts;
    if (exists $query->{cursor}) {
        _bad_list_query('cursor must be a scalar') if ref($query->{cursor});
        _bad_list_query('cursor must be 64-char lowercase hex') unless $query->{cursor} =~ $HEX64;
        $opts{cursor} = $query->{cursor};
    }

    if (exists $query->{limit}) {
        _bad_list_query('limit must be a scalar') if ref($query->{limit});
        _bad_list_query('limit must be a positive integer') unless $query->{limit} =~ /\A[1-9][0-9]*\z/;
        _bad_list_query("limit must not exceed $max_list_limit") if $query->{limit} > $max_list_limit;
        $opts{limit} = $query->{limit};
    } else {
        $opts{limit} = $max_list_limit;
    }

    return %opts;
}

sub _bad_list_query {
    my ($reason) = @_;
    Net::Blossom::Server::Error->throw(status => 400, reason => $reason);
}

sub _pubkey_opt {
    my (%opts) = @_;
    return defined $opts{pubkey} ? (pubkey => $opts{pubkey}) : ();
}

sub _mirror_opts {
    my (%opts) = @_;
    my %mirror_opts;
    $mirror_opts{pubkey} = $opts{pubkey} if defined $opts{pubkey};
    $mirror_opts{authorization} = $opts{authorization} if defined $opts{authorization};
    return %mirror_opts;
}

sub _is_exact_blob_path {
    my ($path) = @_;
    return defined $path && $path =~ m{\A/[0-9a-f]{64}\z};
}

sub _is_blob_retrieval_path {
    my ($path) = @_;
    return defined $path && $path =~ m{\A/[0-9a-f]{64}(?:\.[^/]+)?\z};
}

sub _optional_sha256_header {
    my ($request) = @_;
    my $sha256 = $request->header('x-sha-256');
    return undef unless defined $sha256 && length $sha256;
    Net::Blossom::Server::Error->throw(
        status => 400,
        reason => 'X-SHA-256 must be 64-char lowercase hex',
    ) unless $sha256 =~ $HEX64;
    return $sha256;
}

sub _preflight_error {
    my ($request) = @_;

    my $sha256 = $request->header('x-sha-256');
    return Net::Blossom::Server::Response->error(400, 'Missing X-SHA-256 header')
        unless defined $sha256 && length $sha256;
    return Net::Blossom::Server::Response->error(400, 'Invalid X-SHA-256 header')
        unless $sha256 =~ $HEX64;

    my $type = $request->header('x-content-type');
    return Net::Blossom::Server::Response->error(400, 'Missing X-Content-Type header')
        unless defined $type && length $type;

    my $length = $request->header('x-content-length');
    return Net::Blossom::Server::Response->error(411, 'Missing X-Content-Length header')
        unless defined $length && length $length;
    return Net::Blossom::Server::Response->error(400, 'Invalid X-Content-Length header')
        unless $length =~ /\A\d+\z/;

    return undef;
}

sub _descriptor_from_head_result {
    my ($result) = @_;

    return $result
        if blessed($result) && $result->isa('Net::Blossom::BlobDescriptor');
    return $result->descriptor
        if blessed($result) && $result->isa('Net::Blossom::Server::BlobResult');

    croak "storage head_blob must return a Net::Blossom::BlobDescriptor or Net::Blossom::Server::BlobResult";
}

sub _typed_error_response {
    my ($error) = @_;
    return $error->as_response;
}

sub _body_to_scalar {
    my ($body, $max) = @_;
    croak "body is required" unless defined $body;

    if (!ref($body)) {
        _content_too_large() if length($body) > $max;
        return $body;
    }

    _validate_body($body);
    my $content = '';
    if ($body->can('read')) {
        while (1) {
            my $chunk = '';
            my $read = $body->read($chunk, 8192);
            croak "body stream read failed" unless defined $read;
            last if $read == 0;
            $content .= $chunk;
            _content_too_large() if length($content) > $max;
        }
        return $content;
    }

    while (defined(my $chunk = $body->getline)) {
        croak "body chunks must be scalars" if ref($chunk);
        $content .= $chunk;
        _content_too_large() if length($content) > $max;
    }
    return $content;
}

sub _content_too_large {
    Net::Blossom::Server::Error->throw(
        status => 413,
        reason => 'Mirror request body is too large',
    );
}

sub _valid_mirror_url {
    my ($value) = @_;
    return 0 unless defined $value && !ref($value) && length $value;
    return 0 if $value =~ /[\x00-\x20]/;

    my $uri = URI->new($value);
    my $scheme = $uri->scheme;
    return 0 unless defined $scheme && $scheme =~ /\Ahttps?\z/i;

    my $authority = eval { $uri->authority };
    return 0 unless defined $authority && length $authority;
    return 0 if $authority =~ /\@/;

    my $host = eval { $uri->host };
    return 0 unless defined $host && length $host;

    my $userinfo = eval { $uri->userinfo };
    return 0 if defined $userinfo && length $userinfo;
    return 0 if defined $uri->fragment;

    return 1;
}

sub _fetch_mirror_blob {
    my ($fetcher, $url, %opts) = @_;
    return $fetcher->($url, %opts) if ref($fetcher) eq 'CODE';
    return $fetcher->fetch_blob($url, %opts);
}

sub _mirror_fetch_metadata {
    my ($result) = @_;
    croak "mirror fetcher must return a hash reference" unless ref($result) eq 'HASH';
    croak "mirror fetcher must stream into sink, not return body" if exists $result->{body};

    my %opts;
    if (defined $result->{type}) {
        croak "mirror fetcher result type must be a scalar" if ref($result->{type});
        croak "mirror fetcher result type is required" unless length $result->{type};
        $opts{type} = $result->{type};
    }
    if (defined $result->{content_length}) {
        _validate_content_length($result->{content_length});
        $opts{content_length} = $result->{content_length};
    }

    return \%opts;
}

sub _copy_body_to_upload {
    my ($self, $body, $upload, $sha) = @_;
    my $max = $self->max_upload_bytes;
    my $size = 0;

    if (!ref($body)) {
        _upload_too_large() if defined $max && length($body) > $max;
        _write_upload_chunk($upload, $sha, $body);
        return length $body;
    }

    if ($body->can('read')) {
        while (1) {
            my $chunk = '';
            my $read = $body->read($chunk, $self->chunk_size);
            croak "body stream read failed" unless defined $read;
            last if $read == 0;
            _write_upload_chunk($upload, $sha, $chunk);
            $size += length $chunk;
            _upload_too_large() if defined $max && $size > $max;
        }
        return $size;
    }

    while (defined(my $chunk = $body->getline)) {
        _write_upload_chunk($upload, $sha, $chunk);
        $size += length $chunk;
        _upload_too_large() if defined $max && $size > $max;
    }
    return $size;
}

sub _upload_too_large {
    Net::Blossom::Server::Error->throw(
        status => 413,
        reason => 'Uploaded blob is too large',
    );
}

sub _write_upload_chunk {
    my ($upload, $sha, $chunk) = @_;
    croak "body chunks must be scalars" if ref($chunk);
    $sha->add($chunk);
    my $written = $upload->write($chunk);
    croak "storage write failed" unless defined $written;
}

sub _upload_result_from_commit {
    my ($committed) = @_;

    return $committed
        if blessed($committed) && $committed->isa('Net::Blossom::Server::UploadResult');

    if (ref($committed) eq 'HASH' && exists $committed->{descriptor}) {
        my $descriptor = $committed->{descriptor};
        $descriptor = Net::Blossom::BlobDescriptor->from_hash($descriptor)
            if ref($descriptor) eq 'HASH';
        return Net::Blossom::Server::UploadResult->new(
            descriptor => $descriptor,
            created    => $committed->{created},
        );
    }

    my $descriptor;
    $descriptor = $committed
        if blessed($committed) && $committed->isa('Net::Blossom::BlobDescriptor');
    $descriptor = Net::Blossom::BlobDescriptor->from_hash($committed)
        if ref($committed) eq 'HASH';
    return Net::Blossom::Server::UploadResult->new(
        descriptor => $descriptor,
        created    => 1,
    ) if defined $descriptor;

    croak "storage commit must return an upload result or blob descriptor";
}

sub _validate_committed_descriptor {
    my ($descriptor, $sha256, $size, $type) = @_;
    croak "storage returned descriptor sha256 mismatch" unless $descriptor->sha256 eq $sha256;
    croak "storage returned descriptor size mismatch" unless $descriptor->size == $size;
    croak "storage returned descriptor type mismatch" unless $descriptor->type eq $type;
}

sub _validate_body {
    my ($body) = @_;
    return unless ref($body);
    return if blessed($body) && ($body->can('read') || $body->can('getline'));
    croak "body must be a scalar or stream object";
}

sub _validate_content_length {
    my ($content_length) = @_;
    croak "content_length must be a scalar" if ref($content_length);
    croak "content_length must be a non-negative integer"
        unless $content_length =~ /\A\d+\z/;
}

sub _validate_allowed_sha256 {
    my ($hashes) = @_;
    croak "allowed_sha256 must be an array reference" unless ref($hashes) eq 'ARRAY';
    for my $hash (@$hashes) {
        croak "allowed_sha256 must contain 64-char lowercase hex values"
            unless defined $hash && !ref($hash) && $hash =~ $HEX64;
    }
}

sub _validate_http_status {
    my ($status, $name) = @_;
    croak "$name must be an HTTP status code"
        unless !ref($status) && $status =~ /\A[1-5][0-9][0-9]\z/;
}

sub _sha256_mismatch {
    my (%opts) = @_;
    my $reason = defined $opts{sha256_mismatch_reason}
        ? $opts{sha256_mismatch_reason}
        : ($opts{default_reason} || 'sha256 mismatch');

    if (defined $opts{sha256_mismatch_status}) {
        Net::Blossom::Server::Error->throw(
            status => $opts{sha256_mismatch_status},
            reason => $reason,
        );
    }

    croak $reason;
}

sub _content_length_mismatch {
    my (%opts) = @_;
    my $reason = defined $opts{content_length_mismatch_reason}
        ? $opts{content_length_mismatch_reason}
        : 'content_length mismatch';

    if (defined $opts{content_length_mismatch_status}) {
        Net::Blossom::Server::Error->throw(
            status => $opts{content_length_mismatch_status},
            reason => $reason,
        );
    }

    croak $reason;
}

sub _validate_uploaded {
    my ($uploaded) = @_;
    croak "uploaded must be a scalar" if ref($uploaded);
    croak "uploaded must be a non-negative integer"
        unless $uploaded =~ /\A\d+\z/;
}

sub _validate_pubkey {
    my ($pubkey) = @_;
    croak "pubkey must be a scalar" if ref($pubkey);
    croak "pubkey must be 64-char lowercase hex" unless $pubkey =~ $HEX64;
}

{
    package Net::Blossom::Server::_MirrorSink;

    use strictures 2;

    use Carp qw(croak);

    sub new {
        my ($class, %args) = @_;
        croak "server is required" unless defined $args{server};
        croak "opts must be a hash reference" unless ref($args{opts}) eq 'HASH';

        return bless {
            server    => $args{server},
            opts      => $args{opts},
            sha       => Digest::SHA->new(256),
            size      => 0,
            started   => 0,
            committed => 0,
        }, $class;
    }

    sub started {
        my ($self) = @_;
        return $self->{started};
    }

    sub start {
        my $self = shift;
        my %metadata = @_;
        my %known = map { $_ => 1 } qw(type content_length);
        my @unknown = grep { !exists $known{$_} } keys %metadata;
        croak "unknown mirror metadata: " . join(', ', sort @unknown) if @unknown;
        croak "mirror sink already started" if $self->{started};

        my $type = defined $metadata{type} ? $metadata{type} : 'application/octet-stream';
        croak "mirror content type must be a scalar" if ref($type);
        croak "mirror content type is required" unless length $type;

        Net::Blossom::Server::_validate_content_length($metadata{content_length})
            if defined $metadata{content_length};

        my %context = (type => $type);
        $context{content_length} = $metadata{content_length} if defined $metadata{content_length};
        $context{pubkey} = $self->{opts}{pubkey} if defined $self->{opts}{pubkey};
        $context{allowed_sha256} = [@{$self->{opts}{allowed_sha256}}]
            if defined $self->{opts}{allowed_sha256};

        my $upload = $self->{server}->storage->begin_upload(%context);
        Net::Blossom::Server::Storage->assert_upload($upload);

        $self->{upload} = $upload;
        $self->{type} = $type;
        $self->{content_length} = $metadata{content_length};
        $self->{started} = 1;
        return 1;
    }

    sub write {
        my ($self, $chunk) = @_;
        croak "mirror sink must be started before write" unless $self->{started};
        croak "mirror body chunks must be scalars" if ref($chunk);

        my $new_size = $self->{size} + length($chunk);
        my $max = $self->{server}->max_upload_bytes;
        Net::Blossom::Server::_upload_too_large()
            if defined $max && $new_size > $max;

        Net::Blossom::Server::_write_upload_chunk($self->{upload}, $self->{sha}, $chunk);
        $self->{size} = $new_size;
        return length $chunk;
    }

    sub finish {
        my ($self) = @_;
        $self->start unless $self->{started};

        my %opts = %{$self->{opts}};
        $opts{content_length} = $self->{content_length} if defined $self->{content_length};
        Net::Blossom::Server::_content_length_mismatch(%opts)
            if defined $self->{content_length} && $self->{size} != $self->{content_length};

        my $sha256 = $self->{sha}->hexdigest;
        Net::Blossom::Server::_sha256_mismatch(%opts, default_reason => 'sha256 is not allowed')
            if defined $opts{allowed_sha256}
            && !grep { $_ eq $sha256 } @{$opts{allowed_sha256}};

        my $uploaded = defined $opts{uploaded} ? $opts{uploaded} : $self->{server}->clock->();
        my %commit_metadata = (
            sha256   => $sha256,
            size     => $self->{size},
            type     => $self->{type},
            uploaded => $uploaded,
        );
        $commit_metadata{pubkey} = $opts{pubkey} if defined $opts{pubkey};

        my $result = Net::Blossom::Server::_upload_result_from_commit(
            $self->{upload}->commit(%commit_metadata),
        );
        Net::Blossom::Server::_validate_committed_descriptor(
            $result->descriptor,
            $sha256,
            $self->{size},
            $self->{type},
        );

        $self->{committed} = 1;
        return $result;
    }

    sub abort {
        my ($self) = @_;
        return 1 unless $self->{started};
        return 1 if $self->{committed};
        return $self->{upload}->abort;
    }
}

1;

=pod

=head1 NAME

Net::Blossom::Server - Server-side support for the Blossom protocol

=head1 SYNOPSIS

    use Net::Blossom::Server;

    my $server = Net::Blossom::Server->new(
        storage => $storage,
    );

=head1 DESCRIPTION

C<Net::Blossom::Server> is the framework-neutral server core for the Blossom
protocol. Gateway adapters such as PSGI or PAGI should translate native requests
into C<Net::Blossom::Server::Request> objects and translate
C<Net::Blossom::Server::Response> objects back to their gateway format.

Server support lives in a separate CPAN distribution so client users do not need
server, storage, daemon, or web framework dependencies.

=head1 CONSTRUCTOR

=head2 new

    my $server = Net::Blossom::Server->new(%args);

Required arguments:

=over 4

=item * C<storage>

Storage object that satisfies L<Net::Blossom::Server::Storage>.

=back

Optional arguments:

=over 4

=item * C<chunk_size>

Positive integer read size used when copying stream bodies. Defaults to C<65536>.

=item * C<clock>

Code reference returning the upload timestamp. Defaults to C<time>.

=item * C<mirror_fetcher>

Optional code reference or object with C<fetch_blob>. This is required for
C<PUT /mirror>. Mirror fetchers stream origin bytes into a server-provided sink;
no default network fetcher is provided.

=item * C<max_upload_bytes>

Optional positive integer bounding the size of an accepted upload. When set,
C<PUT /upload>, C<PUT /media>, and mirrored origin bodies that exceed it are
rejected with C<413> and the partial upload is aborted. Defaults to unset (no
limit).

=item * C<max_list_limit>

Positive integer maximum C<GET /list/E<lt>pubkeyE<gt>> page size. List requests
without a C<limit> query parameter use this value as the default. Requests with
a larger C<limit> are rejected with C<400>. Defaults to C<100>.

=back

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 storage

Returns the configured storage object.

=head2 chunk_size

Returns the stream copy chunk size.

=head2 clock

Returns the clock code reference.

=head2 mirror_fetcher

Returns the optional mirror fetcher.

=head2 max_upload_bytes

Returns the configured maximum upload size, or C<undef> when uploads are
not size-limited.

=head2 max_list_limit

Returns the configured maximum list page size.

=head1 METHODS

=head2 receive_blob

    my $result = $server->receive_blob($body, %opts);

Copies a scalar or stream body into storage while computing SHA-256 in the server
core. Returns a C<Net::Blossom::Server::UploadResult>.

Options:

=over 4

=item * C<type>

Blob media type. Defaults to C<application/octet-stream>.

=item * C<expected_sha256>

Optional lowercase 64-character SHA-256 hash. When present, the computed hash
must match before the upload is committed.

=item * C<allowed_sha256>

Optional array reference of lowercase 64-character SHA-256 hashes. When present,
the computed hash must match one of these values before the upload is committed.
This is used for deferred BUD-11 C<PUT /mirror> authorization.

=item * C<content_length>

Optional expected body size. When present, the copied byte count must match
before the upload is committed.

=item * C<uploaded>

Optional upload timestamp. Defaults to C<< $server->clock->() >>.

=item * C<pubkey>

Optional uploader public key as lowercase 64-character hex. Gateway adapters
will normally derive this from BUD-11 authorization.

=item * C<sha256_mismatch_status>

Optional HTTP status code for SHA-256 mismatches. When supplied, mismatches
throw L<Net::Blossom::Server::Error> with this status instead of croaking with
a plain string.

=item * C<sha256_mismatch_reason>

Optional reason string used with C<sha256_mismatch_status>.

=item * C<content_length_mismatch_status>

Optional HTTP status code for content-length mismatches. When supplied,
mismatches throw L<Net::Blossom::Server::Error> with this status instead of
croaking with a plain string.

=item * C<content_length_mismatch_reason>

Optional reason string used with C<content_length_mismatch_status>.

=back

The storage upload is aborted if hashing, length validation, SHA-256 validation,
or storage writing fails.

Storage commit results that are raw C<Net::Blossom::BlobDescriptor> objects or
descriptor hash references are accepted as newly created uploads for compatibility
with early storage implementations. New storage implementations should return a
C<Net::Blossom::Server::UploadResult> or a hash reference with C<descriptor> and
C<created>.

=head2 handle_upload

    my $response = $server->handle_upload($request, %opts);

Handles a normalized C<PUT /upload> request and returns a
C<Net::Blossom::Server::Response>. The request must be a
C<Net::Blossom::Server::Request> with a defined body.

The method passes the request body, content type, content length, optional
C<X-SHA-256>, and optional C<pubkey> into C<receive_blob>. When C<X-SHA-256> is
present, a hash mismatch throws a typed C<409> error before storage commit.
C<Content-Length> mismatches throw a typed C<400> error before storage commit.
The response body is the blob descriptor encoded as JSON. The response status is
C<201> when the blob was newly stored and C<200> when it already existed.

Options:

=over 4

=item * C<pubkey>

Optional already-verified uploader public key as lowercase 64-character hex.
Authorization verification is deliberately outside this method.

=back

=head2 handle_head_upload

    my $response = $server->handle_head_upload($request);

Handles a normalized C<HEAD /upload> BUD-06 preflight request. It validates the
C<X-SHA-256>, C<X-Content-Type>, and C<X-Content-Length> headers and returns an
empty C<200> response when the metadata is well-formed. Malformed metadata
returns C<400>; missing C<X-Content-Length> returns C<411>.

=head2 handle_get_blob

    my $response = $server->handle_get_blob($request);

Handles a normalized C<GET /E<lt>sha256E<gt>> request and returns a
C<Net::Blossom::Server::Response>. The request path must contain one lowercase
64-character SHA-256 hash segment and may include a file extension.

The method calls C<< $server->storage->get_blob($sha256) >>. It returns C<404>
when storage returns C<undef>. Otherwise, storage must return a
C<Net::Blossom::Server::BlobResult> whose descriptor C<sha256> matches the
request path. The response status is C<200>, the response body is the blob body,
and C<Content-Type> and C<Content-Length> come from the descriptor.

=head2 handle_head_blob

    my $response = $server->handle_head_blob($request);

Handles a normalized C<HEAD /E<lt>sha256E<gt>> request and returns the same
C<Content-Type> and C<Content-Length> headers as C<GET /E<lt>sha256E<gt>>
without returning the blob body. The request path may include a file extension.

If storage provides an optional C<head_blob($sha256)> method, that method is
used and may return either a L<Net::Blossom::BlobDescriptor> or a
L<Net::Blossom::Server::BlobResult>. Otherwise C<get_blob> is used and the body
is discarded.

=head2 handle_media

    my $response = $server->handle_media($request, %opts);

Handles a normalized C<PUT /media> request. The current implementation uses the
same identity byte path as C<PUT /upload>: it stores the received bytes without
media transformation and returns a blob descriptor JSON response with C<201> or
C<200>. When C<X-SHA-256> is present, a hash mismatch throws a typed C<409>
error before storage commit. C<Content-Length> mismatches throw a typed C<400>
error before storage commit.

Options:

=over 4

=item * C<pubkey>

Optional already-verified uploader public key as lowercase 64-character hex.

=back

=head2 handle_head_media

    my $response = $server->handle_head_media($request);

Handles a normalized C<HEAD /media> BUD-05 preflight request. It validates the
C<X-SHA-256>, C<X-Content-Type>, and C<X-Content-Length> headers and returns the
same status behavior as C<handle_head_upload>.

=head2 handle_mirror

    my $response = $server->handle_mirror($request, %opts);

Handles a normalized C<PUT /mirror> request. The request body must be a JSON
object with a C<url> field. The URL must use C<http> or C<https>, have a host,
must not include userinfo, and must not include a fragment.

The server calls the configured C<mirror_fetcher> with a streaming sink and stores
origin bytes as the fetcher writes them. SHA-256 calculation and storage commit
remain owned by the server core. A missing C<mirror_fetcher> returns C<503>.
Malformed mirror requests return C<400>. Origin fetch failures, unusable fetch
results, or origin content-length mismatches return C<502>.

The fetcher may be a code reference called with C<$url> and C<< sink => $sink >>,
or an object called as C<< $fetcher->fetch_blob($url, sink => $sink) >>. It must
call C<< $sink->start(%metadata) >> before writing bytes, then call
C<< $sink->write($chunk) >> for each scalar byte chunk. C<%metadata> may include
C<type> and C<content_length>; missing C<type> defaults to
C<application/octet-stream>. For empty origin bodies, the fetcher may instead
return a metadata hash reference and let the server start the sink. Returning a
C<body> value is not supported.

Options:

=over 4

=item * C<pubkey>

Optional already-verified uploader public key.

=item * C<authorization>

Optional L<Net::Blossom::Server::AuthorizationResult>. When provided, the
downloaded blob hash must match one of the authorized C<x> tag hashes before
storage commit, otherwise a typed C<409> error is thrown.

=back

=head2 handle_delete_blob

    my $response = $server->handle_delete_blob($request, pubkey => $pubkey);

Handles a normalized C<DELETE /E<lt>sha256E<gt>> request and returns a
C<Net::Blossom::Server::Response>. The request path must contain one lowercase
64-character SHA-256 hash segment.

C<pubkey> is required and must be the already-verified owner public key as
lowercase 64-character hex. Authorization event verification is deliberately
outside this method.

The method calls C<< $server->storage->delete_blob($sha256, pubkey => $pubkey) >>.
It returns C<204> when storage deletes an owner relationship and C<404> when
storage returns false.

=head2 handle_list_blobs

    my $response = $server->handle_list_blobs($request);

Handles a normalized C<GET /list/E<lt>pubkeyE<gt>> request and returns a
C<Net::Blossom::Server::Response>. The request path must contain one lowercase
64-character public key segment.

The method reads optional C<cursor> and C<limit> query parameters. C<cursor>
must be a lowercase 64-character SHA-256 hash. C<limit> must be a positive
integer no larger than C<max_list_limit>. Requests without C<limit> use
C<max_list_limit> as the default page size. Storage receives a bounded C<limit>
for every list request.

The method calls C<< $server->storage->list_blobs($pubkey, %opts) >> and
returns status C<200> with a JSON array of blob descriptors. Storage must return
an array reference of C<Net::Blossom::BlobDescriptor> objects.

=head2 handle_request

    my $response = $server->handle_request($request, %opts);

Dispatches a normalized C<Net::Blossom::Server::Request> and returns a
C<Net::Blossom::Server::Response>. This is the framework-neutral routing entry
point for future gateway adapters.

Currently implemented routes:

=over 4

=item * C<PUT /upload>

Delegates to C<handle_upload>.

=item * C<HEAD /upload>

Delegates to C<handle_head_upload>.

=item * C<PUT /media>

Delegates to C<handle_media>.

=item * C<HEAD /media>

Delegates to C<handle_head_media>.

=item * C<PUT /mirror>

Delegates to C<handle_mirror>.

=item * C<GET /E<lt>sha256E<gt>>

Delegates to C<handle_get_blob>.

=item * C<HEAD /E<lt>sha256E<gt>>

Delegates to C<handle_head_blob>.

=item * C<DELETE /E<lt>sha256E<gt>>

Delegates to C<handle_delete_blob>.

=item * C<GET /list/E<lt>pubkeyE<gt>>

Delegates to C<handle_list_blobs>.

=back

Unknown paths return C<404>. Known paths with unsupported methods return C<405>.

Options:

=over 4

=item * C<pubkey>

Optional already-verified uploader public key. Passed through to upload, media,
mirror, and delete handlers as needed.

=item * C<authorization>

Optional L<Net::Blossom::Server::AuthorizationResult>. Passed through to
C<handle_mirror> for deferred hash authorization.

=back

=head1 STATUS

The server core is under active development. It implements the protocol handlers
documented above and remains framework-neutral.

=cut
