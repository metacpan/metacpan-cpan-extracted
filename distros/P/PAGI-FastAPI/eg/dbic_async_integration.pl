#!/usr/bin/env perl

# Integrating DBIx::Class::Async with PAGI::FastAPI and JWT Authentication
#
# How to run:
#
# Start the server:
#
#       pagi-server dbic_async_integration.pl
#
# Obtain a test token in another terminal:
#
#       TOKEN=$(perl -MCrypt::JWT=encode_jwt -E 'say encode_jwt(payload=>{sub=>"alice",role=>"admin"}, key=>"demo-shared-secret", alg=>"HS256")')
#
# Try the routes using the token:
#
#       curl -X POST http://127.0.0.1:5000/users \
#            -H "Authorization: Bearer $TOKEN" \
#            -H "Content-Type: application/json" \
#            -d '{"name":"Grace Hopper","email":"grace@example.com"}'
#
#       curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:5000/users/1
#       curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:5000/dashboard
#       curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:5000/users/999

use v5.38;
use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use Future::AsyncAwait;
use Types::Standard qw(Str);
use Crypt::JWT qw(decode_jwt);

use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);
use PAGI::FastAPI::Security::HTTPBearer;

# In a real app, load this from config/environment, not a literal.
use constant JWT_SECRET => 'demo-shared-secret';

my $loop   = IO::Async::Loop->new;
my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;

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
});

$app->on_shutdown(async sub {
    DBIx::Class::Async->disconnect($schema) if $schema;
});

# Dependencies:
# 1. DB Schema Injector
my $get_schema = Depends(async sub ($c) { return $schema }, key => 'schema');

# 2. JWT Verification Dependency
my $auth_deps = [
    $bearer->depends(key => 'token'),
    Depends(async sub ($c) {
        my $claims = eval {
            decode_jwt(token => $c->stash->{token}, key => JWT_SECRET);
        };
        unless ($claims) {
            $c->status(401);
            $c->set_header('WWW-Authenticate' => 'Bearer');
            return { detail => 'Invalid or expired token' };
        }
        return $claims;
    }, key => 'claims'),
];

$app->post('/users',
    body         => { name => Str, email => Str },
    dependencies => [ @$auth_deps, $get_schema ],
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
    dependencies => [ @$auth_deps, $get_schema ],
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

$app->get('/dashboard',
    dependencies => [ @$auth_deps, $get_schema ],
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
