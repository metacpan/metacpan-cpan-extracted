# NAME

Mojolicious::Plugin::Fondation::Authorization - Authorization plugin — grants loading and check\_perm/check\_group helpers

# VERSION

version 0.01

# SYNOPSIS

    # In myapp.conf:
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Authorization',
        ],
    };

# DESCRIPTION

Loads user grants (permissions and groups) from the database and provides
`check_perm` and `check_group` helpers for synchronous access control.

Grants are fetched asynchronously via `$c-`model> once per session on
first request via an `around_dispatch` hook and cached in
`$c->session('grants')`.

Subsequent requests use the cached values — no database queries.

Request flow:

    is_user_authenticated?
      NO  → session(grants => undef) + continue  (cleanup)
      YES → grants in session?
               YES → continue  (fast path)
               NO  → load grants async + continue

The grant chain is:

    user → user_group → group → group_perm → perm

There is no direct user-to-permission table. All permissions are inherited
through group membership.

# NAME

Mojolicious::Plugin::Fondation::Authorization - Permission and group authorization for Fondation

# DEPENDENCIES

- [Mojolicious::Plugin::Fondation::Auth](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth)

    Provides `is_user_authenticated` and `current_user` helpers.

- [Mojolicious::Plugin::Fondation::Group](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AGroup)

    Provides `user_group` and `group` DBIx sources + models.

- [Mojolicious::Plugin::Fondation::Perm](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3APerm)

    Provides `group_perm` and `perm` DBIx sources + models.

# HELPERS

## check\_perm

    if ($c->check_perm('user_create')) { ... }

## check\_group

    if ($c->check_group('admins')) { ... }

# SEE ALSO

[Mojolicious::Plugin::Fondation](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation),
[Mojolicious::Plugin::Fondation::Auth](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAuth)

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
