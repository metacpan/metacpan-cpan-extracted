use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;

catch_run('[compile-response]');

subtest 'basic' => sub {
    my $res = Protocol::HTTP::Response->new({
        code    => 500,
        message => "epta",
        headers => {a => 1},
        body    => "hello",
    });
    $res->header('b', 2);
    
    is $res->to_string,
        "HTTP/1.1 500 epta\r\n".
        "Content-Length: 5\r\n".
        "a: 1\r\n".
        "b: 2\r\n".
        "\r\n".
        "hello"
    ;
};

subtest 'code is not given' => sub {
    my $res = Protocol::HTTP::Response->new();
    
    is $res->to_string,
        "HTTP/1.1 200 OK\r\n".
        "Content-Length: 0\r\n".
        "\r\n"
    ;
};

done_testing();
