use 5.012;
use warnings;
use lib 't'; use MyTest;

my $test_connect = sub {
    my ($req, $check) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest 'whole data' => sub {
        my $p = new Protocol::WebSocket::Fast::ClientParser;
        my $str = $p->connect_request($req);
        my $sp = new Protocol::WebSocket::Fast::ServerParser;
        my $creq = $sp->accept($str) or die "should not happen";
        my $res_str = $creq->error ? $sp->accept_error : $sp->accept_response;
        my $cres = $p->connect($res_str);
        cmp_deeply($cres, methods(%$check), "response ok");
        $cres->error ? ok(!$p->established, "not established on error") : ok($p->established, "established");
    };
    subtest 'chunks' => sub {
        my $p = new Protocol::WebSocket::Fast::ClientParser;
        my $str = $p->connect_request($req);
        my $sp = new Protocol::WebSocket::Fast::ServerParser;
        my $creq = $sp->accept($str) or die "should not happen";
        my $res_str = $creq->error ? $sp->accept_error : $sp->accept_response;
        my $cres;
        while (length($res_str) && !$cres) { $cres = $p->connect(substr($res_str, 0, 5, '')) }
        is(length($res_str), 0, "all chunks used:");
        cmp_deeply($cres, methods(%$check), "response ok");
        $cres->error ? ok(!$p->established, "not established on error") : ok($p->established, "established");
    };
};

subtest 'simple connect' => sub {
    $test_connect->({
        uri           => "ws://crazypanda.ru",
        ws_key        => "dGhlIHNhbXBsZSBub25jZQ==",
        ws_protocol   => "killme",
        ws_extensions => [ [ 'permessage-deflate', { 'client_max_window_bits' => '' } ] ],
    }, {
        code          => 101,
        message       => 'Switching Protocols',
        ws_accept_key => 's3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
        ws_protocol   => 'killme',
        ws_extensions => [ [ 'permessage-deflate', , { 'client_max_window_bits' => '15' } ] ],
        headers       => {
            'connection'               => 'Upgrade',
            'upgrade'                  => 'websocket',
            'sec-websocket-accept'     => 's3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
            'sec-websocket-protocol'   => 'killme',
            'server'                   => ignore(),
            'sec-websocket-extensions' => 'permessage-deflate; client_max_window_bits=15',
            'content-length'           => 0,
        },
    });
};

subtest 'wrong accept key' => sub {
    my $p = new Protocol::WebSocket::Fast::ClientParser;
    my $str = $p->connect_request({uri => "ws://a.ru"});
    my $sp = new Protocol::WebSocket::Fast::ServerParser;
    $sp->accept($str);
    my $res_str = $sp->accept_response;
    $res_str =~ s/^(Sec-WebSocket-Accept: )/$1 a/im;
    my $cres = $p->connect($res_str);
    ok ($cres->error, "error ok");
};

subtest 'version upgrade required' => sub {
    $test_connect->({
        uri => "ws://a.ru",
        ws_version => 14
    }, {
        code    => 426,
        message => "Upgrade Required",
        error   => XS::ErrorCode->new(Protocol::WebSocket::Fast::Error::unsupported_version),
    });
};

subtest 'wrong code' => sub {
    my $p = new Protocol::WebSocket::Fast::ClientParser;
    my $str = $p->connect_request({uri => "ws://a.ru"});
    my $sp = new Protocol::WebSocket::Fast::ServerParser;
    $sp->accept($str);
    my $res_str = $sp->accept_response;
    $res_str =~ s/^(HTTP\/1.1) (\d+)/$1 102/i; # code must be "bodyless", otherwise http parser waits for body
    my $cres = $p->connect($res_str);
    is($cres->error, Protocol::WebSocket::Fast::Error::response_code_101(), "error ok");
};

subtest 'wrong connection header' => sub {
    my $p = new Protocol::WebSocket::Fast::ClientParser;
    my $str = $p->connect_request({uri => "ws://a.ru"});
    my $sp = new Protocol::WebSocket::Fast::ServerParser;
    $sp->accept($str);
    my $res_str = $sp->accept_response;
    $res_str =~ s/^(Connection:) (\S+)/$1 migrate/im;
    my $cres = $p->connect($res_str);
    is($cres->error, Protocol::WebSocket::Fast::Error::connection_mustbe_upgrade(), "error ok");
};

subtest 'wrong upgrade header' => sub {
    my $p = new Protocol::WebSocket::Fast::ClientParser;
    my $str = $p->connect_request({uri => "ws://a.ru"});
    my $sp = new Protocol::WebSocket::Fast::ServerParser;
    $sp->accept($str);
    my $res_str = $sp->accept_response;
    $res_str =~ s/^(Upgrade:) (\S+)/$1 huysocket/im;
    my $cres = $p->connect($res_str);
    is ($cres->error, Protocol::WebSocket::Fast::Error::upgrade_mustbe_websocket(), "error ok");
};

subtest 'frame just after handshake is reachable' => sub {
    my $p = new Protocol::WebSocket::Fast::ClientParser;
    my $str = $p->connect_request({uri => "ws://a.ru"});
    my $sp = new Protocol::WebSocket::Fast::ServerParser;
    $sp->accept($str);
    my $res_str = $sp->accept_response;
    $res_str .= MyTest::gen_message({mask => 1, data => "hello!!"});
    my $cres = $p->connect($res_str);
    ok($p->established, "established");
    my ($msg) = $p->get_messages;
    cmp_deeply($msg, methods(payload => "hello!!"));
};

done_testing();
