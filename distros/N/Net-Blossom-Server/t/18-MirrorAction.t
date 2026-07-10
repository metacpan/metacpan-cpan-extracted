use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON ();

use Net::Blossom::Server;
use Net::Blossom::Server::AuthorizationResult;
use Net::Blossom::Server::Error;
use Net::Blossom::Server::MirrorFetcher::HTTP;
use Net::Blossom::Server::Request;

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $OTHER_SHA256 = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
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

{
    package Local::Fetcher;
    use strictures 2;

    sub new {
        my ($class, %args) = @_;
        return bless { %args, urls => [] }, $class;
    }

    sub fetch_blob {
        my ($self, $url, %opts) = @_;
        push @{$self->{urls}}, $url;
        die "origin failed" if $self->{fail};
        die "sink is required" unless defined $opts{sink};

        my $response = $self->{response} || {};
        my %metadata;
        $metadata{type} = $response->{type} if defined $response->{type};
        $metadata{content_length} = $response->{content_length} if defined $response->{content_length};
        $opts{sink}->start(%metadata);

        my @chunks = exists $response->{body_chunks}
            ? @{$response->{body_chunks}}
            : (defined $response->{body} ? ($response->{body}) : ());
        $opts{sink}->write($_) for @chunks;

        return \%metadata;
    }

    sub request {
        die "HTTP request should not be reached";
    }
}

sub mirror_request {
    my ($url, %args) = @_;
    my $body = defined $url ? $JSON->encode({ url => $url }) : $args{body};
    return Net::Blossom::Server::Request->new(
        method         => $args{method} || 'PUT',
        path           => defined $args{path} ? $args{path} : '/mirror',
        body           => $body,
        content_type   => 'application/json',
        content_length => length($body),
    );
}

sub authorization {
    my (@hashes) = @_;
    return Net::Blossom::Server::AuthorizationResult->new(
        pubkey => $PUBKEY,
        action => 'upload',
        hashes => \@hashes,
    );
}

subtest 'handle_mirror fetches a remote URL and stores the downloaded blob' => sub {
    my @chunks = ('mirrored ', "bytes\n");
    my $body = join '', @chunks;
    my $sha256 = sha256_hex($body);
    my $fetcher = Local::Fetcher->new(response => {
        body_chunks    => \@chunks,
        type           => 'text/plain',
        content_length => length($body),
    });
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(
        storage        => $storage,
        mirror_fetcher => $fetcher,
        clock          => sub { 1725105921 },
    );

    my $response = $server->handle_mirror(
        mirror_request("https://source.example/$sha256.txt?download=1"),
        pubkey        => $PUBKEY,
        authorization => authorization($sha256),
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 201, 'mirrored blob status');
    is($JSON->decode($response->body)->{sha256}, $sha256, 'response descriptor hash');
    is_deeply($fetcher->{urls}, ["https://source.example/$sha256.txt?download=1"], 'fetcher receives URL');

    my ($upload) = $storage->uploads;
    is($upload->{context}{type}, 'text/plain', 'origin content type passed to storage');
    is($upload->{context}{content_length}, length($body), 'origin content length passed to storage');
    is($upload->{context}{pubkey}, $PUBKEY, 'pubkey passed to storage');
    is_deeply($upload->{context}{allowed_sha256}, [$sha256], 'authorized hashes passed to storage');
    is_deeply($upload->{chunks}, \@chunks, 'origin body streamed to storage');
};

subtest 'handle_mirror returns ok for existing mirrored blobs' => sub {
    my $body = 'existing bytes';
    my $fetcher = Local::Fetcher->new(response => { body => $body });
    my $server = Net::Blossom::Server->new(
        storage        => Local::Storage->new(existing => 1),
        mirror_fetcher => $fetcher,
    );

    my $response = $server->handle_mirror(mirror_request('https://source.example/blob.bin'));

    is($response->status, 200, 'existing mirror status');
    is($JSON->decode($response->body)->{sha256}, sha256_hex($body), 'existing descriptor hash');
};

subtest 'handle_mirror fails closed without a configured fetcher' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_mirror(mirror_request('https://source.example/blob.bin'));

    is($response->status, 503, 'mirror unavailable without fetcher');
    is($response->body, '', 'mirror unavailable body');
};

subtest 'handle_mirror maps malformed client input to BUD-04 errors' => sub {
    my $server = Net::Blossom::Server->new(
        storage        => Local::Storage->new,
        mirror_fetcher => sub {
            my ($url, %opts) = @_;
            $opts{sink}->start(type => 'text/plain', content_length => length 'body');
            $opts{sink}->write('body');
            return { type => 'text/plain', content_length => length 'body' };
        },
    );

    is($server->handle_mirror(mirror_request(undef, body => 'not json'))->status, 400,
        'malformed JSON rejected');
    is($server->handle_mirror(mirror_request(undef, body => $JSON->encode([])))->status, 400,
        'non-object JSON rejected');
    is($server->handle_mirror(mirror_request('ftp://source.example/blob.bin'))->status, 400,
        'non-http URL rejected');
    is($server->handle_mirror(mirror_request('https://user:pass@source.example/blob.bin'))->status, 400,
        'URL userinfo rejected');
};

subtest 'handle_mirror maps origin failures to BUD-04 bad gateway' => sub {
    my $fetcher = Local::Fetcher->new(fail => 1);
    my $server = Net::Blossom::Server->new(
        storage        => Local::Storage->new,
        mirror_fetcher => $fetcher,
    );

    my $response = $server->handle_mirror(mirror_request('https://source.example/blob.bin'));

    is($response->status, 502, 'origin failure status');
    is($response->body, '', 'origin failure body');
};

subtest 'handle_mirror preserves typed mirror fetcher policy failures' => sub {
    my $server = Net::Blossom::Server->new(
        storage        => Local::Storage->new,
        mirror_fetcher => Net::Blossom::Server::MirrorFetcher::HTTP->new(
            allowed_hosts => ['allowed.example'],
            max_bytes     => 1024,
            user_agent    => Local::Fetcher->new(response => { body => 'body' }),
        ),
    );

    my $response = $server->handle_mirror(mirror_request('https://blocked.example/blob.bin'));

    is($response->status, 403, 'allowlist rejection status');
    is($response->header('x-reason'), 'Mirror URL host is not allowed', 'allowlist rejection reason');
};

subtest 'handle_mirror maps origin length mismatches to BUD-04 bad gateway before commit' => sub {
    my $fetcher = Local::Fetcher->new(response => {
        body           => 'body',
        content_length => length('body') + 1,
    });
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(
        storage        => $storage,
        mirror_fetcher => $fetcher,
    );

    my $error = dies {
        $server->handle_mirror(mirror_request('https://source.example/blob.bin'));
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 502, 'origin length mismatch status');
    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'origin length mismatch does not commit');
    is($upload->{aborted}, 1, 'origin length mismatch aborts upload');
};

subtest 'handle_mirror rejects unauthorized downloaded hashes before commit' => sub {
    my $body = 'different bytes';
    my $fetcher = Local::Fetcher->new(response => { body => $body });
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(
        storage        => $storage,
        mirror_fetcher => $fetcher,
    );

    my $error = dies {
        $server->handle_mirror(
            mirror_request('https://source.example/blob.bin'),
            pubkey        => $PUBKEY,
            authorization => authorization($OTHER_SHA256),
        );
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 409, 'unauthorized hash status');
    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'unauthorized mirror does not commit');
    is($upload->{aborted}, 1, 'unauthorized mirror aborts upload');
};

subtest 'handle_mirror validates programmer inputs' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { Net::Blossom::Server->new(storage => Local::Storage->new, mirror_fetcher => 'not fetcher') },
        qr/mirror_fetcher must be a code reference or object with fetch_blob/, 'fetcher contract validated');
    like(dies { $server->handle_mirror('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_mirror(mirror_request('https://source.example/blob.bin', method => 'POST')) },
        qr/mirror request method must be PUT/, 'PUT required');
    like(dies { $server->handle_mirror(mirror_request('https://source.example/blob.bin', path => '/upload')) },
        qr/mirror request path must be \/mirror/, 'mirror path required');
    like(dies { $server->handle_mirror(mirror_request('https://source.example/blob.bin'), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');
};

done_testing;
