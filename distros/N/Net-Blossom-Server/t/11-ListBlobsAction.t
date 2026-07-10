use strictures 2;

use Test::More;
use JSON ();

use Net::Blossom::BlobDescriptor;
use Net::Blossom::Server;
use Net::Blossom::Server::Request;

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $CURSOR = '0f343b0931126a20f133d67c2b018a3b5ceca63dd3585a76cb1f3289a274707f';
my $OTHER = 'f' x 64;
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
        return bless { blobs => $args{blobs} || [] }, $class;
    }

    sub begin_upload {
        return Local::Upload->new;
    }

    sub get_blob {
        return;
    }

    sub delete_blob {
        return 0;
    }

    sub list_blobs {
        my ($self, $pubkey, %opts) = @_;
        $self->{last_list_blobs} = [$pubkey, \%opts];
        return $self->{blobs};
    }

    sub last_list_blobs {
        my ($self) = @_;
        return $self->{last_list_blobs};
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
        query  => $args{query},
    );
}

sub descriptor {
    my (%args) = @_;
    my $sha256 = $args{sha256} || $CURSOR;
    return Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$sha256",
        sha256   => $sha256,
        size     => exists $args{size} ? $args{size} : 12,
        type     => $args{type} || 'text/plain',
        uploaded => $args{uploaded} || 1725105921,
    );
}

subtest 'handle_list_blobs returns descriptor JSON array' => sub {
    my @descriptors = (
        descriptor(sha256 => $CURSOR, uploaded => 1725105922),
        descriptor(sha256 => $OTHER, uploaded => 1725105921),
    );
    my $storage = Local::Storage->new(blobs => \@descriptors);
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_list_blobs(request(method => 'GET', path => "/list/$PUBKEY"));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'list status');
    is($response->header('content-type'), 'application/json', 'json content type');
    is_deeply($JSON->decode($response->body), [map { $_->to_hash } @descriptors], 'list body');
    is_deeply($storage->last_list_blobs, [$PUBKEY, { limit => 100 }], 'pubkey and default limit passed to storage');
};

subtest 'handle_list_blobs passes cursor and limit query parameters' => sub {
    my $storage = Local::Storage->new(blobs => []);
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_list_blobs(request(
        method => 'GET',
        path   => "/list/$PUBKEY",
        query  => {
            cursor => $CURSOR,
            limit  => 50,
        },
    ));

    is($response->status, 200, 'list status');
    is_deeply($storage->last_list_blobs, [$PUBKEY, { cursor => $CURSOR, limit => 50 }], 'query options passed to storage');
};

subtest 'handle_list_blobs applies configurable list limit bounds' => sub {
    my $storage = Local::Storage->new(blobs => []);
    my $server = Net::Blossom::Server->new(storage => $storage, max_list_limit => 25);

    my $response = $server->handle_list_blobs(request(method => 'GET', path => "/list/$PUBKEY"));
    is($response->status, 200, 'list status without query limit');
    is_deeply($storage->last_list_blobs, [$PUBKEY, { limit => 25 }], 'configured default limit passed to storage');

    $response = $server->handle_list_blobs(request(
        method => 'GET',
        path   => "/list/$PUBKEY",
        query  => { limit => 10 },
    ));
    is($response->status, 200, 'list status with smaller query limit');
    is_deeply($storage->last_list_blobs, [$PUBKEY, { limit => 10 }], 'smaller query limit passed to storage');

    $response = $server->handle_list_blobs(request(
        method => 'GET',
        path   => "/list/$PUBKEY",
        query  => { limit => 25 },
    ));
    is($response->status, 200, 'list status with exact maximum query limit');
    is_deeply($storage->last_list_blobs, [$PUBKEY, { limit => 25 }], 'exact maximum query limit passed to storage');

    $storage = Local::Storage->new(blobs => []);
    $server = Net::Blossom::Server->new(storage => $storage, max_list_limit => 25);
    my $error = dies {
        $server->handle_list_blobs(request(
            method => 'GET',
            path   => "/list/$PUBKEY",
            query  => { limit => 26 },
        ));
    };
    isa_ok($error, 'Net::Blossom::Server::Error', 'over-limit query throws a typed error');
    is($error->status, 400, 'over-limit query maps to a BUD-12 400');
    is($error->reason, 'limit must not exceed 25', 'over-limit query reason');
    is($storage->last_list_blobs, undef, 'over-limit query does not reach storage');
};

subtest 'constructor validates max_list_limit' => sub {
    is(
        Net::Blossom::Server->new(storage => Local::Storage->new, max_list_limit => 25)->max_list_limit,
        25,
        'custom max list limit accepted',
    );
    like(dies {
        Net::Blossom::Server->new(storage => Local::Storage->new, max_list_limit => 0);
    }, qr/max_list_limit must be a positive integer/, 'zero rejected');
    like(dies {
        Net::Blossom::Server->new(storage => Local::Storage->new, max_list_limit => 'big');
    }, qr/max_list_limit must be a positive integer/, 'non-integer rejected');
    like(dies {
        Net::Blossom::Server->new(storage => Local::Storage->new, max_list_limit => [25]);
    }, qr/max_list_limit must be a positive integer/, 'reference rejected');
};

subtest 'handle_list_blobs validates request inputs' => sub {
    my $storage = Local::Storage->new(blobs => []);
    my $server = Net::Blossom::Server->new(storage => $storage);

    like(dies { $server->handle_list_blobs('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_list_blobs(request(method => 'POST', path => "/list/$PUBKEY")) },
        qr/list request method must be GET/, 'method rejected');
    like(dies { $server->handle_list_blobs(request(method => 'GET', path => '/list')) },
        qr/list request path must be \/list\/<pubkey>/, 'path shape rejected');
    like(dies { $server->handle_list_blobs(request(method => 'GET', path => '/list/' . uc($PUBKEY))) },
        qr/pubkey must be 64-char lowercase hex/, 'uppercase pubkey rejected');
    like(dies { $server->handle_list_blobs(request(method => 'GET', path => "/list/$PUBKEY"), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');
    is($storage->last_list_blobs, undef, 'invalid requests do not reach storage');
};

subtest 'handle_list_blobs rejects malformed query parameters with 400' => sub {
    my $storage = Local::Storage->new(blobs => []);
    my $server = Net::Blossom::Server->new(storage => $storage);

    my @cases = (
        ['uppercase cursor', { cursor => 'A' x 64 }],
        ['non-scalar cursor', { cursor => [$CURSOR] }],
        ['zero limit', { limit => 0 }],
        ['non-scalar limit', { limit => [50] }],
        ['unsupported parameter', { until => 1 }],
    );
    for my $case (@cases) {
        my ($label, $query) = @$case;
        my $error = dies {
            $server->handle_list_blobs(request(method => 'GET', path => "/list/$PUBKEY", query => $query));
        };
        isa_ok($error, 'Net::Blossom::Server::Error', "$label throws a typed error");
        is($error->status, 400, "$label maps to a BUD-12 400");
    }

    is($storage->last_list_blobs, undef, 'malformed queries do not reach storage');
};

subtest 'handle_list_blobs validates storage output' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new(blobs => descriptor()));

    like(dies { $server->handle_list_blobs(request(method => 'GET', path => "/list/$PUBKEY")) },
        qr/storage list_blobs must return an array reference/, 'array result required');

    $server = Net::Blossom::Server->new(storage => Local::Storage->new(blobs => [{}]));
    like(dies { $server->handle_list_blobs(request(method => 'GET', path => "/list/$PUBKEY")) },
        qr/storage list_blobs items must be Net::Blossom::BlobDescriptor/,
        'descriptor items required');
};

done_testing;
