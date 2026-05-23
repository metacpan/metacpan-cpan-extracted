# Router: HEAD Body Stripping and Route Table API — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add RFC 9110-compliant HEAD body stripping to the router dispatch and a `route_table()` introspection API.

**Architecture:** HEAD stripping wraps the `$send` coderef inside the existing dispatch block when `$method eq 'HEAD'` matches a GET route. Route table is a new `route_table()` method that iterates the internal route/mount arrays and returns structured data. Both features are additive — no existing behavior changes.

**Tech Stack:** Perl 5.18+, Test2::V0, Future::AsyncAwait

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `t/router-head.t` | Create | Tests for HEAD body stripping |
| `t/router-route-table.t` | Create | Tests for `route_table()` API |
| `lib/PAGI/App/Router.pm` | Modify | HEAD wrapping in dispatch (~line 756), new `route_table()` method |
| `lib/PAGI/Endpoint/Router.pm` | Modify | Pass-through `route_table()` on RouteBuilder |

---

## Task 1: HEAD Body Stripping — Basic Case

### Files
- Create: `t/router-head.t`
- Modify: `lib/PAGI/App/Router.pm:756-764`

- [ ] **Step 1: Write failing test — HEAD returns empty body with correct status and headers**

Create `t/router-head.t`:

```perl
use strict;
use warnings;

use Test2::V0;
use Future::AsyncAwait;

use PAGI::App::Router;

# Helper to capture response events
sub mock_send {
    my @sent;
    my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
    return ($send, \@sent);
}

# Helper to create a GET handler that returns a body with Content-Length
sub make_get_handler {
    my ($body) = @_;
    return async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [
                ['content-type', 'text/plain'],
                ['content-length', length($body)],
            ],
        });
        await $send->({
            type => 'http.response.body',
            body => $body,
            more => 0,
        });
    };
}

subtest 'HEAD request to GET route returns empty body' => sub {
    my $router = PAGI::App::Router->new;
    $router->get('/hello' => make_get_handler('Hello World'));

    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ method => 'HEAD', path => '/hello' }, sub { Future->done }, $send)->get;

    is $sent->[0]{status}, 200, 'status is 200';
    is $sent->[1]{body}, '', 'body is empty string';
    is $sent->[1]{more}, 0, 'more flag preserved';
};

subtest 'HEAD request preserves Content-Length from GET handler' => sub {
    my $router = PAGI::App::Router->new;
    my $body = 'Hello World';
    $router->get('/hello' => make_get_handler($body));

    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ method => 'HEAD', path => '/hello' }, sub { Future->done }, $send)->get;

    # Find content-length in headers
    my %headers = map { $_->[0] => $_->[1] } @{$sent->[0]{headers}};
    is $headers{'content-length'}, length($body), 'Content-Length preserved from GET handler';
    is $sent->[0]{status}, 200, 'status preserved';
};

done_testing;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-head.t'`

Expected: FAIL — body will be `'Hello World'` instead of `''`

- [ ] **Step 3: Implement HEAD body stripping in router dispatch**

In `lib/PAGI/App/Router.pm`, inside the HTTP dispatch block, after the method match succeeds (around line 756-764), wrap `$send` when `$method eq 'HEAD'`:

Replace the block:

```perl
                if ($method_match) {
                    my $new_scope = {
                        %$scope,
                        path_params => \%params,
                        'pagi.router' => { route => $route->{path} },
                    };

                    await $route->{_handler}->($new_scope, $receive, $send);
                    return;
                }
```

With:

```perl
                if ($method_match) {
                    my $new_scope = {
                        %$scope,
                        path_params => \%params,
                        'pagi.router' => { route => $route->{path} },
                    };

                    # RFC 9110: HEAD responses must have no body
                    my $actual_send = $send;
                    if ($method eq 'HEAD' && $route->{method} ne 'HEAD') {
                        $actual_send = sub {
                            my ($event) = @_;
                            if ($event->{type} eq 'http.response.body') {
                                $event = { %$event, body => '' };
                            }
                            $send->($event);
                        };
                    }

                    await $route->{_handler}->($new_scope, $receive, $actual_send);
                    return;
                }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-head.t'`

Expected: All tests PASS

- [ ] **Step 5: Run existing router tests to check for regressions**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/app-router.t t/router-middleware.t t/endpoint-router.t'`

Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add t/router-head.t lib/PAGI/App/Router.pm
git commit -m "feat: strip body from HEAD responses matched to GET routes (RFC 9110)"
```

---

## Task 2: HEAD Body Stripping — Edge Cases

### Files
- Modify: `t/router-head.t`

- [ ] **Step 1: Write failing test — explicit head() route is NOT wrapped**

Append to `t/router-head.t`:

```perl
subtest 'explicit head() route handler controls its own response' => sub {
    my $router = PAGI::App::Router->new;

    # Register both GET and explicit HEAD for the same path
    $router->get('/resource' => make_get_handler('GET body'));
    $router->head('/resource' => async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['x-custom', 'head-handler']],
        });
        await $send->({
            type => 'http.response.body',
            body => '',
            more => 0,
        });
    });

    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ method => 'HEAD', path => '/resource' }, sub { Future->done }, $send)->get;

    # The explicit HEAD handler should have been called, not the GET handler
    my %headers = map { $_->[0] => $_->[1] } @{$sent->[0]{headers}};
    is $headers{'x-custom'}, 'head-handler', 'explicit HEAD handler was called';
};
```

- [ ] **Step 2: Run test to verify it passes (explicit HEAD routes are already dispatched directly)**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-head.t'`

Expected: PASS — explicit HEAD routes match before the GET fallback because they have `method => 'HEAD'`, and `$match_method` is set to `'GET'` only for the GET-fallback path. The explicit HEAD route matches because the dispatch also checks `$route_method eq $method` (line 754).

- [ ] **Step 3: Write failing test — streaming GET handler has all chunks stripped**

Append to `t/router-head.t`:

```perl
subtest 'HEAD strips body from streaming response (multiple chunks)' => sub {
    my $router = PAGI::App::Router->new;
    $router->get('/stream' => async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({ type => 'http.response.body', body => 'chunk1', more => 1 });
        await $send->({ type => 'http.response.body', body => 'chunk2', more => 1 });
        await $send->({ type => 'http.response.body', body => 'chunk3', more => 0 });
    });

    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ method => 'HEAD', path => '/stream' }, sub { Future->done }, $send)->get;

    is $sent->[0]{status}, 200, 'status preserved';
    is $sent->[1]{body}, '', 'chunk 1 body stripped';
    is $sent->[1]{more}, 1, 'chunk 1 more flag preserved';
    is $sent->[2]{body}, '', 'chunk 2 body stripped';
    is $sent->[2]{more}, 1, 'chunk 2 more flag preserved';
    is $sent->[3]{body}, '', 'chunk 3 body stripped';
    is $sent->[3]{more}, 0, 'chunk 3 more flag preserved';
};
```

- [ ] **Step 4: Run test to verify it passes (implementation already handles this)**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-head.t'`

Expected: PASS — the `$send` wrapper intercepts every `http.response.body` event, not just the first.

- [ ] **Step 5: Write test — HEAD to non-existent route returns 404**

Append to `t/router-head.t`:

```perl
subtest 'HEAD to non-existent route returns 404' => sub {
    my $router = PAGI::App::Router->new;
    $router->get('/exists' => make_get_handler('yes'));

    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ method => 'HEAD', path => '/nope' }, sub { Future->done }, $send)->get;

    is $sent->[0]{status}, 404, 'HEAD to unknown path is 404';
};
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-head.t'`

Expected: PASS

- [ ] **Step 7: Write test — HEAD where path matches but only POST is registered returns 405**

Append to `t/router-head.t`:

```perl
subtest 'HEAD returns 405 when path matches but only POST defined' => sub {
    my $router = PAGI::App::Router->new;
    $router->post('/submit' => async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'ok', more => 0 });
    });

    my $app = $router->to_app;

    my ($send, $sent) = mock_send();
    $app->({ method => 'HEAD', path => '/submit' }, sub { Future->done }, $send)->get;

    is $sent->[0]{status}, 405, 'HEAD to POST-only path is 405';

    my %headers = map { $_->[0] => $_->[1] } @{$sent->[0]{headers}};
    like $headers{'allow'}, qr/POST/, 'Allow header includes POST';
};
```

- [ ] **Step 8: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-head.t'`

Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add t/router-head.t
git commit -m "test: add HEAD edge case tests (explicit head route, streaming, 404, 405)"
```

---

## Task 3: Route Table API — HTTP Routes

### Files
- Create: `t/router-route-table.t`
- Modify: `lib/PAGI/App/Router.pm`

- [ ] **Step 1: Write failing test — empty router returns empty arrayref**

Create `t/router-route-table.t`:

```perl
use strict;
use warnings;

use Test2::V0;

use PAGI::App::Router;

subtest 'empty router returns empty route table' => sub {
    my $router = PAGI::App::Router->new;
    my $table = $router->route_table;

    is ref($table), 'ARRAY', 'route_table returns arrayref';
    is scalar @$table, 0, 'empty router has no routes';
};

done_testing;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: FAIL — `Can't locate object method "route_table"`

- [ ] **Step 3: Implement minimal `route_table()` method**

Add to `lib/PAGI/App/Router.pm`, after the `named_routes` method (around line 444):

```perl
sub route_table {
    my ($self) = @_;

    my @table;

    # HTTP routes
    for my $route (@{$self->{routes}}) {
        my %constraints;
        for my $c (@{$route->{constraints} // []}) {
            $constraints{$c->[0]} = qr/$c->[1]/;
        }
        for my $c (@{$route->{_user_constraints} // []}) {
            $constraints{$c->[0]} = $c->[1];
        }

        push @table, {
            type        => 'http',
            method      => $route->{method},
            path        => $route->{path},
            name        => $route->{name},
            params      => [@{$route->{names}}],
            constraints => \%constraints,
            middleware  => scalar @{$route->{middleware} // []},
        };
    }

    # WebSocket routes
    for my $route (@{$self->{websocket_routes}}) {
        my %constraints;
        for my $c (@{$route->{constraints} // []}) {
            $constraints{$c->[0]} = qr/$c->[1]/;
        }
        for my $c (@{$route->{_user_constraints} // []}) {
            $constraints{$c->[0]} = $c->[1];
        }

        push @table, {
            type        => 'websocket',
            path        => $route->{path},
            name        => $route->{name},
            params      => [@{$route->{names}}],
            constraints => \%constraints,
            middleware  => scalar @{$route->{middleware} // []},
        };
    }

    # SSE routes
    for my $route (@{$self->{sse_routes}}) {
        my %constraints;
        for my $c (@{$route->{constraints} // []}) {
            $constraints{$c->[0]} = qr/$c->[1]/;
        }
        for my $c (@{$route->{_user_constraints} // []}) {
            $constraints{$c->[0]} = $c->[1];
        }

        push @table, {
            type        => 'sse',
            path        => $route->{path},
            name        => $route->{name},
            params      => [@{$route->{names}}],
            constraints => \%constraints,
            middleware  => scalar @{$route->{middleware} // []},
        };
    }

    # Mounts
    for my $m (@{$self->{mounts}}) {
        push @table, {
            type        => 'mount',
            path        => $m->{prefix},
            name        => undef,
            params      => [],
            constraints => {},
            middleware  => scalar @{$m->{middleware} // []},
        };
    }

    return \@table;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 5: Write failing test — HTTP routes with method, path, params, name**

Append to `t/router-route-table.t` (before `done_testing`):

```perl
subtest 'HTTP routes appear with correct fields' => sub {
    my $router = PAGI::App::Router->new;
    $router->get('/users' => sub { Future->done });
    $router->post('/users' => sub { Future->done })->name('create_user');
    $router->get('/users/:id' => sub { Future->done })->name('get_user');

    my $table = $router->route_table;

    is scalar @$table, 3, 'three routes in table';

    # GET /users
    is $table->[0]{type}, 'http', 'type is http';
    is $table->[0]{method}, 'GET', 'method is GET';
    is $table->[0]{path}, '/users', 'path is /users';
    is $table->[0]{name}, undef, 'unnamed route has undef name';
    is $table->[0]{params}, [], 'no params';
    is $table->[0]{constraints}, {}, 'no constraints';
    is $table->[0]{middleware}, 0, 'no middleware';

    # POST /users (named)
    is $table->[1]{type}, 'http', 'type is http';
    is $table->[1]{method}, 'POST', 'method is POST';
    is $table->[1]{name}, 'create_user', 'name is create_user';

    # GET /users/:id (named, with param)
    is $table->[2]{type}, 'http', 'type is http';
    is $table->[2]{method}, 'GET', 'method is GET';
    is $table->[2]{path}, '/users/:id', 'path preserves :id syntax';
    is $table->[2]{name}, 'get_user', 'name is get_user';
    is $table->[2]{params}, ['id'], 'params contains id';
};
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 7: Write test — constraints (inline and chained) appear in entry**

Append to `t/router-route-table.t` (before `done_testing`):

```perl
subtest 'constraints appear in route table entries' => sub {
    my $router = PAGI::App::Router->new;

    # Inline constraint
    $router->get('/items/{id:\\d+}' => sub { Future->done });

    # Chained constraint
    $router->get('/posts/:slug' => sub { Future->done })
        ->constraints(slug => qr/^[a-z0-9-]+$/);

    my $table = $router->route_table;

    is scalar @$table, 2, 'two routes';

    # Inline constraint: {id:\d+}
    ok exists $table->[0]{constraints}{id}, 'inline constraint for id exists';
    like '42', $table->[0]{constraints}{id}, 'inline constraint matches digits';

    # Chained constraint
    ok exists $table->[1]{constraints}{slug}, 'chained constraint for slug exists';
    like 'hello-world', $table->[1]{constraints}{slug}, 'chained constraint matches slug';
    unlike 'Hello World', $table->[1]{constraints}{slug}, 'chained constraint rejects bad slug';
};
```

- [ ] **Step 8: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 9: Write test — middleware count is accurate**

Append to `t/router-route-table.t` (before `done_testing`):

```perl
subtest 'middleware count is accurate' => sub {
    my $router = PAGI::App::Router->new;

    my $mw1 = async sub { my ($scope, $receive, $send, $next) = @_; await $next->() };
    my $mw2 = async sub { my ($scope, $receive, $send, $next) = @_; await $next->() };

    $router->get('/no-mw' => sub { Future->done });
    $router->get('/one-mw' => [$mw1] => sub { Future->done });
    $router->get('/two-mw' => [$mw1, $mw2] => sub { Future->done });

    my $table = $router->route_table;

    is $table->[0]{middleware}, 0, 'no middleware';
    is $table->[1]{middleware}, 1, 'one middleware';
    is $table->[2]{middleware}, 2, 'two middleware';
};
```

- [ ] **Step 10: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 11: Commit**

```bash
git add t/router-route-table.t lib/PAGI/App/Router.pm
git commit -m "feat: add route_table() introspection API to PAGI::App::Router"
```

---

## Task 4: Route Table API — WebSocket, SSE, and Mounts

### Files
- Modify: `t/router-route-table.t`

- [ ] **Step 1: Write test — WebSocket and SSE routes appear with correct type**

Append to `t/router-route-table.t` (before `done_testing`):

```perl
subtest 'WebSocket and SSE routes appear in route table' => sub {
    my $router = PAGI::App::Router->new;
    $router->websocket('/ws/chat/:room' => sub { Future->done })->name('chat');
    $router->sse('/events' => sub { Future->done });

    my $table = $router->route_table;

    is scalar @$table, 2, 'two routes';

    is $table->[0]{type}, 'websocket', 'type is websocket';
    is $table->[0]{path}, '/ws/chat/:room', 'websocket path correct';
    is $table->[0]{name}, 'chat', 'websocket name correct';
    is $table->[0]{params}, ['room'], 'websocket params correct';
    ok !exists $table->[0]{method}, 'websocket has no method key';

    is $table->[1]{type}, 'sse', 'type is sse';
    is $table->[1]{path}, '/events', 'sse path correct';
    is $table->[1]{name}, undef, 'unnamed sse route';
    ok !exists $table->[1]{method}, 'sse has no method key';
};
```

- [ ] **Step 2: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 3: Write test — mounts appear with correct type and prefix**

Append to `t/router-route-table.t` (before `done_testing`):

```perl
subtest 'mounts appear in route table' => sub {
    my $router = PAGI::App::Router->new;
    my $sub_app = sub { Future->done };
    my $mw = async sub { my ($scope, $receive, $send, $next) = @_; await $next->() };

    $router->get('/top' => sub { Future->done });
    $router->mount('/api' => $sub_app);
    $router->mount('/admin' => [$mw] => $sub_app);

    my $table = $router->route_table;

    is scalar @$table, 3, 'three entries (1 route + 2 mounts)';

    # HTTP route first
    is $table->[0]{type}, 'http', 'first entry is http';

    # Mounts after
    is $table->[1]{type}, 'mount', 'second entry is mount';
    is $table->[1]{path}, '/api', 'mount path is /api';
    is $table->[1]{name}, undef, 'mount has no name';
    is $table->[1]{params}, [], 'mount has no params';
    is $table->[1]{constraints}, {}, 'mount has no constraints';
    is $table->[1]{middleware}, 0, 'first mount has no middleware';
    ok !exists $table->[1]{method}, 'mount has no method key';

    is $table->[2]{type}, 'mount', 'third entry is mount';
    is $table->[2]{path}, '/admin', 'mount path is /admin';
    is $table->[2]{middleware}, 1, 'second mount has one middleware';
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 5: Write test — ordering: HTTP, WebSocket, SSE, mounts**

Append to `t/router-route-table.t` (before `done_testing`):

```perl
subtest 'route table ordering: http, websocket, sse, mount' => sub {
    my $router = PAGI::App::Router->new;

    # Register in mixed order
    $router->mount('/mounted' => sub { Future->done });
    $router->sse('/events' => sub { Future->done });
    $router->get('/page' => sub { Future->done });
    $router->websocket('/ws' => sub { Future->done });
    $router->post('/data' => sub { Future->done });

    my $table = $router->route_table;

    is scalar @$table, 5, 'five entries';

    # HTTP first (registration order within type)
    is $table->[0]{type}, 'http', 'first is http (GET /page)';
    is $table->[0]{path}, '/page', 'GET /page';
    is $table->[1]{type}, 'http', 'second is http (POST /data)';
    is $table->[1]{path}, '/data', 'POST /data';

    # Then websocket
    is $table->[2]{type}, 'websocket', 'third is websocket';

    # Then SSE
    is $table->[3]{type}, 'sse', 'fourth is sse';

    # Then mounts
    is $table->[4]{type}, 'mount', 'fifth is mount';
};
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add t/router-route-table.t
git commit -m "test: add route table tests for websocket, sse, mounts, and ordering"
```

---

## Task 5: Route Table — Endpoint::Router Pass-Through

### Files
- Modify: `lib/PAGI/Endpoint/Router.pm`
- Modify: `t/router-route-table.t`

- [ ] **Step 1: Write failing test — Endpoint::Router exposes route_table()**

Append to `t/router-route-table.t` (before `done_testing`):

```perl
subtest 'Endpoint::Router passes through route_table()' => sub {
    {
        package TestApp::RouteTable;
        use parent 'PAGI::Endpoint::Router';
        use Future::AsyncAwait;

        sub routes {
            my ($self, $r) = @_;
            $r->get('/hello' => 'say_hello');
            $r->post('/data' => 'handle_data');
            $r->websocket('/ws' => 'ws_handler');
        }

        async sub say_hello {
            my ($self, $ctx) = @_;
            await $ctx->response->text('hi');
        }

        async sub handle_data {
            my ($self, $ctx) = @_;
            await $ctx->response->text('ok');
        }

        async sub ws_handler {
            my ($self, $ctx) = @_;
        }
    }

    my $router = TestApp::RouteTable->new;
    my $table = $router->route_table;

    is ref($table), 'ARRAY', 'route_table returns arrayref';
    is scalar @$table, 3, 'three routes';

    is $table->[0]{type}, 'http', 'first is http';
    is $table->[0]{method}, 'GET', 'GET method';
    is $table->[0]{path}, '/hello', 'path correct';

    is $table->[1]{type}, 'http', 'second is http';
    is $table->[1]{method}, 'POST', 'POST method';

    is $table->[2]{type}, 'websocket', 'third is websocket';
};
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: FAIL — `Can't locate object method "route_table"` on `PAGI::Endpoint::Router`

- [ ] **Step 3: Add route_table() to Endpoint::Router and RouteBuilder**

In `lib/PAGI/Endpoint/Router.pm`, the `Endpoint::Router` class needs a `route_table()` that builds the internal router and delegates. Add after the `to_app` method (around line 60):

```perl
sub route_table {
    my ($self) = @_;

    # Build internal router if not already built
    $self = $self->new unless blessed($self);

    load('PAGI::App::Router');
    my $internal_router = PAGI::App::Router->new;
    $self->_build_routes($internal_router);

    return $internal_router->route_table;
}
```

Also add pass-through on `RouteBuilder` (after the `named_routes` method, around line 309):

```perl
# Pass through route_table() to internal router
sub route_table {
    my ($self) = @_;
    return $self->{router}->route_table;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/router-route-table.t'`

Expected: PASS

- [ ] **Step 5: Run all router-related tests for regressions**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/app-router.t t/app-router-group.t t/router-named-routes.t t/router-middleware.t t/endpoint-router.t t/router-head.t t/router-route-table.t'`

Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add lib/PAGI/Endpoint/Router.pm t/router-route-table.t
git commit -m "feat: add route_table() pass-through to PAGI::Endpoint::Router"
```

---

## Task 6: POD Documentation

### Files
- Modify: `lib/PAGI/App/Router.pm`
- Modify: `lib/PAGI/Endpoint/Router.pm`

- [ ] **Step 1: Add POD for route_table() in App::Router**

Find the POD section for `named_routes` in `lib/PAGI/App/Router.pm` (around line 1169) and add documentation for `route_table` after it:

```pod
=head2 route_table

    my $table = $router->route_table;

Returns an arrayref of hashrefs describing every registered route and mount.
Useful for debugging, testing, and building tooling around the router.

Each entry contains:

    {
        type        => 'http',              # 'http', 'websocket', 'sse', or 'mount'
        method      => 'GET',               # HTTP routes only (string, arrayref, or '*')
        path        => '/users/:id',        # the route pattern as registered
        name        => 'get_user',          # undef if not named
        params      => ['id'],              # parameter names from the path
        constraints => { id => qr/\d+/ },   # merged inline and chained constraints
        middleware  => 2,                    # count of middleware on this route
    }

Mount entries use C<type =E<gt> 'mount'> and do not include a C<method> key.

Routes are ordered: HTTP routes first, then WebSocket, SSE, and mounts last.
Within each type, routes appear in registration order.
```

- [ ] **Step 2: Add POD for route_table() in Endpoint::Router**

Find the `named_routes` pass-through docs in `lib/PAGI/Endpoint/Router.pm` POD and add after it:

```pod
=head2 route_table

    my $table = $router->route_table;

Returns an arrayref of route information hashrefs from the internal
L<PAGI::App::Router>. See L<PAGI::App::Router/route_table> for the
entry format.
```

- [ ] **Step 3: Add POD for HEAD body stripping behavior in App::Router**

Find the HEAD-related documentation in `lib/PAGI/App/Router.pm` POD. Add a note about body stripping behavior near the existing HEAD documentation:

```pod
=head2 HEAD Request Handling

HEAD requests are automatically matched to GET routes. When a HEAD request
matches a GET route, the response body is stripped (replaced with empty
string) while preserving all headers including Content-Length, per RFC 9110.

Routes registered explicitly with C<head()> are NOT wrapped — those handlers
are responsible for their own response.
```

- [ ] **Step 4: Run pod-syntax check**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && perl -MPod::Simple::SimpleTree -e "Pod::Simple::SimpleTree->new->parse_file(shift)->root or die" lib/PAGI/App/Router.pm && echo "POD OK"'`

Expected: POD OK

- [ ] **Step 5: Commit**

```bash
git add lib/PAGI/App/Router.pm lib/PAGI/Endpoint/Router.pm
git commit -m "docs: add POD for route_table() and HEAD body stripping behavior"
```

---

## Task 7: Final Validation

- [ ] **Step 1: Run the full test suite**

Run: `bash -c 'source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.40.0@default && RELEASE_TESTING=1 prove -l t/'`

Expected: All tests PASS, no regressions

- [ ] **Step 2: Review — verify HEAD stripping only activates for GET-matched HEAD requests**

Read `lib/PAGI/App/Router.pm` around the HEAD wrapping code and confirm:
- The condition checks `$method eq 'HEAD'` (original request method)
- The condition checks `$route->{method} ne 'HEAD'` (only wraps when matched route is NOT an explicit HEAD route)
- The wrapper correctly shallow-copies the event hashref (does not mutate the original)

- [ ] **Step 3: Review — verify route_table() does not expose internal state**

Read `lib/PAGI/App/Router.pm` `route_table()` and confirm:
- Params arrays are copies (`[@{$route->{names}}]`), not references to internal arrays
- The method does not expose the compiled regex, handler coderef, or internal `_handler`
- Constraint regexes are safe to expose (they're already compiled `qr//` objects)

- [ ] **Step 4: Review — check no dead code or redundancy introduced**

Scan modified files for:
- Unused variables
- Duplicate logic that could be extracted (the constraint-merging loop appears 3 times in `route_table()` — consider extracting if it bothers John)
- Any accidental changes to existing behavior

- [ ] **Step 5: Commit any review fixes if needed**
