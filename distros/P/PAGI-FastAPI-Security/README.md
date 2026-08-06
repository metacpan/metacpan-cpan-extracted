# PAGI::FastAPI::Security

Authentication scheme building blocks for [PAGI::FastAPI](https://metacpan.org/pod/PAGI::FastAPI),
modelled on Python FastAPI's `fastapi.security` module.

## What this is

Four small classes that extract credentials from a request in a standard
way, and set a spec-appropriate HTTP error response when they're missing
or malformed:

| Class | Extracts | Failure |
|---|---|---|
| `PAGI::FastAPI::Security::HTTPBearer` | `Authorization: Bearer <token>` | 401 + `WWW-Authenticate: Bearer` |
| `PAGI::FastAPI::Security::HTTPBasic` | `Authorization: Basic <base64>` | 401 + `WWW-Authenticate: Basic realm="..."` |
| `PAGI::FastAPI::Security::APIKey` | header / query / cookie | 403 |
| `PAGI::FastAPI::Security::OAuth2::PasswordBearer` | `Authorization: Bearer <token>` + token_url/scopes metadata | 401 + `WWW-Authenticate: Bearer` |

## What this is *not*

None of this verifies any credentials. There is no JWT signature verification,
there is no password hash matching, there is no access to databases, and there
is no OAuth2 token endpoint. This is by design, as verification works differently
for different applications, so you are free to come up with your own approach,
just like in `fastapi.security`.

```perl
use PAGI::FastAPI::Security::HTTPBearer;
use PAGI::FastAPI::Depends qw(Depends);

my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;

$app->get('/items',
    dependencies => [
        $bearer->depends(key => 'token'),
        Depends(async sub ($c) {
            my $claims = eval { verify_jwt($c->stash->{token}) };
            unless ($claims) {
                $c->status(401);
                return { detail => 'Invalid or expired token' };
            }
            return $claims;
        }, key => 'claims'),
    ],
    handler => async sub ($c) {
        return { user_id => $c->stash->{claims}{sub} };
    },
);
```

## Install

```bash
cpanm PAGI::FastAPI::Security
```

## Quick start

```perl
use PAGI::FastAPI;
use PAGI::FastAPI::Security::HTTPBearer;

my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;
my $app = PAGI::FastAPI->new(title => 'My API');

$app->get('/items',
    dependencies => [ $bearer->depends(key => 'token') ],
    handler      => async sub ($c) {
        return { items => [], authenticated_with => $c->stash->{token} };
    },
);

$app->to_app;
```

Run it with `pagi-server app.pl`.

## Optional auth

Every scheme accepts `auto_error => 0`, which resolves to `undef` instead
of short-circuiting with an error, so you can implement routes that
behave differently for authenticated vs. anonymous requests:

```perl
my $bearer = PAGI::FastAPI::Security::HTTPBearer->new(auto_error => 0);
```

## SEE ALSO

* `eg/jwt_protected_app.pl`  -  a fuller example chaining `HTTPBearer`
  with real JWT verification via `Crypt::JWT`.
* [PAGI::FastAPI](https://metacpan.org/pod/PAGI::FastAPI)

## LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

http://www.perlfoundation.org/artistic_license_2_0
