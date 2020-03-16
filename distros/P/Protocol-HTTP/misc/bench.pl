#!/usr/bin/env perl
use 5.012;
use warnings;
use Benchmark qw/timethis timethese cmpthese/;
use Protocol::HTTP;
use HTTP::Parser;
use HTTP::Parser::XS;

say $$;

my $small_request =
    "GET / HTTP/1.1\r\n".
    "Content-Length: 0\r\n".
    "Connection: keep-alive\r\n".
    "\r\n"
    ;
    
my $big_request = 
        "POST /jsonrpc_example/json_service/ HTTP/1.1\r\n".
        "Host: alx3apps.appspot.com\r\n".
        "User-Agent: Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13\r\n".
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n".
        "Accept-Language: en-gb,en;q=0.5\r\n".
        "Accept-Encoding: gzip,deflate\r\n".
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n".
        "Keep-Alive: 115\r\n".
        "Connection: keep-alive\r\n".
        "Content-Type: application/json-rpc;charset=UTF-8\r\n".
        "X-Requested-With: XMLHttpRequest\r\n".
        "Referer: http://alx3apps.appspot.com/jsonrpc_example/\r\n".
        "Content-Length: 0\r\n".
        "Pragma: no-cache\r\n".
        "Cache-Control: no-cache\r\n".
        "\r\n"
        ;

my $big_response =
        "HTTP/1.1 200 OK\r\n".
        "Host: alx3apps.appspot.com\r\n".
        "User-Agent: Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13\r\n".
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n".
        "Accept-Language: en-gb,en;q=0.5\r\n".
        "Accept-Encoding: gzip,deflate\r\n".
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n".
        "Keep-Alive: 115\r\n".
        "Connection: keep-alive\r\n".
        "Content-Type: application/json-rpc;charset=UTF-8\r\n".
        "X-Requested-With: XMLHttpRequest\r\n".
        "Referer: http://alx3apps.appspot.com/jsonrpc_example/\r\n".
        "Content-Length: 0\r\n".
        "Pragma: no-cache\r\n".
        "Cache-Control: no-cache\r\n".
        "\r\n"
        ;

my $phttp_reqp = Protocol::HTTP::RequestParser->new;
my $phttp_req  = Protocol::HTTP::Request->new;
my $phttp_resp = Protocol::HTTP::ResponseParser->new;

my $hp_reqp = HTTP::Parser->new(request  => 1);
my $hp_resp = HTTP::Parser->new(response => 1);

say "==================== request with few headers";
cmpthese(-1, {
    "Protocol::HTTP"   => sub { $phttp_reqp->parse($small_request) },
    "HTTP::Parser"     => sub { my $st = $hp_reqp->add($small_request); $hp_reqp->object },
    "HTTP::Parser::XS" => sub { HTTP::Parser::XS::parse_http_request($small_request, {}) },
});

say "==================== request with many headers";
cmpthese(-1, {
    "Protocol::HTTP"   => sub { $phttp_reqp->parse($big_request) },
    "HTTP::Parser"     => sub { my $st = $hp_reqp->add($big_request); $hp_reqp->object },
    "HTTP::Parser::XS" => sub { HTTP::Parser::XS::parse_http_request($big_request, {}) },
});

say "==================== response with many headers";
cmpthese(-1, {
    "Protocol::HTTP"   => sub { $phttp_resp->set_context_request($phttp_req); $phttp_resp->parse($big_response) },
    "HTTP::Parser"     => sub { my $st = $hp_resp->add($big_response); $hp_resp->object },
    "HTTP::Parser::XS" => sub { HTTP::Parser::XS::parse_http_response($big_response, HTTP::Parser::XS::HEADERS_AS_ARRAYREF, {}) },
});

my $long_response =
        "HTTP/1.1 200 OK\r\n".
        "Host: alx3apps.appspot.com\r\n".
        "User-Agent: Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13\r\n".
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n".
        "Accept-Language: en-gb,en;q=0.5\r\n".
        "Accept-Encoding: gzip,deflate\r\n".
        "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n".
        "Keep-Alive: 115\r\n".
        "Connection: keep-alive\r\n".
        "Content-Type: application/json-rpc;charset=UTF-8\r\n".
        "X-Requested-With: XMLHttpRequest\r\n".
        "Referer: http://alx3apps.appspot.com/jsonrpc_example/\r\n".
        "Pragma: no-cache\r\n".
        "Cache-Control: no-cache\r\n".
        "Content-Length: 10000\r\n".
        "\r\n".
        ("x" x 10000)
        ;

say "==================== response with many headers and 10KB body (only for Protocol::HTTP)";
timethis(-1, sub { $phttp_resp->set_context_request($phttp_req); $phttp_resp->parse($long_response) });
