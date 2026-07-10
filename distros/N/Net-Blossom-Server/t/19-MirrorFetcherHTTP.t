use strictures 2;

use Test::More;

use Net::Blossom::Server::Error;
use Net::Blossom::Server::MirrorFetcher::HTTP;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::UA;
    use strictures 2;

    sub new {
        my ($class, %args) = @_;
        return bless { requests => [], %args }, $class;
    }

    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{$self->{requests}}, [$method, $url, $opts];
        die "request failed" if $self->{die};

        my $response = $self->{response} || {
            success => 1,
            status  => 200,
            reason  => 'OK',
            headers => {},
            content => '',
        };

        if (exists $response->{body_chunks}) {
            for my $chunk (@{$response->{body_chunks}}) {
                $opts->{data_callback}->($chunk, $response);
            }
        }
        elsif (exists $response->{content} && ref($opts) eq 'HASH' && $opts->{data_callback}) {
            $opts->{data_callback}->($response->{content}, $response);
        }

        return $response;
    }

    sub requests {
        my ($self) = @_;
        return @{$self->{requests}};
    }
}

{
    package Local::Sink;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless { starts => [], chunks => [] }, $class;
    }

    sub start {
        my ($self, %metadata) = @_;
        push @{$self->{starts}}, { %metadata };
        return 1;
    }

    sub write {
        my ($self, $chunk) = @_;
        push @{$self->{chunks}}, $chunk;
        return length $chunk;
    }

    sub content {
        my ($self) = @_;
        return join '', @{$self->{chunks}};
    }
}

{
    package Local::FailingSink;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub start {
        return 1;
    }

    sub write {
        die "sink write failed";
    }
}

sub error_status(&) {
    my ($code) = @_;
    my $error = dies { $code->() };
    isa_ok($error, 'Net::Blossom::Server::Error');
    return $error->status;
}

subtest 'constructs allowlist-only HTTP mirror fetcher' => sub {
    my $ua = Local::UA->new;
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['CDN.Example', 'media.example'],
        max_bytes     => 1024,
        timeout       => 3,
        user_agent    => $ua,
    );

    isa_ok($fetcher, 'Net::Blossom::Server::MirrorFetcher::HTTP');
    is_deeply($fetcher->allowed_hosts, ['cdn.example', 'media.example'], 'hosts normalized');
    is($fetcher->max_bytes, 1024, 'max bytes accessor');
    is($fetcher->timeout, 3, 'timeout accessor');
    is($fetcher->user_agent, $ua, 'user agent accessor');

    my $hosts = $fetcher->allowed_hosts;
    push @$hosts, 'mutated.example';
    is_deeply($fetcher->allowed_hosts, ['cdn.example', 'media.example'], 'allowed_hosts does not alias');
};

subtest 'validates constructor policy' => sub {
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(max_bytes => 1024) },
        qr/allowed_hosts is required/, 'allowed_hosts required');
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(allowed_hosts => [], max_bytes => 1024) },
        qr/allowed_hosts must not be empty/, 'allowed_hosts cannot be empty');
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(allowed_hosts => ['https://cdn.example'], max_bytes => 1024) },
        qr/allowed_hosts must contain host names only/, 'allowed_hosts rejects URLs');
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(allowed_hosts => ['cdn.example']) },
        qr/max_bytes is required/, 'max_bytes required');
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(allowed_hosts => ['cdn.example'], max_bytes => 0) },
        qr/max_bytes must be a positive integer/, 'max_bytes positive');
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(allowed_hosts => ['cdn.example'], max_bytes => 1024, timeout => 0) },
        qr/timeout must be a positive integer/, 'timeout positive');
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(allowed_hosts => ['cdn.example'], max_bytes => 1024, user_agent => bless {}, 'Local::NoRequest') },
        qr/user_agent must provide request/, 'user agent contract required');
    like(dies { Net::Blossom::Server::MirrorFetcher::HTTP->new(allowed_hosts => ['cdn.example'], max_bytes => 1024, bogus => 1) },
        qr/unknown argument\(s\): bogus/, 'unknown arguments rejected');
};

subtest 'fetch_blob requires a streaming sink' => sub {
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => Local::UA->new,
    );

    like(dies { $fetcher->fetch_blob('https://cdn.example/blob.bin') },
        qr/sink is required/, 'sink required');
    like(dies { $fetcher->fetch_blob('https://cdn.example/blob.bin', sink => bless {}, 'Local::NoSink') },
        qr/sink must provide start and write/, 'sink contract required');
};

subtest 'fetch_blob accepts only allowed HTTP URLs' => sub {
    my $ua = Local::UA->new(response => {
        success => 1,
        status  => 200,
        reason  => 'OK',
        headers => { 'content-type' => 'text/plain', 'content-length' => 4 },
        content => 'body',
    });
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => $ua,
    );

    my $sink = Local::Sink->new;
    my $result = $fetcher->fetch_blob('https://cdn.example/path/blob.txt?download=1', sink => $sink);
    is_deeply($result, {
        type           => 'text/plain',
        content_length => 4,
    }, 'allowed URL returns metadata without buffering body');
    is_deeply($sink->{starts}, [{ type => 'text/plain', content_length => 4 }], 'sink receives metadata');
    is_deeply($sink->{chunks}, ['body'], 'sink receives body chunks');

    my ($request) = $ua->requests;
    is($request->[0], 'GET', 'uses GET');
    is($request->[1], 'https://cdn.example/path/blob.txt?download=1', 'request URL');
    is(ref($request->[2]{data_callback}), 'CODE', 'streams through data_callback');

    is(error_status { $fetcher->fetch_blob('ftp://cdn.example/blob.bin', sink => Local::Sink->new) },
        400, 'non-http URL rejected');
    is(error_status { $fetcher->fetch_blob('https://user:pass@cdn.example/blob.bin', sink => Local::Sink->new) },
        400, 'userinfo URL rejected');
    is(error_status { $fetcher->fetch_blob('https://cdn.example/blob.bin#frag', sink => Local::Sink->new) },
        400, 'fragment URL rejected');
    is(error_status { $fetcher->fetch_blob('https://blocked.example/blob.bin', sink => Local::Sink->new) },
        403, 'non-allowlisted host rejected');
};

subtest 'fetch_blob preserves sink write failures' => sub {
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => Local::UA->new(response => {
            success => 1,
            status  => 200,
            reason  => 'OK',
            headers => { 'content-type' => 'text/plain' },
            content => 'body',
        }),
    );

    like(dies { $fetcher->fetch_blob('https://cdn.example/blob.bin', sink => Local::FailingSink->new) },
        qr/sink write failed/, 'sink write failure is not translated to origin failure');
};

subtest 'fetch_blob starts sink for empty successful responses' => sub {
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => Local::UA->new(response => {
            success => 1,
            status  => 200,
            reason  => 'OK',
            headers => { 'content-type' => 'text/plain', 'content-length' => 0 },
        }),
    );
    my $sink = Local::Sink->new;

    is_deeply($fetcher->fetch_blob('https://cdn.example/empty.txt', sink => $sink), {
        type           => 'text/plain',
        content_length => 0,
    }, 'empty response returns metadata');
    is_deeply($sink->{starts}, [{ type => 'text/plain', content_length => 0 }],
        'empty response starts sink after headers');
    is_deeply($sink->{chunks}, [], 'empty response writes no chunks');
};

subtest 'fetch_blob rejects non-default ports on allowed hosts' => sub {
    my $ua = Local::UA->new(response => {
        success => 1,
        status  => 200,
        reason  => 'OK',
        headers => { 'content-type' => 'text/plain', 'content-length' => 4 },
        content => 'body',
    });
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => $ua,
    );

    # An allowlisted host name must not become a way to reach arbitrary ports
    # (e.g. internal services co-located on that host).
    is(error_status { $fetcher->fetch_blob('http://cdn.example:22/blob.bin', sink => Local::Sink->new) },
        403, 'non-default http port rejected');
    is(error_status { $fetcher->fetch_blob('https://cdn.example:8443/blob.bin', sink => Local::Sink->new) },
        403, 'non-default https port rejected');

    # The scheme default port, explicit or implicit, is allowed.
    ok($fetcher->fetch_blob('https://cdn.example/blob.txt', sink => Local::Sink->new), 'implicit default port allowed');
    ok($fetcher->fetch_blob('https://cdn.example:443/blob.txt', sink => Local::Sink->new), 'explicit default https port allowed');
    ok($fetcher->fetch_blob('http://cdn.example:80/blob.txt', sink => Local::Sink->new), 'explicit default http port allowed');
};

subtest 'fetch_blob rejects redirects and origin failures' => sub {
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => Local::UA->new(response => {
            success => 0,
            status  => 302,
            reason  => 'Found',
            headers => { location => 'https://other.example/blob.bin' },
            content => '',
        }),
    );

    my $sink = Local::Sink->new;
    is(error_status { $fetcher->fetch_blob('https://cdn.example/blob.bin', sink => $sink) },
        502, 'redirect response rejected');
    is_deeply($sink->{chunks}, [], 'redirect body not streamed');

    $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => Local::UA->new(die => 1),
    );
    is(error_status { $fetcher->fetch_blob('https://cdn.example/blob.bin', sink => Local::Sink->new) },
        502, 'client exception rejected');
};

subtest 'fetch_blob enforces response size limits' => sub {
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 4,
        user_agent    => Local::UA->new(response => {
            success => 1,
            status  => 200,
            reason  => 'OK',
            headers => { 'content-length' => 5 },
            content => 'hello',
        }),
    );

    my $sink = Local::Sink->new;
    is(error_status { $fetcher->fetch_blob('https://cdn.example/blob.bin', sink => $sink) },
        413, 'Content-Length over max rejected');
    is_deeply($sink->{chunks}, [], 'oversized Content-Length is rejected before streaming body');

    $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 4,
        user_agent    => Local::UA->new(response => {
            success     => 1,
            status      => 200,
            reason      => 'OK',
            headers     => {},
            body_chunks => ['he', 'llo'],
        }),
    );

    $sink = Local::Sink->new;
    is(error_status { $fetcher->fetch_blob('https://cdn.example/blob.bin', sink => $sink) },
        413, 'stream over max rejected');
    is_deeply($sink->{chunks}, ['he'], 'stream is stopped before oversized chunk is written');
};

subtest 'fetch_blob defaults content type and rejects bad metadata' => sub {
    my $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => Local::UA->new(response => {
            success => 1,
            status  => 200,
            reason  => 'OK',
            headers => {},
            content => 'body',
        }),
    );

    my $sink = Local::Sink->new;
    is_deeply($fetcher->fetch_blob('https://cdn.example/blob.bin', sink => $sink), {
        type => 'application/octet-stream',
    }, 'missing content type defaults');
    is_deeply($sink->{starts}, [{ type => 'application/octet-stream' }], 'default content type passed to sink');
    is($sink->content, 'body', 'body streamed to sink');

    $fetcher = Net::Blossom::Server::MirrorFetcher::HTTP->new(
        allowed_hosts => ['cdn.example'],
        max_bytes     => 1024,
        user_agent    => Local::UA->new(response => {
            success => 1,
            status  => 200,
            reason  => 'OK',
            headers => { 'content-length' => 'abc' },
            content => 'body',
        }),
    );

    is(error_status { $fetcher->fetch_blob('https://cdn.example/blob.bin', sink => Local::Sink->new) },
        502, 'invalid Content-Length rejected');
};

done_testing;
