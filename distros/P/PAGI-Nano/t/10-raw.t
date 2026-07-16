use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Response;
use PAGI::Test::Client;
use PAGI::Nano;

# `raw` is an imperative HTTP route: the handler gets $c, owns its own response
# (no return-value coercion), matches any method, and can drop fully to raw PAGI
# via $c->scope / $c->receive / $c->send. The escape hatch.

subtest 'raw handler sends its own response; the return value is ignored' => sub {
    my $app = app {
        raw '/x' => async sub {
            my ($c) = @_;
            await $c->respond(PAGI::Response->text('hand-sent', status => 201));
            return { coerced => 'nope' };   # must be ignored (no coercion)
        };
    };
    my $res = PAGI::Test::Client->new(app => $app)->get('/x');
    is $res->status, 201, 'status from the hand-sent response';
    is $res->content, 'hand-sent', 'body hand-sent; the returned hashref is not coerced to JSON';
};

subtest 'raw matches any method' => sub {
    my $app = app {
        raw '/m' => async sub {
            my ($c) = @_;
            await $c->respond(PAGI::Response->text($c->method));
        };
    };
    my $client = PAGI::Test::Client->new(app => $app);
    is $client->get('/m')->content,  'GET',  'GET';
    is $client->post('/m')->content, 'POST', 'POST';
};

subtest 'path placeholders map to the signature' => sub {
    my $app = app {
        raw '/u/:id' => async sub {
            my ($c, $id) = @_;
            await $c->respond(PAGI::Response->json({ id => $id }));
        };
    };
    my $res = PAGI::Test::Client->new(app => $app)->get('/u/42');
    is $res->json, { id => '42' }, ':id reaches the signature';
};

subtest 'raw can drop fully to the raw PAGI send triple' => sub {
    my $app = app {
        raw '/low' => async sub {
            my ($c) = @_;
            my ($scope, $send) = ($c->scope, $c->send);   # $c->send is the raw send on HTTP
            await $send->({ type => 'http.response.start', status => 200,
                            headers => [['content-type', 'text/plain']] });
            await $send->({ type => 'http.response.body', body => "path=$scope->{path}", more => 0 });
        };
    };
    my $res = PAGI::Test::Client->new(app => $app)->get('/low');
    is $res->content, 'path=/low', 'handler used the raw $scope/$send directly';
};

done_testing;
