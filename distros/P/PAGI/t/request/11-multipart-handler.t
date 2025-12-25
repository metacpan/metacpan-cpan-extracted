#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 'lib';
use PAGI::Request::MultiPartHandler;

# Helper to build multipart body
sub build_multipart {
    my ($boundary, @parts) = @_;
    my $body = '';
    for my $part (@parts) {
        $body .= "--$boundary\r\n";
        $body .= "Content-Disposition: form-data; name=\"$part->{name}\"";
        if ($part->{filename}) {
            $body .= "; filename=\"$part->{filename}\"";
        }
        $body .= "\r\n";
        if ($part->{content_type}) {
            $body .= "Content-Type: $part->{content_type}\r\n";
        }
        $body .= "\r\n";
        $body .= $part->{data};
        $body .= "\r\n";
    }
    $body .= "--$boundary--\r\n";
    return $body;
}

sub mock_receive {
    my ($body) = @_;
    my $sent = 0;
    return async sub {
        if (!$sent) {
            $sent = 1;
            return { type => 'http.request', body => $body, more => 0 };
        }
        return { type => 'http.disconnect' };
    };
}

subtest 'parse simple form fields' => sub {
    my $boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
    my $body = build_multipart($boundary,
        { name => 'title', data => 'Hello World' },
        { name => 'count', data => '42' },
    );

    my $receive = mock_receive($body);
    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary => $boundary,
        receive  => $receive,
    );

    my ($form, $uploads) = (async sub { await $handler->parse })->()->get;

    isa_ok($form, ['Hash::MultiValue'], 'form is Hash::MultiValue');
    is($form->get('title'), 'Hello World', 'title field');
    is($form->get('count'), '42', 'count field');
    is([$uploads->keys], [], 'no uploads');
};

subtest 'parse file upload' => sub {
    my $boundary = '----TestBoundary';
    my $body = build_multipart($boundary,
        { name => 'name', data => 'John' },
        {
            name         => 'avatar',
            filename     => 'photo.jpg',
            content_type => 'image/jpeg',
            data         => 'fake image bytes',
        },
    );

    my $receive = mock_receive($body);
    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary => $boundary,
        receive  => $receive,
    );

    my ($form, $uploads) = (async sub { await $handler->parse })->()->get;

    is($form->get('name'), 'John', 'form field');

    my $upload = $uploads->get('avatar');
    isa_ok($upload, ['PAGI::Request::Upload'], 'upload object');
    is($upload->filename, 'photo.jpg', 'filename');
    is($upload->content_type, 'image/jpeg', 'content_type');
    is($upload->slurp, 'fake image bytes', 'content');
};

subtest 'parse multiple files same field' => sub {
    my $boundary = '----Multi';
    my $body = build_multipart($boundary,
        { name => 'files', filename => 'a.txt', content_type => 'text/plain', data => 'AAA' },
        { name => 'files', filename => 'b.txt', content_type => 'text/plain', data => 'BBB' },
    );

    my $receive = mock_receive($body);
    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary => $boundary,
        receive  => $receive,
    );

    my ($form, $uploads) = (async sub { await $handler->parse })->()->get;

    my @files = $uploads->get_all('files');
    is(scalar(@files), 2, 'two files');
    is($files[0]->filename, 'a.txt', 'first file');
    is($files[1]->filename, 'b.txt', 'second file');
};

subtest 'spool large files to disk' => sub {
    my $boundary = '----Large';
    my $large_data = 'x' x (65 * 1024);  # 65KB, over 64KB threshold
    my $body = build_multipart($boundary,
        { name => 'large', filename => 'big.bin', content_type => 'application/octet-stream', data => $large_data },
    );

    my $receive = mock_receive($body);
    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary => $boundary,
        receive  => $receive,
    );

    my ($form, $uploads) = (async sub { await $handler->parse })->()->get;

    my $upload = $uploads->get('large');
    ok($upload->is_on_disk, 'large file is spooled to disk');
    ok(-f $upload->temp_path, 'temp file exists');
    is(length($upload->slurp), 65 * 1024, 'content length matches');
};

subtest 'enforce max_files limit' => sub {
    my $boundary = '----MaxFiles';
    # Build body with 3 files but limit to 2
    my $body = build_multipart($boundary,
        { name => 'f1', filename => '1.txt', data => 'a' },
        { name => 'f2', filename => '2.txt', data => 'b' },
        { name => 'f3', filename => '3.txt', data => 'c' },
    );

    my $receive = mock_receive($body);
    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary  => $boundary,
        receive   => $receive,
        max_files => 2,
    );

    like(
        dies { (async sub { await $handler->parse })->()->get },
        qr/Too many files/,
        'dies when exceeding max_files'
    );
};

subtest 'enforce max_fields limit' => sub {
    my $boundary = '----MaxFields';
    my $body = build_multipart($boundary,
        { name => 'f1', data => 'a' },
        { name => 'f2', data => 'b' },
        { name => 'f3', data => 'c' },
    );

    my $receive = mock_receive($body);
    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary   => $boundary,
        receive    => $receive,
        max_fields => 2,
    );

    like(
        dies { (async sub { await $handler->parse })->()->get },
        qr/Too many fields/,
        'dies when exceeding max_fields'
    );
};

subtest 'enforce max_field_size limit' => sub {
    my $boundary = '----MaxSize';
    my $large_data = 'x' x (100 * 1024);  # 100KB form field (no filename = not a file)
    my $body = build_multipart($boundary,
        { name => 'big_field', data => $large_data },
    );

    my $receive = mock_receive($body);
    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary       => $boundary,
        receive        => $receive,
        max_field_size => 50 * 1024,  # 50KB limit for form fields
    );

    like(
        dies { (async sub { await $handler->parse })->()->get },
        qr/Form field too large/,
        'dies when exceeding max_field_size'
    );
};

subtest 'chunked input streaming' => sub {
    my $boundary = '----Chunked';
    my $full_body = build_multipart($boundary,
        { name => 'title', data => 'Hello' },
        { name => 'doc', filename => 'test.txt', content_type => 'text/plain', data => 'file content here' },
    );

    # Split body into chunks
    my @chunks;
    my $chunk_size = 30;
    for (my $i = 0; $i < length($full_body); $i += $chunk_size) {
        push @chunks, substr($full_body, $i, $chunk_size);
    }

    my $index = 0;
    my $receive = async sub {
        if ($index >= @chunks) {
            return { type => 'http.disconnect' };
        }
        my $chunk = $chunks[$index++];
        return {
            type => 'http.request',
            body => $chunk,
            more => $index < @chunks,
        };
    };

    my $handler = PAGI::Request::MultiPartHandler->new(
        boundary => $boundary,
        receive  => $receive,
    );

    my ($form, $uploads) = (async sub { await $handler->parse })->()->get;

    is($form->get('title'), 'Hello', 'form field from chunked input');
    my $upload = $uploads->get('doc');
    is($upload->slurp, 'file content here', 'file content from chunked input');
};

done_testing;
