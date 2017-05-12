use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use Nephia::Core;

my $v = Nephia::Core->new(
    plugins => [qw/Dispatch/],
    app => sub {
        get('/' => sub {
            my $req = req();
            [200, [], 'OK'];
        });
        get([qw|/foo /bar|] => sub {
            my $req = req();
            [200, [], 'hoge'];
        });
        get('/user' => sub {
            my $app = shift;
            my $id = $app->{active} || 'noname';
            [200, [], "id = $id"];
        });
        post('/user/:id' => sub {
            my $app = shift;
            my $id = path_param('id');
            $app->{active} = $id;
            [200, [], "done"];
        });
        put('/user/:id' => sub {
            my $app = shift;
            my $id = path_param('id');
            $app->{active} ||= '';
            $app->{active} .= $id;
            [200, [], "appended"];
        });
        del('/user' => sub {
            my $app = shift;
            $app->{active} = undef;
            [200, [], "deleted"];
        });
    },
);

test_psgi $v->run, sub {
    my $cb = shift;
    my $res;
    $res = $cb->(GET '/');
    is $res->content, 'OK';
    $res = $cb->(GET '/foo');
    is $res->content, 'hoge';
    $res = $cb->(GET '/bar');
    is $res->content, 'hoge';
    $res = $cb->(GET '/user');
    is $res->content, 'id = noname';
    $res = $cb->(POST '/user/ytnobody');
    is $res->content, 'done';
    $res = $cb->(GET '/user');
    is $res->content, 'id = ytnobody';
    $res = $cb->(PUT '/user/_foolish');
    is $res->content, 'appended';
    $res = $cb->(GET '/user');
    is $res->content, 'id = ytnobody_foolish';
    $res = $cb->(DELETE '/user');
    is $res->content, 'deleted';
    $res = $cb->(GET '/user');
    is $res->content, 'id = noname';
};

done_testing;

