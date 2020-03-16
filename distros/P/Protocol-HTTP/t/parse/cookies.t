use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;
use Protocol::HTTP::Response;
use Protocol::HTTP::Request;
use Protocol::HTTP::Message;

catch_run('[parse-cookies]');

subtest 'request cookies' => sub {
    my $p = Protocol::HTTP::RequestParser->new;

    my ($req, $state, $pos, $err) = $p->parse(
        "GET / HTTP/1.0\r\n".
        "Cookie: key1=v1\r\n".
        "Cookie: key2=v2\r\n".
        "Cookie: key3=v3; key4=v4\r\n".
        "\r\n"
    );
    is $state, Protocol::HTTP::Message::STATE_DONE;
    ok !$err;
    is_deeply $req->cookies, {
        key1 => 'v1', key2 => 'v2', key3 => 'v3', key4 => 'v4'
    };
};

subtest 'response cookies' => sub {
    my $p = Protocol::HTTP::ResponseParser->new;
    $p->set_context_request(new Protocol::HTTP::Request({method => METHOD_GET}));
    my $raw =
        "HTTP/1.0 200 OK\r\n".
        "Set-Cookie: k1=v1; Domain=.crazypanda.ru; Path=/; Max-Age=999; Secure; HttpOnly; SameSite=None\r\n".
        "Set-Cookie: k2=v2; Domain=epta.ru; Expires=Sun, 28 Nov 2032 21:43:59 GMT; SameSite\r\n".
        "\r\n";

    my ($res, $state, $pos, $err) = $p->parse($raw);

    ok $state != STATE_DONE;
    ok !$err;
    is_deeply $res->cookies, {
        k1 => {
            value     => 'v1',
            domain    => '.crazypanda.ru',
            path      => '/',
            max_age   => 999,
            secure    => 1,
            http_only => 1,
            same_site => COOKIE_SAMESITE_NONE
        },
        k2 => {
            value     => 'v2',
            domain    => 'epta.ru',
            expires   => Date->new("2032-11-28 21:43:59+00"),
            same_site => COOKIE_SAMESITE_STRICT,
            secure    => 0,
            http_only => 0,
        },
    };
};

done_testing();
