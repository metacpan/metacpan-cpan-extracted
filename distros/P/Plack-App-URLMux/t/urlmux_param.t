use strict;
use Test::More;
use Plack::App::URLMux;
use Plack::Test;
use HTTP::Request::Common;

my $app1 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.map'}};
    my $name = $params{name};
    my $body = join "|", $name, $env->{SCRIPT_NAME}, $env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app = Plack::App::URLMux->new;
# position of url and parameters matter!
$app->map("/" => $app1, name=>"app1");
$app->map("/foo" => $app1, name=>"app2");
$app->map("/foobar" => $app1, name=>"app3");
$app->map("http://bar.example.com/" => $app1,   name=>"app4");

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res ;

    # returns content for app
    # $app1 => |name|PATH_INFO|SCRIPT_NAME

    $res = $cb->(GET "http://localhost/");
    is $res->content, 'app1||/';

    $res = $cb->(GET "http://localhost/foo");
    is $res->content, 'app2|/foo|';

    $res = $cb->(GET "http://localhost/foo/bar");
    is $res->content, 'app2|/foo|/bar';

    $res = $cb->(GET "http://localhost/foox");
    is $res->content, 'app1||/foox';

    $res = $cb->(GET "http://localhost/foox/bar");
    is $res->content, 'app1||/foox/bar';

    $res = $cb->(GET "http://localhost/foobar");
    is $res->content, 'app3|/foobar|';

    $res = $cb->(GET "http://localhost/foobar/baz");
    is $res->content, 'app3|/foobar|/baz';

    $res = $cb->(GET "http://localhost/bar/foo");
    is $res->content, 'app1||/bar/foo';

    $res = $cb->(GET "http://bar.example.com/");
    is $res->content, 'app4||/';

    $res = $cb->(GET "http://bar.example.com/foo");
    is $res->content, 'app4||/foo';

    # Fix a bug where $location eq ''
    $_ = "bar"; /bar/;
    $res = $cb->(GET "http://localhost/");
    is $res->content, 'app1||/';

};

done_testing;
