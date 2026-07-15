# NAME

Mojolicious::Plugin::Fondation::User::UI::Bootstrap - Web UI for Fondation::User — templates, assets, and i18n

# VERSION

version 0.02

# SYNOPSIS

    # myapp.conf
    'Fondation::User::UI::Bootstrap' => {};

# DESCRIPTION

Fondation::User::UI::Bootstrap provides the web interface for user management
in Fondation applications. It includes templates, assets, translations, and
routes for listing, creating, editing, and deleting users.

The plugin registers a single route `GET /users` which requires the
`fondation.perm => user_list` condition. All other user CRUD operations
are handled by the generic REST actions provided by [Fondation::User](https://metacpan.org/pod/Fondation%3A%3AUser) via
[Mojolicious::Plugin::Fondation::Action::REST](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAction%3A%3AREST).

## Dependencies

This plugin requires [Fondation::User](https://metacpan.org/pod/Fondation%3A%3AUser) and [Fondation::Layout::Bootstrap](https://metacpan.org/pod/Fondation%3A%3ALayout%3A%3ABootstrap)
to be loaded.

# NAME

Mojolicious::Plugin::Fondation::User::UI::Bootstrap — Bootstrap 5 web UI for Fondation::User

# VERSION

version 0.01

# ROUTES

## GET /users

- Condition: `fondation.perm => user_list`
- Controller: `User`
- Action: `index`

Renders the user management page with a Bootstrap 5 DataTable listing all
users. The table supports inline editing, role/group assignment, and
activation/deactivation via modal dialogs provided by the plugin's templates
and JavaScript assets.

# CONFIGURATION

    'Fondation::User::UI::Bootstrap' => {
        title => 'User Management',
    };

- `title` — page title displayed in the UI. Defaults to `User Management`.

# RESOURCES

The plugin ships with:

- `share/templates/` — EP templates for user listing and modals
- `share/public/` — JavaScript modules (`DatatableUser.js`) for client-side DataTable initialization
- `share/translations/` — i18n lexicons (en, fr)

# SEE ALSO

- [Mojolicious::Plugin::Fondation::User](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AUser) — the user management engine
- [Mojolicious::Plugin::Fondation::Layout::Bootstrap](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3ALayout%3A%3ABootstrap) — Bootstrap 5 layout
- [Mojolicious::Plugin::Fondation::Action::REST](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AFondation%3A%3AAction%3A%3AREST) — generic REST actions

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# AUTHOR

Daniel Brosseau <dab@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
