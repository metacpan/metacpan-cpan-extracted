use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;
use File::Temp qw(tempfile);

use PAGI::Request::BodyStream;

# Mock receive function
sub mock_receive {
    my @chunks = @_;
    my $i = 0;
    return sub {
        my $chunk = $chunks[$i++];
        return Future->done($chunk);
    };
}

subtest 'basic streaming' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => 'Hello', more => 1 },
        { type => 'http.request', body => ' World', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(receive => $receive);

    my $chunk1 = $stream->next_chunk->get;
    is $chunk1, 'Hello', 'first chunk';
    ok !$stream->is_done, 'not done yet';

    my $chunk2 = $stream->next_chunk->get;
    is $chunk2, ' World', 'second chunk';
    ok $stream->is_done, 'done after last chunk';

    is $stream->bytes_read, 11, 'bytes_read correct';
};

subtest 'max_bytes limit' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => 'Hello World', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(
        receive => $receive,
        max_bytes => 5,
    );

    like dies { $stream->next_chunk->get }, qr/max_bytes exceeded/, 'throws on limit exceeded';
};

subtest 'UTF-8 decoding' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => "caf\xc3\xa9", more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(
        receive => $receive,
        decode => 'UTF-8',
    );

    my $chunk = $stream->next_chunk->get;
    is $chunk, "café", 'UTF-8 decoded';
};

subtest 'disconnect handling' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => 'Hello', more => 1 },
        { type => 'http.disconnect' },
    );

    my $stream = PAGI::Request::BodyStream->new(receive => $receive);

    my $chunk1 = $stream->next_chunk->get;
    is $chunk1, 'Hello', 'first chunk';

    my $chunk2 = $stream->next_chunk->get;
    is $chunk2, undef, 'undef on disconnect';
    ok $stream->is_done, 'done after disconnect';
};

subtest 'UTF-8 boundary handling - split multi-byte sequence' => sub {
    # Split café (caf\xc3\xa9) across chunks: "caf\xc3" and "\xa9"
    my $receive = mock_receive(
        { type => 'http.request', body => "caf\xc3", more => 1 },
        { type => 'http.request', body => "\xa9", more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(
        receive => $receive,
        decode => 'UTF-8',
    );

    my $chunk1 = $stream->next_chunk->get;
    is $chunk1, "caf", 'first chunk without incomplete sequence';

    my $chunk2 = $stream->next_chunk->get;
    is $chunk2, "é", 'second chunk completes the sequence';

    ok $stream->is_done, 'stream done';
};

subtest 'empty chunks are handled' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => '', more => 1 },
        { type => 'http.request', body => 'data', more => 1 },
        { type => 'http.request', body => '', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(receive => $receive);

    my $chunk1 = $stream->next_chunk->get;
    is $chunk1, '', 'empty first chunk';

    my $chunk2 = $stream->next_chunk->get;
    is $chunk2, 'data', 'non-empty chunk';

    my $chunk3 = $stream->next_chunk->get;
    is $chunk3, '', 'empty last chunk';

    ok $stream->is_done, 'stream done';
    is $stream->bytes_read, 4, 'bytes_read only counts non-empty';
};

subtest 'stream_to custom sink' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => 'Hello', more => 1 },
        { type => 'http.request', body => ' World', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(receive => $receive);

    my $collected = '';
    my $bytes = $stream->stream_to(sub {
        my ($chunk) = @_;
        $collected .= $chunk;
    })->get;

    is $collected, 'Hello World', 'all chunks collected';
    is $bytes, 11, 'bytes_processed correct';
    ok $stream->is_done, 'stream done';
};

subtest 'stream_to_file' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => 'Hello', more => 1 },
        { type => 'http.request', body => ' World', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(receive => $receive);

    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;

    my $bytes = $stream->stream_to_file($filename)->get;

    is $bytes, 11, 'bytes written correct';
    ok $stream->is_done, 'stream done';

    # Read file to verify
    open my $read_fh, '<', $filename or die "Cannot read $filename: $!";
    my $content = do { local $/; <$read_fh> };
    close $read_fh;

    is $content, 'Hello World', 'file content correct';
};

subtest 'custom limit_name in error' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => 'Too much data', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(
        receive => $receive,
        max_bytes => 5,
        limit_name => 'upload_size',
    );

    like dies { $stream->next_chunk->get }, qr/upload_size exceeded/, 'custom limit name in error';
};

subtest 'strict UTF-8 mode' => sub {
    # Invalid UTF-8 sequence
    my $receive = mock_receive(
        { type => 'http.request', body => "\xFF\xFE", more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(
        receive => $receive,
        decode => 'UTF-8',
        strict => 1,
    );

    like dies { $stream->next_chunk->get }, qr/Failed to decode/, 'strict mode throws on invalid UTF-8';
};

subtest 'no receive callback throws' => sub {
    like dies {
        PAGI::Request::BodyStream->new();
    }, qr/receive is required/, 'throws without receive';
};

subtest 'bytes_read tracking' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => '12345', more => 1 },
        { type => 'http.request', body => '67890', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(receive => $receive);

    is $stream->bytes_read, 0, 'zero before reading';

    $stream->next_chunk->get;
    is $stream->bytes_read, 5, 'five after first chunk';

    $stream->next_chunk->get;
    is $stream->bytes_read, 10, 'ten after second chunk';
};

subtest 'stream_to_file rejects decode option' => sub {
    my $receive = mock_receive(
        { type => 'http.request', body => 'test', more => 0 },
    );

    my $stream = PAGI::Request::BodyStream->new(
        receive => $receive,
        decode => 'UTF-8',
    );

    like dies { $stream->stream_to_file('/tmp/test.bin')->get },
        qr/cannot be used with decode/,
        'stream_to_file throws with decode option';
};

subtest 'PAGI::Request body_stream' => sub {
    use PAGI::Request;

    my $chunks = [
        { type => 'http.request', body => 'Hello', more => 1 },
        { type => 'http.request', body => ' World', more => 0 },
    ];
    my $i = 0;
    my $receive = sub { Future->done($chunks->[$i++]) };

    my $scope = { method => 'POST', path => '/', headers => [] };
    my $req = PAGI::Request->new($scope, $receive);

    my $stream = $req->body_stream;
    isa_ok $stream, 'PAGI::Request::BodyStream';

    my $chunk1 = $stream->next_chunk->get;
    is $chunk1, 'Hello', 'first chunk via Request';
};

subtest 'body_stream mutual exclusivity' => sub {
    use PAGI::Request;

    # Streaming then buffered should fail
    my $scope1 = { method => 'POST', path => '/', headers => [] };
    my $receive1 = sub { Future->done({ type => 'http.request', body => 'test', more => 0 }) };
    my $req1 = PAGI::Request->new($scope1, $receive1);
    $req1->body_stream;
    like dies { $req1->body->get }, qr/streaming/, 'body after stream fails';

    # Buffered then streaming should fail
    my $scope2 = { method => 'POST', path => '/', headers => [] };
    my $receive2 = sub { Future->done({ type => 'http.request', body => 'x', more => 0 }) };
    my $req2 = PAGI::Request->new($scope2, $receive2);
    $req2->body->get;
    like dies { $req2->body_stream }, qr/consumed|read/, 'stream after body fails';
};

done_testing;
