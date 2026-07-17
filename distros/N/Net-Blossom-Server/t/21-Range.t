use strictures 2;

use Test::More;

use Net::Blossom::BlobDescriptor;
use Net::Blossom::Server;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::Request;

my $SHA256 = '0f343b0931126a20f133d67c2b018a3b5ceca63dd3585a76cb1f3289a274707f';

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::Storage;
    use strictures 2;

    sub new {
        my ($class, %args) = @_;
        return bless {
            blobs => $args{blobs} || {},
        }, $class;
    }

    sub begin_upload {
        return Local::Upload->new;
    }

    sub get_blob {
        my ($self, $sha256) = @_;
        push @{$self->{get_calls}}, $sha256;
        return $self->{blobs}{$sha256};
    }

    sub delete_blob {
        return 0;
    }

    sub list_blobs {
        return [];
    }
}

{
    package Local::RangeStorage;
    use strictures 2;

    our @ISA = ('Local::Storage');

    sub head_blob {
        my ($self, $sha256) = @_;
        push @{$self->{head_calls}}, $sha256;
        my $result = $self->{blobs}{$sha256};
        return defined $result ? $result->descriptor : undef;
    }

    sub get_blob_range {
        my ($self, $sha256, %opts) = @_;
        push @{$self->{range_calls}}, [$sha256, {%opts}];
        return if $self->{range_missing};
        return $self->{range_body} if exists $self->{range_body};
        return substr($self->{blobs}{$sha256}->body, $opts{offset}, $opts{length});
    }
}

{
    package Local::Upload;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub write {
        return length $_[1];
    }

    sub commit {
        return;
    }

    sub abort {
        return 1;
    }
}

{
    package Local::ReadStream;
    use strictures 2;

    sub new {
        my ($class, $data) = @_;
        return bless {
            data   => $data,
            offset => 0,
            closed => 0,
        }, $class;
    }

    sub read {
        my ($self, undef, $length) = @_;
        die "stream is closed\n" if $self->{closed};
        $_[1] = '';
        return 0 if $self->{offset} >= length $self->{data};
        $_[1] = substr($self->{data}, $self->{offset}, $length);
        $self->{offset} += length $_[1];
        return length $_[1];
    }

    sub close {
        my ($self) = @_;
        $self->{closed} = 1;
        return 1;
    }
}

{
    package Local::GetlineStream;
    use strictures 2;

    sub new {
        my ($class, $data) = @_;
        return bless {
            data   => $data,
            read   => 0,
            closed => 0,
        }, $class;
    }

    sub getline {
        my ($self) = @_;
        return if $self->{read}++;
        return $self->{data};
    }

    sub close {
        my ($self) = @_;
        $self->{closed} = 1;
        return 1;
    }
}

sub request {
    my (%args) = @_;
    return Net::Blossom::Server::Request->new(
        method  => $args{method} || 'GET',
        path    => "/$SHA256",
        headers => $args{headers} || {},
    );
}

sub descriptor {
    my ($body) = @_;
    return Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$SHA256.txt",
        sha256   => $SHA256,
        size     => length($body),
        type     => 'text/plain',
        uploaded => 1725105921,
    );
}

sub blob_result {
    my ($body, $response_body) = @_;
    $response_body = $body unless defined $response_body;
    return Net::Blossom::Server::BlobResult->new(
        descriptor => descriptor($body),
        body       => $response_body,
    );
}

sub response_for {
    my ($storage, $range) = @_;
    my $server = Net::Blossom::Server->new(storage => $storage);
    my %headers = defined $range ? (Range => $range) : ();
    return $server->handle_get_blob(request(headers => \%headers));
}

sub read_body {
    my ($body) = @_;
    return $body unless ref($body);

    my $content = '';
    while (1) {
        my $chunk = '';
        my $read = $body->read($chunk, 2);
        last unless $read;
        $content .= $chunk;
    }
    return $content;
}

subtest 'ordinary GET and HEAD advertise byte ranges' => sub {
    my $body = 'abcdefghij';
    my $storage = Local::Storage->new(blobs => {$SHA256 => blob_result($body)});
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $get = $server->handle_get_blob(request());
    is($get->status, 200, 'GET status');
    is($get->header('accept-ranges'), 'bytes', 'GET advertises byte ranges');
    is($get->header('content-range'), undef, 'full GET has no content range');

    my $head = $server->handle_head_blob(request(method => 'HEAD'));
    is($head->status, 200, 'HEAD status');
    is($head->header('accept-ranges'), 'bytes', 'HEAD advertises byte ranges');
    is($head->body, '', 'HEAD body remains empty');
};

subtest 'native storage serves fixed, open, suffix, and clamped ranges' => sub {
    my $body = 'abcdefghij';
    my @cases = (
        ['bytes=2-5',  'cdef', 2, 4, 'bytes 2-5/10'],
        ['bytes=6-',   'ghij', 6, 4, 'bytes 6-9/10'],
        ['bytes=-3',   'hij',  7, 3, 'bytes 7-9/10'],
        ['bytes=8-99', 'ij',   8, 2, 'bytes 8-9/10'],
    );

    for my $case (@cases) {
        my ($range, $expected, $offset, $length, $content_range) = @$case;
        my $storage = Local::RangeStorage->new(
            blobs => {$SHA256 => blob_result($body)},
        );
        my $response = response_for($storage, $range);

        is($response->status, 206, "$range status");
        is($response->body, $expected, "$range body");
        is($response->header('content-length'), $length, "$range content length");
        is($response->header('content-range'), $content_range, "$range content range");
        is($response->header('accept-ranges'), 'bytes', "$range advertises byte ranges");
        is($response->header('content-type'), 'text/plain', "$range preserves content type");
        is_deeply(
            $storage->{range_calls},
            [[$SHA256, {offset => $offset, length => $length}]],
            "$range passes the bounded range to storage",
        );
        is_deeply($storage->{head_calls}, [$SHA256], "$range reads metadata without the body");
        is($storage->{get_calls}, undef, "$range does not retrieve the full body");
    }
};

subtest 'valid unsatisfiable ranges return 416 without reading bytes' => sub {
    my @cases = (
        ['bytes=10-', 'range starts at the blob size'],
        ['bytes=-0',  'zero suffix length'],
    );

    for my $case (@cases) {
        my ($range, $name) = @$case;
        my $storage = Local::RangeStorage->new(
            blobs => {$SHA256 => blob_result('abcdefghij')},
        );
        my $response = response_for($storage, $range);

        is($response->status, 416, "$name status");
        is($response->header('content-range'), 'bytes */10', "$name content range");
        is($response->header('content-length'), 0, "$name content length");
        is($response->header('accept-ranges'), 'bytes', "$name advertises byte ranges");
        is($response->body, '', "$name body");
        is($storage->{range_calls}, undef, "$name does not read bytes");
    }

    my $storage = Local::RangeStorage->new(
        blobs => {$SHA256 => blob_result('')},
    );
    my $response = response_for($storage, 'bytes=0-');
    is($response->status, 416, 'empty blob range status');
    is($response->header('content-range'), 'bytes */0', 'empty blob content range');
    is($storage->{range_calls}, undef, 'empty blob does not read bytes');
};

subtest 'unsatisfiable fallback range closes the full-body stream' => sub {
    my $body = 'abcdefghij';
    my $stream = Local::ReadStream->new($body);
    my $storage = Local::Storage->new(
        blobs => {$SHA256 => blob_result($body, $stream)},
    );
    my $response = response_for($storage, 'bytes=10-');

    is($response->status, 416, 'fallback range status');
    ok($stream->{closed}, 'unused full-body stream is closed');
    is($stream->{offset}, 0, 'fallback stream is not read');
};

subtest 'malformed, unsupported, and multipart ranges are ignored' => sub {
    my $body = 'abcdefghij';
    for my $range ('bytes=bogus', 'items=0-1', 'bytes=0-1,4-5', 'bytes=5-3') {
        my $storage = Local::RangeStorage->new(
            blobs => {$SHA256 => blob_result($body)},
        );
        my $response = response_for($storage, $range);

        is($response->status, 200, "$range status");
        is($response->body, $body, "$range full body");
        is($response->header('content-length'), length($body), "$range full content length");
        is($response->header('content-range'), undef, "$range has no content range");
        is($storage->{range_calls}, undef, "$range does not call native range retrieval");
        is_deeply($storage->{get_calls}, [$SHA256], "$range retrieves the normal body");
    }
};

subtest 'storage without native ranges gets a bounded scalar fallback' => sub {
    my $body = 'abcdefghij';
    my $storage = Local::Storage->new(blobs => {$SHA256 => blob_result($body)});
    my $response = response_for($storage, 'bytes=2-5');

    is($response->status, 206, 'fallback status');
    is($response->body, 'cdef', 'fallback scalar is sliced');
    is($response->header('content-length'), 4, 'fallback content length');
    is_deeply($storage->{get_calls}, [$SHA256], 'fallback retrieves the normal body once');
};

subtest 'array fallback slices across chunk boundaries' => sub {
    my $body = 'abcdefghij';
    my $storage = Local::Storage->new(
        blobs => {$SHA256 => blob_result($body, ['ab', 'cde', 'fghij'])},
    );
    my $response = response_for($storage, 'bytes=2-5');

    is($response->status, 206, 'array fallback status');
    is_deeply($response->body, ['cde', 'f'], 'array fallback returns only requested chunks');
    is(join('', @{$response->body}), 'cdef', 'array fallback returns requested bytes');
};

subtest 'stream fallback discards only the prefix and closes at the range end' => sub {
    my $body = 'abcdefghij';
    my $stream = Local::ReadStream->new($body);
    my $storage = Local::Storage->new(
        blobs => {$SHA256 => blob_result($body, $stream)},
    );
    my $response = response_for($storage, 'bytes=2-5');

    is($response->status, 206, 'stream fallback status');
    isnt($response->body, $stream, 'stream is wrapped');
    is(read_body($response->body), 'cdef', 'stream fallback returns only requested bytes');
    is($stream->{offset}, 6, 'stream does not read beyond the requested range');
    ok($stream->{closed}, 'stream is closed at the range end');
};

subtest 'getline fallback does not retain bytes beyond the range' => sub {
    my $body = 'abcdefghij';
    my $stream = Local::GetlineStream->new($body);
    my $storage = Local::Storage->new(
        blobs => {$SHA256 => blob_result($body, $stream)},
    );
    my $response = response_for($storage, 'bytes=2-5');
    my $range = $response->body;

    my $chunk = '';
    is($range->read($chunk, 2), 2, 'first bounded read length');
    is($chunk, 'cd', 'first bounded read bytes');
    is($range->buffer, 'ef', 'only bytes still needed by the range are retained');
    is($range->getline, 'ef', 'remaining range bytes are readable with getline');
    is($range->getline, undef, 'getline remains at EOF');
    ok($stream->{closed}, 'getline stream is closed at the range end');

    my $large_stream = Local::GetlineStream->new($body);
    my $large_storage = Local::Storage->new(
        blobs => {$SHA256 => blob_result($body, $large_stream)},
    );
    my $server = Net::Blossom::Server->new(
        storage    => $large_storage,
        chunk_size => 4,
    );
    my $large_range = $server->handle_get_blob(
        request(headers => {Range => 'bytes=7-8'}),
    );

    is(read_body($large_range->body), 'hi',
        'a large getline chunk can span the skipped prefix and range');
    ok($large_stream->{closed}, 'large getline stream closes at the range end');
};

subtest 'native range retrieval handles disappearance and invalid lengths' => sub {
    my $body = 'abcdefghij';
    my $missing = Local::RangeStorage->new(
        blobs => {$SHA256 => blob_result($body)},
    );
    $missing->{range_missing} = 1;
    my $response = response_for($missing, 'bytes=2-5');
    is($response->status, 404, 'disappearing blob returns 404');

    my $short = Local::RangeStorage->new(
        blobs => {$SHA256 => blob_result($body)},
    );
    $short->{range_body} = 'abc';
    like(
        dies { response_for($short, 'bytes=2-5') },
        qr/range body length must match requested length/,
        'short native scalar body is rejected',
    );
};

done_testing;
