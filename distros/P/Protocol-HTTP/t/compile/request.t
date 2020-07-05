use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;
use Protocol::HTTP::Request;

catch_run('[compile-request]');

subtest 'basic' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_GET,
        uri          => "http://crazypanda.ru:12345/hello/world",
        http_version => 10,
        headers      => {MyHeader => "my value"},
        body         => "my body",
    });
    
    is $req->to_string,
        "GET /hello/world HTTP/1.0\r\n".
        "Host: crazypanda.ru:12345\r\n".
        "Content-Length: 7\r\n".
        "MyHeader: my value\r\n".
        "\r\n".
        "my body"
    ;
};

subtest 'no netloc in uri' => sub {
    my $req = Protocol::HTTP::Request->new({
        uri => "/hello",
    });
    is $req->to_string, "GET /hello HTTP/1.1\r\n\r\n";
};

subtest 'no uri' => sub {
    my $req = Protocol::HTTP::Request->new({});
    is $req->to_string, "GET / HTTP/1.1\r\n\r\n";
};

subtest "method string" => sub {
    is Protocol::HTTP::Request::method_str(METHOD_POST), 'POST';
    is Protocol::HTTP::Request::method_str(99), '[UNKNOWN]';

    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_GET,
        uri          => "http://crazypanda.ru/hello/world",
        http_version => 10,
    });
    is $req->method_str, 'GET';

    my $req2 = Protocol::HTTP::Request->new({
        uri => "http://crazypanda.ru/hello/world",
    });
    is $req2->method_str, 'GET', "correctly deduced";
    is $req2->method_raw, METHOD_UNSPECIFIED;
    is $req2->method, METHOD_GET;
};

subtest "bugfix: MEIACORE-1000, no double cookeis on output " => sub {

    my $req = Protocol::HTTP::Request->new({
        method  => METHOD_GET,
        cookies => { foo => '123' },
    });
    my $expected =
        "GET / HTTP/1.1\r\n".
        "Cookie: foo=123\r\n".
        "\r\n"
        ;
    is $req->to_string, $expected;
    is $req->to_string, $expected;
};



done_testing();
