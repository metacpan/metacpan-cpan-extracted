# NAME

Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap - Web UI extension for Fondation::Perm — injects perm checkboxes into group forms

# VERSION

version 0.01

# SYNOPSIS

    # myapp.conf
    'Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap' => {};

# DESCRIPTION

Injects permission checkboxes into the group add/edit modal via Fondation
zones (`group/add`). Provides `loadPerms()` and `collectPermAssignments()`
JavaScript functions consumed by `DatatableGroup.js`.

# ZONES

## group/add

- `html/group/add/perms.html.ep`

    Bootstrap 5 checkboxes listing all available permissions, hidden by default,
    shown by `loadPerms()`.

- `js/group/add/perms.js.ep`

    Two functions:

    - `loadPerms(group)`

        Fetches all permissions via `GET /api/perm`, renders checkboxes, and pre-checks
        those the group already has (from `group.perms`).

    - `collectPermAssignments()`

        Returns an array of checked permission IDs — called by `validateGroupForm()`
        in `DatatableGroup.js` before save.

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
