#!/usr/bin/env perl

# Integrating DBIx::Class::Async with PAGI::FastAPI
#
# The three things that make this work:
#
#   1. Create ONE DBIx::Class::Async::Schema for the app's whole lifetime,
#      in on_startup(), and disconnect it in on_shutdown().
#      PAGI::FastAPI's lifespan hooks map directly onto DBIx::Class::Async's
#      own "create once / disconnect once" guidance.
#
#   2. Hand the schema (or a resultset) to route handlers via Depends(),
#      the same DI mechanism you'd use for anything else. Handlers then
#      just `await` the Future-returning DBIx::Class::Async calls directly,
#      since both modules build on Future::AsyncAwait.
#
#   3. Whatever event loop actually drives your PAGI server MUST be the
#      same loop instance passed to
#      DBIx::Class::Async::Schema->connect(..., { loop => $loop }).
#
#      DBIx::Class::Async's worker pool talks to the main process over
#      pipes, and something has to be pumping that loop for the
#      resulting Futures to ever resolve, this is exactly the same
#      requirement documented in DBIx::Class::Async's own "EVENT LOOP
#      INTEGRATION" section for Mojolicious (IO::Async::Loop::Mojo).
#
# How to run:
#
# Start the server
#
#       pagi-server dbic_async_integration.pl
#
# In another terminal, try this:
#
#       curl -X POST http://127.0.0.1:5000/users -d '{"name":"Grace Hopper","email":"grace@example.com"}'
#       curl http://127.0.0.1:5000/users/1
#       curl http://127.0.0.1:5000/dashboard
#       curl http://127.0.0.1:5000/users/999
#
use v5.36;
use lib 'lib/';
use File::Temp;
use Future::AsyncAwait;
use Types::Standard qw(Str);
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);
use DBIx::Class::Async::Schema;
use IO::Async::Loop;

# In a real deployment this is whatever loop pagi-server hands you /
# constructs internally, reuse it rather than creating a second one.
my $loop = IO::Async::Loop->new;

my $app = PAGI::FastAPI->new(
    title   => 'Users API',
    version => '1.0.0',
);

my $schema;  # set in on_startup, torn down in on_shutdown
my ($fh, $db_file) = File::Temp::tempfile(SUFFIX => '.db', UNLINK => 1);

$app->on_startup(async sub {
    $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 1,
            schema_class => 'MyApp::Schema',
            loop         => $loop,
            cache_ttl    => 0,   # opt in per-query where staleness is fine
        }
    );
    await $schema->deploy;
    # NOTE: deploy() (like most DDL) broadcasts to every worker's own
    # connection. With workers > 1, workers after the first will report
    # harmless "table already exists" errors for a schema that already
    # exists on disk, expected, not a failure. Skip deploy() entirely
    # in production once the schema is already migrated.
});

$app->on_shutdown(async sub {
    DBIx::Class::Async->disconnect($schema) if $schema;
});

# Dependency: inject the schema into any route that needs DB access.
my $get_schema = async sub ($c) { return $schema };

$app->post('/users',
    body         => { name => Str, email => Str },
    dependencies => { schema => $get_schema },
    handler      => async sub ($c) {
        my $user = await $c->stash->{schema}
                           ->resultset('User')
                           ->create({ name  => $c->body('name'), email => $c->body('email') });
        $c->status(201);
        return {
            id    => $user->id,
            name  => $user->name,
            email => $user->email
        };
    }
);

$app->get('/users/{id}',
    dependencies => { schema => $get_schema },
    handler      => async sub ($c) {
        my $user = await $c->stash->{schema}
                           ->resultset('User')
                           ->find($c->path_param('id'));
        unless ($user) {
            $c->status(404);
            return { detail => 'User not found' };
        }
        return {
            id    => $user->id,
            name  => $user->name,
            email => $user->email
        };
    }
);

# Concurrent queries: fire several Future-returning DBIx::Class::Async
# calls together and await them as a batch instead of one at a time,
# so the worker pool actually runs them in parallel.
$app->get('/dashboard',
    dependencies => { schema => $get_schema },
    handler      => async sub ($c) {
        my $rs = $c->stash->{schema}->resultset('User');
        my ($total, $active) = await Future->needs_all(
            $rs->count,
            $rs->search({ active => 1 })->count,
        );
        return {
            total_users  => $total,
            active_users => $active
        };
    }
);

$app->to_app;
