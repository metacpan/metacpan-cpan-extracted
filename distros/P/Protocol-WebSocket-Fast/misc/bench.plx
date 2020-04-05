#!/usr/bin/env perl
use 5.012;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Benchmark qw/timethis timethese cmpthese/;

use URI::XS;
use Protocol::WebSocket::Fast::ClientParser;
use Protocol::WebSocket::Fast::ServerParser;
use Protocol::WebSocket::Frame;

my $client = Protocol::WebSocket::Fast::ClientParser->new;
my $req_str = $client->connect_request({
    uri           => URI::XS->new("ws://example.com/"),
    ws_key        => "dGhlIHNhbXBsZSBub25jZQ==",
    ws_protocol   => "chat",
    ws_extensions => [ [ 'permessage-deflate'] ],
    headers       => {
        'Origin'          => 'http://www.crazypanda.ru',
        'User-Agent'      => 'My-UA',
    },
});

my $server = Protocol::WebSocket::Fast::ServerParser->new;
my $req    = $server->accept($req_str);

my $accept_reply_str = $req->error ? $server->accept_error : $server->accept_response;
my $reply = $client->connect($accept_reply_str);
$client->established;      
$client->is_deflate_active;
$server->is_deflate_active;


my $data = $server->send_message(opcode => OPCODE_TEXT, deflate => 0, payload => "Lorem ipsum dolor " x 10);

cmpthese(-1, {
    "Protocol::WebSocket::Fast" => sub { $client->get_messages($data) },
    "Protocol::WebSocket "    => sub { Protocol::WebSocket::Frame->new($data)->next },
});
