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
}

{
    package Local::HeadStorage;
    use strictures 2;

    our @ISA = ('Local::Storage');

    sub head_blob {
        my ($self, $sha256) = @_;
        $self->{last_head_blob} = $sha256;
        return $self->{blobs}{$sha256};
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
        url      => "https://cdn.example.com/$SHA256.txt",
        sha256   => $SHA256,
        size     => exists $args{size} ? $args{size} : length($body),
        type     => exists $args{type} ? $args{type} : 'text/plain',
        uploaded => 1725105921,
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

subtest 'handle_head_blob returns metadata without the blob body' => sub {
    my $storage = Local::Storage->new(blobs => { $SHA256 => blob_result(body => 'hello body') });
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_head_blob(request(method => 'HEAD', path => "/$SHA256"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'head blob status');
    is($response->header('content-type'), 'text/plain', 'content type from descriptor');
    is($response->header('content-length'), length('hello body'), 'content length from descriptor');
    is($response->body, '', 'head response body is empty');
    is($storage->{last_get_blob}, $SHA256, 'fallback get_blob used');
};

subtest 'handle_head_blob sets the same defensive headers as GET' => sub {
    my $head = sub {
        my ($type) = @_;
        my $storage = Local::Storage->new(blobs => {
            $SHA256 => blob_result(descriptor => descriptor(type => $type)),
        });
        return Net::Blossom::Server->new(storage => $storage)
            ->handle_head_blob(request(method => 'HEAD', path => "/$SHA256"));
    };

    my $plain = $head->('text/plain');
    is($plain->header('x-content-type-options'), 'nosniff', 'nosniff always present');
    is($plain->header('content-disposition'), undef, 'text/plain is not forced to download');

    my $html = $head->('text/html');
    is($html->header('content-disposition'), 'attachment', 'dangerous type served as attachment');
    is($html->header('x-content-type-options'), 'nosniff', 'nosniff present for dangerous type');

    my $png = $head->('image/png');
    is($png->header('content-disposition'), undef, 'inline-safe type not forced to download');
};

subtest 'handle_head_blob uses optional storage head_blob method' => sub {
    my $storage = Local::HeadStorage->new(blobs => { $SHA256 => descriptor(size => 99) });
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_head_blob(request(method => 'HEAD', path => "/$SHA256.pdf"));

    is($response->status, 200, 'extended blob path accepted');
    is($response->header('content-length'), 99, 'descriptor returned by head_blob used');
    is($response->body, '', 'empty body');
    is($storage->{last_head_blob}, $SHA256, 'head_blob receives hash without extension');
    is($storage->{last_get_blob}, undef, 'get_blob not called when head_blob exists');
};

subtest 'handle_get_blob accepts optional file extension from BUD-01' => sub {
    my $body = 'hello body';
    my $storage = Local::Storage->new(blobs => { $SHA256 => blob_result(body => $body) });
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_get_blob(request(method => 'GET', path => "/$SHA256.txt"));

    is($response->status, 200, 'get blob extension status');
    is($response->body, $body, 'get blob extension body');
    is($storage->{last_get_blob}, $SHA256, 'get_blob receives hash without extension');
};

subtest 'handle_head_blob returns 404 when the blob is absent' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_head_blob(request(method => 'HEAD', path => "/$SHA256"));

    is($response->status, 404, 'missing blob status');
    is($response->body, '', 'missing blob body');
    is($response->header('content-length'), 0, 'missing blob content length');
};

subtest 'handle_head_blob validates inputs and storage results' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { $server->handle_head_blob('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_head_blob(request(method => 'GET', path => "/$SHA256")) },
        qr/blob head request method must be HEAD/, 'HEAD required');
    like(dies { $server->handle_head_blob(request(method => 'HEAD', path => '/missing')) },
        qr/blob request path must be \/<sha256>/, 'path shape rejected');
    like(dies { $server->handle_head_blob(request(method => 'HEAD', path => '/' . uc($SHA256))) },
        qr/sha256 must be 64-char lowercase hex/, 'uppercase hash rejected');
    like(dies { $server->handle_head_blob(request(method => 'HEAD', path => "/$SHA256"), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');

    my $storage = Local::HeadStorage->new(blobs => { $SHA256 => { sha256 => $SHA256 } });
    $server = Net::Blossom::Server->new(storage => $storage);
    like(dies { $server->handle_head_blob(request(method => 'HEAD', path => "/$SHA256")) },
        qr/storage head_blob must return a Net::Blossom::BlobDescriptor or Net::Blossom::Server::BlobResult/,
        'head_blob result class required');
};

done_testing;
