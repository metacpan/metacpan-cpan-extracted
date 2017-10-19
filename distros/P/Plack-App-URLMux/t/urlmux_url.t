use strict;
use Test::More;
use Plack::App::URLMux;
use Plack::Test;
use HTTP::Request::Common;

my $app1 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name} ||= [];
    my $body = join "|", 'app1', join(',', @$name), $env->{SCRIPT_NAME}, $env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app2 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name} ||= [];
    my $test = $params{test} ||= [];
    my $body = join "|", 'app2', join(',', @$name), join(',', @$test), $env->{SCRIPT_NAME}, $env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app = Plack::App::URLMux->new;
$app->map("/" => $app1);
$app->map("/:name" => $app1);
$app->map("/:name/foo" => $app1);
$app->map("/foobar/:name" => $app1);
$app->map("http://bar.example.com/:name" => $app1);
$app->map("/:name/bar/:test/" => $app2);

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res;

    # returns content for app
    # $app1 => |app1|:name|PATH_INFO|SCRIPT_NAME
    # $app2 => |app2|:name|:test|PATH_INFO|SCRIPT_NAME

    # don`t be confused by appN in url as parameters!

    $res = $cb->(GET "http://localhost/name1");
    is $res->content, 'app1|name1|/name1|';

    $res = $cb->(GET "http://localhost/name2/foo");
    is $res->content, 'app1|name2|/name2/foo|';

    $res = $cb->(GET "http://localhost/name1/foo/bar");
    is $res->content, 'app1|name1|/name1/foo|/bar';

    $res = $cb->(GET "http://localhost/name1/bar/test1/baz");
    is $res->content, 'app2|name1|test1|/name1/bar/test1|/baz';

    $res = $cb->(GET "http://localhost/app1/foox");
    is $res->content, 'app1|app1|/app1|/foox';

    $res = $cb->(GET "http://localhost/app1/foox/bar");
    is $res->content, 'app1|app1|/app1|/foox/bar';

    $res = $cb->(GET "http://localhost/foobar/app3");
    is $res->content, 'app1|app3|/foobar/app3|';

    $res = $cb->(GET "http://localhost/foobar/app3/baz");
    is $res->content, 'app1|app3|/foobar/app3|/baz';

    $res = $cb->(GET "http://localhost/app1/bar/foo");
    is $res->content, 'app2|app1|foo|/app1/bar/foo|';

    $res = $cb->(GET "http://bar.example.com/app4");
    is $res->content, 'app1|app4|/app4|';

    $res = $cb->(GET "http://bar.example.com/app4/foo");
    is $res->content, 'app1|app4|/app4|/foo';

    # Fix a bug where $location eq ''
    #$_ = "bar"; /bar/;
    $res = $cb->(GET "http://localhost/");
    is $res->content, 'app1|||/';

};

done_testing;
