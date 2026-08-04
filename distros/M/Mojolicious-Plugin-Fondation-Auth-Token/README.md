# NAME

Mojolicious::Plugin::Fondation::Auth::Token - Personal Access Token authentication for Fondation

# VERSION

version 0.01

# SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Model::DBIx::Async',
            'Fondation::Auth',
            'Fondation::Auth::Token',
        ],
    };

    # Opt-in on API routes — combine with other conditions:
    $r->get('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_read')
      ->to('User#list');

    # Routes without fondation.bearer reject Bearer headers with 403.

# DESCRIPTION

This plugin adds Bearer token authentication to a Fondation application.
It provides the `fondation.bearer` route condition which must be
explicitly added to routes that should accept Bearer tokens.

A token is a random string whose SHA-256 hash is stored in the `api_tokens`
table. Tokens are created via CLI or fixtures — there is no HTTP endpoint
for token creation (no login/password in scripts).

# NAME

Mojolicious::Plugin::Fondation::Auth::Token - Personal Access Token for Fondation

# EXAMPLE — Protecting an API route

    $r->get('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_read')
      ->to('User#list');

The order of `requires` does not matter — Mojo evaluates all conditions.

## With `fondation.bearer` only (no Authorization plugin)

    $r->get('/api/data')
      ->requires('fondation.bearer')
      ->to(cb => sub ($c) { $c->render(json => { ok => true }) });

Any authenticated request (Bearer or cookie) is accepted. Invalid Bearer
tokens return 403. Unauthenticated requests return 401.

## With `fondation.bearer` + `fondation.perm`

    $r->get('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_read')
      ->to('User#list');

The request must be authenticated AND the user must hold the `user_read`
permission. Both conditions are checked independently.

# ROUTE CONDITION

## fondation.bearer

Opt-in condition. Add `->requires('fondation.bearer')` to any route
that should accept Bearer token authentication.

    $r->get('/api/data')
      ->requires('fondation.bearer')
      ->to('Data#list');

Behaviours:

    Authorization header        Token       Result
    ──────────────────────      ──────      ──────
    Bearer <valid>              valid       200 (user authenticated)
    (none, cookie session)      ignored     200 (if session valid)
    Bearer <invalid>            invalid     403 "Invalid bearer token"
    (none, no cookie)           ignored     401 "Authentication required"

Routes **without** `fondation.bearer` reject any Bearer header with 403.
In production mode the message is `"Access denied"`; in development mode
it includes `"Bearer token not allowed on this route"` for debugging.

The condition is compatible with `fondation.perm`, `fondation.group`,
and `fondation.authenticated`. Stack them as needed:

    $r->post('/api/user')
      ->requires('fondation.bearer')
      ->requires('fondation.perm' => 'user_create')
      ->to('User#create');

# DEPENDENCIES

- [Mojolicious::Plugin::Fondation::Auth](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth)
- [Mojolicious::Plugin::Fondation::Model::DBIx::Async](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AModel%3A%3ADBIx%3A%3AAsync)

# TABLE

    CREATE TABLE api_tokens (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL REFERENCES users(id),
        token_hash   TEXT NOT NULL UNIQUE,
        name         VARCHAR(255) NOT NULL,
        scopes       TEXT,
        last_used_at DATETIME,
        created_at   DATETIME NOT NULL
    );

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),
[Mojolicious::Plugin::Fondation::Auth](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
