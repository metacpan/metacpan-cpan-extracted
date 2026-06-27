use strict; use warnings;
use Test2::V0;
use Future::AsyncAwait;

plan skip_all => 'set RELEASE_TESTING=1 to run the full-stack PAGI::Server e2e'
    unless $ENV{RELEASE_TESTING};
plan skip_all => "full-stack deps unavailable: $@"
    unless eval { require PAGI::Server; require Net::Async::HTTP; require HTTP::Request::Common;
                  require IO::Async::Loop; require Digest::MD5; require JSON::MaybeXS; 1 };

use PAGI::Request;

# An app that drives the feature under test: pull each part off the multipart
# stream, hashing file parts as they arrive and buffering field values, then
# report a JSON summary the test can assert the round-trip against.
my $app = async sub {
    my ($scope, $receive, $send) = @_;
    my $req = PAGI::Request->new($scope, $receive);
    my @summary;
    my $stream = $req->multipart_stream;
    while (defined(my $part = await $stream->next)) {
        if ($part->is_file) {
            my $size = 0;
            my $md5  = Digest::MD5->new;
            await $part->stream_to(sub {
                my ($chunk) = @_;
                $size += length $chunk;
                $md5->add($chunk);
                return Future->done;
            });
            push @summary, { type => 'file', name => $part->name,
                             filename => $part->filename, size => $size, md5 => $md5->hexdigest };
        }
        else {
            push @summary, { type => 'field', name => $part->name, value => (await $part->value) };
        }
    }
    my $body = JSON::MaybeXS::encode_json(\@summary);
    await $send->({ type => 'http.response.start', status => 200,
                    headers => [['content-type', 'application/json']] });
    await $send->({ type => 'http.response.body', body => $body, more => 0 });
};

subtest 'real PAGI::Server round-trips multipart_stream parts' => sub {
    my $big = 'X' x 200_000;   # large file part -> multi-chunk delivery through the real server

    my $loop = IO::Async::Loop->new;
    my $server = PAGI::Server->new(app => $app, host => '127.0.0.1', port => 0,
        quiet => 1, access_log => undef);   # access_log => undef keeps the run pristine
    $loop->add($server);
    $server->listen->get;
    my $port = $server->port;

    my $http_request = HTTP::Request::Common::POST(
        "http://127.0.0.1:$port/",
        Content_Type => 'form-data',
        Content => [
            title => 'Hello',
            doc   => [ undef, 'a.txt',   'Content_Type' => 'text/plain',               Content => "line1\nline2" ],
            big   => [ undef, 'big.bin', 'Content_Type' => 'application/octet-stream', Content => $big ],
        ],
    );

    my $http = Net::Async::HTTP->new;
    $loop->add($http);
    my $response = $http->do_request(request => $http_request)->get;

    $server->shutdown->get;
    $loop->remove($server);

    is $response->code, 200, 'Response status is 200';

    my $summary = JSON::MaybeXS::decode_json($response->decoded_content);

    my ($title) = grep { $_->{type} eq 'field' && $_->{name} eq 'title' } @$summary;
    is $title, { type => 'field', name => 'title', value => 'Hello' }, 'title field round-tripped';

    my ($doc) = grep { $_->{type} eq 'file' && $_->{name} eq 'doc' } @$summary;
    is $doc, {
        type => 'file', name => 'doc', filename => 'a.txt',
        size => 11, md5 => Digest::MD5::md5_hex("line1\nline2"),
    }, 'doc file round-tripped (size + md5)';

    my ($bigp) = grep { $_->{type} eq 'file' && $_->{name} eq 'big' } @$summary;
    is $bigp, {
        type => 'file', name => 'big', filename => 'big.bin',
        size => 200000, md5 => Digest::MD5::md5_hex($big),
    }, 'big file round-tripped across chunks (size + md5)';
};

done_testing;
