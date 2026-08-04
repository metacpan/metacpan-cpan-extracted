#!/usr/bin/env perl
use v5.36;
use warnings;

use Future::AsyncAwait;
use Types::Standard qw(Int Str);
use PAGI::FastAPI;

my $app = PAGI::FastAPI->new(
    title   => 'PAGI::FastAPI Demo Store',
    version => '1.0.0',
);

# 1. Enable CORS
$app->add_cors(allow_origins => ['*']);

# 2. Asynchronous Dependencies
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

# Print startup banner to STDERR so it doesn't pollute stdout
warn "PAGI::FastAPI app initialized.\n";
warn "OpenAPI Spec available at /openapi.json\n";
warn "Swagger UI available at /docs\n";

# Return the PAGI handler coderef as the last statement!
my $pagi_app = $app->to_app;
$pagi_app;
