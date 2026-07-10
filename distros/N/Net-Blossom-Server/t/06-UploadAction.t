use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON ();

use Net::Blossom::Server;
use Net::Blossom::Server::Request;

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
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
        return bless { uploads => [], %args }, $class;
    }

    sub begin_upload {
        my ($self, %context) = @_;
        my $upload = Local::Upload->new($self, \%context);
        push @{$self->{uploads}}, $upload;
        return $upload;
    }

    sub get_blob {
        return;
    }

    sub delete_blob {
        return 0;
    }

    sub list_blobs {
        return [];
    }

    sub uploads {
        my ($self) = @_;
        return @{$self->{uploads}};
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
            created => $self->{storage}{existing} ? 0 : 1,
        };
    }

    sub abort {
        my ($self) = @_;
        $self->{aborted}++;
        return 1;
    }
}

sub upload_request {
    my ($body, %args) = @_;
    my %headers;
    $headers{'X-SHA-256'} = $args{x_sha256} if defined $args{x_sha256};
    return Net::Blossom::Server::Request->new(
        method         => $args{method} || 'PUT',
        path           => defined $args{path} ? $args{path} : '/upload',
        headers        => \%headers,
        body           => $body,
        content_type   => $args{content_type},
        content_length => defined $args{content_length} ? $args{content_length} : length($body),
    );
}

subtest 'handle_upload returns created JSON response' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });
    my $body = "hello blossom\n";

    my $response = $server->handle_upload(
        upload_request($body, content_type => 'text/plain', x_sha256 => sha256_hex($body)),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 201, 'created upload status');
    is($response->header('content-type'), 'application/json', 'json content type');

    my $json = $JSON->decode($response->body);
    is($json->{sha256}, sha256_hex($body), 'response descriptor sha');
    is($json->{size}, length($body), 'response descriptor size');
    is($json->{type}, 'text/plain', 'response descriptor type');
    is($json->{uploaded}, 1725105921, 'response descriptor uploaded');

    my ($upload) = $storage->uploads;
    is($upload->{context}{type}, 'text/plain', 'content type passed to storage');
    is($upload->{context}{expected_sha256}, sha256_hex($body), 'X-SHA-256 passed to storage');
    is($upload->{context}{content_length}, length($body), 'content length passed to storage');
    is($upload->{context}{pubkey}, $PUBKEY, 'pubkey passed to storage');
    is_deeply($upload->{chunks}, [$body], 'body written to storage');
};

subtest 'handle_upload maps X-SHA-256 mismatch to BUD-02 conflict before commit' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $error = dies {
        $server->handle_upload(upload_request('body', x_sha256 => '0' x 64));
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 409, 'sha mismatch status');
    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'mismatch does not commit');
    is($upload->{aborted}, 1, 'mismatch aborts upload');
};

subtest 'handle_upload maps Content-Length mismatch to BUD-02 bad request before commit' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $error = dies {
        $server->handle_upload(upload_request('body', content_length => length('body') + 1));
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 400, 'content length mismatch status');
    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'mismatch does not commit');
    is($upload->{aborted}, 1, 'mismatch aborts upload');
};

subtest 'handle_upload enforces max_upload_bytes with a 413' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(
        storage => $storage, max_upload_bytes => 4, clock => sub { 1725105921 });

    my $error = dies {
        $server->handle_upload(upload_request('oversized body'));
    };
    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 413, 'oversize upload rejected with 413');
    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'oversize upload does not commit');
    is($upload->{aborted}, 1, 'oversize upload aborts');

    my $ok_storage = Local::Storage->new;
    my $ok_server = Net::Blossom::Server->new(
        storage => $ok_storage, max_upload_bytes => 4, clock => sub { 1725105921 });
    my $response = $ok_server->handle_upload(upload_request('byte'));
    is($response->status, 201, 'upload exactly at the size limit succeeds');
};

subtest 'constructor validates max_upload_bytes' => sub {
    like(dies {
        Net::Blossom::Server->new(storage => Local::Storage->new, max_upload_bytes => 0);
    }, qr/max_upload_bytes must be a positive integer/, 'zero rejected');
    like(dies {
        Net::Blossom::Server->new(storage => Local::Storage->new, max_upload_bytes => 'big');
    }, qr/max_upload_bytes must be a positive integer/, 'non-integer rejected');
};

subtest 'handle_upload returns ok for existing blobs' => sub {
    my $storage = Local::Storage->new(existing => 1);
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });

    my $response = $server->handle_upload(upload_request('body'), pubkey => $PUBKEY);

    is($response->status, 200, 'existing upload status');
    my $json = $JSON->decode($response->body);
    is($json->{sha256}, sha256_hex('body'), 'existing descriptor body');
    is($json->{type}, 'application/octet-stream', 'default upload type');
};

subtest 'handle_upload accepts empty body requests' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });

    my $response = $server->handle_upload(upload_request('', content_length => 0), pubkey => $PUBKEY);

    is($response->status, 201, 'empty upload status');
    is($JSON->decode($response->body)->{size}, 0, 'empty upload size');
};

subtest 'handle_upload validates request inputs' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { $server->handle_upload('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_upload(upload_request('body', method => 'POST')) },
        qr/upload request method must be PUT/, 'PUT required');
    like(dies { $server->handle_upload(upload_request('body', path => '/other')) },
        qr/upload request path must be \/upload/, 'upload path required');
    like(dies {
        $server->handle_upload(Net::Blossom::Server::Request->new(method => 'PUT', path => '/upload'));
    }, qr/upload request body is required/, 'body required');
    like(dies { $server->handle_upload(upload_request('body'), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');
    like(dies { $server->handle_upload(upload_request('body'), pubkey => 'A' x 64) },
        qr/pubkey must be 64-char lowercase hex/, 'pubkey validated by receive_blob');
};

done_testing;
