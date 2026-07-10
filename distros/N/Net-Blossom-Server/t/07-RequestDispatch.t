use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON ();

use Net::Blossom::BlobDescriptor;
use Net::Blossom::Server;
use Net::Blossom::Server::BlobResult;
use Net::Blossom::Server::Request;

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $SHA256 = '0f343b0931126a20f133d67c2b018a3b5ceca63dd3585a76cb1f3289a274707f';
my $JSON = JSON->new->utf8->canonical;

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
            uploads    => [],
            blobs      => $args{blobs} || {},
            list_blobs => $args{list_blobs} || [],
        }, $class;
    }

    sub begin_upload {
        my ($self, %context) = @_;
        my $upload = Local::Upload->new($self, \%context);
        push @{$self->{uploads}}, $upload;
        return $upload;
    }

    sub get_blob {
        my ($self, $sha256) = @_;
        $self->{last_get_blob} = $sha256;
        return $self->{blobs}{$sha256};
    }

    sub delete_blob {
        my ($self, $sha256, %opts) = @_;
        $self->{last_delete_blob} = [$sha256, \%opts];
        return 1;
    }

    sub list_blobs {
        my ($self, $pubkey, %opts) = @_;
        $self->{last_list_blobs} = [$pubkey, \%opts];
        return $self->{list_blobs} || [];
    }

    sub uploads {
        my ($self) = @_;
        return @{$self->{uploads}};
    }

    sub last_get_blob {
        my ($self) = @_;
        return $self->{last_get_blob};
    }
}

{
    package Local::Upload;
    use strictures 2;

    sub new {
        my ($class, $storage, $context) = @_;
        return bless {
            storage => $storage,
            context => $context,
            chunks  => [],
        }, $class;
    }

    sub write {
        my ($self, $chunk) = @_;
        push @{$self->{chunks}}, $chunk;
        return length $chunk;
    }

    sub commit {
        my ($self, %metadata) = @_;
        $self->{commit} = \%metadata;
        return {
            descriptor => {
                url      => "https://cdn.example.com/$metadata{sha256}.bin",
                sha256   => $metadata{sha256},
                size     => $metadata{size},
                type     => $metadata{type},
                uploaded => $metadata{uploaded},
            },
            created => 1,
        };
    }

    sub abort {
        my ($self) = @_;
        $self->{aborted}++;
        return 1;
    }
}

sub request {
    my (%args) = @_;
    return Net::Blossom::Server::Request->new(
        method         => $args{method},
        path           => $args{path},
        body           => $args{body},
        content_type   => $args{content_type},
        content_length => $args{content_length},
    );
}

subtest 'handle_request dispatches PUT /upload' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });
    my $body = "dispatch body\n";

    my $response = $server->handle_request(
        request(
            method         => 'PUT',
            path           => '/upload',
            body           => $body,
            content_type   => 'text/plain',
            content_length => length($body),
        ),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 201, 'upload status');
    is($JSON->decode($response->body)->{sha256}, sha256_hex($body), 'upload descriptor response');

    my ($upload) = $storage->uploads;
    is($upload->{context}{pubkey}, $PUBKEY, 'pubkey passed to upload handler');
    is_deeply($upload->{chunks}, [$body], 'body reached storage');
};

subtest 'handle_request dispatches GET /<sha256>' => sub {
    my $body = 'dispatch body';
    my $descriptor = Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$SHA256",
        sha256   => $SHA256,
        size     => length($body),
        type     => 'text/plain',
        uploaded => 1725105921,
    );
    my $storage = Local::Storage->new(blobs => {
        $SHA256 => Net::Blossom::Server::BlobResult->new(
            descriptor => $descriptor,
            body       => $body,
        ),
    });
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_request(request(method => 'GET', path => "/$SHA256"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'get blob status');
    is($response->header('content-type'), 'text/plain', 'get blob content type');
    is($response->header('content-length'), length($body), 'get blob content length');
    is($response->body, $body, 'get blob body');
    is($storage->last_get_blob, $SHA256, 'sha256 passed to storage');
};

subtest 'handle_request dispatches HEAD /<sha256>' => sub {
    my $descriptor = Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$SHA256.txt",
        sha256   => $SHA256,
        size     => length('dispatch body'),
        type     => 'text/plain',
        uploaded => 1725105921,
    );
    my $storage = Local::Storage->new(blobs => {
        $SHA256 => Net::Blossom::Server::BlobResult->new(
            descriptor => $descriptor,
            body       => 'dispatch body',
        ),
    });
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_request(request(method => 'HEAD', path => "/$SHA256.txt"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'head blob status');
    is($response->header('content-type'), 'text/plain', 'head blob content type');
    is($response->header('content-length'), length('dispatch body'), 'head blob content length');
    is($response->body, '', 'head blob body');
    is($storage->last_get_blob, $SHA256, 'sha256 passed to storage');
};

subtest 'handle_request dispatches DELETE /<sha256>' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_request(
        request(method => 'DELETE', path => "/$SHA256"),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 204, 'delete blob status');
    is($response->body, '', 'delete blob body');
    is_deeply($storage->{last_delete_blob}, [$SHA256, { pubkey => $PUBKEY }], 'delete passed to storage');
};

subtest 'handle_request dispatches GET /list/<pubkey>' => sub {
    my $descriptor = Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$SHA256",
        sha256   => $SHA256,
        size     => 12,
        type     => 'text/plain',
        uploaded => 1725105921,
    );
    my $storage = Local::Storage->new(list_blobs => [$descriptor]);
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_request(
        request(method => 'GET', path => "/list/$PUBKEY"),
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'list status');
    is_deeply($JSON->decode($response->body), [$descriptor->to_hash], 'list response body');
    is_deeply($storage->{last_list_blobs}, [$PUBKEY, { limit => 100 }], 'list passed to storage');
};

subtest 'handle_request dispatches HEAD /upload preflight' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_request(Net::Blossom::Server::Request->new(
        method  => 'HEAD',
        path    => '/upload',
        headers => {
            'X-SHA-256'        => $SHA256,
            'X-Content-Type'   => 'text/plain',
            'X-Content-Length' => 12,
        },
    ));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'upload preflight status');
    is($response->body, '', 'upload preflight body');
};

subtest 'handle_request dispatches PUT and HEAD /media' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });
    my $body = 'media dispatch';
    my $sha256 = sha256_hex($body);

    my $response = $server->handle_request(
        Net::Blossom::Server::Request->new(
            method         => 'PUT',
            path           => '/media',
            body           => $body,
            content_type   => 'text/plain',
            content_length => length($body),
            headers        => { 'X-SHA-256' => $sha256 },
        ),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 201, 'media upload status');
    is($JSON->decode($response->body)->{sha256}, $sha256, 'media descriptor response');

    $response = $server->handle_request(Net::Blossom::Server::Request->new(
        method  => 'HEAD',
        path    => '/media',
        headers => {
            'X-SHA-256'        => $sha256,
            'X-Content-Type'   => 'text/plain',
            'X-Content-Length' => length($body),
        },
    ));
    is($response->status, 200, 'media preflight status');
};

subtest 'handle_request dispatches PUT /mirror' => sub {
    my $body = 'mirror dispatch';
    my $sha256 = sha256_hex($body);
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(
        storage        => $storage,
        mirror_fetcher => sub {
            my ($url, %opts) = @_;
            $opts{sink}->start(type => 'text/plain', content_length => length($body));
            $opts{sink}->write($body);
            return {
                type           => 'text/plain',
                content_length => length($body),
            };
        },
        clock          => sub { 1725105921 },
    );

    my $response = $server->handle_request(
        Net::Blossom::Server::Request->new(
            method         => 'PUT',
            path           => '/mirror',
            body           => $JSON->encode({ url => "https://source.example/$sha256.txt" }),
            content_type   => 'application/json',
            content_length => length($JSON->encode({ url => "https://source.example/$sha256.txt" })),
        ),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 201, 'mirror status');
    is($JSON->decode($response->body)->{sha256}, $sha256, 'mirror descriptor response');
};

subtest 'handle_request returns 404 for unknown paths' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_request(request(method => 'GET', path => '/missing'));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 404, 'unknown path status');
    is($response->body, '', 'unknown path body');
    is($response->header('content-length'), 0, 'unknown path content length');
};

subtest 'handle_request treats uppercase blob paths as unknown' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);
    my $response;

    is(dies { $response = $server->handle_request(request(method => 'GET', path => '/' . uc($SHA256))) },
        undef, 'uppercase blob path does not croak');
    if (isa_ok($response, 'Net::Blossom::Server::Response')) {
        is($response->status, 404, 'uppercase blob path status');
        is($response->body, '', 'uppercase blob path body');
    }
};

subtest 'handle_request returns 405 for unsupported upload methods' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_request(request(method => 'GET', path => '/upload'));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 405, 'unsupported method status');
    is($response->header('allow'), 'HEAD, PUT', 'allow header');
    is($response->body, '', 'unsupported method body');
};

subtest 'handle_request returns 405 for unsupported list methods' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_request(request(method => 'POST', path => "/list/$PUBKEY"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 405, 'unsupported method status');
    is($response->header('allow'), 'GET', 'allow header');
    is($response->body, '', 'unsupported method body');
};

subtest 'handle_request returns 405 for unsupported blob methods' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_request(request(method => 'POST', path => "/$SHA256"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 405, 'unsupported method status');
    is($response->header('allow'), 'DELETE, GET, HEAD', 'allow header');
    is($response->body, '', 'unsupported method body');
};

subtest 'handle_request validates inputs' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { $server->handle_request('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_request(request(method => 'GET', path => '/missing'), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');
};

done_testing;
