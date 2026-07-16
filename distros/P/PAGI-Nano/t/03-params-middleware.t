use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use FindBin ();
use lib "$FindBin::Bin/lib";
use PAGI::Test::Client;
use PAGI::Nano;

# Path placeholders become handler parameters in path order; route/group/app
# middleware compose in the right scopes; POST handlers shape input via params.

my @trail;   # records middleware execution order across a request

# A coderef event-layer middleware that tags the request as it passes through.
sub tagger { my ($label) = @_;
    return async sub { my ($scope, $receive, $send, $next) = @_;
        push @trail, "enter:$label";
        await $next->($scope, $receive, $send);
        push @trail, "leave:$label";
    };
}

my $app = app {
    enable tagger('app');

    get '/u/:uid/p/:pid' => sub { my ($c, $uid, $pid) = @_;
        { uid => $uid, pid => $pid };
    };

    get '/tagged' => [tagger('route')] => sub { my ($c) = @_; { ok => 1 } };

    group '/api' => [tagger('group')] => sub {
        get '/ping' => sub { my ($c) = @_; { pong => 1 } };
    };

    post '/tasks' => async sub { my ($c) = @_;
        my $attrs = await $c->params->required(
            'title',
            +{ tags => [] },
            sub { my ($ctx, $missing) = @_;
                $ctx->json({ error => 'missing', fields => $missing }, status => 400);
            },
        );
        return $c->json({ created => $attrs }, status => 201);
    };
};

my $client = PAGI::Test::Client->new(app => $app);

subtest 'placeholders map to the signature in path order' => sub {
    my $res = $client->get('/u/42/p/7');
    is $res->json, { uid => '42', pid => '7' }, ':uid and :pid arrive as $uid, $pid';
};

subtest 'app middleware wraps every request' => sub {
    @trail = ();
    $client->get('/u/1/p/2');
    is \@trail, ['enter:app', 'leave:app'], 'app-wide middleware runs outermost';
};

subtest 'route middleware composes inside app middleware' => sub {
    @trail = ();
    $client->get('/tagged');
    is \@trail, ['enter:app', 'enter:route', 'leave:route', 'leave:app'],
        'route middleware is inside app middleware';
};

subtest 'group middleware wraps the branch' => sub {
    @trail = ();
    my $res = $client->get('/api/ping');
    is $res->json, { pong => 1 }, 'grouped route reachable under prefix';
    is \@trail, ['enter:app', 'enter:group', 'leave:group', 'leave:app'],
        'group middleware wraps the branch, inside app middleware';
};

subtest 'POST success: params shape and required pass through' => sub {
    my $res = $client->post('/tasks', json => { title => 'Buy milk', tags => ['x'], junk => 1 });
    is $res->status, 201, 'created';
    is $res->json, { created => { title => 'Buy milk', tags => ['x'] } },
        'only permitted keys survive';
};

subtest 'POST failure: required missing -> callback response thrown and sent' => sub {
    my $res = $client->post('/tasks', json => { tags => ['x'] });
    is $res->status, 400, 'missing required title -> 400';
    is $res->json, { error => 'missing', fields => ['title'] }, 'callback shaped the body';
};

subtest "a leading ^ escapes the PAGI::Middleware:: prefix" => sub {
    @NanoTest::Mw::TRAIL = ();
    my $app = app {
        enable '^NanoTest::Mw', tag => 'escaped';
        get '/' => sub { my ($c) = @_; { ok => 1 } };
    };
    PAGI::Test::Client->new(app => $app)->get('/');
    is \@NanoTest::Mw::TRAIL, ['escaped'],
        'enable ^Class resolved NanoTest::Mw verbatim, not PAGI::Middleware::NanoTest::Mw';
};

done_testing;
