use strict;
use warnings;

use Test2::V0;
use Net::Async::MCP::Server;
use Future;

# Helper: build a fully-formed 2026-07-28 request envelope. Tests can override
# any field by passing args. Mirrors t/02-protocol-2026-07-28.t's helper.
# Helper: the standard 2026-07-28 params envelope with the required _meta
# block. Pass extra params (uri, name, arguments) to merge them alongside
# _meta. Mirrors t/02-protocol-2026-07-28.t's helper.
sub _params {
    my (%extra) = @_;
    return {
        _meta => {
            'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
            'io.modelcontextprotocol/clientCapabilities' => {},
        },
        %extra,
    };
}

sub _req {
    my (%override) = @_;
    my %base = (
        jsonrpc => '2.0',
        id      => 1,
        method  => 'resources/list',
        params  => _params(),
    );
    return { %base, %override };
}

# --- resources -------------------------------------------------------------

subtest 'resources/list wire shape' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_resource(
        uri         => 'file:///a.txt',
        name        => 'a',
        mimeType    => 'text/plain',
        description => 'A file',
        title       => 'A (display)',
    );
    $server->register_resource(
        uri  => 'file:///b.txt',
        name => 'b',
    );

    my $response = $server->handle(_req(method => 'resources/list', id => 1));

    ok($response, 'got response');
    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    is(scalar @{ $r->{resources} }, 2, 'two resources listed');

    my ($full, $bare) = @{ $r->{resources} };
    is($full->{uri}, 'file:///a.txt', 'uri present');
    is($full->{name}, 'a', 'name present');
    is($full->{mimeType}, 'text/plain', 'mimeType present when set');
    is($full->{description}, 'A file', 'description present when set');
    is($full->{title}, 'A (display)', 'title present when set');

    is($bare->{uri}, 'file:///b.txt', 'bare resource uri present');
    is($bare->{name}, 'b', 'bare resource name present');
    ok(!exists $bare->{mimeType}, 'mimeType absent when not set');
    ok(!exists $bare->{description}, 'description absent when not set');
    ok(!exists $bare->{title}, 'title absent when not set');
};

subtest 'resources/read default wrapping: bare scalar becomes one text content' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_resource(
        uri      => 'file:///a.txt',
        name     => 'a',
        mimeType => 'text/plain',
        code     => sub { my ($uri) = @_; return "contents of $uri" },
    );

    my $response = $server->handle(_req(
        method => 'resources/read',
        id     => 2,
        params => _params(
            uri => 'file:///a.txt',
        ),
    ));

    my $r = $response->{result};
    is(scalar @{ $r->{contents} }, 1, 'one content block');
    is($r->{contents}[0]{uri}, 'file:///a.txt', 'content uri echoes requested uri');
    is($r->{contents}[0]{text}, 'contents of file:///a.txt', 'text is the code return value');
    is($r->{contents}[0]{mimeType}, 'text/plain', 'mimeType tagged from the resource registration');
};

subtest 'resources/read code passthrough: hashref with contents passed through verbatim' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_resource(
        uri  => 'file:///multi.txt',
        name => 'multi',
        code => sub {
            return {
                contents => [
                    { uri => 'file:///multi.txt', mimeType => 'text/plain', text => 'part one' },
                    { uri => 'file:///multi.txt', mimeType => 'text/plain', text => 'part two' },
                ],
            };
        },
    );

    my $response = $server->handle(_req(
        method => 'resources/read',
        id     => 3,
        params => _params(
            uri => 'file:///multi.txt',
        ),
    ));

    my $r = $response->{result};
    is(scalar @{ $r->{contents} }, 2, 'both content parts passed through');
    is($r->{contents}[0]{text}, 'part one', 'first part verbatim');
    is($r->{contents}[1]{text}, 'part two', 'second part verbatim');
};

subtest 'resources/read unknown uri returns -32602' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle(_req(
        method => 'resources/read',
        id     => 4,
        params => _params(
            uri => 'file:///does-not-exist.txt',
        ),
    ));

    ok(exists $response->{error}, 'JSON-RPC error returned');
    is($response->{error}{code}, -32602, 'error code -32602 Invalid params');
    like($response->{error}{message}, qr/unknown resource/i, 'message mentions unknown resource');
};

subtest 'capabilities advertise resources only when >=1 resource registered' => sub {
    my $empty = Net::Async::MCP::Server->new;
    my $empty_response = $empty->handle(_req(method => 'server/discover', id => 5));
    ok(
        !exists $empty_response->{result}{capabilities}{resources},
        'resources capability absent with none registered',
    );

    my $with_one = Net::Async::MCP::Server->new;
    $with_one->register_resource(uri => 'file:///a.txt', name => 'a');
    my $with_response = $with_one->handle(_req(method => 'server/discover', id => 6));
    ok(
        exists $with_response->{result}{capabilities}{resources},
        'resources capability present once >=1 registered',
    );
};

# --- prompts -----------------------------------------------------------------

subtest 'prompts/list wire shape' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_prompt(
        name        => 'greet',
        title       => 'Greet (display)',
        description => 'Says hello',
        arguments   => [ { name => 'who', required => 1 } ],
    );
    $server->register_prompt(
        name => 'bare',
    );

    my $response = $server->handle(_req(method => 'prompts/list', id => 7));

    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    is(scalar @{ $r->{prompts} }, 2, 'two prompts listed');

    my ($full, $bare) = @{ $r->{prompts} };
    is($full->{name}, 'greet', 'name present');
    is($full->{title}, 'Greet (display)', 'title present when set');
    is($full->{description}, 'Says hello', 'description present when set');
    is($full->{arguments}[0]{name}, 'who', 'arguments passed through');

    is($bare->{name}, 'bare', 'bare prompt name present');
    is($bare->{arguments}, [], 'arguments defaults to empty arrayref');
    ok(!exists $bare->{title}, 'title absent when not set');
    ok(!exists $bare->{description}, 'description absent when not set');
};

subtest 'prompts/get default wrapping: bare scalar becomes one user text message' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_prompt(
        name => 'greet',
        code => sub { my ($args) = @_; return "Hello, $args->{who}!" },
    );

    my $response = $server->handle(_req(
        method => 'prompts/get',
        id     => 8,
        params => _params(
            name      => 'greet',
            arguments => { who => 'World' },
        ),
    ));

    my $r = $response->{result};
    is(scalar @{ $r->{messages} }, 1, 'one message');
    is($r->{messages}[0]{role}, 'user', 'default role is user');
    is($r->{messages}[0]{content}{type}, 'text', 'content type is text');
    is($r->{messages}[0]{content}{text}, 'Hello, World!', 'text is the code return value');
};

subtest 'prompts/get code passthrough: hashref with messages passed through verbatim' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_prompt(
        name => 'conversation',
        code => sub {
            return {
                description => 'A short exchange',
                messages    => [
                    { role => 'user',      content => { type => 'text', text => 'hi' } },
                    { role => 'assistant', content => { type => 'text', text => 'hello there' } },
                ],
            };
        },
    );

    my $response = $server->handle(_req(
        method => 'prompts/get',
        id     => 9,
        params => _params(
            name      => 'conversation',
            arguments => {},
        ),
    ));

    my $r = $response->{result};
    is($r->{description}, 'A short exchange', 'description passed through');
    is(scalar @{ $r->{messages} }, 2, 'both messages passed through');
    is($r->{messages}[1]{role}, 'assistant', 'second message role verbatim (not forced to user)');
};

subtest 'prompts/get unknown name returns -32602' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle(_req(
        method => 'prompts/get',
        id     => 10,
        params => _params(
            name      => 'does_not_exist',
            arguments => {},
        ),
    ));

    ok(exists $response->{error}, 'JSON-RPC error returned');
    is($response->{error}{code}, -32602, 'error code -32602 Invalid params');
    like($response->{error}{message}, qr/unknown prompt/i, 'message mentions unknown prompt');
};

subtest 'prompts/get missing required argument returns -32602 without running code' => sub {
    my $server = Net::Async::MCP::Server->new;
    my $ran = 0;
    $server->register_prompt(
        name      => 'greet',
        arguments => [ { name => 'who', required => 1 }, { name => 'mood' } ],
        code      => sub { $ran++; return 'hi' },
    );

    for my $args ( {}, { mood => 'x' }, { who => undef } ) {
        my $response = $server->handle(_req(
            method => 'prompts/get',
            id     => 30,
            params => _params( name => 'greet', arguments => $args ),
        ));
        is($response->{error}{code}, -32602, 'code -32602');
        is($response->{error}{message}, "Invalid params: missing required argument 'who'", 'message');
    }
    is($ran, 0, 'code not invoked');

    my $ok = $server->handle(_req(
        method => 'prompts/get',
        id     => 31,
        params => _params( name => 'greet', arguments => { who => 'W' } ),
    ));
    ok(!$ok->{error}, 'present required argument passes');
    is($ran, 1, 'code invoked');
};

subtest 'capabilities advertise prompts only when >=1 prompt registered' => sub {
    my $empty = Net::Async::MCP::Server->new;
    my $empty_response = $empty->handle(_req(method => 'server/discover', id => 11));
    ok(
        !exists $empty_response->{result}{capabilities}{prompts},
        'prompts capability absent with none registered',
    );

    my $with_one = Net::Async::MCP::Server->new;
    $with_one->register_prompt(name => 'greet');
    my $with_response = $with_one->handle(_req(method => 'server/discover', id => 12));
    ok(
        exists $with_response->{result}{capabilities}{prompts},
        'prompts capability present once >=1 registered',
    );
};

# --- regression: k29/k30/k31 -------------------------------------------------

subtest 'resources/read dying code returns -32603, not an exception' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_resource(
        uri  => 'file:///boom.txt',
        name => 'boom',
        code => sub { die "resource exploded\n" },
    );

    my $response = eval { $server->handle(_req(
        method => 'resources/read',
        id     => 20,
        params => _params(
            uri => 'file:///boom.txt',
        ),
    )) };

    ok($response, 'got response, no exception escaped handle()');
    ok(exists $response->{error}, 'JSON-RPC error returned');
    is($response->{error}{code}, -32603, 'error code -32603 Internal error');
    like($response->{error}{message}, qr/exploded/, 'message carries the die text');
};

subtest 'resources/read registered but codeless resource returns -32603' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_resource(uri => 'file:///nocode.txt', name => 'nocode');

    my $response = eval { $server->handle(_req(
        method => 'resources/read',
        id     => 21,
        params => _params(
            uri => 'file:///nocode.txt',
        ),
    )) };

    ok($response, 'got response, no exception escaped handle()');
    ok(exists $response->{error}, 'JSON-RPC error returned');
    is($response->{error}{code}, -32603, 'error code -32603 Internal error');
    like(
        $response->{error}{message},
        qr/has no implementation/,
        'message explains the resource has no implementation',
    );
};

subtest 'prompts/get dying code returns -32603, not an exception' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_prompt(
        name => 'boom',
        code => sub { die "prompt exploded\n" },
    );

    my $response = eval { $server->handle(_req(
        method => 'prompts/get',
        id     => 22,
        params => _params(
            name      => 'boom',
            arguments => {},
        ),
    )) };

    ok($response, 'got response, no exception escaped handle()');
    ok(exists $response->{error}, 'JSON-RPC error returned');
    is($response->{error}{code}, -32603, 'error code -32603 Internal error');
    like($response->{error}{message}, qr/exploded/, 'message carries the die text');
};

subtest 'prompts/get registered but codeless prompt returns -32603' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_prompt(name => 'nocode');

    my $response = eval { $server->handle(_req(
        method => 'prompts/get',
        id     => 23,
        params => _params(
            name      => 'nocode',
            arguments => {},
        ),
    )) };

    ok($response, 'got response, no exception escaped handle()');
    ok(exists $response->{error}, 'JSON-RPC error returned');
    is($response->{error}{code}, -32603, 'error code -32603 Internal error');
    like(
        $response->{error}{message},
        qr/has no implementation/,
        'message explains the prompt has no implementation',
    );
};

subtest 'resources/read code returning a Future is awaited before wrapping' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_resource(
        uri  => 'file:///async.txt',
        name => 'async',
        code => sub { return Future->done("async contents") },
    );

    my $response = $server->handle(_req(
        method => 'resources/read',
        id     => 24,
        params => _params(
            uri => 'file:///async.txt',
        ),
    ));

    my $r = $response->{result};
    is($r->{contents}[0]{text}, 'async contents', 'Future resolved before default wrapping');
};

subtest 'prompts/get code returning a Future is awaited before wrapping' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_prompt(
        name => 'async_greet',
        code => sub { return Future->done("Hello, async!") },
    );

    my $response = $server->handle(_req(
        method => 'prompts/get',
        id     => 25,
        params => _params(
            name      => 'async_greet',
            arguments => {},
        ),
    ));

    my $r = $response->{result};
    is($r->{messages}[0]{content}{text}, 'Hello, async!', 'Future resolved before default wrapping');
};

subtest 'discover capabilities are rebuilt per call: late registration is advertised' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $first = $server->handle(_req(method => 'server/discover', id => 30));
    ok(
        !exists $first->{result}{capabilities}{resources},
        'resources capability absent before any registration',
    );
    ok(
        !exists $first->{result}{capabilities}{prompts},
        'prompts capability absent before any registration',
    );

    $server->register_resource(uri => 'file:///late.txt', name => 'late');
    $server->register_prompt(name => 'late_prompt');

    my $second = $server->handle(_req(method => 'server/discover', id => 31));
    ok(
        exists $second->{result}{capabilities}{resources},
        'resources capability present after late registration',
    );
    ok(
        exists $second->{result}{capabilities}{prompts},
        'prompts capability present after late registration',
    );
};

done_testing;
