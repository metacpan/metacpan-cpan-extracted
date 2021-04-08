use 5.012;
use warnings;
use lib 't/lib';
use MyTest qw/gen_frame/;
use Test::More;
use Test::Catch;
use Encode::Base2N 'encode_base64pad';
use Protocol::WebSocket::Fast;

catch_run("[deflate-frames]");

my $default_compression =<<END;
GET /?encoding=text HTTP/1.1\r
Host: dev.crazypanda.ru:4680\r
Connection: Upgrade\r
Pragma: no-cache\r
Cache-Control: no-cache\r
Upgrade: websocket\r
Origin: http://www.websocket.org\r
Sec-WebSocket-Version: 13\r
User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36\r
Accept-Encoding: gzip, deflate, sdch\r
Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4\r
Cookie: _ga=GA1.2.1700804447.1456741171\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
Sec-WebSocket-Extensions: permessage-deflate\r
\r
END

my $create_server = sub {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $handshake_message = shift;
    my $p = Protocol::WebSocket::Fast::ServerParser->new;
    ok $p->accept($handshake_message);
    $p->accept_response;
    ok $p->established;
    return $p;
};

subtest 'empty payload frame' => sub {
    my $payload = "";
    my $bin = $create_server->($default_compression)->start_message(deflate => 1)->send($payload, 1);
    ok $bin;
    is(length($bin), 3, "frame length ok"); # 2 header + 1 bytes empty zlib frame
    my $deflate_payload = substr($bin, 2);
    is($bin, gen_frame({mask => 0, fin => 1, rsv1 => 1, opcode => OPCODE_BINARY, data => $deflate_payload}), "frame ok");
};

subtest 'small server2client frame (rfc7692 "Hello" sample)' => sub {
    my $payload = "Hello"; # must be <= 125
    my $bin = $create_server->($default_compression)->start_message(deflate => 1, opcode => OPCODE_TEXT)->send($payload, 1);
    is(length($bin), 9, "frame length ok"); # 2 header + 10 payload
    my $deflate_payload = substr($bin, 2);
    note "frame = ", encode_base64pad($bin);
    my $encoded = encode_base64pad($deflate_payload);
    note $encoded;
    is $encoded, '8kjNyckHAA==';
    is($bin, gen_frame({mask => 0, fin => 1, rsv1 => 1, opcode => OPCODE_TEXT, data => $deflate_payload}), "frame ok");

    subtest "it mode" => sub {
        my $bin2 = $create_server->($default_compression)->start_message(deflate => 1, opcode => OPCODE_TEXT)->send([qw/Hel lo/], 1);
        is(length($bin2), 9, "frame length ok");
        my $deflate_payload2 = substr($bin2, 2);
        is($deflate_payload2, $deflate_payload, "it mode ok");
        is($bin2, $bin, "it mode ok");
    };

    subtest "it mode by byte" => sub {
        my $bin3 = $create_server->($default_compression)->start_message(deflate => 1, opcode => OPCODE_TEXT)->send([split //, $payload], 1);
        is($bin3, $bin, "it mode ok");
    };
};

subtest 'big (1923 b) server2client frame' => sub {
    my @payload = ('0') x (1923);
    my $payload = join('', @payload);
    my $bin = $create_server->($default_compression)->start_message(deflate => 1)->send($payload, 1);
    is(length($bin), 20, "frame length ok");
    my $deflate_payload = substr($bin, 2);
    my $encoded = encode_base64pad($deflate_payload);
    note $encoded;
    is $encoded, 'MjAYBaNgFIyCUTAKRsEAAAAA';
    is($bin, gen_frame({mask => 0, fin => 1, rsv1 => 1, opcode => OPCODE_BINARY, data => $deflate_payload}), "frame ok");

    subtest "it mode" => sub {
        my $bin2 = $create_server->($default_compression)->start_message(deflate => 1)->send(\@payload, 1);
        is(length($bin2), length($bin), "frame length ok");
        my $deflate_payload2 = substr($bin2, 2);
        my $encoded2 = encode_base64pad($deflate_payload2);
        is $encoded2, $encoded;
        note $encoded2;
        is($deflate_payload2, $deflate_payload, "it mode ok");
        is($bin2, $bin, "it mode ok");
    };
};

subtest 'big (108 kb) server2client frame' => sub {
    my @payload = ('0') x (1024 * 108);
    my $payload = join('', @payload);
    my $bin = $create_server->($default_compression)->start_message(deflate => 1)->send($payload, 1);
    is(length($bin), 130, "frame length ok");
    my $deflate_payload = substr($bin, 4);
    my $encoded = encode_base64pad($deflate_payload);
    note $encoded;
    is($bin, gen_frame({mask => 0, fin => 1, rsv1 => 1, opcode => OPCODE_BINARY, data => $deflate_payload}), "frame ok");

    subtest "it mode" => sub {
        my $bin2 = $create_server->($default_compression)->start_message(deflate => 1)->send(\@payload, 1);
        is(length($bin2), length($bin), "frame length ok");
        my $deflate_payload2 = substr($bin2, 4);
        my $encoded2 = encode_base64pad($deflate_payload2);
        note $encoded2;
        is($deflate_payload2, $deflate_payload, "it mode ok");
        is($bin2, $bin, "it mode ok");
    };
};


subtest 'big (1 mb) server2client frame' => sub {
    my @payload = ('0') x (1024 * 1024);
    my $payload = join('', @payload);
    my $bin = $create_server->($default_compression)->start_message(deflate => 1)->send($payload, 1);
    is(length($bin), 1038, "frame length ok");
    my $deflate_payload = substr($bin, 4);
    my $encoded = encode_base64pad($deflate_payload);
    note $encoded;
    is($bin, gen_frame({mask => 0, fin => 1, rsv1 => 1, opcode => OPCODE_BINARY, data => $deflate_payload}), "frame ok");

    subtest "it mode" => sub {
        my $bin2 = $create_server->($default_compression)->start_message(deflate => 1)->send(\@payload, 1);
        is length($bin2), length($bin);
    };
};

subtest '2 messages in a sequence (different due to context takeover)' => sub {
    my @payload = ('0') x (1024);
    
    subtest "as single lines" => sub {
        my $p = $create_server->($default_compression);
        my $payload = join('', @payload);
        my $bin_1 = $p->start_message(deflate => 1)->send($payload, 1);
        ok $bin_1;
        my $bin_2 = $p->start_message(deflate => 1)->send($payload, 1);
        ok $bin_2;
        ok length($bin_1) > length($bin_2);
        my $e1 = encode_base64pad($bin_1);
        my $e2 = encode_base64pad($bin_2);
        note "e1 = ", $e1, ", e2 = ", $e2;
        isnt $e1, $e2;
    };

    subtest "as iterators" => sub {
        my $p = $create_server->($default_compression);
        my $bin_1 = $p->start_message(deflate => 1)->send(\@payload, 1);
        ok $bin_1;
        my $bin_2 = $p->start_message(deflate => 1)->send(\@payload, 1);
        ok length($bin_1) > length($bin_2);
        my $e1 = encode_base64pad($bin_1);
        my $e2 = encode_base64pad($bin_2);
        note "e1 = ", $e1, ", e2 = ", $e2;
        isnt $e1, $e2;
    };
};

subtest "no context takeover" => sub {
    my $handshake =<<END;
GET /?encoding=text HTTP/1.1\r
Host: dev.crazypanda.ru:4680\r
Connection: Upgrade\r
Upgrade: websocket\r
Sec-WebSocket-Version: 13\r
User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
Sec-WebSocket-Extensions: permessage-deflate; client_no_context_takeover; server_no_context_takeover\r
\r
END
    my $p = $create_server->($handshake);
    my @payload = ('0') x (1024);
    my $payload = join('', @payload);
    my $bin_1 = $p->start_message()->send($payload, 1);
    ok $bin_1;
    my $bin_2 = $p->start_message()->send($payload, 1);
    my $e1 = encode_base64pad($bin_1);
    my $e2 = encode_base64pad($bin_2);
    is $e1, $e2;
};

done_testing;
