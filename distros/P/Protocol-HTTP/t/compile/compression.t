use 5.012;
# prevent loading brotly plugin
BEGIN { $INC{'Protocol/HTTP/Compression/Brotli.pm'}=1; }

use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;
use Protocol::HTTP::Request;
use Protocol::HTTP::Compression;

catch_run('[compile-compression]');

subtest 'allow compression array' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_GET,
        uri          => "http://crazypanda.ru/",
        allow_compression => Protocol::HTTP::Compression::gzip,
    });
    is $req->to_string,
        "GET / HTTP/1.1\r\n".
        "Host: crazypanda.ru\r\n".
        "Accept-Encoding: gzip\r\n".
        "\r\n"
    ;
};

subtest 'allow compression array (gzip + identity)' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_GET,
        uri          => "http://crazypanda.ru/",
        allow_compression => [ Protocol::HTTP::Compression::gzip, Protocol::HTTP::Compression::identity ],
    });
    is $req->to_string,
        "GET / HTTP/1.1\r\n".
        "Host: crazypanda.ru\r\n".
        "Accept-Encoding: gzip\r\n".
        "\r\n"
    ;
    ok $req->allowed_compression & Protocol::HTTP::Compression::gzip;
    ok $req->allowed_compression & Protocol::HTTP::Compression::identity;
};

subtest 'allow compression array (identity) - ignored' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_GET,
        uri          => "http://crazypanda.ru/",
        allow_compression => [ Protocol::HTTP::Compression::identity ],
    });
    is $req->to_string,
        "GET / HTTP/1.1\r\n".
        "Host: crazypanda.ru\r\n".
        "\r\n"
    ;
};

subtest 'allow compression method' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_GET,
        uri          => "http://crazypanda.ru/",
    });
    $req->allow_compression(Protocol::HTTP::Compression::gzip);

    ok $req->allowed_compression & Protocol::HTTP::Compression::gzip;
    is $req->to_string,
        "GET / HTTP/1.1\r\n".
        "Host: crazypanda.ru\r\n".
        "Accept-Encoding: gzip\r\n".
        "\r\n"
    ;
};

subtest 'allow compression method' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_POST,
        uri          => "http://crazypanda.ru/",
        body         => "my body",
        compress     => Protocol::HTTP::Compression::gzip,
    });
    like $req->to_string, qr/Content-Length: 27/;
    like $req->to_string, qr/Content-Encoding: gzip/;
    is $req->compression, Protocol::HTTP::Compression::gzip;
};

subtest 'max compression ' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_POST,
        uri          => "http://crazypanda.ru/",
        body         => "lorem ipsum dolor sit amet",
    });
    $req->compress(Protocol::HTTP::Compression::gzip, Protocol::HTTP::Compression::LEVEL_MAX);
    like $req->to_string, qr/Content-Length: 46/;
    like $req->to_string, qr/Content-Encoding: gzip/;
    is $req->compression, Protocol::HTTP::Compression::gzip;
};

subtest 'SRV-1748 bugfix (invalid compression params)' => sub {
    my $req = Protocol::HTTP::Request->new({
        method       => METHOD_GET,
        uri          => "http://crazypanda.ru/",
    });
    $req->allow_compression(0..10);
    is $req->to_string,
        "GET / HTTP/1.1\r\n".
        "Host: crazypanda.ru\r\n".
        "Accept-Encoding: gzip, br\r\n".
        "\r\n"
        ;
    my $req2 = Protocol::HTTP::Request->new({
        method            => METHOD_GET,
        uri               => "http://crazypanda.ru/",
        allow_compression => [0..10],
    });
    is $req->to_string, $req2->to_string;
};

done_testing;
