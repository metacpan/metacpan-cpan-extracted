use 5.012;
use warnings;
use lib 't'; use MyTest;

my $req = {
    uri    => "ws://crazypanda.ru",
    ws_key => "dGhlIHNhbXBsZSBub25jZQ==",
};

subtest "default config" => sub {
    my $server = Protocol::WebSocket::Fast::ServerParser->new;
    $server->configure({ deflate => undef });
    is $server->deflate_config, undef;
    $server->configure({ deflate => {client_no_context_takeover => 1, mem_level => 5 }});
    ok $server->deflate_config;
    is $server->deflate_config->{compression_level}, -1, "default settings";
    is $server->deflate_config->{mem_level}, 5, "supplied settings";
};

subtest "permessage-deflate extension in request" => sub {
    subtest "no deflate enabled => no extension" => sub {
        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        $client->no_deflate;
        my $str = $client->connect_request($req);
        unlike $str, qr/permessage-deflate/;
    };

    subtest "deflate enabled => extension is present" => sub {
        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        my $str = $client->connect_request($req);
        like $str, qr/permessage-deflate/;
    };

    subtest "deflate enabled(custom params) => extension is present" => sub {
        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        $client->configure({deflate => {
            client_no_context_takeover => 1,
            server_no_context_takeover => 1,
            server_max_window_bits     => 13,
            client_max_window_bits     => 14,
        }});
        my $str = $client->connect_request($req);
        like $str, qr/permessage-deflate/;
        like $str, qr/client_no_context_takeover/;
        like $str, qr/server_no_context_takeover/;
        like $str, qr/server_max_window_bits=13/;
        like $str, qr/client_max_window_bits=14/;
    };
};

subtest "permessage-deflate extension in server reply" => sub {

    subtest "no deflate enabled => no extension" => sub {
        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        $client->no_deflate;
        my $str = $client->connect_request($req);
        my $server = Protocol::WebSocket::Fast::ServerParser->new;
        my $creq = $server->accept($str) or die "should not happen";
        my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
        unlike $res_str, qr/permessage-deflate/;
    };

    subtest "client deflate: on, server deflate: off => extension: off" => sub {
        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        my $str = $client->connect_request($req);
        my $server = Protocol::WebSocket::Fast::ServerParser->new;
        $server->no_deflate;
        my $creq = $server->accept($str) or die "should not happen";
        my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
        like $str, qr/permessage-deflate/;
        unlike $res_str, qr/permessage-deflate/;
        ok !$client->is_deflate_active;
        ok !$server->is_deflate_active;
    };

    subtest "client deflate: on, server deflate: on => extension: on" => sub {
        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        my $server = Protocol::WebSocket::Fast::ServerParser->new;

        my $str = $client->connect_request($req);
        my $creq = $server->accept($str) or die "should not happen";
        my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
        like $str, qr/permessage-deflate/;
        like $res_str, qr/permessage-deflate/;
        ok $server->is_deflate_active;

        $client->connect($res_str);
        ok $client->established;
        ok $client->is_deflate_active;
    };

    subtest "client deflate: on (empty client_max_window_bits), server deflate: on => extension: on" => sub {
        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        my $server = Protocol::WebSocket::Fast::ServerParser->new;

        my $str = $client->connect_request($req);
        $str =~ s/(client_max_window_bits)=15/$1/;
        my $creq = $server->accept($str) or die "should not happen";
        my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
        like $str, qr/permessage-deflate/;
        like $res_str, qr/permessage-deflate/;
        like $res_str, qr/client_max_window_bits=15/;
        ok $server->is_deflate_active;

        $client->connect($res_str);
        ok $client->established;
        ok $client->is_deflate_active;
    };

    subtest "client deflate: on (wrong params), server deflate: on => extension: off" => sub {

        subtest "too small window" => sub {
            my $server = Protocol::WebSocket::Fast::ServerParser->new;

            my $client = Protocol::WebSocket::Fast::ClientParser->new;
            $client->configure({ deflate => { client_max_window_bits => 3}});

            my $str = $client->connect_request($req);
            my $creq = $server->accept($str) or die "should not happen";
            my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
            like $str, qr/permessage-deflate/;
            unlike $res_str, qr/permessage-deflate/;
            ok !$server->is_deflate_active;

            $client->connect($res_str);
            ok $client->established;
            ok !$client->is_deflate_active;
        };

        subtest "too big window" => sub {
            my $server = Protocol::WebSocket::Fast::ServerParser->new;
            my $client = Protocol::WebSocket::Fast::ClientParser->new;
            $client->configure({deflate => { client_max_window_bits => 30}});

            my $str = $client->connect_request($req);
            my $creq = $server->accept($str) or die "should not happen";
            my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
            like $str, qr/permessage-deflate/;
            unlike $res_str, qr/permessage-deflate/;
            ok !$server->is_deflate_active;

            $client->connect($res_str);
            ok $client->established;
            ok !$client->is_deflate_active;
        };

        subtest "unknown parameter" => sub {
            my $req = {
                uri           => "ws://crazypanda.ru",
                ws_key        => "dGhlIHNhbXBsZSBub25jZQ==",
                ws_extensions => [ [ 'permessage-deflate', { 'hacker' => 'huyaker' } ] ],
            };


            my $server = Protocol::WebSocket::Fast::ServerParser->new;

            my $client = Protocol::WebSocket::Fast::ClientParser->new;
            $client->no_deflate;    # manually set up by client in request

            my $str = $client->connect_request($req);
            my $creq = $server->accept($str) or die "should not happen";
            my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
            like $str, qr/permessage-deflate/;
            unlike $res_str, qr/permessage-deflate/;
            ok !$server->is_deflate_active;

            $client->connect($res_str);
            ok $client->established;
            ok !$client->is_deflate_active;
        };

        subtest "incorrect parameter" => sub {
            my $req = {
                uri           => "ws://crazypanda.ru",
                ws_key        => "dGhlIHNhbXBsZSBub25jZQ==",
                ws_extensions => [ [ 'permessage-deflate', { 'client_max_window_bits' => 'kak tebe takoe, Ilon Mask?' } ] ],
            };

            my $server = Protocol::WebSocket::Fast::ServerParser->new;

            my $client = Protocol::WebSocket::Fast::ClientParser->new;
            $client->no_deflate;    # manually set up by client in request

            my $str = $client->connect_request($req);
            my $creq = $server->accept($str) or die "should not happen";
            my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
            like $str, qr/permessage-deflate/;
            unlike $res_str, qr/permessage-deflate/;
            ok !$server->is_deflate_active;

            $client->connect($res_str);
            ok $client->established;
            ok !$client->is_deflate_active;
        };

    };

    subtest "client deflate: on, server deflate: on (wrong params) => no connection" => sub {
        subtest "offected other windows size" => sub {
            my $client = Protocol::WebSocket::Fast::ClientParser->new;

            my $str = $client->connect_request($req);
            my $res_str =<<END;
HTTP/1.1 101 Switching Protocols\r
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r
Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=13; client_max_window_bits=15\r
Connection: Upgrade\r
Server: Panda-WebSocket\r
Upgrade: websocket\r
\r
END
            my $conn_res = $client->connect($res_str);
            ok !$client->established;
            ok !$client->is_deflate_active;
            is $conn_res->error, Protocol::WebSocket::Fast::Error::deflate_negotiation_failed;
        };

        subtest "offected garbage windows size" => sub {
            my $client = Protocol::WebSocket::Fast::ClientParser->new;

            my $str = $client->connect_request($req);
            my $res_str =<<END;
HTTP/1.1 101 Switching Protocols\r
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r
Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=zzzz; client_max_window_bits=15\r
Connection: Upgrade\r
Server: Panda-WebSocket\r
Upgrade: websocket\r
\r
END
            my $conn_res = $client->connect($res_str);
            ok !$client->established;
            ok !$client->is_deflate_active;
            is $conn_res->error, Protocol::WebSocket::Fast::Error::deflate_negotiation_failed;
        };

        subtest "offected garbage extension parameter" => sub {
            my $client = Protocol::WebSocket::Fast::ClientParser->new;

            my $str = $client->connect_request($req);
            my $res_str =<<END;
HTTP/1.1 101 Switching Protocols\r
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r
Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=15; client_max_window_bits=15; hello=world\r
Connection: Upgrade\r
Server: Panda-WebSocket\r
Upgrade: websocket\r
\r
END
            my $conn_res = $client->connect($res_str);
            ok !$client->established;
            ok !$client->is_deflate_active;
            is $conn_res->error, Protocol::WebSocket::Fast::Error::deflate_negotiation_failed;
        };

    };

};

subtest "SRV-1229 bufix" => sub {
    my $request_str =<<END;
GET / HTTP/1.1\r
User-Agent: Panda-WebSocket\r
Upgrade: websocket\r
Connection: Upgrade\r
Host: crazypanda.ru\r
Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=13; client_max_window_bits\r
Sec-WebSocket-Version: 13\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
\r
END
    my $server = Protocol::WebSocket::Fast::ServerParser->new;
    my $res = $server->accept($request_str) or die "should not happen";
    my $res_str = $res->error ? $server->accept_error : $server->accept_response;
    note $res_str;
    like $res_str, qr/permessage-deflate/;
    like $res_str, qr/client_max_window_bits=15/;
};

subtest "8-bit windows are not allowed" => sub {
    subtest "server ignores permessage-deflate option with window_bits=8, and uses no compression" => sub {
        my $req = {
            uri           => "ws://crazypanda.ru",
            ws_key        => "dGhlIHNhbXBsZSBub25jZQ==",
        };

        subtest "8-bit request is rejected" => sub {
            my $server = Protocol::WebSocket::Fast::ServerParser->new;
            my $client = Protocol::WebSocket::Fast::ClientParser->new;
            $client->configure({deflate => { client_max_window_bits => 9 }});

            my $str = $client->connect_request($req);
            $str =~ s/window_bits=9/window_bits=8/g;
            my $creq = $server->accept($str) or die "should not happen";
            my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
            like $str, qr/permessage-deflate/;
            unlike $res_str, qr/permessage-deflate/;
            ok !$server->is_deflate_active;

            $client->connect($res_str);
            ok $client->established;
            ok !$client->is_deflate_active;
        };

        subtest "8-bit response is rejected" => sub {
            my $server = Protocol::WebSocket::Fast::ServerParser->new;
            my $client = Protocol::WebSocket::Fast::ClientParser->new;
            $client->configure({deflate => { client_max_window_bits => 9 }});

            my $str = $client->connect_request($req);
            my $creq = $server->accept($str) or die "should not happen";
            my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
            like $str, qr/permessage-deflate/;
            like $res_str, qr/permessage-deflate/;
            ok $server->is_deflate_active;

            $res_str =~ s/window_bits=9/window_bits=8/g;
            my $conn_res = $client->connect($res_str);
            ok !$client->established;
            ok !$client->is_deflate_active;
            is $conn_res->error, Protocol::WebSocket::Fast::Error::deflate_negotiation_failed;
        };

        subtest "9-bit window is OK" => sub {
            my $server = Protocol::WebSocket::Fast::ServerParser->new;
            my $client = Protocol::WebSocket::Fast::ClientParser->new;
            $_->configure({deflate => { client_max_window_bits => 9 }}) for ($server, $client);

            my $str = $client->connect_request($req);
            my $creq = $server->accept($str) or die "should not happen";
            my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
            $client->connect($res_str);
            ok $client->established;
            ok $client->is_deflate_active;
            ok $server->is_deflate_active;
            is $client->effective_deflate_config->{client_max_window_bits}, 9;
            is $client->effective_deflate_config->{server_max_window_bits}, 15;
            is $server->effective_deflate_config->{client_max_window_bits}, 9;
            is $server->effective_deflate_config->{server_max_window_bits}, 15;
        };
    }
};

subtest "configuration getters" => sub {
    my $client = Protocol::WebSocket::Fast::ClientParser->new;
    my $deflate_cfg = {
        client_no_context_takeover => 1,
        server_no_context_takeover => 1,
        server_max_window_bits     => 13,
        client_max_window_bits     => 14,
        mem_level                  => 3,
        compression_level          => 2,
        strategy                   => 1,
        compression_threshold      => 1000,
    };
    $client->configure({
        max_frame_size     => 7,
        max_message_size   => 8,
        max_handshake_size => 9,
        deflate =>         => $deflate_cfg,
    });
    is $client->max_frame_size, 7;
    is $client->max_message_size, 8;
    is $client->max_handshake_size, 9;
    is_deeply $client->deflate_config, $deflate_cfg;

    $client->no_deflate;
    is $client->deflate_config, undef;
};

done_testing;
