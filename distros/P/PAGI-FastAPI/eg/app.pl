#!/usr/bin/env perl

# Start the server
#
#   pagi-server app.pl
#
# In another terminal, try these web requests:
#
# 1. Public GET request with a query parameter
#
#   curl http://localhost:5000/items/123?verbose=1
#
# 2. Protected POST Request
#
# Send a POST request with the required JSON body and the valid authorisation.
#
#   curl -X POST http://localhost:5000/items \
#        -H "Authorization: Bearer secret123" \
#        -H "Content-Type: application/json" \
#        -d '{"name": "Camel Plushie", "price": 25}'
#
# 3. Fetch OpenAPI Docs
#
# You can also request the generated OpenAPI spec or Swagger UI endpoints:
#
#   curl http://localhost:5000/openapi.json
#

use v5.36;
use Future::AsyncAwait;
use Types::Standard qw(Int Str);
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new(
    title   => 'PAGI::FastAPI Demo Store',
    version => '1.0.0',
);

# 1. Enable CORS (delegates to PAGI::Middleware::CORS)
$app->add_cors(origins => ['*']);

# 2. Asynchronous Dependencies
#    NOTE: this hand-rolled 'eq' comparison against a hardcoded token is
#    for demo purposes only. For a real app, use PAGI::FastAPI::Security
#    (e.g. PAGI::FastAPI::Security::HTTPBearer) to get proper 401 +
#    WWW-Authenticate handling, then verify the extracted token yourself
#    (JWT signature check, DB/cache lookup, etc.), see that module's
#    docs for a full example with Crypt::JWT.
my $get_db = async sub ($c) {
    return { status => 'connected', pool_size => 5 };
};

my $get_current_user = async sub ($c) {
    my $token = $c->header('Authorization') // '';
    if ($token ne 'Bearer secret123') {
        $c->status(401);
        return { detail => 'Invalid credentials' };
    }
    return { user_id => 42, username => 'alice', role => 'admin' };
};

# 3. Public GET Route with Query Validation
$app->get('/items/{id}',
    query   => { verbose => Int },
    handler => async sub ($c) {
        return {
            id      => $c->path_param('id'),
            verbose => $c->query_param('verbose'),
            item    => 'Perl Mascot Plushie',
        };
    }
);

# 4. Protected POST Route with Body Validation & Dependency Injection
$app->post('/items',
    dependencies => {
        db   => $get_db,
        user => $get_current_user,
    },
    body => {
        name  => Str,
        price => Int,
    },
    handler => async sub ($c) {
        my $user = $c->stash->{user};
        $c->status(201); # 201 Created
        return {
            created_by => $user->{username},
            item       => $c->body,
        };
    }
);

warn "PAGI::FastAPI app initialised.\n";
warn "OpenAPI Spec available at /openapi.json\n";
warn "Swagger UI available at /docs\n";

$app->to_app;
