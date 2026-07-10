use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON ();

use Net::Blossom::Server;
use Net::Blossom::Server::Error;
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

sub media_request {
    my ($body, %args) = @_;
    my %headers;
    $headers{'X-SHA-256'} = $args{x_sha256} if defined $args{x_sha256};
    return Net::Blossom::Server::Request->new(
        method         => $args{method} || 'PUT',
        path           => defined $args{path} ? $args{path} : '/media',
        headers        => \%headers,
        body           => $body,
        content_type   => $args{content_type},
        content_length => defined $args{content_length} ? $args{content_length} : length($body),
    );
}

sub head_media_request {
    my (%headers) = @_;
    return Net::Blossom::Server::Request->new(
        method  => 'HEAD',
        path    => '/media',
        headers => \%headers,
    );
}

subtest 'handle_media stores media bytes through the upload pipeline' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });
    my $body = "image bytes\n";
    my $sha256 = sha256_hex($body);

    my $response = $server->handle_media(
        media_request(
            $body,
            content_type => 'image/png',
            x_sha256     => $sha256,
        ),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 201, 'created media status');
    is($response->header('content-type'), 'application/json', 'json content type');
    is($JSON->decode($response->body)->{sha256}, $sha256, 'response descriptor hash');

    my ($upload) = $storage->uploads;
    is($upload->{context}{type}, 'image/png', 'content type passed to storage');
    is($upload->{context}{expected_sha256}, $sha256, 'X-SHA-256 passed to storage');
    is($upload->{context}{content_length}, length($body), 'content length passed to storage');
    is($upload->{context}{pubkey}, $PUBKEY, 'pubkey passed to storage');
    is_deeply($upload->{chunks}, [$body], 'body written to storage unchanged');
};

subtest 'handle_media returns ok for existing processed media' => sub {
    my $storage = Local::Storage->new(existing => 1);
    my $server = Net::Blossom::Server->new(storage => $storage, clock => sub { 1725105921 });

    my $response = $server->handle_media(media_request('body', x_sha256 => sha256_hex('body')));

    is($response->status, 200, 'existing media status');
};

subtest 'handle_media maps X-SHA-256 mismatch to BUD-05 conflict before commit' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $error = dies {
        $server->handle_media(media_request('body', x_sha256 => '0' x 64));
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 409, 'sha mismatch status');
    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'mismatch does not commit');
    is($upload->{aborted}, 1, 'mismatch aborts upload');
};

subtest 'handle_media maps Content-Length mismatch to BUD-05 bad request before commit' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $error = dies {
        $server->handle_media(media_request('body', content_length => length('body') + 1));
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 400, 'content length mismatch status');
    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'mismatch does not commit');
    is($upload->{aborted}, 1, 'mismatch aborts upload');
};

subtest 'handle_head_media accepts and rejects BUD-05 preflight metadata' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);
    my $response = $server->handle_head_media(head_media_request(
        'X-SHA-256'        => sha256_hex('body'),
        'X-Content-Type'   => 'image/png',
        'X-Content-Length' => 4,
    ));

    is($response->status, 200, 'media preflight accepted');
    is($response->body, '', 'media preflight body empty');

    is($server->handle_head_media(head_media_request(
        'X-Content-Type'   => 'image/png',
        'X-Content-Length' => 4,
    ))->status, 400, 'missing X-SHA-256 rejected');
    is($server->handle_head_media(head_media_request(
        'X-SHA-256'      => sha256_hex('body'),
        'X-Content-Type' => 'image/png',
    ))->status, 411, 'missing X-Content-Length rejected');
};

subtest 'media handlers validate programmer inputs' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { $server->handle_media('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_media(media_request('body', method => 'POST')) },
        qr/media request method must be PUT/, 'PUT required');
    like(dies { $server->handle_media(media_request('body', path => '/upload')) },
        qr/media request path must be \/media/, 'media path required');
    like(dies {
        $server->handle_media(Net::Blossom::Server::Request->new(method => 'PUT', path => '/media'));
    }, qr/media request body is required/, 'body required');
    like(dies { $server->handle_media(media_request('body'), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'media unknown option rejected');

    like(dies { $server->handle_head_media('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'head request object required');
    like(dies {
        $server->handle_head_media(Net::Blossom::Server::Request->new(method => 'PUT', path => '/media'));
    }, qr/media preflight method must be HEAD/, 'HEAD required');
    like(dies {
        $server->handle_head_media(Net::Blossom::Server::Request->new(method => 'HEAD', path => '/upload'));
    }, qr/media preflight path must be \/media/, 'media preflight path required');
};

done_testing;
