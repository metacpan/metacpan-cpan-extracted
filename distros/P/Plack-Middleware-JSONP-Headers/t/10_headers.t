use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request;
use JSON qw(from_json);

sub mock_app {
    my ($status, $body, @headers) = @_;
    sub { [ $status, ['Content-Type' => 'application/json', @headers], [$body] ] };
}

sub with_link {
    [400,[
        Link => '<url1>; rel="next", <url2>; rel="foo"; bar="baz"',
        'X-Error' => "bad request",
        'Content-Type' => 'application/json; encoding=utf8'
    ],['{"message":"bad request"}']]
}

my @tests = (
       {
        app  => mock_app(200,'{"foo":"bar"}'),
        json => { meta => { status => 200, 'Content-Type' => 'application/json' }, data => { foo => "bar" } },
    },{
        app  => mock_app(200,'{"foo":"bar"}'),
        json => { meta => { status => 200 }, data => { foo => "bar" } },
        headers => [],
    },{
        app  => mock_app(200,'{"foo":"bar"}', 'X-Bar' => "1"),
        json => { meta => { status => 200, 'X-Bar' => "1" }, data => { foo => "bar" } },
        headers => ['X-Foo','X-Bar'],
    },{
        app => \&with_link,
        json => { 
            meta => { 
                status => 400,
                'X-Error' => 'bad request',
            }, data => { message => "bad request" } },
        headers => qr/^X-/,
    },{
        app => \&with_link,
        json => { meta => { 
                status => 400,
                Link => [ 
                    [ "url1", { rel => "next" } ],
                    [ "url2", { rel => "foo", bar => "baz" } ],
                ]
            }, data => { message => "bad request" } },
        headers => qr/^[^[CX]/,
    },{
        app  => mock_app(400,'[1,2,3]','X-Foo' => 42, 'X-Bar' => 23),
        json => { headers => { status => 400, 'X-Foo' => 42 }, body => [1,2,3] },
        headers  => ['X-Foo'],
        template => '{ "headers": %s, "body": %s }',
    }
);

foreach my $test (@tests) {
    my $app  = delete $test->{app};
    my $json = delete $test->{json};
    $app = builder {
        enable 'JSONP::Headers', %$test;
        $app;
    };
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/?callback=foo'));
        ok($res->content =~ qr{^foo\((.+)\)$}, 'callback'); 
        is_deeply from_json($1), $json, 'wrapped';
    };
}

done_testing;
