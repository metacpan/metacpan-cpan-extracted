use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;
use Protocol::HTTP::Response;

catch_run('[compile-cookies]');

subtest 'request cookies' => sub {
    subtest '"cookies" in ctor' => sub {
        my $req = new Protocol::HTTP::Request({
            cookies => {a => 1},
        });
        is $req->to_string,
            "GET / HTTP/1.1\r\n".
            "Cookie: a=1\r\n".
            "\r\n";
    };
    subtest 'cookies()' => sub {
        my $req = new Protocol::HTTP::Request;
        $req->cookies({junk => 1}); # should be overwritten
        my $hash = {a => 1};
        $req->cookies($hash);
        is $req->to_string,
            "GET / HTTP/1.1\r\n".
            "Cookie: a=1\r\n".
            "\r\n";
        is_deeply $req->cookies, $hash;
    };
    subtest 'cookie()' => sub {
        my $req = new Protocol::HTTP::Request;
        is $req->cookie("session"), undef;
        $req->cookie("session", "abc");
        is $req->cookie("session"), "abc";
        is $req->to_string,
            "GET / HTTP/1.1\r\n".
            "Cookie: session=abc\r\n".
            "\r\n";
    };
};

subtest 'response cookies' => sub {
    subtest '"cookies" in ctor' => sub {
        my $res = new Protocol::HTTP::Response({
            cookies => {session => {
                value     => "123",
                domain    => "epta.ru",
                path      => "/",
                max_age   => 1000,
                secure    => 1,
                http_only => 1,
                same_site => COOKIE_SAMESITE_NONE,
            }},
        });
        is $res->to_string,
            "HTTP/1.1 200 OK\r\n".
            "Content-Length: 0\r\n".
            "Set-Cookie: session=123; Domain=epta.ru; Path=/; Max-Age=1000; Secure; HttpOnly; SameSite=None\r\n".
            "\r\n";
    };
    subtest 'cookies()' => sub {
        my $res = new Protocol::HTTP::Response;
        $res->cookies({Lorem => {value => 'Ipsum'}}); # should be overwritten
        my $hash = {Sit => {
            value => 'amen',
            domain    => "epta.ru",
            path      => "/",
            secure    => 1,
            http_only => 1,
            expires  => Date->new("2032-11-28 21:43:59+00"),
            same_site => COOKIE_SAMESITE_NONE,
        }};
        $res->cookies($hash);
        is $res->to_string,
            "HTTP/1.1 200 OK\r\n".
            "Content-Length: 0\r\n".
            "Set-Cookie: Sit=amen; Domain=epta.ru; Path=/; Expires=Sun, 28 Nov 2032 21:43:59 GMT; Secure; HttpOnly; SameSite=None\r\n".
            "\r\n";
        is_deeply $res->cookies, $hash;
    };

    subtest 'cookie()' => sub {
        my $res = new Protocol::HTTP::Response;
        is $res->cookie("session"), undef;
        $res->cookie("session", {value => 'abc'});
        is_deeply $res->cookie("session"), {
            value     => 'abc',
            http_only => 0,
            secure    => 0,
            same_site => Protocol::HTTP::Response::COOKIE_SAMESITE_DISABLED,
        };
        is $res->to_string,
            "HTTP/1.1 200 OK\r\n".
            "Content-Length: 0\r\n".
            "Set-Cookie: session=abc\r\n".
            "\r\n";
    };
};

done_testing();
