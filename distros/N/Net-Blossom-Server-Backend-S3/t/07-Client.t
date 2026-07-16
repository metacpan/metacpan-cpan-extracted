use strictures 2;

use File::Temp qw(tempfile);
use HTTP::Response;
use Test::More;

use Net::Blossom::Server::Backend::S3::_Client;

my $configured = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket            => 'blossom',
    endpoint          => 'http://127.0.0.1:9000',
    region            => 'garage',
    access_key_id     => 'access',
    secret_access_key => 'secret',
);
my $s3 = $configured->bucket->client->s3;
is($s3->host, '127.0.0.1:9000', 'custom endpoint host and port are retained');
ok(!$s3->secure, 'HTTP custom endpoint is retained');
ok(!$s3->use_virtual_host, 'custom endpoints default to path-style URLs');
is($s3->vendor->default_region, 'garage', 'custom endpoint region is retained');
ok($s3->retry, 'request retries are enabled by default');

my $virtual = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket            => 'blossom',
    endpoint          => 'https://objects.example.test',
    access_key_id     => 'access',
    secret_access_key => 'secret',
    path_style        => 0,
);
ok($virtual->bucket->client->s3->use_virtual_host, 'URL style can be overridden');

my $session = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket            => 'blossom',
    endpoint          => 'https://objects.example.test',
    access_key_id     => 'access',
    secret_access_key => 'secret',
    session_token     => 'token',
);
is($session->bucket->client->s3->aws_session_token, 'token',
    'session credentials are passed to the S3 client');

for my $case (
    ['https://user@objects.example.test', qr/userinfo/, 'endpoint userinfo is rejected'],
    ['https://objects.example.test/base', qr/cannot contain a path/, 'endpoint path is rejected'],
    ['ftp://objects.example.test', qr/HTTP URL/, 'non-HTTP endpoint is rejected'],
    ['https://objects.example.test:0', qr/port must be between/, 'zero endpoint port is rejected'],
    ['https://objects.example.test:99999', qr/port must be between/, 'large endpoint port is rejected'],
    ['https://objects.example.test:abc', qr/numeric port/, 'nonnumeric endpoint port is rejected'],
) {
    my ($endpoint, $error, $name) = @$case;
    my $ok = eval {
        Net::Blossom::Server::Backend::S3::_Client->new(
            bucket            => 'blossom',
            endpoint          => $endpoint,
            access_key_id     => 'access',
            secret_access_key => 'secret',
        );
        1;
    };
    ok(!$ok, $name);
    like($@, $error, "$name reports the cause");
}

for my $case (
    [[region => 'us-east-1/path'], qr/region contains unsafe/, 'unsafe region is rejected'],
    [[path_style => []], qr/path_style must be 0 or 1/, 'path style must be boolean'],
    [[retry => []], qr/retry must be 0 or 1/, 'retry must be boolean'],
    [[session_token => []], qr/session_token must be a non-empty scalar/, 'session token must be scalar'],
    [[s3 => $s3, endpoint => 'https://ignored.example.test'],
        qr/s3 cannot be combined/, 'injected S3 object rejects ignored connection arguments'],
) {
    my ($extra, $error, $name) = @$case;
    my $ok = eval {
        Net::Blossom::Server::Backend::S3::_Client->new(
            bucket            => 'blossom',
            access_key_id     => 'access',
            secret_access_key => 'secret',
            @$extra,
        );
        1;
    };
    ok(!$ok, $name);
    like($@, $error, "$name reports the cause");
}

my ($small_fh, $small_path) = tempfile();
binmode $small_fh;
print {$small_fh} 'small body';
close $small_fh;

my $object = Local::Object->new;
my $bucket = Local::Bucket->new(_object => $object);
my $client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => $bucket,
);
$client->upload_file(
    key                 => 'small-key',
    path                => $small_path,
    size                => 10,
    content_type        => 'text/plain',
    sha256              => 'a' x 64,
    multipart_threshold => 100,
    multipart_part_size => 5 * 1024 * 1024,
);
is_deeply($object->put_filenames, [$small_path], 'small upload uses put_filename');
is($bucket->object_args->[0]{key}, 'small-key', 'single PUT uses requested key');
is($bucket->object_args->[0]{content_type}, 'text/plain', 'single PUT sets content type');
is_deeply(
    $bucket->object_args->[0]{user_metadata},
    {sha256 => 'a' x 64},
    'single PUT sets hash metadata',
);

$object = Local::Object->new;
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$client->upload_file(
    key                 => 'threshold-key',
    path                => $small_path,
    size                => 10,
    content_type        => 'text/plain',
    sha256              => 'e' x 64,
    multipart_threshold => 10,
    multipart_part_size => 5 * 1024 * 1024,
);
is(scalar @{$object->parts}, 1, 'an object at the threshold uses multipart upload');

$object = Local::Object->new;
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$client->upload_file(
    key                 => 'single-put-boundary-key',
    path                => $small_path,
    size                => 5_000_000_000,
    content_type        => 'text/plain',
    sha256              => '4' x 64,
    multipart_threshold => 6_000_000_000,
    multipart_part_size => 5 * 1024 * 1024,
);
is(scalar @{$object->put_filenames}, 1, 'an object at 5 GB may use one PUT');
is(scalar @{$object->parts}, 0, 'an object at 5 GB need not use multipart upload');

$object = Local::Object->new;
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$client->upload_file(
    key                 => 'single-put-limit-key',
    path                => $small_path,
    size                => 5_000_000_001,
    content_type        => 'text/plain',
    sha256              => '4' x 64,
    multipart_threshold => 6_000_000_000,
    multipart_part_size => 5 * 1024 * 1024,
);
is(scalar @{$object->put_filenames}, 0, 'an object above 5 GB does not use one PUT');
is(scalar @{$object->parts}, 1, 'an object above 5 GB uses multipart upload');

my ($large_fh, $large_path) = tempfile();
binmode $large_fh;
print {$large_fh} 'x' x (11 * 1024 * 1024);
close $large_fh;

$object = Local::Object->new;
$bucket = Local::Bucket->new(_object => $object);
$client = Net::Blossom::Server::Backend::S3::_Client->new(bucket_object => $bucket);
$client->upload_file(
    key                 => 'large-key',
    path                => $large_path,
    size                => 11 * 1024 * 1024,
    content_type        => 'application/octet-stream',
    sha256              => 'b' x 64,
    multipart_threshold => 1,
    multipart_part_size => 5 * 1024 * 1024,
);
is_deeply(
    [map { length $_->{value} } @{$object->parts}],
    [5 * 1024 * 1024, 5 * 1024 * 1024, 1024 * 1024],
    'multipart upload reads bounded parts',
);
is_deeply(
    $object->init_headers,
    {
        'Content-Type'      => 'application/octet-stream',
        'x-amz-meta-sha256' => 'b' x 64,
    },
    'multipart initiation sets content type and hash metadata',
);
is_deeply($object->completed->{part_numbers}, [1, 2, 3], 'multipart completion orders parts');
is_deeply($object->completed->{etags}, ['"etag-1"', '"etag-2"', '"etag-3"'],
    'multipart completion includes returned ETags');
is($object->abort_count, 0, 'successful multipart upload is not aborted');

my $enlarged = Net::Blossom::Server::Backend::S3::_Client::_part_size_for(
    200_000_000_000,
    16 * 1024 * 1024,
);
ok(int((200_000_000_000 + $enlarged - 1) / $enlarged) <= 10_000,
    'part size grows to stay within 10,000 parts');

$object = Local::Object->new(fail_part => 2);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
my $ok = eval {
    $client->upload_file(
        key                 => 'failed-key',
        path                => $large_path,
        size                => 11 * 1024 * 1024,
        content_type        => 'application/octet-stream',
        sha256              => 'c' x 64,
        multipart_threshold => 1,
        multipart_part_size => 5 * 1024 * 1024,
    );
    1;
};
ok(!$ok, 'multipart part failure propagates');
like($@, qr/multipart part 2 failed/, 'multipart part error is useful');
is($object->abort_count, 1, 'failed multipart upload is aborted');

$object = Local::Object->new(missing_etag => 1);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$ok = eval {
    $client->upload_file(
        key                 => 'missing-etag-key',
        path                => $small_path,
        size                => 10,
        content_type        => 'text/plain',
        sha256              => 'd' x 64,
        multipart_threshold => 1,
        multipart_part_size => 5 * 1024 * 1024,
    );
    1;
};
ok(!$ok, 'missing multipart ETag is rejected');
like($@, qr/returned no ETag/, 'missing ETag is reported');
is($object->abort_count, 1, 'multipart upload without an ETag is aborted');

$object = Local::Object->new(fail_complete => 1);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$ok = eval {
    $client->upload_file(
        key                 => 'failed-complete-key',
        path                => $small_path,
        size                => 10,
        content_type        => 'text/plain',
        sha256              => 'f' x 64,
        multipart_threshold => 1,
        multipart_part_size => 5 * 1024 * 1024,
    );
    1;
};
ok(!$ok, 'multipart completion failure propagates');
like($@, qr/multipart completion failed/, 'completion failure is reported');
is($object->abort_count, 1, 'failed multipart completion is aborted');

$object = Local::Object->new(fail_part => 1, fail_abort => 1);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$ok = eval {
    $client->upload_file(
        key                 => 'failed-abort-key',
        path                => $small_path,
        size                => 10,
        content_type        => 'text/plain',
        sha256              => '1' x 64,
        multipart_threshold => 1,
        multipart_part_size => 5 * 1024 * 1024,
    );
    1;
};
ok(!$ok, 'abort failure does not hide the upload failure');
like($@, qr/multipart part 1 failed/, 'primary multipart failure is preserved');

$object = Local::Object->new;
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$ok = eval {
    $client->upload_file(
        key                 => 'above-legacy-limit-key',
        path                => '/does/not/exist',
        size                => 5 * 1024 * 1024 * 1024 * 1024 + 1,
        content_type        => 'application/octet-stream',
        sha256              => '2' x 64,
        multipart_threshold => 1,
        multipart_part_size => 5 * 1024 * 1024,
    );
    1;
};
ok(!$ok, 'a simulated object above 5 TiB reaches file access');
unlike($@, qr/object size exceeds/, 'the former 5 TiB object limit is not enforced');
like($@, qr/unable to read upload temp file/, 'the simulated upload passes size validation');
is($object->abort_count, 1, 'failed simulated upload is aborted after size validation');

my $maximum_object_size = 10_000 * 5 * 1024 * 1024 * 1024;
is(
    Net::Blossom::Server::Backend::S3::_Client::_part_size_for(
        $maximum_object_size,
        16 * 1024 * 1024,
    ),
    5 * 1024 * 1024 * 1024,
    'the maximum object fits exactly 10,000 maximum-size parts',
);
$ok = eval {
    $client->upload_file(
        key                 => 'too-large-key',
        path                => '/does/not/exist',
        size                => $maximum_object_size + 1,
        content_type        => 'application/octet-stream',
        sha256              => '2' x 64,
        multipart_threshold => 1,
        multipart_part_size => 5 * 1024 * 1024,
    );
    1;
};
ok(!$ok, 'objects cannot exceed the S3 multipart maximum');
like($@, qr/object size exceeds multipart limit/,
    'an object above 10,000 maximum-size parts is rejected before file access');

$object = Local::Object->new(head => {ContentLength => 10}, range_body => '2345');
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
is_deeply($client->head('key'), {size => 10}, 'HEAD response exposes object size');
is($object->head_operation, 'Net::Amazon::S3::Operation::Object::Head',
    'HEAD uses the operation whose 404 response is nonfatal');
is($client->get_range('key', 2, 5), '2345', 'range body is returned');
is($object->range_value, 'bytes=2-5', 'range request uses an inclusive byte range');
ok($client->delete('key'), 'existing object is deleted');
is($object->delete_count, 1, 'delete request is issued once');

$object = Local::Object->new(head => undef);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
ok(!$client->delete('missing'), 'missing object is not deleted');
is($object->delete_count, 0, 'missing object avoids DELETE request');

for my $status (403, 500) {
    $object = Local::Object->new(head_status => $status);
    $client = Net::Blossom::Server::Backend::S3::_Client->new(
        bucket_object => Local::Bucket->new(_object => $object),
    );
    $ok = eval { $client->head('failed-head'); 1 };
    ok(!$ok, "HEAD $status is not reported as a missing object");
    like($@, qr/S3 HEAD failed.*$status/, "HEAD $status reports the service failure");
}

$object = Local::Object->new(
    range_body   => '<Error>injected range failure</Error>',
    range_status => 500,
);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$ok = eval { $client->get_range('failed-range', 0, 3); 1 };
ok(!$ok, 'ranged GET service failure does not become blob bytes');
like($@, qr/S3 ranged GET failed.*500/, 'ranged GET reports the service failure');

$object = Local::Object->new(
    head          => {ContentLength => 10},
    delete_status => 500,
);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$ok = eval { $client->delete('failed-delete'); 1 };
ok(!$ok, 'DELETE service failure propagates');
like($@, qr/S3 DELETE failed.*500/, 'DELETE reports the service failure');

$object = Local::Object->new(embedded_complete_error => 1);
$client = Net::Blossom::Server::Backend::S3::_Client->new(
    bucket_object => Local::Bucket->new(_object => $object),
);
$ok = eval {
    $client->upload_file(
        key                 => 'embedded-complete-error',
        path                => $small_path,
        size                => 10,
        content_type        => 'text/plain',
        sha256              => '3' x 64,
        multipart_threshold => 1,
        multipart_part_size => 5 * 1024 * 1024,
    );
    1;
};
ok(!$ok, 'multipart completion rejects an error embedded in HTTP 200');
like($@, qr/S3 multipart completion failed.*InternalError/,
    'embedded completion error reports its S3 code');
is($object->abort_count, 1, 'embedded completion error aborts the multipart upload');

done_testing;

{
    package Local::Bucket;

    use Class::Tiny qw(_object), {
        object_args => sub { [] },
    };

    sub object {
        my ($self, %args) = @_;
        push @{$self->{object_args}}, {%args};
        return $self->{_object};
    }
}

{
    package Local::Object;

    use Class::Tiny qw(
        head range_body fail_part missing_etag fail_complete fail_abort init_headers
        completed range_value head_operation head_status range_status delete_status
        embedded_complete_error
    ), {
        put_filenames => sub { [] },
        parts         => sub { [] },
        abort_count   => 0,
        delete_count  => 0,
    };

    sub put_filename {
        my ($self, $path) = @_;
        push @{$self->{put_filenames}}, $path;
        return;
    }

    sub _perform_operation {
        my ($self, $operation, %args) = @_;
        if ($operation eq 'Net::Amazon::S3::Operation::Object::Delete') {
            ++$self->{delete_count};
            return _operation_response($self->{delete_status} || 204);
        }
        if ($operation eq 'Net::Amazon::S3::Operation::Object::Upload::Complete') {
            $self->{completed} = {%args};
            my $status = $self->{fail_complete} ? 500 : 200;
            my $http = HTTP::Response->new(
                $status,
                $status == 200 ? 'OK' : 'Injected failure',
            );
            $http->content(<<'XML') if $self->{embedded_complete_error};
<Error><Code>InternalError</Code><Message>Injected failure</Message></Error>
XML
            return Local::OperationResponse->new(
                success       => $status == 200 ? 1 : 0,
                error         => $status >= 400 || $self->{embedded_complete_error} ? 1 : 0,
                error_code    => $self->{embedded_complete_error}
                    ? 'InternalError'
                    : ($status >= 400 ? $status : undef),
                http_response => $http,
            );
        }

        $self->{head_operation} = $operation;
        my $status = $self->{head_status}
            || (defined $self->{head} ? 200 : 404);
        my $http = HTTP::Response->new($status, $status == 200 ? 'OK' : 'Injected failure');
        $http->header('Content-Length' => $self->{head}{ContentLength})
            if $status == 200 && defined $self->{head};
        return Local::OperationResponse->new(
            success       => $status == 200 ? 1 : 0,
            error         => $status >= 400 ? 1 : 0,
            error_code    => $status >= 400 ? $status : undef,
            http_response => $http,
        );
    }

    sub initiate_multipart_upload {
        my ($self, %args) = @_;
        $self->{init_headers} = $args{headers};
        return 'upload-id';
    }

    sub put_part {
        my ($self, %args) = @_;
        push @{$self->{parts}}, {%args};
        return HTTP::Response->new(500, 'Injected failure')
            if $self->{fail_part} && $args{part_number} == $self->{fail_part};
        my $response = HTTP::Response->new(200, 'OK');
        $response->header(ETag => '"etag-' . $args{part_number} . '"')
            unless $self->{missing_etag};
        return $response;
    }

    sub complete_multipart_upload {
        my ($self, %args) = @_;
        $self->{completed} = {%args};
        my $response = $self->{fail_complete}
            ? HTTP::Response->new(500, 'Injected failure')
            : HTTP::Response->new(200, 'OK');
        $response->content(
            '<Error><Code>InternalError</Code><Message>Injected failure</Message></Error>'
        ) if $self->{embedded_complete_error};
        return $response;
    }

    sub abort_multipart_upload {
        my ($self) = @_;
        ++$self->{abort_count};
        die "injected abort failure\n" if $self->{fail_abort};
        return HTTP::Response->new(204, 'No Content');
    }

    sub range {
        my ($self, $range) = @_;
        $self->{range_value} = $range;
        return Local::Range->new(
            body   => $self->{range_body},
            status => $self->{range_status} || 206,
        );
    }

    sub delete {
        my ($self) = @_;
        ++$self->{delete_count};
        return 0 if $self->{delete_status} && $self->{delete_status} >= 400;
        return 1;
    }

    sub _operation_response {
        my ($status) = @_;
        my $http = HTTP::Response->new(
            $status,
            $status >= 400 ? 'Injected failure' : 'OK',
        );
        return Local::OperationResponse->new(
            success       => $status >= 200 && $status < 300 ? 1 : 0,
            error         => $status >= 400 ? 1 : 0,
            error_code    => $status >= 400 ? $status : undef,
            http_response => $http,
        );
    }
}

{
    package Local::Range;

    use Class::Tiny qw(body status);

    sub get { $_[0]->body }

    sub _get {
        my ($self) = @_;
        my $http = HTTP::Response->new(
            $self->status,
            $self->status >= 400 ? 'Injected failure' : 'Partial Content',
        );
        $http->content($self->body);
        return Local::OperationResponse->new(
            success       => $self->status >= 200 && $self->status < 300 ? 1 : 0,
            error         => $self->status >= 400 ? 1 : 0,
            error_code    => $self->status >= 400 ? $self->status : undef,
            http_response => $http,
        );
    }
}

{
    package Local::OperationResponse;

    use Class::Tiny qw(success error error_code http_response);

    sub is_success { $_[0]->success }
    sub is_error { $_[0]->error }
    sub code { $_[0]->http_response->code }
    sub status_line { $_[0]->http_response->status_line }
    sub content { $_[0]->http_response->content }
}
