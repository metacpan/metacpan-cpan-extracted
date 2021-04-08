use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;

catch_run('[compile-chunks]');

subtest "make chunk + final_chunk" => sub {
    my $res = Protocol::HTTP::Response->new({
        chunked => 1,
    });
    is $res->to_string,
        "HTTP/1.1 200 OK\r\n".
        "Transfer-Encoding: chunked\r\n".
        "\r\n"
    ;
    is $res->make_chunk('hello-world'),
        "b\r\n".
        "hello-world\r\n"
        ;
    is $res->final_chunk(),
        "0\r\n".
        "\r\n"
        ;
};

done_testing;
