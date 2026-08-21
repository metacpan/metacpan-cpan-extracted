## PAGI::FastAPI

[![CPAN version](https://badge.fury.io/pl/PAGI-FastAPI.svg)](https://metacpan.org/pod/PAGI::FastAPI)

FastAPI-inspired asynchronous micro-framework for Perl built on the **PAGI** protocol with **Type::Tiny** validation, full **WebSocket** support, and automatic **OpenAPI 3.1** / **Swagger UI** documentation.

## SYNOPSIS

    use v5.38;
    use PAGI::FastAPI;
    use PAGI::FastAPI::Depends qw(Depends);
    use Types::Standard qw(Int Str);
    use Future::AsyncAwait;

    my $app = PAGI::FastAPI->new(
        title   => 'Store Microservice',
        version => '1.0.0',
    );

    # 1. Add CORS Support (delegates to PAGI::Middleware::CORS from PAGI::Tools)
    $app->add_cors(
        origins => ['https://example.com'],
        methods => ['GET', 'POST'],
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

    # 9. Typed path parameters, response filtering, redirects, files, and
    #    structured error handling
    use PAGI::FastAPI::TypedPath qw(TypedPath);
    use PAGI::FastAPI::ResponseModel qw(with_response_model);
    use PAGI::FastAPI::Response::Redirect qw(redirect_to);
    use PAGI::FastAPI::Response::File qw(file_response);
    use Types::Standard qw(Int Str);

    $app->get('/products/{item_id}',
        dependencies => [ Depends(TypedPath('item_id', Int), key => 'item_id') ],
        handler      => with_response_model(
            { id => Int, name => Str },   # extra fields your handler returns
            async sub ($c) {              # (e.g. an ORM row) are filtered out
                return { id => $c->stash->{item_id}, name => 'Widget', internal_note => 'hidden' };
            }
        ),
    );

    $app->get('/old-url',    handler => async sub ($c) { return redirect_to('/new-url') });
    $app->get('/report.pdf', handler => async sub ($c) { return file_response('/var/reports/latest.pdf') });

    my $pagi_app = $app->to_app;

    # 10. Non-blocking WebSocket Endpoint
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

    # 11. Authentication via the companion PAGI::FastAPI::Security distribution
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

## RESPONSE HELPERS, VALIDATION & ERROR HANDLING

Six small modules, each built on an existing `PAGI::FastAPI` extension point
(subclassing `PAGI::FastAPI::Response`, `Depends()`, or `add_middleware`) —
no core routing or dispatch behavior changed to add them.

* **`PAGI::FastAPI::TypedPath`** — `TypedPath($param_name, $type)` validates
  (and, for a coercing `Type::Tiny` type, converts) a path parameter,
  through the same `Depends()` mechanism `query`/`body` validation already
  uses internally. An invalid path segment gets a `422` automatically,
  before your handler runs.

* **`PAGI::FastAPI::ResponseModel`** — `with_response_model($schema, $handler)`
  wraps a handler so its return value is checked against a declared
  `Type::Tiny` schema. Pass a HashRef of `field => Type` and it also
  *filters* the output to just those fields — the common case of an ORM row
  carrying extra internal columns (a password hash, say) doesn't leak to
  the client. A mismatch is treated as a `500` (a server bug), not a client
  error, mirroring Python FastAPI's `ResponseValidationError`.

* **`PAGI::FastAPI::Middleware::ExceptionHandler`** — registers a handler
  per exception class, dispatched by `blessed($err)`/`isa()`, with a
  configurable fallback. For the case where a real Perl exception (`die`)
  escapes a handler or dependency, rather than the `$c->status(...)`-and-
  return convention described above.

* **`PAGI::FastAPI::Response::Redirect`** — `redirect_to($location, %opts)`
  (defaults to `302`) or construct directly for `301`/`303`/`307`/`308`.

* **`PAGI::FastAPI::Response::File`** — `file_response($path, %opts)` reads
  a file from disk and returns it with a guessed content-type and
  `Content-Disposition`. Reads the whole file into memory — fine for
  templates, generated reports, small-to-moderate assets; not intended for
  very large files or video.

* **`PAGI::FastAPI::Cookies`** — `parse_cookies($raw_header)` /
  `cookie($c, $name)` parse the request `Cookie` header. Setting response
  cookies needs no extra module: `$c->add_header('set-cookie' => '...')`
  already works today.

```perl
use PAGI::FastAPI::TypedPath qw(TypedPath);
use PAGI::FastAPI::ResponseModel qw(with_response_model);
use PAGI::FastAPI::Middleware::ExceptionHandler;
use PAGI::FastAPI::Response::Redirect qw(redirect_to);
use PAGI::FastAPI::Response::File qw(file_response);
use PAGI::FastAPI::Cookies qw(cookie);
use Types::Standard qw(Int Str);

# Typed path param + filtered response shape:
$app->get('/products/{item_id}',
    dependencies => [ Depends(TypedPath('item_id', Int), key => 'item_id') ],
    handler      => with_response_model(
        { id => Int, name => Str },
        async sub ($c) { return My::DB->find_product($c->stash->{item_id}) },
    ),
);

# Typed exception -> handler dispatch:
my $exc_handler = PAGI::FastAPI::Middleware::ExceptionHandler->new(
    handlers => {
        'My::Errors::NotFound' => async sub ($err, $c) {
            $c->status(404);
            return { detail => $err->message };
        },
    },
    default_handler => async sub ($err, $c) {
        $c->status(500);
        return { detail => 'Internal Server Error' };
    },
);
$app->add_middleware(async sub ($c, $next) { return await $exc_handler->handle($c, $next) });

# Redirects, file downloads, cookies:
$app->get('/old-url', handler => async sub ($c) { return redirect_to('/new-url') });
$app->get('/report.pdf', handler => async sub ($c) { return file_response('/var/reports/latest.pdf') });
$app->get('/whoami', handler => async sub ($c) { return { session_id => cookie($c, 'session_id') } });
```

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
