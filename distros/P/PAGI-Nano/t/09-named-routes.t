use strict;
use warnings;
use utf8;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Test::Client;
use PAGI::Nano;

# Named routes for link generation. A route is named with the name() marker (in
# the same arrow chain as the path and middleware); $c->uri_for builds the URL.
# Crucially, names form one flat namespace across mounts: a mounted app can link
# to a name in the parent, and the parent can link to a name in the mount.

subtest 'name() + uri_for resolves a route' => sub {
    my $app = app {
        get '/users/:id' => name('user') => sub {
            my ($c, $id) = @_;
            { url => $c->uri_for('user', { id => $id }) };
        };
    };
    my $res = PAGI::Test::Client->new(app => $app)->get('/users/5');
    is $res->json, { url => '/users/5' }, 'path param substituted';
};

subtest 'uri_for appends a query string' => sub {
    my $app = app {
        get '/users/:id' => name('user') => sub {
            my ($c, $id) = @_;
            { url => $c->uri_for('user', { id => $id }, { tab => 'profile' }) };
        };
    };
    my $res = PAGI::Test::Client->new(app => $app)->get('/users/5');
    is $res->json->{url}, '/users/5?tab=profile', 'query string appended';
};

subtest 'uri_for percent-encodes decoded strings with route-aware semantics' => sub {
    my $ctx = bless {
        scope => {
            'pagi.nano.routes' => {
                user   => '/café/users/:id',
                search => '/search',
                files  => '/files/*path',
            },
        },
    }, 'PAGI::Nano::Context';

    is $ctx->uri_for('user', { id => 'a b?#%' }),
        '/caf%C3%A9/users/a%20b%3F%23%25',
        'literal and ordinary-placeholder values use UTF-8 path encoding';

    is $ctx->uri_for('search', {}, { café => 'a b&=', z => '☃' }),
        '/search?caf%C3%A9=a%20b%26%3D&z=%E2%98%83',
        'query keys and values use sorted UTF-8 percent encoding';

    is $ctx->uri_for('files', { path => 'café/a b' }),
        '/files/caf%C3%A9/a%20b',
        'splat preserves only its slash separators';

    is $ctx->uri_for('user', { id => '%2F' }),
        '/caf%C3%A9/users/%252F',
        'callers pass decoded values rather than pre-encoded values';
};

subtest 'uri_for rejects slash in an ordinary placeholder' => sub {
    my $ctx = bless {
        scope => { 'pagi.nano.routes' => { user => '/users/:id' } },
    }, 'PAGI::Nano::Context';

    my $err = dies { $ctx->uri_for('user', { id => 'a/b' }) };
    like $err, qr{/.*splat|splat.*/}i,
        'ordinary placeholder rejects a path-valued input and points to splat';
};

subtest 'middleware() marker is equivalent to the [] shorthand' => sub {
    my @trail;
    my $mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @trail, 'mw';
        await $next->();
    };
    my $app = app {
        get '/a' => middleware($mw) => sub { my ($c) = @_; { ok => 1 } };
    };
    PAGI::Test::Client->new(app => $app)->get('/a');
    is \@trail, ['mw'], 'middleware() marker ran the middleware';
};

subtest 'name() composes with middleware in any order' => sub {
    my @trail;
    my $mw = async sub {
        my ($scope, $receive, $send, $next) = @_;
        push @trail, 'mw';
        await $next->();
    };
    my $app = app {
        get '/a' => middleware($mw) => name('thing') => sub {
            my ($c) = @_;
            { url => $c->uri_for('thing') };
        };
    };
    my $res = PAGI::Test::Client->new(app => $app)->get('/a');
    is \@trail, ['mw'], 'middleware ran';
    is $res->json, { url => '/a' }, 'route still named and linkable';
};

subtest 'cross-mount: parent links to mount name, mount links to parent name' => sub {
    my $api = app {
        get '/users/:id' => name('user') => sub {
            my ($c, $id) = @_;
            {
                self => $c->uri_for('user', { id => $id }),   # own name
                home => $c->uri_for('home'),                  # parent's name
            };
        };
    };

    my $app = app {
        get '/' => name('home') => sub {
            my ($c) = @_;
            { api_user => $c->uri_for('user', { id => 7 }) };  # mount's name
        };
        mount '/api' => $api;
    };

    my $client = PAGI::Test::Client->new(app => $app);

    my $in_mount = $client->get('/api/users/3')->json;
    is $in_mount->{self}, '/api/users/3', 'mount links its own name with the mount prefix';
    is $in_mount->{home}, '/', 'mount links a name defined in the parent';

    my $in_parent = $client->get('/')->json;
    is $in_parent->{api_user}, '/api/users/7',
        'parent links a name defined in the mount, mount-prefixed';
};

subtest 'uri_for works from WebSocket and SSE handlers too' => sub {
    my $app = app {
        get '/users/:id' => name('user') => sub { my ($c, $id) = @_; {} };

        websocket '/ws' => async sub {
            my ($c) = @_;
            my $ws = $c->websocket;
            await $ws->accept;
            await $ws->send_text($c->uri_for('user', { id => 9 }));
        };

        sse '/sse' => async sub {
            my ($c) = @_;
            my $s = $c->sse;
            await $s->send($c->uri_for('user', { id => 8 }));
            await $s->close;
        };
    };
    my $client = PAGI::Test::Client->new(app => $app);

    $client->websocket('/ws', sub {
        my ($ws) = @_;
        is $ws->receive_text, '/users/9', 'uri_for from a WebSocket handler';
    });

    $client->sse('/sse', sub {
        my ($sse) = @_;
        is $sse->receive_event->{data}, '/users/8', 'uri_for from an SSE handler';
    });
};

subtest 'no module-level route registry leaks between apps' => sub {
    # Cross-mount name resolution must not rely on a package global: building
    # and mounting named apps leaves no growing module-level registry behind.
    my $api = app {
        get '/x/:id' => name('leak_probe_x') => sub { my ($c) = @_; {} };
    };
    app {
        get '/' => name('leak_probe_home') => sub { my ($c) = @_; {} };
        mount '/api' => $api;
    };
    no warnings 'once';
    is scalar keys %PAGI::Nano::APP_ROUTES, 0,
        'no PAGI::Nano::APP_ROUTES package global accumulates app entries';
};

subtest 'duplicate route names are a loud error' => sub {
    my $err = dies {
        app {
            get '/a' => name('dup') => sub { my ($c) = @_; 'a' };
            get '/b' => name('dup') => sub { my ($c) = @_; 'b' };
        };
    };
    like $err, qr/[Dd]uplicate route name 'dup'/, 'naming the same name twice dies';
};

done_testing;
