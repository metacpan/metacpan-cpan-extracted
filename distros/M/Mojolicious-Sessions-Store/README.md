# NAME

Mojolicious::Sessions::Store - another server-side session storage for Mojolicious

# VERSION

version 0.01

# SYNOPSIS

    use Mojolicious::Lite;
    use Mojolicious::Sessions::Store;
    use Mojolicious::Sessions::Store::Backend::File;

    app->sessions(
        Mojolicious::Sessions::Store->new(
            backend => Mojolicious::Sessions::Store::Backend::File->new(
                store_dir => app->home->child('data/sessions'),
            ),
            cookie_name        => 'myapp',
            default_expiration => 3600,
        )
    );

    get '/' => sub ($c) {
        $c->session(user_id => 42);
        $c->render(text => 'Session stored server-side');
    };

    app->start;

# DESCRIPTION

`Mojolicious::Sessions::Store` replaces the default signed-cookie session
storage with server-side storage. A signed cookie containing only a
session ID is sent to the client; the actual session data lives in a
backend (filesystem, Redis, database, etc.).

The [Mojolicious::Controller](https://metacpan.org/pod/Mojolicious%3A%3AController) `session` helper works exactly as before
— the change is transparent to application code.

# NAME

Mojolicious::Sessions::Store - Server-side session storage for Mojolicious

# ATTRIBUTES

`Mojolicious::Sessions::Store` inherits all attributes from
[Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious%3A%3ASessions) and adds the following.

## backend

    my $backend = $store->backend;
    $store      = $store->backend($backend);

The backend instance that provides `load`, `save`, and `delete` methods.
Required. See [Mojolicious::Sessions::Store::Backend](https://metacpan.org/pod/Mojolicious%3A%3ASessions%3A%3AStore%3A%3ABackend) for the interface.

# INHERITED ATTRIBUTES

All attributes from [Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious%3A%3ASessions) are supported, including:

- cookie\_domain
- cookie\_name
- cookie\_path
- default\_expiration
- samesite
- secure

# HOW IT WORKS

On `load()`:

- 1. Read the signed cookie to extract the session ID.
- 2. Call `$backend->load($session_id)` to retrieve session data.
- 3. Check expiration (`expires` field).
- 4. Store the hashref in `$c->stash('mojo.session')`.

On `store()`:

- 1. Read session data from `$c->stash('mojo.session')`.
- 2. Generate a new session ID if this is the first write.
- 3. Call `$store->save($session_id, $data)`.
- 4. Set a signed cookie containing only the session ID.

# BACKENDS

- [Mojolicious::Sessions::Store::Backend::File](https://metacpan.org/pod/Mojolicious%3A%3ASessions%3A%3AStore%3A%3ABackend%3A%3AFile) — JSON files on disk

Custom backends must implement `load`, `save`, and `delete` as
described in [Mojolicious::Sessions::Store::Backend](https://metacpan.org/pod/Mojolicious%3A%3ASessions%3A%3AStore%3A%3ABackend).

# SEE ALSO

[Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious%3A%3ASessions), [Mojolicious::Sessions::Store::Backend](https://metacpan.org/pod/Mojolicious%3A%3ASessions%3A%3AStore%3A%3ABackend),
[Mojolicious::Sessions::Store::Backend::File](https://metacpan.org/pod/Mojolicious%3A%3ASessions%3A%3AStore%3A%3ABackend%3A%3AFile)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
