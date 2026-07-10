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
        return bless { blobs => $args{blobs} || {} }, $class;
    }

    sub begin_upload {
        return Local::Upload->new;
    }

    sub get_blob {
        my ($self, $sha256) = @_;
        $self->{last_get_blob} = $sha256;
        return $self->{blobs}{$sha256};
    }

    sub delete_blob {
        return 0;
    }

    sub list_blobs {
        return [];
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
        return bless { data => $data, offset => 0 }, $class;
    }

    sub read {
        my ($self, undef, $length) = @_;
        return 0 if $self->{offset} >= length $self->{data};
        $_[1] = substr($self->{data}, $self->{offset}, $length);
        $self->{offset} += length $_[1];
        return length $_[1];
    }
}

sub request {
    my (%args) = @_;
    return Net::Blossom::Server::Request->new(
        method => $args{method},
        path   => $args{path},
    );
}

sub descriptor {
    my (%args) = @_;
    my $body = exists $args{body} ? $args{body} : 'hello body';
    return Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$SHA256",
        sha256   => $SHA256,
        size     => exists $args{size} ? $args{size} : length($body),
        type     => exists $args{type} ? $args{type} : 'text/plain',
        uploaded => 1725105921,
        extra    => { alt => 'https://mirror.example.com/blob' },
    );
}

sub blob_result {
    my (%args) = @_;
    my $body = exists $args{body} ? $args{body} : 'hello body';
    return Net::Blossom::Server::BlobResult->new(
        descriptor => $args{descriptor} || descriptor(body => $body),
        body       => $body,
    );
}

subtest 'handle_get_blob returns blob body response' => sub {
    my $body = 'hello body';
    my $storage = Local::Storage->new(blobs => { $SHA256 => blob_result(body => $body) });
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_get_blob(request(method => 'GET', path => "/$SHA256"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'blob status');
    is($response->header('content-type'), 'text/plain', 'blob content type');
    is($response->header('content-length'), length($body), 'blob content length');
    is($response->body, $body, 'blob body');
    is($storage->last_get_blob, $SHA256, 'sha256 passed to storage');
};

subtest 'handle_get_blob returns stream bodies without flattening' => sub {
    my $stream = Local::ReadStream->new('hello body');
    my $storage = Local::Storage->new(blobs => {
        $SHA256 => blob_result(
            descriptor => descriptor(size => 10),
            body       => $stream,
        ),
    });
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_get_blob(request(method => 'GET', path => "/$SHA256"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'stream status');
    is($response->header('content-length'), 10, 'stream content length from descriptor');
    is($response->body, $stream, 'stream body preserved');
};

subtest 'handle_get_blob sets defensive headers against sniffing and inline script' => sub {
    my $server = sub {
        my ($type) = @_;
        my $storage = Local::Storage->new(blobs => {
            $SHA256 => blob_result(descriptor => descriptor(type => $type, body => 'payload'), body => 'payload'),
        });
        return Net::Blossom::Server->new(storage => $storage)
            ->handle_get_blob(request(method => 'GET', path => "/$SHA256"));
    };

    my $plain = $server->('text/plain');
    is($plain->header('x-content-type-options'), 'nosniff', 'nosniff always present');
    is($plain->header('content-disposition'), undef, 'text/plain is not forced to download');

    # Actively-rendered types that can carry script must be sent as attachments.
    for my $type ('text/html', 'text/html; charset=utf-8', 'image/svg+xml',
        'application/xhtml+xml', 'application/xml', 'text/xml', 'IMAGE/SVG+XML') {
        my $response = $server->($type);
        is($response->header('content-disposition'), 'attachment',
            "dangerous type $type served as attachment");
        is($response->header('content-type'), $type,
            "content-type preserved for $type");
        is($response->header('x-content-type-options'), 'nosniff',
            "nosniff present for $type");
    }

    # Types clients legitimately render inline must not be forced to download.
    for my $type ('image/png', 'image/jpeg', 'application/pdf', 'video/mp4',
        'audio/mpeg', 'application/octet-stream') {
        my $response = $server->($type);
        is($response->header('content-disposition'), undef,
            "inline-safe type $type not forced to download");
        is($response->header('x-content-type-options'), 'nosniff',
            "nosniff present for $type");
    }
};

subtest 'handle_get_blob returns 404 when storage has no descriptor' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_get_blob(request(method => 'GET', path => "/$SHA256"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 404, 'missing descriptor status');
    is($response->body, '', 'missing descriptor body');
    is($response->header('content-length'), 0, 'missing descriptor content length');
    is($storage->last_get_blob, $SHA256, 'missing sha256 passed to storage');
};

subtest 'handle_get_blob validates request inputs' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { $server->handle_get_blob('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_get_blob(request(method => 'POST', path => "/$SHA256")) },
        qr/blob request method must be GET/, 'method rejected');
    like(dies { $server->handle_get_blob(request(method => 'GET', path => '/missing')) },
        qr/blob request path must be \/<sha256>/, 'path shape rejected');
    like(dies { $server->handle_get_blob(request(method => 'GET', path => '/' . uc($SHA256))) },
        qr/sha256 must be 64-char lowercase hex/, 'uppercase hash rejected');
    like(dies { $server->handle_get_blob(request(method => 'GET', path => "/$SHA256"), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');
};

subtest 'handle_get_blob rejects invalid storage descriptors' => sub {
    my $storage = Local::Storage->new(blobs => { $SHA256 => { sha256 => $SHA256 } });
    my $server = Net::Blossom::Server->new(storage => $storage);

    like(dies { $server->handle_get_blob(request(method => 'GET', path => "/$SHA256")) },
        qr/storage get_blob must return a Net::Blossom::Server::BlobResult/,
        'storage result class required');

    my $other = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
    my $bad_descriptor = Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$other",
        sha256   => $other,
        size     => 12,
        type     => 'text/plain',
        uploaded => 1725105921,
    );
    $storage = Local::Storage->new(blobs => {
        $SHA256 => Net::Blossom::Server::BlobResult->new(
            descriptor => $bad_descriptor,
            body       => 'hello body!!',
        ),
    });
    $server = Net::Blossom::Server->new(storage => $storage);

    like(dies { $server->handle_get_blob(request(method => 'GET', path => "/$SHA256")) },
        qr/storage returned descriptor sha256 mismatch/,
        'storage descriptor hash must match request path');
};

done_testing;
