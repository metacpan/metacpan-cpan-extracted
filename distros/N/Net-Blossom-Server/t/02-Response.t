use strictures 2;

use Test::More;

use Net::Blossom::Server::Error;
use Net::Blossom::Server::Response;

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

    sub getline {
        return;
    }
}

subtest 'constructs response objects' => sub {
    my $response = Net::Blossom::Server::Response->new(
        status  => 201,
        headers => {
            'Content-Type' => 'application/json',
            'X-Reason'     => 'created',
        },
        body    => '{"ok":1}',
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 201, 'status');
    is($response->body, '{"ok":1}', 'body');
    is($response->header('content-type'), 'application/json', 'case-insensitive header lookup');
    is($response->header('missing'), undef, 'missing header');
    is_deeply($response->body_chunks, ['{"ok":1}'], 'scalar body as body chunks');
};

subtest 'headers accessor and pairs return copies' => sub {
    my $response = Net::Blossom::Server::Response->new(
        status  => 200,
        headers => { 'Content-Type' => 'text/plain', 'X-Reason' => 'ok' },
        body    => 'ok',
    );

    my $headers = $response->headers;
    $headers->{'content-type'} = 'application/json';
    is($response->header('content-type'), 'text/plain', 'mutating returned headers does not mutate response');

    is_deeply(
        $response->header_pairs,
        ['Content-Type' => 'text/plain', 'X-Reason' => 'ok'],
        'header pairs are deterministic',
    );
};

subtest 'supports array and stream bodies' => sub {
    my $array = Net::Blossom::Server::Response->new(
        status => 200,
        body   => ['a', 'b'],
    );
    is_deeply($array->body_chunks, ['a', 'b'], 'array body chunks');

    my $stream = Local::Body->new;
    my $response = Net::Blossom::Server::Response->new(
        status => 200,
        body   => $stream,
    );
    is($response->body, $stream, 'stream body preserved');
    like(dies { $response->body_chunks },
        qr/stream body cannot be returned as chunks/, 'stream body cannot be coerced to chunks');
};

subtest 'helper constructors build common responses' => sub {
    my $json = Net::Blossom::Server::Response->json({ ok => 1 }, status => 202);
    is($json->status, 202, 'json status');
    is($json->header('content-type'), 'application/json', 'json content type');
    is($json->header('content-length'), length($json->body), 'json content length');
    is($json->body, '{"ok":1}', 'canonical json body');

    my $text = Net::Blossom::Server::Response->text('hello', status => 201);
    is($text->status, 201, 'text status');
    is($text->header('content-type'), 'text/plain; charset=utf-8', 'text content type');
    is($text->header('content-length'), 5, 'text content length');

    my $empty = Net::Blossom::Server::Response->empty(204);
    is($empty->status, 204, 'empty status');
    is($empty->body, '', 'empty body');
    is($empty->header('content-length'), 0, 'empty content length');

    my $redirect = Net::Blossom::Server::Response->redirect('https://cdn.example.com/blob', status => 308);
    is($redirect->status, 308, 'redirect status');
    is($redirect->header('location'), 'https://cdn.example.com/blob', 'redirect location');

    my $error = Net::Blossom::Server::Response->error(404, 'blob missing');
    is($error->status, 404, 'error status');
    is($error->header('x-reason'), 'blob missing', 'error reason header');
};

subtest 'validates response inputs' => sub {
    like(dies { Net::Blossom::Server::Response->new(status => 200, bogus => 1) },
        qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
    like(dies { Net::Blossom::Server::Response->new },
        qr/status is required/, 'status required');
    like(dies { Net::Blossom::Server::Response->new(status => 99) },
        qr/status must be an HTTP status code/, 'low status rejected');
    like(dies { Net::Blossom::Server::Response->new(status => 600) },
        qr/status must be an HTTP status code/, 'high status rejected');
    like(dies { Net::Blossom::Server::Response->new(status => 200, headers => []) },
        qr/headers must be a hash reference/, 'headers hash required');
    like(dies { Net::Blossom::Server::Response->new(status => 200, headers => { Good => [] }) },
        qr/header values must be scalars/, 'header values scalar');
    like(dies { Net::Blossom::Server::Response->new(status => 200, headers => { Good => "ok\nbad" }) },
        qr/header values must not contain CR or LF/, 'header values reject LF');
    like(dies { Net::Blossom::Server::Response->new(status => 200, headers => { Good => "ok\rbad" }) },
        qr/header values must not contain CR or LF/, 'header values reject CR');
    like(dies { Net::Blossom::Server::Response->new(status => 200, headers => { A => 1, a => 2 }) },
        qr/duplicate header/i, 'duplicate case-insensitive header rejected');
    like(dies { Net::Blossom::Server::Response->new(status => 200, body => [{}]) },
        qr/body array values must be scalars/, 'body array scalar chunks');
    like(dies { Net::Blossom::Server::Response->new(status => 200, body => {}) },
        qr/body must be a scalar, array reference, or stream object/, 'bad body rejected');
    like(dies { Net::Blossom::Server::Response->redirect('', status => 307) },
        qr/location is required/, 'redirect location required');
    like(dies { Net::Blossom::Server::Response->json({ ok => 1 }, bogus => 1) },
        qr/unknown option\(s\): bogus/, 'json unknown option rejected');
    like(dies { Net::Blossom::Server::Response->text('ok', bogus => 1) },
        qr/unknown option\(s\): bogus/, 'text unknown option rejected');
    like(dies { Net::Blossom::Server::Response->empty(204, bogus => 1) },
        qr/unknown option\(s\): bogus/, 'empty unknown option rejected');
    like(dies { Net::Blossom::Server::Response->redirect('/x', bogus => 1) },
        qr/unknown option\(s\): bogus/, 'redirect unknown option rejected');
    like(dies { Net::Blossom::Server::Response->error(404, 'missing', bogus => 1) },
        qr/unknown option\(s\): bogus/, 'error unknown option rejected');
};

subtest 'rejects unsafe error response headers' => sub {
    like(dies { Net::Blossom::Server::Error->new(status => 400, headers => { Good => "ok\nbad" }) },
        qr/header values must not contain CR or LF/, 'error header values reject LF');
    like(dies { Net::Blossom::Server::Error->new(status => 400, headers => { Good => "ok\rbad" }) },
        qr/header values must not contain CR or LF/, 'error header values reject CR');
    like(dies { Net::Blossom::Server::Response->error(400, "bad\nreason") },
        qr/header values must not contain CR or LF/, 'response error reason rejects LF before X-Reason header');
    like(dies { Net::Blossom::Server::Error->new(status => 400, reason => "bad\nreason") },
        qr/reason must not contain CR or LF/, 'typed error reason rejects LF');
    like(dies { Net::Blossom::Server::Error->new(status => 400, reason => "bad\rreason")->as_response },
        qr/reason must not contain CR or LF/, 'typed error reason rejects CR before X-Reason header');
};

subtest 'helper constructors validate explicit false statuses' => sub {
    like(dies { Net::Blossom::Server::Response->json({ ok => 1 }, status => 0) },
        qr/status must be an HTTP status code/, 'json rejects explicit zero status');
    like(dies { Net::Blossom::Server::Response->text('ok', status => 0) },
        qr/status must be an HTTP status code/, 'text rejects explicit zero status');
    like(dies { Net::Blossom::Server::Response->redirect('/x', status => 0) },
        qr/status must be an HTTP status code/, 'redirect rejects explicit zero status');
};

done_testing;
