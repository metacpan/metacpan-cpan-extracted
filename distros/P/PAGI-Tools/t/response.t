use strict;
use warnings;
use Test2::V0;
use Future;
use Future::AsyncAwait;

use PAGI::Response;

subtest 'constructor no args' => sub {
    my $res = PAGI::Response->new;
    isa_ok $res, 'PAGI::Response';
};

subtest 'constructor with scope' => sub {
    my $res = PAGI::Response->new({});
    isa_ok $res, 'PAGI::Response';
};

subtest 'constructor rejects non-hashref scope' => sub {
    like dies { PAGI::Response->new("not a hashref") }, qr/hashref/i, 'dies with non-hashref';
};

subtest 'status method' => sub {
    my $res = PAGI::Response->new;

    my $ret = $res->status(404);
    is $ret, $res, 'status returns self for chaining';
    is $res->status, 404, 'status getter returns current status';
};

subtest 'header method' => sub {
    my $res = PAGI::Response->new;

    my $ret = $res->header('X-Custom' => 'value');
    is $ret, $res, 'header returns self for chaining';
    is $res->header('X-Custom'), 'value', 'header getter returns last value';
};

subtest 'content_type method' => sub {
    my $res = PAGI::Response->new;

    my $ret = $res->content_type('application/xml');
    is $ret, $res, 'content_type returns self for chaining';
    is $res->content_type, 'application/xml', 'content_type getter returns value';
};

subtest 'chaining multiple methods' => sub {
    my $res = PAGI::Response->new;

    my $ret = $res->status(201)->header('X-Foo' => 'bar')->content_type('text/plain');
    is $ret, $res, 'chaining works';
};

subtest 'status sets internal state' => sub {
    my $res = PAGI::Response->new;
    $res->status(404);
    is $res->{_status}, 404, 'status code set correctly';
};

subtest 'header adds to headers array' => sub {
    my $res = PAGI::Response->new;
    $res->header('X-Custom' => 'value1');
    $res->header('X-Other' => 'value2');
    is scalar(@{$res->{_headers}}), 2, 'two headers added';
    is scalar(@{$res->headers}), 2, 'headers getter returns arrayref';
};

subtest 'content_type replaces existing' => sub {
    my $res = PAGI::Response->new;
    $res->header('Content-Type' => 'text/html');
    $res->content_type('text/plain');
    my @ct = grep { lc($_->[0]) eq 'content-type' } @{$res->{_headers}};
    is scalar(@ct), 1, 'only one content-type header';
    is $ct[0][1], 'text/plain', 'content-type replaced';
    is $res->content_type, 'text/plain', 'content_type getter reflects current';
};

subtest 'try setters and has_*' => sub {
    my $res = PAGI::Response->new;

    ok !$res->has_status, 'no explicit status set initially';
    ok !$res->has_content_type, 'no content-type set initially';
    ok !$res->has_header('X-Foo'), 'no header set initially';

    $res->status_try(201);
    ok $res->has_status, 'status_try sets status once';
    is $res->{_status}, 201, 'status_try sets status';
    $res->status_try(202);
    is $res->{_status}, 201, 'status_try does not override existing status';

    $res->header_try('X-Foo' => 'a');
    ok $res->has_header('x-foo'), 'header_try marks header as set';
    $res->header_try('X-Foo' => 'b');
    my @foo = grep { lc($_->[0]) eq 'x-foo' } @{$res->{_headers}};
    is scalar(@foo), 1, 'header_try does not add duplicate header';
    is $foo[0]->[1], 'a', 'header_try keeps original header value';
    is $res->header('X-Foo'), 'a', 'header getter returns original value';
    my @foo_all = $res->header_all('X-Foo');
    is scalar(@foo_all), 1, 'header_all returns one value';
    is $foo_all[0], 'a', 'header_all returns correct value';

    $res->content_type_try('text/plain');
    ok $res->has_content_type, 'content_type_try marks content-type as set';
    my @ct = grep { lc($_->[0]) eq 'content-type' } @{$res->{_headers}};
    is $ct[0][1], 'text/plain', 'content_type_try sets content-type';
    $res->content_type_try('application/json');
    @ct = grep { lc($_->[0]) eq 'content-type' } @{$res->{_headers}};
    is $ct[0][1], 'text/plain', 'content_type_try does not override';
};

subtest 'status rejects invalid codes' => sub {
    my $res = PAGI::Response->new;
    like dies { $res->status("not a number") }, qr/number/i, 'rejects non-number';
    like dies { $res->status(99) }, qr/100-599/i, 'rejects < 100';
    like dies { $res->status(600) }, qr/100-599/i, 'rejects > 599';
};

subtest 'send_raw method' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->status(200)->header('x-test' => 'value');
    $res->send_raw("Hello")->respond($send)->get;

    is scalar(@sent), 2, 'two messages sent';
    is $sent[0]->{type}, 'http.response.start', 'first is start';
    is $sent[0]->{status}, 200, 'status correct';
    is $sent[1]->{type}, 'http.response.body', 'second is body';
    is $sent[1]->{body}, 'Hello', 'body correct';
    is $sent[1]->{more}, 0, 'more is false';
};

subtest 'send method encodes UTF-8' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->send("café")->respond($send)->get;

    # Should be UTF-8 encoded bytes
    is $sent[1]->{body}, "caf\xc3\xa9", 'UTF-8 encoded';

    # Should have charset in content-type
    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    like $headers{'content-type'}, qr/charset=utf-8/i, 'charset added';
};

subtest 'respond is re-entrant by design' => sub {
    # respond() on a detached Response does NOT guard double-send.
    # The same response value can be served to multiple connections.
    # Double-send protection is the responsibility of the caller (e.g. $ctx->respond).
    my $send1_count = 0;
    my $send2_count = 0;
    my $send1 = sub { $send1_count++; Future->done };
    my $send2 = sub { $send2_count++; Future->done };
    my $res = PAGI::Response->new->send_raw("hello");

    $res->respond($send1)->get;
    $res->respond($send2)->get;  # re-entrant — same value, different connections

    ok $send1_count > 0, 'first connection received events';
    ok $send2_count > 0, 'second connection received events';
};

sub _server_send {
    my ($conn, $sink) = @_;
    return sub {
        my ($e) = @_;
        $conn->_mark_response_started if ($e->{type} // '') eq 'http.response.start';
        push @$sink, $e; Future->done;
    };
}

subtest 'is_sent reads pagi.connection->response_started' => sub {
    require PAGI::Context; require PAGI::Test::ConnectionState;
    my $conn = PAGI::Test::ConnectionState->new; my @sent;
    my $scope = { type => 'http', method => 'GET', 'pagi.connection' => $conn };
    my $ctx = PAGI::Context->new($scope, sub { Future->done }, _server_send($conn, \@sent));
    my $res = $ctx->response;
    ok !$res->is_sent, 'false before respond';
    $ctx->respond($res->send_raw("test"))->get;
    ok $res->is_sent, 'true after the response started';
};

subtest 'two Response objects share sent state via the connection object' => sub {
    require PAGI::Context; require PAGI::Test::ConnectionState;
    my $conn = PAGI::Test::ConnectionState->new; my @sent;
    my $scope = { type => 'http', method => 'GET', 'pagi.connection' => $conn };
    my $ctx = PAGI::Context->new($scope, sub { Future->done }, _server_send($conn, \@sent));
    my $res1 = PAGI::Response->new($scope); my $res2 = PAGI::Response->new($scope);
    ok !$res1->is_sent && !$res2->is_sent, 'neither sent initially';
    $ctx->respond($res1->send_raw("test"))->get;
    ok $res1->is_sent && $res2->is_sent, 'both see it (shared object survives cloning)';
};

subtest 'double-send rejected synchronously (same context, no await between)' => sub {
    require PAGI::Context; require PAGI::Test::ConnectionState;
    my $conn = PAGI::Test::ConnectionState->new; my @sent;
    my $ctx = PAGI::Context->new(
        { type => 'http', method => 'GET', 'pagi.connection' => $conn },
        sub { Future->done }, _server_send($conn, \@sent));
    my $f1  = $ctx->respond(PAGI::Response->new($ctx->scope)->send_raw("a"));   # not awaited
    my $err = eval { $ctx->respond(PAGI::Response->new($ctx->scope)->send_raw("b")); 1 } ? undef : $@;
    like $err, qr/already sent/, 'second respond croaks in the same tick';
    $f1->get;
};

subtest 'malformed pagi.connection dies loudly in BOTH is_sent and respond' => sub {
    require PAGI::Context;
    my $bad   = bless {}, 'Bare::Object';   # no response_started method
    my $scope = { type => 'http', method => 'GET', 'pagi.connection' => $bad };

    my $res = PAGI::Response->new($scope);
    my $e1  = eval { $res->is_sent; 1 } ? undef : $@;
    like $e1, qr/lacks response_started/, 'is_sent croaks on a malformed connection';

    my $ctx = PAGI::Context->new($scope, sub { Future->done }, sub { Future->done });
    my $e2  = eval { $ctx->respond($ctx->response->send_raw("x")); 1 } ? undef : $@;
    like $e2, qr/lacks response_started/, 'respond croaks on a malformed connection too';
};

subtest 'cross-context double-send: a second context on the same request is rejected' => sub {
    require PAGI::Context; require PAGI::Test::ConnectionState;
    my $conn  = PAGI::Test::ConnectionState->new; my @sent;
    my $scope = { type => 'http', method => 'GET', 'pagi.connection' => $conn };
    my $send  = _server_send($conn, \@sent);

    my $ctx1 = PAGI::Context->new($scope, sub { Future->done }, $send);
    my $ctx2 = PAGI::Context->new($scope, sub { Future->done }, $send);   # different context, same request

    $ctx1->respond($ctx1->response->send_raw("first"))->get;             # response_started now true on the shared conn
    my $err = eval { $ctx2->respond($ctx2->response->send_raw("second")); 1 } ? undef : $@;
    like $err, qr/already sent/, 'ctx2 rejects because the shared connection already started';
};

subtest 'text method' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->text("Hello World")->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'content-type'}, 'text/plain; charset=utf-8', 'content-type set';
    is $sent[0]->{status}, 200, 'default status 200';
};

subtest 'html method' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->html("<h1>Hello</h1>")->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'content-type'}, 'text/html; charset=utf-8', 'content-type set';
};

subtest 'json method' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->json({ message => 'Hello', count => 42 })->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'content-type'}, 'application/json', 'content-type set';

    # Body should be valid JSON
    like $sent[1]->{body}, qr/"message"/, 'contains message key';
    like $sent[1]->{body}, qr/"count"/, 'contains count key';
};

subtest 'json with status' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->status(201)->json({ created => 1 })->respond($send)->get;

    is $sent[0]->{status}, 201, 'custom status preserved';
};

subtest 'json with unicode' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->json({ message => 'café', count => 42 })->respond($send)->get;

    # Verify JSON is decodable and unicode is preserved
    # Body is UTF-8 bytes, so decode with utf8 => 1
    my $decoded = JSON::MaybeXS->new(utf8 => 1)->decode($sent[1]->{body});
    is $decoded->{message}, 'café', 'unicode character preserved';
    is $decoded->{count}, 42, 'number preserved';
};

subtest 'redirect method default 302' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->redirect('/login')->respond($send)->get;

    is $sent[0]->{status}, 302, 'default status 302';
    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'location'}, '/login', 'location header set';
};

subtest 'redirect with custom status' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->redirect('/permanent', 301)->respond($send)->get;

    is $sent[0]->{status}, 301, 'custom status 301';
};

subtest 'redirect 303 See Other' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->redirect('/result', 303)->respond($send)->get;

    is $sent[0]->{status}, 303, 'status 303';
};

subtest 'empty method' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->empty()->respond($send)->get;

    is $sent[0]->{status}, 204, 'default status 204';
    is $sent[1]->{body}, '', 'empty body';
};

subtest 'empty with custom status' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->status(201)->empty()->respond($send)->get;

    is $sent[0]->{status}, 201, 'custom status preserved';
};

subtest 'cookie method basic' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    my $ret = $res->cookie('session' => 'abc123');
    is $ret, $res, 'cookie returns self for chaining';

    $res->text("ok")->respond($send)->get;

    my @cookies = grep { lc($_->[0]) eq 'set-cookie' } @{$sent[0]->{headers}};
    is scalar(@cookies), 1, 'one set-cookie header';
    like $cookies[0][1], qr/session=abc123/, 'cookie name=value';
};

subtest 'cookie with options' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->cookie('token' => 'xyz',
        max_age  => 3600,
        path     => '/',
        domain   => 'example.com',
        secure   => 1,
        httponly => 1,
        samesite => 'Strict',
    );
    $res->text("ok")->respond($send)->get;

    my @cookies = grep { lc($_->[0]) eq 'set-cookie' } @{$sent[0]->{headers}};
    my $cookie = $cookies[0][1];

    like $cookie, qr/token=xyz/, 'name=value';
    like $cookie, qr/Max-Age=3600/i, 'max-age';
    like $cookie, qr/Path=\//i, 'path';
    like $cookie, qr/Domain=example\.com/i, 'domain';
    like $cookie, qr/Secure/i, 'secure';
    like $cookie, qr/HttpOnly/i, 'httponly';
    like $cookie, qr/SameSite=Strict/i, 'samesite';
};

subtest 'delete_cookie' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    my $ret = $res->delete_cookie('session');
    is $ret, $res, 'delete_cookie returns self';

    $res->text("ok")->respond($send)->get;

    my @cookies = grep { lc($_->[0]) eq 'set-cookie' } @{$sent[0]->{headers}};
    my $cookie = $cookies[0][1];

    like $cookie, qr/session=/, 'cookie name';
    like $cookie, qr/Max-Age=0/i, 'max-age is 0';
};

subtest 'multiple cookies' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->cookie('a' => '1')->cookie('b' => '2');
    $res->text("ok")->respond($send)->get;

    my @cookies = grep { lc($_->[0]) eq 'set-cookie' } @{$sent[0]->{headers}};
    is scalar(@cookies), 2, 'two set-cookie headers';
};

subtest 'stream method' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->content_type('text/plain');
    $res->stream(async sub {
        my ($writer) = @_;
        await $writer->write("chunk1");
        await $writer->write("chunk2");
        await $writer->close();
    })->respond($send)->get;

    is scalar(@sent), 4, 'start + 2 chunks + close';
    is $sent[0]->{type}, 'http.response.start', 'first is start';
    is $sent[1]->{body}, 'chunk1', 'first chunk';
    is $sent[1]->{more}, 1, 'more=1 for chunk';
    is $sent[2]->{body}, 'chunk2', 'second chunk';
    is $sent[2]->{more}, 1, 'more=1 for chunk';
    is $sent[3]->{more}, 0, 'more=0 for close';
};

subtest 'stream writer bytes_written' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    my $bytes;
    $res->stream(async sub {
        my ($writer) = @_;
        await $writer->write("12345");
        await $writer->write("67890");
        $bytes = $writer->bytes_written;
        await $writer->close();
    })->respond($send)->get;

    is $bytes, 10, 'bytes_written tracks total';
};

subtest 'json error response pattern' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->status(400)->json({ error => "Bad Request" })->respond($send)->get;

    is $sent[0]->{status}, 400, 'status from error';
    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'content-type'}, 'application/json', 'json content-type';

    my $body = JSON::MaybeXS->new(utf8 => 1)->decode($sent[1]->{body});
    is $body->{error}, 'Bad Request', 'error message in body';
};

subtest 'json content-type carries no charset (RFC 8259)' => sub {
    # JSON is always UTF-8; application/json defines no charset parameter, so
    # the body helpers never advertise one.
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };

    PAGI::Response->new({})->json({ ok => 1 })->respond($send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $h{'content-type'}, 'application/json', 'json() emits bare application/json';

    @sent = ();
    PAGI::Response->new({})
        ->content_type('application/json')->json({ ok => 1 })
        ->respond($send)->get;
    %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $h{'content-type'}, 'application/json', 'explicit application/json stays bare';

    @sent = ();
    PAGI::Response->new({})
        ->content_type('application/ld+json')->json({ ok => 1 })
        ->respond($send)->get;
    %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $h{'content-type'}, 'application/ld+json', '+json suffix types stay bare';
};

subtest 'body helpers append charset to a charset-less text type' => sub {
    # text/html/json UTF-8-encode the body, so the Content-Type must advertise
    # the encoding for types where charset is meaningful (RFC 7303 for XML).
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };

    my %cases = (
        'application/xml'       => 'application/xml; charset=utf-8',
        'application/xhtml+xml' => 'application/xhtml+xml; charset=utf-8',
        'text/csv'              => 'text/csv; charset=utf-8',
        'text/javascript'       => 'text/javascript; charset=utf-8',
    );
    for my $preset (sort keys %cases) {
        @sent = ();
        PAGI::Response->new({})
            ->content_type($preset)->text('<doc/>')
            ->respond($send)->get;
        my %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
        is $h{'content-type'}, $cases{$preset}, "text() appends charset to $preset";
    }

    @sent = ();
    PAGI::Response->new({})
        ->content_type('application/xml')->html('<doc/>')
        ->respond($send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $h{'content-type'}, 'application/xml; charset=utf-8',
        'html() appends charset to application/xml';
};

subtest 'an explicit charset is never overridden' => sub {
    # A deliberate (even non-UTF-8) charset choice is left untouched; the
    # helpers only fill in a missing one.
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };

    PAGI::Response->new({})
        ->content_type('application/xml; charset=iso-8859-1')->text('x')
        ->respond($send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $h{'content-type'}, 'application/xml; charset=iso-8859-1',
        'preset charset preserved';
};

subtest 'send() leaves application/json bare' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };

    PAGI::Response->new({})
        ->content_type('application/json')->send('{"ok":1}')
        ->respond($send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $h{'content-type'}, 'application/json',
        'send() does not add charset to application/json';
};

use File::Temp qw(tempfile);

subtest 'send_file basic' => sub {
    # Create temp file
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "Hello File Content";
    close $fh;

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->send_file($filename)->respond($send)->get;

    is $sent[0]->{status}, 200, 'status 200';
    is $sent[1]->{file}, $filename, 'file path sent via PAGI protocol';
    ok !exists $sent[1]->{offset}, 'no offset for full file';
    ok !exists $sent[1]->{length}, 'no length for full file';

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    ok exists $headers{'content-type'}, 'has content-type';
    is $headers{'content-length'}, 18, 'content-length set';
};

subtest 'send_file with filename option' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "data";
    close $fh;

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->send_file($filename, filename => 'download.txt')->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    like $headers{'content-disposition'}, qr/attachment/, 'attachment disposition';
    like $headers{'content-disposition'}, qr/download\.txt/, 'filename in disposition';
};

subtest 'send_file inline' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.txt');
    print $fh "inline data";
    close $fh;

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->send_file($filename, inline => 1)->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    like $headers{'content-disposition'}, qr/inline/, 'inline disposition';
};

subtest 'send_file not found' => sub {
    my $res = PAGI::Response->new({});

    like dies { $res->send_file('/nonexistent/file.txt') },
        qr/not found|no such file/i, 'dies for missing file';
};

subtest 'send_file with offset' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "0123456789ABCDEF";  # 16 bytes
    close $fh;

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->send_file($filename, offset => 5)->respond($send)->get;

    is $sent[1]->{file}, $filename, 'file path sent';
    is $sent[1]->{offset}, 5, 'offset included';
    ok !exists $sent[1]->{length}, 'length omitted (reads to end)';

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'content-length'}, 11, 'content-length is file_size - offset';
};

subtest 'send_file with offset and length' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "0123456789ABCDEF";  # 16 bytes
    close $fh;

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->send_file($filename, offset => 5, length => 5)->respond($send)->get;

    is $sent[1]->{file}, $filename, 'file path sent';
    is $sent[1]->{offset}, 5, 'offset included';
    is $sent[1]->{length}, 5, 'length included';

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'content-length'}, 5, 'content-length matches length option';
};

subtest 'send_file offset validation' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "small";  # 5 bytes
    close $fh;

    # Negative offset
    my $res1 = PAGI::Response->new({});
    like dies { $res1->send_file($filename, offset => -1) },
        qr/non-negative/, 'negative offset rejected';

    # Offset beyond file
    my $res2 = PAGI::Response->new({});
    like dies { $res2->send_file($filename, offset => 100) },
        qr/exceeds file size/, 'offset beyond file rejected';

    # Negative length
    my $res3 = PAGI::Response->new({});
    like dies { $res3->send_file($filename, length => -1) },
        qr/non-negative/, 'negative length rejected';
};

subtest 'send_file length clamped to remaining' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "0123456789";  # 10 bytes
    close $fh;

    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    # Request more bytes than available
    $res->send_file($filename, offset => 5, length => 100)->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'content-length'}, 5, 'length clamped to available bytes';
    ok !exists $sent[1]->{length}, 'no length in protocol when clamped to remaining';
};

subtest 'cors basic' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    my $ret = $res->cors;
    is $ret, $res, 'cors returns self';

    $res->json({ data => 'test' })->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'access-control-allow-origin'}, '*', 'default origin is *';
    is $headers{'vary'}, 'Origin', 'Vary header set';
    ok !exists $headers{'access-control-allow-credentials'}, 'no credentials by default';
};

subtest 'cors with specific origin' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->cors(origin => 'https://example.com')->json({})->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'access-control-allow-origin'}, 'https://example.com', 'specific origin';
};

subtest 'cors with credentials' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->cors(
        origin      => 'https://example.com',
        credentials => 1,
    )->json({})->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'access-control-allow-origin'}, 'https://example.com', 'origin set';
    is $headers{'access-control-allow-credentials'}, 'true', 'credentials header';
};

subtest 'cors with expose headers' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->cors(
        expose => [qw(X-Request-Id X-RateLimit)],
    )->json({})->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    like $headers{'access-control-expose-headers'}, qr/X-Request-Id/, 'expose header 1';
    like $headers{'access-control-expose-headers'}, qr/X-RateLimit/, 'expose header 2';
};

subtest 'cors preflight' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    $res->cors(
        origin    => 'https://example.com',
        methods   => [qw(GET POST PUT)],
        headers   => [qw(Content-Type X-Custom)],
        max_age   => 3600,
        preflight => 1,
    )->status(204)->empty->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'access-control-allow-origin'}, 'https://example.com', 'origin';
    like $headers{'access-control-allow-methods'}, qr/GET/, 'methods includes GET';
    like $headers{'access-control-allow-methods'}, qr/POST/, 'methods includes POST';
    like $headers{'access-control-allow-methods'}, qr/PUT/, 'methods includes PUT';
    like $headers{'access-control-allow-headers'}, qr/Content-Type/, 'headers includes Content-Type';
    like $headers{'access-control-allow-headers'}, qr/X-Custom/, 'headers includes X-Custom';
    is $headers{'access-control-max-age'}, '3600', 'max-age';
};

subtest 'cors credentials with wildcard uses request_origin' => sub {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    my $res = PAGI::Response->new({});

    # When credentials is true and origin is *, we must provide request_origin
    $res->cors(
        origin         => '*',
        credentials    => 1,
        request_origin => 'https://client.example.com',
    )->json({})->respond($send)->get;

    my %headers = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $headers{'access-control-allow-origin'}, 'https://client.example.com', 'echoes request origin';
    is $headers{'access-control-allow-credentials'}, 'true', 'credentials set';
};

subtest 'headers() returns a PAGI::Headers object' => sub {
    my $res = PAGI::Response->new;
    $res->header('X-Foo' => 'a')->header('X-Foo' => 'b');
    isa_ok $res->headers, ['PAGI::Headers'], 'headers() is a PAGI::Headers';
    is [$res->headers->get_all('x-foo')], ['a','b'], 'object exposes get_all';
    is scalar(@{$res->headers}), 2, '@{$res->headers} still yields the pairs';
};

subtest 'remove_header' => sub {
    my $res = PAGI::Response->new;
    $res->header('X-Gone' => '1')->header('X-Keep' => '2');
    is $res->remove_header('x-gone'), $res, 'remove_header returns self';
    ok !$res->has_header('X-Gone'), 'header removed';
    ok $res->has_header('X-Keep'), 'other header kept';
};

subtest 'content_type(undef) clears so a body method re-defaults' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };
    my $res = PAGI::Response->new({});
    $res->content_type('application/xml');
    is $res->content_type, 'application/xml', 'set';
    $res->content_type(undef);
    ok !$res->has_content_type, 'cleared';
    $res->html('<x/>')->respond($send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$sent[0]->{headers}};
    is $h{'content-type'}, 'text/html; charset=utf-8', 'html default re-applied after clear';
};

subtest 'buffered response: one authoritative Content-Length, no Transfer-Encoding' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };
    my $res = PAGI::Response->new({});
    $res->header('content-length' => '9999')        # user-set (wrong)
        ->header('transfer-encoding' => 'chunked')   # smuggling vector
        ->send_raw('hello');                         # 5-byte body
    $res->respond($send)->get;
    my @cl = grep { lc($_->[0]) eq 'content-length' } @{$sent[0]{headers}};
    is scalar(@cl), 1, 'exactly one Content-Length';
    is $cl[0][1], 5, 'Content-Length is the actual body length';
    my @te = grep { lc($_->[0]) eq 'transfer-encoding' } @{$sent[0]{headers}};
    is scalar(@te), 0, 'Transfer-Encoding stripped on a buffered response';
};

subtest 'middleware push over writer() survives (real arrayref, not a copy)' => sub {
    my @start;
    # A "middleware" send wrapper that mutates the start event's headers in place,
    # like PAGI::Middleware::SecurityHeaders.
    my $send = sub {
        my ($e) = @_;
        if (($e->{type} // '') eq 'http.response.start') {
            push @{$e->{headers}}, ['x-frame-options', 'DENY'];
            push @start, $e;
        }
        Future->done;
    };
    my $res = PAGI::Response->new({});
    $res->status(200)->header('content-type' => 'text/plain');
    $res->writer($send)->get;
    my %h = map { lc($_->[0]) => $_->[1] } @{$start[0]{headers}};
    is $h{'x-frame-options'}, 'DENY', 'a header pushed onto the writer start event survives';
    is $h{'content-type'}, 'text/plain', 'response headers present too';
};

done_testing;
