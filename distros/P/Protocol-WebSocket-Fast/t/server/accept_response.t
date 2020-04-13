use 5.012;
use warnings;
use lib 't/lib';
use MyTest 'accept_packet';
use Test::More;

my $p = new Protocol::WebSocket::Fast::ServerParser;

subtest 'successful response' => sub {
    my $data = accept_packet();
    $p->accept($data);
    ok($p->accepted, "accepted");
    my $ans = $p->accept_response();
    like($ans, qr/^HTTP\/1\.1 101 Switching Protocols\r\n/, "status line ok");
    like($ans, qr/^Upgrade: websocket\r\n/m, "upgrade ok");
    like($ans, qr/^Connection: Upgrade\r\n/m, "connection ok");
    like($ans, qr/^Sec-WebSocket-Protocol: chat\r\n/m, "protocol ok");
    unlike($ans, qr/^Sec-WebSocket-Extensions/, "no extensions now");
    like($ans, qr/^Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK\+xOo=\r\n/m, "accept key ok");
    ok($p->established, "connection established");
};

$p->reset();

subtest 'successful response with args' => sub {
    my $data = accept_packet();
    $p->accept($data);
    ok($p->accepted, "accepted");
    my $ans = $p->accept_response({
        ws_protocol   => "jopa",
        ws_extensions => [["ext1"], ["ext2", {arg1 => 1}], ["ext3"]],
        headers       => {h1 => 1},
    });
    like($ans, qr/^HTTP\/1\.1 101 Switching Protocols\r\n/, "status line ok");
    like($ans, qr/^Sec-WebSocket-Protocol: jopa\r\n/m, "protocol ok");
    like($ans, qr/^h1: 1\r\n/m, "header ok");
    unlike($ans, qr/^Sec-WebSocket-Extensions/, "unsupported extensions removed");
};

$p->reset();

done_testing();
