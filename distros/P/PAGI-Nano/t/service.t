use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Scalar::Util qw(refaddr);
use PAGI::Test::Client;
use PAGI::Nano;

# The service registry: a tiny three-scope keyword (service NAME => BUILDER)
# giving Nano apps app-scoped singletons, per-request makers, and always-new
# factories, discriminated by what the builder returns. See
# docs/superpowers/specs/2026-07-13-service-registry-design.md for the design.

subtest 'app-scoped: builders run once, before user startup, in declaration order' => sub {
    my @build_log;
    my $app = app {
        service first => sub {
            push @build_log, 'first';
            return { name => 'first' };
        };
        service second => sub {
            push @build_log, 'second';
            return { name => 'second' };
        };
        startup async sub { push @build_log, 'user-startup' };

        get '/first' => sub { my ($c) = @_; $c->service('first') };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    is \@build_log, ['first', 'second', 'user-startup'],
        'both builders ran once, in declaration order, before the user startup hook';

    $client->get('/first');   # a request must not rebuild anything
    is \@build_log, ['first', 'second', 'user-startup'],
        'a request does not re-run any builder';

    $client->stop;
};

subtest 'app-scoped: every request sees the same object' => sub {
    my $app = app {
        service thing => sub { return { built_at => rand() } };
        get '/addr' => sub { my ($c) = @_; { addr => refaddr($c->service('thing')) } };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    my $addr1 = $client->get('/addr')->json->{addr};
    my $addr2 = $client->get('/addr')->json->{addr};
    is $addr1, $addr2, 'same refaddr across two requests: one shared singleton';

    $client->stop;
};

subtest 'declaration order + composition: a later service gets an earlier one via $app->service' => sub {
    my $app = app {
        service first  => sub { return { name => 'first' } };
        service second => sub {
            my ($app) = @_;
            return { name => 'second', first => $app->service('first') };
        };
        get '/second' => sub { my ($c) = @_; $c->service('second') };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    is $client->get('/second')->json,
        { name => 'second', first => { name => 'first' } },
        'second builder composed with the already-built first via $app->service';

    $client->stop;
};

subtest 'app-scoped: a builder returning undef is a legitimate built value, not "unbuilt"' => sub {
    # ServiceRegistry::service checks `exists $self->{built}{$name}`, not
    # definedness or truthiness -- a builder is free to return undef, and that
    # must be stored and handed back as-is, never mistaken for "never built".
    my $app = app {
        service maybe_absent => sub { return undef };
        get '/x' => sub {
            my ($c) = @_;
            { is_undef => (defined($c->service('maybe_absent')) ? 0 : 1) };
        };
    };

    my $client = PAGI::Test::Client->new(
        app => $app, lifespan => 1, raise_app_exceptions => 1,
    );
    $client->start;

    my $res = $client->get('/x');
    is $res->status, 200, 'no croak: an app-scoped undef value is legitimate, not "not yet built"';
    is $res->json->{is_undef}, 1, 'the value really is undef, not some other falsy placeholder';

    $client->stop;
};

subtest 'test seam: resolve an app-scoped service after startup, without a request' => sub {
    # The registry the startup hook builds is retained by closure on the
    # assembled app coderef (it is the same object the request-time injector and
    # the probe wrapper close over). resolve_service reaches it through a probe
    # token, so a test can read an app-scoped service after lifespan startup
    # without driving a request handler.
    my $app = app {
        service schema => sub { 'THE-SCHEMA' };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    is PAGI::Nano::resolve_service($app, 'schema'), 'THE-SCHEMA',
        'resolve_service returns the built app-scoped value with no request issued';

    $client->stop;
};

subtest 'test seam: resolve_service returns a per-request maker raw, unresolved' => sub {
    # resolve_service has no request context, so a service whose builder
    # returns a plain coderef (a per-request maker) can't be resolved to a
    # per-request value here. The documented contract: resolve_service hands
    # back that raw coderef unchanged, by reference identity -- it must not
    # be routed through ServiceRegistry::_resolve, which would invoke the
    # maker and hand back its result instead of the maker itself.
    my $maker = sub { return { built => 'per-request' } };
    my $app = app {
        service widget => sub { return $maker };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    my $resolved = PAGI::Nano::resolve_service($app, 'widget');
    is refaddr($resolved), refaddr($maker),
        'resolve_service returns the exact maker coderef by reference, not a per-request-resolved value';

    $client->stop;
};

subtest 'test seam: resolving an unknown service croaks, naming it' => sub {
    my $app = app {
        service known => sub { 1 };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    my $err = dies { PAGI::Nano::resolve_service($app, 'nope') };
    like $err, qr/nope/, 'the croak names the unknown service (delegates to the registry)';

    $client->stop;
};

subtest 'test seam: resolving on an app that declared no services croaks' => sub {
    my $app = app {
        get '/x' => sub { 'ok' };
    };

    my $err = dies { PAGI::Nano::resolve_service($app, 'anything') };
    like $err, qr/no services/i, 'the croak explains the app declares no services';
};

subtest 'per-request: unblessed coderef => per-request maker, memoized in-request, fresh per request' => sub {
    my @maker_ctx;
    my $app = app {
        service widget => sub {
            return sub {
                my ($ctx) = @_;
                push @maker_ctx, $ctx;
                return { seq => scalar(@maker_ctx) };
            };
        };
        get '/addr-twice' => sub {
            my ($c) = @_;
            my $a = $c->service('widget');
            my $b = $c->service('widget');
            { same_ref => (refaddr($a) == refaddr($b) ? 1 : 0), seq => $a->{seq} };
        };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    my $r1 = $client->get('/addr-twice')->json;
    is $r1->{same_ref}, 1, 'two calls within one request return the same memoized object';

    my $r2 = $client->get('/addr-twice')->json;
    isnt $r1->{seq}, $r2->{seq}, 'a second request gets a freshly-built object (fresh maker invocation)';

    is scalar(@maker_ctx), 2, 'the maker ran once per request (not once per call)';
    ok((Scalar::Util::blessed($maker_ctx[0]) && $maker_ctx[0]->isa('PAGI::Nano::Context::HTTP')),
        'the maker received the request context as its argument');

    $client->stop;
};

subtest 'per-request: undef maker result is still memoized by existence' => sub {
    my $maker_calls = 0;
    my $app = app {
        service maybe => sub {
            return sub {
                ++$maker_calls;
                return undef;
            };
        };
        get '/twice' => sub {
            my ($c) = @_;
            my $first  = $c->service('maybe');
            my $second = $c->service('maybe');
            return {
                both_undef => (!defined($first) && !defined($second) ? 1 : 0),
                calls      => $maker_calls,
            };
        };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;
    is $client->get('/twice')->json,
        { both_undef => 1, calls => 1 },
        'two accesses in one request invoke an undef-returning maker once';
    is $client->get('/twice')->json,
        { both_undef => 1, calls => 2 },
        'the next request has a fresh cache and invokes it once';
    $client->stop;
};

subtest 'per-request: a maker whose return value is itself a coderef is returned as-is, memoized' => sub {
    # Scope discrimination applies only to the BUILDER's return value (deciding
    # "this is a per-request maker"); the maker's own result is never
    # re-examined for a second level of discrimination, even if it happens to
    # be a coderef too.
    my $inner_cb = sub { 'inner result' };
    my @maker_calls;
    my $app = app {
        service cb_holder => sub {
            return sub {
                my ($ctx) = @_;
                push @maker_calls, $ctx;
                return $inner_cb;
            };
        };
        get '/twice' => sub {
            my ($c) = @_;
            my $a = $c->service('cb_holder');
            my $b = $c->service('cb_holder');
            {
                a_is_cb  => (ref($a) eq 'CODE' ? 1 : 0),
                same_cb  => (refaddr($a) == refaddr($b) ? 1 : 0),
                a_result => $a->(),
            };
        };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    my $r = $client->get('/twice')->json;
    is $r->{a_is_cb}, 1, 'the memoized value is the coderef itself, not invoked a second level';
    is $r->{same_cb}, 1, 'both calls return the same coderef (memoized, not rebuilt)';
    is $r->{a_result}, 'inner result', 'the returned coderef still behaves like the original';
    is scalar(@maker_calls), 1, 'the maker itself ran exactly once for two calls in one request';

    $client->stop;
};

subtest 'factory: always-new maker, fresh on every call, receives the context' => sub {
    my @maker_ctx;
    my $app = app {
        service stamp => sub {
            return factory sub {
                my ($ctx) = @_;
                push @maker_ctx, $ctx;
                return { seq => scalar(@maker_ctx) };
            };
        };
        get '/twice' => sub {
            my ($c) = @_;
            my $a = $c->service('stamp');
            my $b = $c->service('stamp');
            { a => $a->{seq}, b => $b->{seq} };
        };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    my $r = $client->get('/twice')->json;
    isnt $r->{a}, $r->{b}, 'two calls in the same request return different objects';
    is scalar(@maker_ctx), 2, 'the maker ran on every call, not memoized';
    ok((Scalar::Util::blessed($maker_ctx[0]) && $maker_ctx[0]->isa('PAGI::Nano::Context::HTTP')),
        'the maker received the request context as its argument');

    $client->stop;
};

subtest '$c->service resolves from WebSocket and SSE handlers too, not just HTTP' => sub {
    my $app = app {
        service greeting => sub { return { hello => 'world' } };

        websocket '/ws' => async sub {
            my ($c) = @_;
            my $ws = $c->websocket;
            await $ws->accept;
            await $ws->send_text($c->service('greeting')->{hello});
        };

        sse '/sse' => async sub {
            my ($c) = @_;
            my $s = $c->sse;
            await $s->send($c->service('greeting')->{hello});
            await $s->close;
        };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    $client->websocket('/ws', sub {
        my ($ws) = @_;
        is $ws->receive_text, 'world', '$c->service resolves from a WebSocket handler';
    });

    $client->sse('/sse', sub {
        my ($sse) = @_;
        is $sse->receive_event->{data}, 'world', '$c->service resolves from an SSE handler';
    });

    $client->stop;
};

# Mounting: "the outermost app owns lifecycle" (documented for startup/shutdown
# already) applies to services too. A mounted child with no services of its
# own shares the parent's registry (nothing overwrites what the parent injected
# onto the scope); a mounted child that DOES declare services is refused at
# mount time, since its own lifespan startup would never run.

subtest 'a mounted child with no services of its own shares the parent registry' => sub {
    my @maker_calls;
    my $child = app {
        get '/child-app-scoped' => sub { my ($c) = @_; $c->service('shared_value') };
        get '/child-per-request' => sub {
            my ($c) = @_;
            my $a = $c->service('shared_maker');
            my $b = $c->service('shared_maker');
            { same => (refaddr($a) == refaddr($b) ? 1 : 0) };
        };
    };

    my $app = app {
        service shared_value => sub { return { from => 'parent' } };
        service shared_maker => sub {
            return sub {
                my ($ctx) = @_;
                push @maker_calls, $ctx;
                return {};
            };
        };
        mount '/child' => $child;
        get '/parent-app-scoped' => sub { my ($c) = @_; $c->service('shared_value') };
    };

    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;

    is $client->get('/child/child-app-scoped')->json, { from => 'parent' },
        'a request routed into the mounted child sees the parent app-scoped service';

    my $r = $client->get('/child/child-per-request')->json;
    is $r->{same}, 1,
        'the parent per-request maker is memoized within one request, even inside the mounted child';

    is $client->get('/parent-app-scoped')->json, { from => 'parent' },
        'parent-owned routes still see the same service too';

    $client->stop;
};

subtest 'error: mounting a Nano app that declares its own services croaks at mount time' => sub {
    my $child = app {
        service oops => sub { return 1 };
    };

    my $err = dies {
        app {
            mount '/child' => $child;
        };
    };
    like $err, qr/service/i, 'croaks mentioning services';
    like $err, qr/lifecycle/i, 'croaks explaining the outermost app owns lifecycle';
};

subtest 'error: duplicate service declaration' => sub {
    my $err = dies {
        app {
            service dup => sub { 1 };
            service dup => sub { 2 };
        };
    };
    like $err, qr/dup/, 'croaks naming the duplicate service';
};

subtest 'error: service() called outside an app { } block' => sub {
    my $err = dies { service('orphan', sub { 1 }) };
    like $err, qr/orphan/, 'croaks naming the service';
    like $err, qr/app \{/, 'croaks mentioning the app { } block';
};

subtest 'error: $c->service(unknown) at request time' => sub {
    my $app = app {
        service known => sub { 1 };
        get '/x' => sub { my ($c) = @_; $c->service('nope') };
    };
    my $client = PAGI::Test::Client->new(
        app => $app, lifespan => 1, raise_app_exceptions => 1,
    );
    $client->start;

    my $err = dies { $client->get('/x') };
    like $err, qr/nope/, 'croaks naming the unknown service';

    $client->stop;
};

subtest 'error: $c->service used in an app that declared no services at all' => sub {
    my $app = app {
        get '/x' => sub { my ($c) = @_; $c->service('anything') };
    };
    my $client = PAGI::Test::Client->new(app => $app, raise_app_exceptions => 1);

    my $err = dies { $client->get('/x') };
    like $err, qr/service/i, 'croaks (no registry was ever injected onto the scope)';
};

subtest 'error: factory() called with a non-coderef' => sub {
    my $err = dies { factory('not a coderef') };
    like $err, qr/coderef/i, 'croaks explaining a coderef is required';
};

subtest 'error: a forward reference to a not-yet-built service fails lifespan startup' => sub {
    # $app->service('late') from within 'early's builder, before 'late' has run:
    # services build eagerly in declaration order, so this must fail the whole
    # worker at boot (via the lifespan protocol), not at first request.
    #
    # PAGI::Test::Client->start doesn't surface lifespan.startup.failed (it just
    # busy-waits for .complete and gives up after its own deadline), so drive the
    # lifespan protocol by hand here to observe the failure event directly.
    my $app = app {
        service early => sub { my ($app) = @_; return $app->service('late') };
        service late  => sub { return 'ok' };
    };

    my @events;
    my $scope = {
        type => 'lifespan',
        pagi => { version => '0.2', spec_version => '0.2' },
        state => {},
    };
    my $receive_calls = 0;
    my $receive = async sub {
        $receive_calls++;
        return { type => 'lifespan.startup' } if $receive_calls == 1;
        die 'test receive() called more than once; unexpected for a failed startup';
    };
    my $send = async sub { my ($event) = @_; push @events, $event };

    $app->($scope, $receive, $send)->get;

    my ($failed) = grep { ($_->{type} // '') eq 'lifespan.startup.failed' } @events;
    ok $failed, 'lifespan.startup.failed was sent';
    like $failed->{message}, qr/late/, 'the failure names the forward-referenced service';
    like $failed->{message}, qr/declaration order/i,
        'the failure explains services build in declaration order';

    ok !(grep { ($_->{type} // '') eq 'lifespan.startup.complete' } @events),
        'lifespan.startup.complete was never sent';
};

subtest 'error: a builder returning a Future croaks at lifespan startup, naming the service' => sub {
    # Builders are synchronous -- they run at lifespan startup. A builder
    # written as `async sub {...}` returns an unresolved Future; storing that
    # verbatim as the "service" would fail cryptically later at $c->service
    # time. Fail fast and loud at build time instead. As with the forward-ref
    # case above, drive the lifespan protocol by hand to observe the failure
    # event directly (PAGI::Test::Client->start does not surface it).
    my $app = app {
        service async_oops => async sub { my ($app) = @_; return 42 };
    };

    my @events;
    my $scope = {
        type => 'lifespan',
        pagi => { version => '0.2', spec_version => '0.2' },
        state => {},
    };
    my $receive_calls = 0;
    my $receive = async sub {
        $receive_calls++;
        return { type => 'lifespan.startup' } if $receive_calls == 1;
        die 'test receive() called more than once; unexpected for a failed startup';
    };
    my $send = async sub { my ($event) = @_; push @events, $event };

    $app->($scope, $receive, $send)->get;

    my ($failed) = grep { ($_->{type} // '') eq 'lifespan.startup.failed' } @events;
    ok $failed, 'lifespan.startup.failed was sent';
    like $failed->{message}, qr/async_oops/, 'the failure names the offending service';
    like $failed->{message}, qr/Future/, 'the failure explains a Future was returned';

    ok !(grep { ($_->{type} // '') eq 'lifespan.startup.complete' } @events),
        'lifespan.startup.complete was never sent';
};

done_testing;
