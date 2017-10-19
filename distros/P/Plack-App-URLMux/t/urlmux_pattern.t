use strict;
use Test::More;
use Plack::App::URLMux;
use Plack::Test;
use HTTP::Request::Common;

my $app1 = sub {
    my $env = shift;
    my $body = join "|", 'app=app1', 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app2 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $body = join "|", 'app=app2', 'name='.join(',', @$name), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app3 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $body = join "|", 'app=app3', 'name='.join(',', @$name), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app4 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $body = join "|", 'app=app4', 'name='.join(',', @$name), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app5 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $body = join "|", 'app=app5', 'name='.join(',', @$name), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app6 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $test = $params{test};
    my $body = join "|", 'app=app6', 'name='.join(',', @$name), 'test='.join(',', @$test), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app7 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $body = join "|", 'app=app7', 'name='.join(',', @$name), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app8 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $body = join "|", 'app=app8', 'name='.join(',', @$name), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};

my $app9 = sub {
    my $env = shift;
    my %params = @{$env->{'plack.urlmux.params.url'}};
    my $name = $params{name};
    my $body = join "|", 'app=app9', 'name='.join(',', @$name), 'script='.$env->{SCRIPT_NAME}, 'path='.$env->{PATH_INFO};
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
};


my $app = Plack::App::URLMux->new;
$app->map("/" => $app1);
$app->map("/:name*" => $app2);
$app->map("/:name+/foo" => $app3);
$app->map("/foobar/:name+" => $app4);
$app->map("http://bar.example.com/:name*" => $app5);
$app->map("/:name*/bar/:test*" => $app6);
$app->map("/foo/:name{2,}" => $app7);
$app->map("/foo/:name{2,3}" => $app8);
$app->map("/foo/:name{1,4}" => $app9);

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res;

    ####################################################################
    # test app1 $app->map("/" => $app1);

    $res = $cb->(GET "http://localhost/");
    is $res->content, 'app=app1|script=|path=/';

    ####################################################################
    # test app2  $app->map("/:name*" => $app2);

    $res = $cb->(GET "http://localhost/name1");
    is $res->content, 'app=app2|name=name1|script=/name1|path=';

    #FIXME
    $res = $cb->(GET "http://localhost/name1/name2");
    is $res->content, 'app=app2|name=name1,name2|script=/name1/name2|path=';

    $res = $cb->(GET "http://localhost/name1/name2/name3");
    is $res->content, 'app=app2|name=name1,name2,name3|script=/name1/name2/name3|path=';

    ####################################################################
    # test app3 $app->map("/:name+/foo" => $app3);

    $res = $cb->(GET "http://localhost/name2/foo");
    is $res->content, 'app=app3|name=name2|script=/name2/foo|path=';

    $res = $cb->(GET "http://localhost/name1/name2/foo");
    is $res->content, 'app=app3|name=name1,name2|script=/name1/name2/foo|path=';

    $res = $cb->(GET "http://localhost/foo");
    is $res->content, 'app=app2|name=foo|script=/foo|path=';

    ####################################################################
    # test app4 $app->map("/foobar/:name+" => $app4);

    $res = $cb->(GET "http://localhost/foobar/name1");
    is $res->content, 'app=app4|name=name1|script=/foobar/name1|path=';

    $res = $cb->(GET "http://localhost/foobar/name1/name2");
    is $res->content, 'app=app4|name=name1,name2|script=/foobar/name1/name2|path=';

    ####################################################################
    # test app5 $app->map("http://bar.example.com/:name*" => $app5);

    $res = $cb->(GET "http://bar.example.com/");
    is $res->content, 'app=app5|name=|script=|path=/';

    $res = $cb->(GET "http://bar.example.com/name1");
    is $res->content, 'app=app5|name=name1|script=/name1|path=';

    ####################################################################
    # test app6 $app->map("/:name*/bar/:test*" => $app6);

    $res = $cb->(GET "http://localhost/bar/name1");
    is $res->content, 'app=app6|name=|test=name1|script=/bar/name1|path=';

    $res = $cb->(GET "http://localhost/name1/bar/name2");
    is $res->content, 'app=app6|name=name1|test=name2|script=/name1/bar/name2|path=';

    $res = $cb->(GET "http://localhost/name1/name2/bar/name3");
    is $res->content, 'app=app6|name=name1,name2|test=name3|script=/name1/name2/bar/name3|path=';

    ####################################################################
    # test app7 $app->map("/foo/:name{2,}"  => $app7);
    # test app8 $app->map("/foo/:name{2,3}" => $app8);
    # test app9 $app->map("/foo/:name{1,4}" => $app9);

    $res = $cb->(GET "http://localhost/foo/name1");
    is $res->content, 'app=app9|name=name1|script=/foo/name1|path=';

    $res = $cb->(GET "http://localhost/foo/name1/name2");
    is $res->content, 'app=app8|name=name1,name2|script=/foo/name1/name2|path=';

    $res = $cb->(GET "http://localhost/foo/name1/name2/name3");
    is $res->content, 'app=app8|name=name1,name2,name3|script=/foo/name1/name2/name3|path=';

    $res = $cb->(GET "http://localhost/foo/name1/name2/name3/name4");
    is $res->content, 'app=app9|name=name1,name2,name3,name4|script=/foo/name1/name2/name3/name4|path=';

    $res = $cb->(GET "http://localhost/foo/name1/name2/name3/name4/name5");
    is $res->content, 'app=app7|name=name1,name2,name3,name4,name5|script=/foo/name1/name2/name3/name4/name5|path=';

    # Fix a bug where $location eq ''
    #$_ = "bar"; /bar/;
    $res = $cb->(GET "http://localhost/");
    is $res->content, 'app=app1|script=|path=/';

};

done_testing;
