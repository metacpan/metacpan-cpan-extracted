use strictures 2;

use Test::More;

use Net::Blossom::Server::Request;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::Body;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub read {
        return;
    }
}

subtest 'constructs normalized request objects' => sub {
    my $request = Net::Blossom::Server::Request->new(
        method      => 'put',
        path        => '/upload',
        query       => { limit => 10, tag => ['image', 'public'] },
        headers     => {
            'Content-Type'   => 'image/png',
            'Content-Length' => 4,
            'X-Reason'       => 'accepted',
        },
        body        => 'data',
        remote_addr => '203.0.113.7',
    );

    isa_ok($request, 'Net::Blossom::Server::Request');
    is($request->method, 'PUT', 'method is normalized to uppercase');
    is($request->path, '/upload', 'path');
    is($request->remote_addr, '203.0.113.7', 'remote address');
    is($request->content_type, 'image/png', 'content type from header');
    is($request->content_length, 4, 'content length from header');
    is($request->header('content-type'), 'image/png', 'header lookup is case-insensitive');
    is($request->header('CONTENT-LENGTH'), 4, 'uppercase header lookup');
    is($request->header('missing'), undef, 'missing header');
    is($request->query_param('limit'), 10, 'single query parameter');
    is($request->query_param('tag'), 'image', 'first repeated query parameter');
    is_deeply([$request->query_params('tag')], ['image', 'public'], 'all repeated query parameters');
    ok($request->has_body, 'has body');
};

subtest 'headers and query accessors return copies' => sub {
    my $request = Net::Blossom::Server::Request->new(
        method  => 'GET',
        path    => '/list/pubkey',
        query   => { cursor => 'abc', tag => ['one'] },
        headers => { Accept => 'application/json' },
    );

    my $headers = $request->headers;
    $headers->{accept} = 'text/plain';
    is($request->header('accept'), 'application/json', 'mutating returned headers does not mutate request');

    my $query = $request->query;
    $query->{cursor} = 'changed';
    push @{$query->{tag}}, 'two';
    is($request->query_param('cursor'), 'abc', 'mutating returned query scalar does not mutate request');
    is_deeply([$request->query_params('tag')], ['one'], 'mutating returned query array does not mutate request');
};

subtest 'accepts stream-like request bodies' => sub {
    my $body = Local::Body->new;
    my $request = Net::Blossom::Server::Request->new(
        method => 'PUT',
        path   => '/upload',
        body   => $body,
    );

    is($request->body, $body, 'body stream is preserved');
    ok($request->has_body, 'stream body counts as body');
};

subtest 'validates request inputs' => sub {
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', bogus => 1) },
        qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
    like(dies { Net::Blossom::Server::Request->new(path => '/upload') },
        qr/method is required/, 'method required');
    like(dies { Net::Blossom::Server::Request->new(method => [], path => '/upload') },
        qr/method must be a scalar/, 'method scalar required');
    like(dies { Net::Blossom::Server::Request->new(method => 'BAD METHOD', path => '/upload') },
        qr/method must be an HTTP token/, 'method token required');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET') },
        qr/path is required/, 'path required');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => 'upload') },
        qr/path must start with \//, 'absolute path required');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload?x=1') },
        qr/path must not contain a query string/, 'query string rejected in path');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', headers => []) },
        qr/headers must be a hash reference/, 'headers hash required');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', headers => { Good => [] }) },
        qr/header values must be scalars/, 'header values scalar');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', headers => { A => 1, a => 2 }) },
        qr/duplicate header/i, 'duplicate case-insensitive header rejected');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', query => []) },
        qr/query must be a hash reference/, 'query hash required');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', query => { tag => [{}] }) },
        qr/query values must be scalars/, 'query values scalar');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', content_length => -1) },
        qr/content_length must be a non-negative integer/, 'negative content length rejected');
    like(dies { Net::Blossom::Server::Request->new(method => 'GET', path => '/upload', body => {}) },
        qr/body must be a scalar or stream object/, 'bad body rejected');
};

done_testing;
