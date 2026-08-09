## PAGI::FastAPI

[![CPAN version](https://badge.fury.io/pl/PAGI-FastAPI.svg)](https://metacpan.org/pod/PAGI::FastAPI)

FastAPI-inspired asynchronous micro-framework for Perl built on the **PAGI** protocol with **Type::Tiny** validation, full **WebSocket** support, and automatic **OpenAPI 3.1** / **Swagger UI** documentation.

## SYNOPSIS

    use v5.36;
    use PAGI::FastAPI;
    use PAGI::FastAPI::Depends qw(Depends);
    use Types::Standard qw(Int Str);
    use Future::AsyncAwait;

    my $app = PAGI::FastAPI->new(
        title   => 'Store Microservice',
        version => '1.0.0',
    );

    # 1. Add CORS Support
    $app->add_cors(
        allow_origins => ['https://example.com'],
        allow_methods => ['GET', 'POST'],
    );

    # 2. Add Authentication Middleware Hook
    #    (hand-rolled here for illustration only, for ready-made schemes,
    #    including proper 401 challenges, see PAGI::FastAPI::Security)
    $app->add_middleware(async sub ($c, $next) {
        my $auth = $c->header('Authorization') // '';
        if ($auth ne 'Bearer secret_token') {
            $c->status(401);
            return { detail => 'Unauthorized' };
        }
        $c->stash->{user_id} = 42;
        return await $next->($c);
    });

    # 3. Register Lifespan Handlers
    $app->on_startup(async sub {
        warn "Connecting to database connection pool...\n";
    });

    $app->on_shutdown(async sub {
        warn "Closing database connections...\n";
    });

    # 4. Declare Async Dependencies
    my $get_db = async sub ($c) {
        return { db_name => 'production_db' };
    };

    my $get_current_user = async sub ($c) {
        my $token = $c->header('Authorization') // '';
        unless ($token eq 'Bearer secret_token') {
            $c->status(401);
            return { detail => 'Invalid credentials' };
        }
        return { user_id => 42, role => 'admin' };
    };

    # 5. Route using HashRef Dependency Map
    $app->get('/profile',
        dependencies => {
            db   => $get_db,
            user => $get_current_user,
        },
        handler => async sub ($c) {
            my $db   = $c->stash->{db};
            my $user = $c->stash->{user};
            return { user => $user, db => $db->{db_name} };
        }
    );

    # 6. Route using Depends() Array Spec
    $app->get('/admin',
        dependencies => [
            Depends($get_current_user, key => 'user'),
            async sub ($c) {
                if ($c->stash->{user}{role} ne 'admin') {
                    $c->status(403);
                    return { detail => 'Admin privileges required' };
                }
            }
        ],
        handler => async sub ($c) {
            return { message => 'Welcome to admin panel' };
        }
    );

    # 7. Non-blocking GET route with path parameter & query validation
    $app->get('/items/{id}',
        query   => { limit => Int },
        handler => async sub ($c) {
            return {
                item_id => $c->param('id'),
                limit   => $c->param('limit'),
                status  => 'active',
            };
        }
    );

    # 8. Non-blocking POST route with JSON payload validation
    $app->post('/items',
        body    => { name => Str, price => Int },
        handler => async sub ($c) {
            return {
                created => 1,
                name    => $c->body('name'),
                price   => $c->body('price'),
            };
        }
    );

    my $pagi_app = $app->to_app;

    # 9. Non-blocking WebSocket Endpoint
    # $ws is a PAGI::WebSocket (from PAGI::Tools), so on_close/each_json/
    # on_close/each_json/try_send_json/keepalive and more are all built in.
    $app->websocket('/ws', handler => async sub ($ws, $deps) {
        await $ws->accept;

        $ws->on_close(async sub {
            my ($code, $reason) = @_;
            # runs on every disconnect path, not just a clean loop exit
        });

        await $ws->each_json(async sub {
            my ($data) = @_;
            await $ws->send_json({ echo => $data });
        });
    });

    # 10. Authentication via the companion PAGI::FastAPI::Security distribution
    #     (extraction only, you supply the verification logic)
    #
    #     use PAGI::FastAPI::Security::HTTPBearer;
    #     my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;
    #     $app->get('/secure',
    #         dependencies => [ $bearer->depends(key => 'token') ],
    #         handler      => async sub ($c) {
    #             return { token => $c->stash->{token} };
    #         }
    #     );
    #
    #     See PAGI::FastAPI::Security for HTTP Basic, API Key
    #     (header/query/cookie), and OAuth2 password-bearer schemes.

## AUTHENTICATION AND SECURITY

`PAGI::FastAPI` has no authentication built in by design, auth needs vary too
much between applications to standardise.

Instead you get two general-purpose building blocks:

* **Middleware** (`add_middleware`), runs for every request.
* **Dependencies** (the `dependencies` route option), runs per-route.

A dependency signals failure by calling `$c->status($code)` with a code >= 400 and returning a body HashRef (not by `die`ing, dependency execution isn't wrapped in `eval`).

For ready-made schemes instead of hand-rolling this every time, see the companion distribution **[PAGI::FastAPI::Security](https://metacpan.org/pod/PAGI::FastAPI::Security)**:

* `PAGI::FastAPI::Security::HTTPBearer`: `Authorization: Bearer <token>`, with a `401` + `WWW-Authenticate: Bearer` challenge.
* `PAGI::FastAPI::Security::HTTPBasic`: `Authorization: Basic <base64>`, with a `401` + `WWW-Authenticate: Basic realm="..."` challenge.
* `PAGI::FastAPI::Security::APIKey`: header, query string, or cookie, with a `403` on failure.
* `PAGI::FastAPI::Security::OAuth2::PasswordBearer`: OAuth2 bearer-token extraction plus `token_url`/`scopes` metadata.

Each scheme only *extracts* the credential, verification (JWT signature checking, password hashing, database/cache lookups) is left to you, so you aren't locked into one library. All schemes accept `auto_error => 0` for optional-auth routes. See `PAGI::FastAPI::Security`'s own docs for a full JWT-verification example.

## LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

http://www.perlfoundation.org/artistic_license_2_0
