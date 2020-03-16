use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;
use Protocol::HTTP::Request;
use Protocol::HTTP::Message;

catch_run('[parse-request]');

subtest "get" => sub {
    my $p = Protocol::HTTP::RequestParser->new;

    my ($req, $state, $pos, $err) = $p->parse(
        "GET / HTTP/1.0\r\n".
        "Host: host1\r\n".
        "\r\n"
    );
    
    is $state, Protocol::HTTP::Message::STATE_DONE;
    ok !$err;
    is $req->method, Protocol::HTTP::Request::METHOD_GET;
    is $req->http_version, 10;
    is $req->uri, "/";
    is ref($req->uri), 'URI::XS';
    ok !$req->body;
    ok !$req->chunked;
    is $pos, 31;
};

subtest "post" => sub {
    my $p = Protocol::HTTP::RequestParser->new;
    my $raw =
        "POST /upload HTTP/1.1\r\n".
        "Content-Length: 23\r\n".
        "\r\n".
        "Wikipedia in\r\n\r\nchunks."
    ;

    my ($req, $state, $err) = $p->parse_shift($raw);
    
    is $state, STATE_DONE;
    ok !$err;
    is $req->method, METHOD_POST;
    is $req->http_version, 11;
    is $req->uri, "/upload";
    is $req->body, "Wikipedia in\r\n\r\nchunks.";
    is $req->header("Content-Length"), 23;
    is $raw, "";
};

subtest 'error' => sub {
    my $p = Protocol::HTTP::RequestParser->new;
    my ($req, $state, undef, $err) = $p->parse("EPTA");
    is $state, STATE_ERROR;
    ok $err;
};

subtest 'reset' => sub {
    my $p = Protocol::HTTP::RequestParser->new;
    $p->parse("GET");
    
    $p->reset;
    
    my ($req, $state) = $p->parse("GET / HTTP/1.0\r\n\r\n");
    is $state, STATE_DONE;
    is $req->method, METHOD_GET;
};

subtest 'backref' => sub {
    my $p = Protocol::HTTP::RequestParser->new;
    
    my ($req)  = $p->parse("GET / HTTP/1.0\r\n");
    my ($req2, $state) = $p->parse("Host: host1\r\n\r\n");
    is $state, STATE_DONE;
    is $req, $req2;
};

done_testing();